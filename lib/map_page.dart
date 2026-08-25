import 'dart:async';
import 'dart:convert';
import 'widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:audioplayers/audioplayers.dart';

import 'map_style.dart';
import 'dart:math';

import 'widgets/top_bar.dart';
import 'widgets/map_view.dart';
import 'widgets/more_page.dart';

import 'dialogs/sos_dialog.dart';
import 'helpers/map_text_helper.dart';

import 'controllers/sensor_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/commute_controller.dart';
import 'controllers/route_controller.dart';
import 'controllers/gps_update_controller.dart';

import 'services/camera_service.dart';
import 'services/train_mode_service.dart';

import 'state/map_state.dart';
import 'utils/nav_logger.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapState = MapState();

  CommutePhase commutePhase = CommutePhase.bike;
  GoogleMapController? mapController;
  DateTime lastCameraUpdate = DateTime.now();

  LatLng currentPos = const LatLng(35.681236, 139.767125);

  LatLng? lastCameraTarget;
  LatLng? homePos;
  LatLng? companyPos;

  LatLng? dragStartTarget;
  LatLng? currentCameraTarget;

  String? selectingLocationType;
  String saveMode = '';

  OverlayEntry? trainPopup;
  final AudioPlayer trainPlayer = AudioPlayer();

  // =========================================================
  // isProgrammaticMove の管理はここだけ。
  // 外から直接 isProgrammaticMove = false と書かない。
  // =========================================================
  bool isProgrammaticMove = false;
  Timer? _programmaticTimer;

  /// プログラムによるカメラ移動を開始する前に必ず呼ぶ。
  /// タイマーが唯一の解除手段。onCameraIdle や他の箇所で
  /// isProgrammaticMove = false と直接書いてはいけない。
  void setProgrammaticMove() {
    NavLogger.camera('SET PROGRAMMATIC TRUE');
    isProgrammaticMove = true;

    _programmaticTimer?.cancel();
    _programmaticTimer = Timer(const Duration(seconds: 2), () {
      NavLogger.camera('SET PROGRAMMATIC FALSE');
      isProgrammaticMove = false;
    });
  }

  void showTrainPopup({
    required String title,
    required String subtitle,
  }) {
    trainPlayer.play(AssetSource('sounds/alert1.mp3'));

    trainPopup?.remove();

    trainPopup = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).size.height * 0.18,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.88),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(trainPopup!);

    // ✅ 修正: isProgrammaticMove の直接操作を削除。
    //    ポップアップの非表示はポップアップ表示だけを担当する。
    Future.delayed(const Duration(seconds: 2), () {
      trainPopup?.remove();
      trainPopup = null;
    });
  }

  Future<void> loadHome() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('homePos');
    if (data == null) return;
    final map = jsonDecode(data);
    setState(() {
      homePos = LatLng(map['lat'], map['lng']);
    });
  }

  Future<void> loadCompany() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('companyPos');
    if (data == null) return;
    final map = jsonDecode(data);
    setState(() {
      companyPos = LatLng(map['lat'], map['lng']);
    });
  }

  double speed = 0;
  double heading = 0;
  double smoothedHeading = 0;

  bool isFollowing = true;
  bool showSpeed = false;
  bool isRouteOverview = false;
  bool isFullView = false;
  bool hasMoved = false;
  bool isCameraLocked = false;
  bool _trainAlertFired = false; // ✅ 追加: 目的地接近アラートの重複防止

  double routeDistanceKm = 0;
  String etaText = "--";

  DateTime lastRouteTime = DateTime.now();

  Timer? clockTimer;

  final searchController = TextEditingController();
  final sensorController = SensorController();

  String nowTime = "--:--";

  DateTime lastCameraMove = DateTime.now();
  DateTime lastUiUpdate = DateTime.now();

  BitmapDescriptor? walkIcon;
  BitmapDescriptor? bikeIcon;

  @override
  void initState() {
    super.initState();

    loadHome();
    loadCompany();

    WakelockPlus.enable();

    sensorController.startGps(
      isActive: () => true,
      onUpdate: (pos, spd, hdg) async {
        NavLogger.follow(
            'isFollowing=$isFollowing routeOverview=$isRouteOverview');
        NavLogger.gps('pos=$pos speed=$spd heading=$hdg');

        GpsUpdateController.updateBasicState(
          pos: pos,
          spd: spd,
          hdg: hdg,
          setPos: (v) {
            currentPos = v;
          },
          setSpeed: (v) => speed = v,
          setHeading: (_) {},
        );

        if (mapState.goal != null &&
            GpsUpdateController.shouldShowTurnGuide(
              currentPos: currentPos,
              routePoints: mapState.routePoints,
            )) {
          mapState.nextGuideText = 'まもなく曲がります';
        }

        smoothedHeading = GpsUpdateController.smoothHeading(
          currentHeading: smoothedHeading,
          newHeading: hdg,
        );
        heading = smoothedHeading;

        if (isFollowing && !isRouteOverview && mapController != null) {
          CameraService.updateCamera(
            isFollowing: true,
            isRouteOverview: false,
            mapController: mapController,
            currentPos: currentPos,
            goal: mapState.goal,
            heading: heading,
            speed: speed,
            preset: CameraService.presetFromViewMode(mapState.viewMode),
            onProgrammaticMove: setProgrammaticMove,
          );
        }

        GpsUpdateController.handleInitialCamera(
          hasMoved: hasMoved,
          controller: mapController,
          currentPos: currentPos,
          setHasMoved: (v) => hasMoved = v,
          onProgrammaticMove: setProgrammaticMove, // ✅ 追加
        );

        if (mapState.goal != null &&
            GpsUpdateController.shouldReroute(
              currentPos: currentPos,
              routePoints: mapState.routePoints,
              lastRouteTime: lastRouteTime,
            )) {
          lastRouteTime = DateTime.now();
          mapState.nextGuideText = '再検索中...';
          await generateRoute();
        }

        if (mapState.goal != null &&
            GpsUpdateController.shouldArrive(
              currentPos: currentPos,
              goal: mapState.goal!,
              threshold: 0.0001,
            )) {
          setState(() {
            mapState.clearRoute();
            isRouteOverview = false;
          });
        }

        // ✅ 追加: 電車モード時、目的地まで300m以内で接近アラート通知
        if (mapState.transportMode == TransportMode.train &&
            mapState.goal != null &&
            !_trainAlertFired) {
          final distM = NavigationMath.distanceMeters(
            currentPos,
            mapState.goal!,
          );
          if (distM < 300) {
            _trainAlertFired = true;
            await TrainModeService.alertArrival(
              stationName: '目的地',
              distanceM: distM, // alertArrival内でオーバーレイも更新される
            );
          }
        }

        if (mapState.routePoints.isNotEmpty) {
          mapState.routeProgress = GpsUpdateController.routeProgress(
            currentPos: currentPos,
            routePoints: mapState.routePoints,
          );
        }

        if (GpsUpdateController.shouldUpdateUi(lastUiUpdate: lastUiUpdate)) {
          lastUiUpdate = DateTime.now();
          if (mounted) setState(() {});
        }
      },
    );

    sensorController.startCompass(
      getCurrentHeading: () => heading,
      getSensorHeading: () => heading,
      isActive: () => true,
      onRotate: (_) {},
    );

    startClock();
    _loadMarkerIcons();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    clockTimer?.cancel();
    _programmaticTimer?.cancel(); // ✅ 修正: タイマーを確実にキャンセル
    searchController.dispose();
    sensorController.dispose();
    super.dispose();
  }

  void startClock() {
    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      nowTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      if (mounted) setState(() {});
    });
  }

  Future<void> generateRoute() async {
    if (mapState.goal == null) return;

    final route = await RouteController.previewRoute(
      currentPos,
      mapState.goal!,
      mapState.routeMode.name,
      transportMode: mapState.transportMode, // ✅ 修正: モードを反映
    );

    final km = RouteController.calcDistanceKm(route);
    final eta = RouteController.calcEta(km, speed < 5 ? 15 : speed);

    setState(() {
      mapState.routePoints = route;
      mapState.routeProgress = 0;
      routeDistanceKm = km;
      etaText = eta;
      mapState.nextGuideText = 'ルート案内中';
    });
  }

  Future<void> saveHome(LatLng pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'homePos', jsonEncode({'lat': pos.latitude, 'lng': pos.longitude}));
  }

  Future<void> routeToHome() async {
    if (homePos == null) return;
    setState(() {
      mapState.goal = homePos;
      isRouteOverview = false;
      isFollowing = false;
    });
    await generateRoute();
    await showFullView();
  }

  Future<void> routeToCompany() async {
    if (companyPos == null) return;
    setState(() {
      mapState.goal = companyPos;
      isRouteOverview = false;
      isFollowing = false;
    });
    await generateRoute();
    await showFullView();
  }

  Future<void> saveCompany(LatLng pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'companyPos', jsonEncode({'lat': pos.latitude, 'lng': pos.longitude}));
  }

  void changeMode() async {
    final from = mapState.transportMode;

    final next = from == TransportMode.bike
        ? TransportMode.train
        : from == TransportMode.train
            ? TransportMode.walk
            : TransportMode.bike;

    if (from == TransportMode.bike && next == TransportMode.train) {
      await NavLogger.flushWithModeHeader('${from.name} -> ${next.name}');
    }

    setState(() {
      mapState.transportMode = next;
      commutePhase = CommuteController.next(commutePhase);
      isFollowing = next != TransportMode.train;
    });

    if (next == TransportMode.train) {
      showTrainPopup(title: '🚆 電車モード開始', subtitle: '乗過ごし防止 ON');

      await TrainModeService.start(text: '乗過ごし防止 ON');

      // ✅ ポップアップ表示後にアプリを自動で裏に回す
      Future.delayed(const Duration(seconds: 2), () {
        FlutterForegroundTask.minimizeApp();
      });
    } else {
      _trainAlertFired = false; // ✅ 追加: アラートフラグをリセット
      final running = await TrainModeService.isRunning();
      if (running) await TrainModeService.stop();
    }
  }

  void changeViewMode() {
    setState(() {
      mapState.viewMode = ViewMode
          .values[(mapState.viewMode.index + 1) % ViewMode.values.length];
    });

    CameraService.reset();
    setProgrammaticMove();

    CameraService.updateCamera(
      isFollowing: true,
      isRouteOverview: false,
      mapController: mapController,
      currentPos: currentPos,
      goal: mapState.goal,
      heading: heading,
      speed: speed,
      preset: CameraService.presetFromViewMode(mapState.viewMode),
      onProgrammaticMove: () {},
    );
  }

  void cancelRoute() {
    setState(() {
      mapState.clearRoute();
      searchController.clear();
      isFullView = false;
      isRouteOverview = false;
    });
  }

  void startNavigation() {
    if (!NavigationController.canStartNavigation(mapState.routePoints)) return;

    setState(() {
      isRouteOverview = false;
      isFollowing = true;
      mapState.appMode = AppMode.navigating;
    });

    // ✅ 修正: animateCameraの1回だけでなく、CameraServiceで
    //    追従カメラを即座に起動する。これでナビ開始後すぐに
    //    地図が現在地追従モードになる。
    setProgrammaticMove();
    CameraService.reset();
    CameraService.updateCamera(
      isFollowing: true,
      isRouteOverview: false,
      mapController: mapController,
      currentPos: currentPos,
      goal: mapState.goal,
      heading: heading,
      speed: speed,
      preset: CameraService.presetFromViewMode(mapState.viewMode),
      onProgrammaticMove: setProgrammaticMove,
    );
  }

  Future<void> showFullView() async {
    if (mapState.goal == null) return;

    await generateRoute();

    setState(() {
      isRouteOverview = true;
      isFullView = true;
      isFollowing = false;
      mapState.appMode = AppMode.preview;
      mapState.nextGuideText = 'ルート案内中';
    });
  }

  Future<void> searchPlace() async {
    final result =
        await RouteController.searchPlaceFromText(searchController.text);
    if (result == null) return;

    setState(() {
      mapState.goal = result;
      isFollowing = false;
    });

    mapController?.animateCamera(CameraUpdate.newLatLngZoom(result, 17));
    await showFullView();
  }

  Future<void> _loadMarkerIcons() async {
    walkIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(20, 20)),
      'assets/icons/walk_marker.png',
    );
    bikeIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/icons/bike001.png',
    );
    if (mounted) setState(() {});
  }

  // =========================================================
  // onCameraIdle: isProgrammaticMove は「読む」だけ。
  // false への書き込みはタイマーに完全委譲。
  // =========================================================
  void _onCameraIdle() {
    if (dragStartTarget == null || currentCameraTarget == null) {
      // ✅ 修正: ここで isProgrammaticMove = false を書かない
      return;
    }

    final start = dragStartTarget!;
    final end = currentCameraTarget!;

    final moved = (start.latitude - end.latitude).abs() +
        (start.longitude - end.longitude).abs();

    NavLogger.camera(
      'idle programmatic=$isProgrammaticMove following=$isFollowing moved=$moved',
    );

    // ✅ 修正: isProgrammaticMove=true のときはドラッグ判定をスキップするだけ。
    //    false への書き込みは行わない（タイマーが処理する）。
    if (isProgrammaticMove) return;

    if (moved > 0.00002 && isFollowing) {
      NavLogger.follow('FOLLOW OFF BY DRAG moved=$moved');
      setState(() {
        isFollowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapView(
              currentPos: currentPos,
              markers: {
                Marker(
                  markerId: const MarkerId('me'),
                  position: currentPos,
                  rotation: heading,
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                  zIndex: 10,
                  icon: bikeIcon ?? BitmapDescriptor.defaultMarker,
                ),
                if (mapState.goal != null)
                  Marker(
                    markerId: const MarkerId('goal'),
                    position: mapState.goal!,
                  ),
              },
              polylines: {
                if (mapState.routePoints.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: mapState.routePoints,
                    width: 6,
                    color: const Color(0xFFB388FF),
                  ),
                Polyline(
                  polylineId: const PolylineId('heading_line'),
                  points: [
                    currentPos,
                    LatLng(
                      currentPos.latitude + 0.0002 * cos(heading * pi / 180),
                      currentPos.longitude + 0.0002 * sin(heading * pi / 180),
                    ),
                  ],
                  width: 4,
                  color: const Color(0xFF4CAF50),
                ),
              },
              onMapCreated: (c) {
                mapController = c;
                c.setMapStyle(mapStyle);
              },
              onTap: (pos) async {
                setState(() {
                  mapState.goal = pos;
                  isFollowing = false;
                });
                await showFullView();
              },
              onLongPress: (pos) async {
                if (selectingLocationType == 'home') {
                  setState(() => homePos = pos);
                  await saveHome(pos);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('自宅を登録しました')),
                  );
                }

                if (selectingLocationType == 'company') {
                  setState(() => companyPos = pos);
                  await saveCompany(pos);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('会社を登録しました')),
                  );
                }

                selectingLocationType = null;
              },
              onCameraMove: (position) {
                currentCameraTarget = position.target;
              },
              onCameraMoveStarted: () {
                dragStartTarget = currentCameraTarget;

                NavLogger.camera(
                  'moveStarted '
                  'programmatic=$isProgrammaticMove '
                  'following=$isFollowing '
                  'routeOverview=$isRouteOverview',
                );
              },
              onCameraIdle: _onCameraIdle, // ✅ 修正: メソッドに切り出し
            ),
          ),
          Positioned(
            top: 45,
            left: 10,
            right: 10,
            child: TopBar(
              controller: searchController,
              speed: speed,
              dangerValue: 0,
              routeModeText: mapState.routeMode == RouteMode.fast
                  ? 'F'
                  : mapState.routeMode == RouteMode.safe
                      ? 'S'
                      : 'C',
              onSearch: searchPlace,
              onMore: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MorePage(
                      homeRegistered: homePos != null,
                      companyRegistered: companyPos != null,
                      onSelectHome: () async {
                        if (homePos != null) {
                          setState(() {
                            mapState.goal = homePos;
                            isFollowing = false;
                            isRouteOverview = true;
                          });
                          await generateRoute();
                          return;
                        }
                        setState(() => selectingLocationType = 'home');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('地図を長押しして自宅登録')),
                        );
                      },
                      onSelectCompany: () async {
                        if (companyPos != null) {
                          setState(() {
                            mapState.goal = companyPos;
                            isFollowing = false;
                            isRouteOverview = true;
                          });
                          await generateRoute();
                          return;
                        }
                        setState(() => selectingLocationType = 'company');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('地図を長押しして会社登録')),
                        );
                      },
                    ),
                  ),
                );
              },
              onRouteMode: (mode) {
                setState(() {
                  if (mode == 'F') {
                    mapState.routeMode = RouteMode.fast;
                  } else if (mode == 'S') {
                    mapState.routeMode = RouteMode.safe;
                  } else if (mode == 'C') {
                    mapState.routeMode = RouteMode.scenic;
                  }
                });
                if (mapState.goal != null) generateRoute();
              },
              onProfile: showFullView,
              onCancel: cancelRoute,
              onGo: () async {
                // ✅ 修正: showFullView内でgenerateRouteが呼ばれるので
                //    ここでの二重呼び出しを削除
                await showFullView();
                startNavigation();
              },
              isNavigating: mapState.appMode == AppMode.navigating,
              isFullView: isFullView,
              distanceKm: routeDistanceKm,
              etaText: etaText,
              guideText: mapState.nextGuideText,
            ),
          ),
          Positioned(
            bottom: 22,
            left: 8,
            right: 8,
            child: BottomBar(
              nowTime: nowTime,
              speed: speed,
              showSpeed: showSpeed,
              onTimeTap: () {
                setState(() => showSpeed = !showSpeed);
              },
              modeText: MapTextHelper.modeText(mapState.transportMode),
              viewText: MapTextHelper.viewText(mapState.viewMode),
              commuteText: CommuteController.label(commutePhase),
              walkMode: mapState.transportMode == TransportMode.walk,
              isTrainMode: mapState.transportMode == TransportMode.train,
              onCurrent: () {
                NavLogger.follow('GPS button tapped');
                setProgrammaticMove();
                setState(() {
                  isRouteOverview = false;
                  isFollowing = true;
                });
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(currentPos, 19.8),
                );
              },
              onMode: changeMode,
              onViewMode: changeViewMode,
              onWait: () {
                FlutterForegroundTask.minimizeApp();
              },
              onWaitLongPress: () {
                showTrainPopup(title: '🚉 次で降車です', subtitle: '新宿駅まで 240m');
              },
              onSos: () => showSosDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
