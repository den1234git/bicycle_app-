import 'dart:async';
import 'widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:audioplayers/audioplayers.dart';

import 'map_style.dart';
import 'dart:math';

import 'widgets/top_bar.dart';
import 'widgets/map_view.dart';
import 'widgets/more_page.dart';

import 'dialogs/sos_dialog.dart';
import 'dialogs/hazard_dialog.dart';
import 'models/hazard_report.dart';
import 'services/hazard_store.dart';
import 'widgets/shiba_marker.dart';
import 'services/weather_service.dart';
import 'services/osm_data_service.dart';
import 'services/ride_tracker.dart';
import 'models/ride_report.dart';
import 'helpers/map_text_helper.dart';

import 'controllers/sensor_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/commute_controller.dart';
import 'controllers/route_controller.dart';
import 'controllers/gps_update_controller.dart';

import 'services/camera_service.dart';
import 'services/train_mode_service.dart';
import 'services/location_store.dart';

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

  LatLng currentPos = const LatLng(35.681236, 139.767125);

  LatLng? dragStartTarget;
  LatLng? currentCameraTarget;
  LatLng? homePos;
  LatLng? companyPos;

  String? selectingLocationType;

  OverlayEntry? trainPopup;
  final AudioPlayer trainPlayer = AudioPlayer();

  bool isProgrammaticMove = false;
  Timer? _programmaticTimer;
  bool hasMoved = false;
  bool _trainAlertFired = false;

  DateTime lastRouteTime = DateTime.now();
  DateTime lastUiUpdate = DateTime.now();

  Timer? clockTimer;
  final searchController = TextEditingController();
  final sensorController = SensorController();
  String nowTime = "--:--";

  BitmapDescriptor? walkIcon;
  BitmapDescriptor? bikeIcon;
  BitmapDescriptor? shibaIcon;
  List<HazardReport> hazardReports = [];
  String? weatherText;
  List<OsmPoi> osmPois = [];
  DateTime? _lastOsmFetch;
  final rideTracker = RideTracker();

  void setProgrammaticMove() {
    NavLogger.camera('SET PROGRAMMATIC TRUE');
    isProgrammaticMove = true;
    _programmaticTimer?.cancel();
    _programmaticTimer = Timer(const Duration(seconds: 2), () {
      NavLogger.camera('SET PROGRAMMATIC FALSE');
      isProgrammaticMove = false;
    });
  }

  // ── 初期化 ──

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
    _loadHazardReports();
    _fetchWeather();
    WakelockPlus.enable();
    _initGps();
    _initCompass();
    _startClock();
    _loadMarkerIcons();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    clockTimer?.cancel();
    _programmaticTimer?.cancel();
    searchController.dispose();
    sensorController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocations() async {
    final home = await LocationStore.loadHome();
    final work = await LocationStore.loadWork();
    setState(() {
      if (home != null) homePos = LatLng(home['lat']!, home['lng']!);
      if (work != null) companyPos = LatLng(work['lat']!, work['lng']!);
    });
  }

  Future<void> _loadHazardReports() async {
    final reports = await HazardStore.load();
    setState(() => hazardReports = reports);
  }

  Future<void> _fetchWeather() async {
    final info = await WeatherService.fetch(currentPos);
    if (info != null && mounted) {
      setState(() => weatherText = info.summary);
    }
  }

  Future<void> _fetchOsmPois() async {
    final now = DateTime.now();
    if (_lastOsmFetch != null && now.difference(_lastOsmFetch!).inSeconds < 60) return;
    _lastOsmFetch = now;
    final pois = await OsmDataService.fetchNearby(currentPos);
    if (mounted) setState(() => osmPois = pois);
  }

  void _initCompass() {
    sensorController.startCompass(
      getCurrentHeading: () => mapState.heading,
      getSensorHeading: () => mapState.heading,
      isActive: () => true,
      onRotate: (_) {},
    );
  }

  void _startClock() {
    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      nowTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      if (mounted) setState(() {});
    });
  }

  // ── GPS ──

  void _initGps() {
    sensorController.startGps(
      isActive: () => true,
      onUpdate: _onGpsUpdate,
    );
  }

  bool _draggedWhileStopped = false;

  Future<void> _onGpsUpdate(LatLng pos, double spd, double hdg) async {
    currentPos = pos;
    mapState.speed = spd;

    if (_draggedWhileStopped && spd > 3) {
      _draggedWhileStopped = false;
      setState(() {
        mapState.isFollowing = true;
      });
    }

    rideTracker.recordPosition(currentPos, spd);

    if (GpsUpdateController.detectSuddenBrake(currentSpeed: spd)) {
      final report = await HazardStore.addReport(
        type: HazardType.suddenBrake,
        position: currentPos,
      );
      rideTracker.recordHazard(report);
      setState(() => hazardReports.add(report));
    }

    mapState.smoothedHeading = GpsUpdateController.smoothHeading(
      currentHeading: mapState.smoothedHeading,
      newHeading: hdg,
    );
    mapState.heading = mapState.smoothedHeading;

    if (mapState.goal != null &&
        GpsUpdateController.shouldShowTurnGuide(
          currentPos: currentPos,
          routePoints: mapState.routePoints,
        )) {
      mapState.nextGuideText = 'まもなく曲がります';
    }

    if (mapState.isFollowing &&
        !mapState.isRouteOverview &&
        mapController != null) {
      CameraService.updateCamera(
        isFollowing: true,
        isRouteOverview: false,
        mapController: mapController,
        currentPos: currentPos,
        goal: mapState.goal,
        heading: mapState.heading,
        speed: mapState.speed,
        preset: CameraService.presetFromViewMode(mapState.viewMode),
        onProgrammaticMove: setProgrammaticMove,
      );
    }

    GpsUpdateController.handleInitialCamera(
      hasMoved: hasMoved,
      controller: mapController,
      currentPos: currentPos,
      setHasMoved: (v) => hasMoved = v,
      onProgrammaticMove: setProgrammaticMove,
    );

    if (mapState.goal != null &&
        GpsUpdateController.shouldReroute(
          currentPos: currentPos,
          routePoints: mapState.routePoints,
          lastRouteTime: lastRouteTime,
        )) {
      lastRouteTime = DateTime.now();
      mapState.nextGuideText = '再検索中...';
      await _generateRoute();
    }

    if (mapState.goal != null &&
        GpsUpdateController.shouldArrive(
          currentPos: currentPos,
          goal: mapState.goal!,
          threshold: 0.0001,
        )) {
      final report = await rideTracker.stop(mapState.routeDistanceKm);
      setState(() {
        mapState.clearRoute();
      });
      if (report != null && mounted) {
        _showRideResult(report);
      }
    }

    if (mapState.transportMode == TransportMode.train &&
        mapState.goal != null &&
        !_trainAlertFired) {
      final distM = NavigationMath.distanceMeters(currentPos, mapState.goal!);
      if (distM < 300) {
        _trainAlertFired = true;
        await TrainModeService.alertArrival(
          stationName: '目的地',
          distanceM: distM,
        );
      }
    }

    if (mapState.routePoints.isNotEmpty) {
      mapState.routeProgress = GpsUpdateController.routeProgress(
        currentPos: currentPos,
        routePoints: mapState.routePoints,
      );
    }

    _fetchOsmPois();

    if (GpsUpdateController.shouldUpdateUi(lastUiUpdate: lastUiUpdate)) {
      lastUiUpdate = DateTime.now();
      if (mounted) setState(() {});
    }
  }

  // ── ルート ──

  Future<void> _generateRoute() async {
    if (mapState.goal == null) return;

    final route = await RouteController.previewRoute(
      currentPos,
      mapState.goal!,
      mapState.routeMode.name,
      transportMode: mapState.transportMode,
    );

    final km = RouteController.calcDistanceKm(route);
    final eta =
        RouteController.calcEta(km, mapState.speed < 5 ? 15 : mapState.speed);

    setState(() {
      mapState.routePoints = route;
      mapState.routeProgress = 0;
      mapState.routeDistanceKm = km;
      mapState.etaText = eta;
      mapState.nextGuideText = 'ルート案内中';
    });
  }

  Future<void> _generateAllRoutes() async {
    if (mapState.goal == null) return;

    final spd = mapState.speed < 5 ? 15.0 : mapState.speed;
    final futures = RouteMode.values.map((mode) async {
      final route = await RouteController.previewRoute(
        currentPos,
        mapState.goal!,
        mode.name,
        transportMode: mapState.transportMode,
      );
      final km = RouteController.calcDistanceKm(route);
      final eta = RouteController.calcEta(km, spd);
      return MapEntry(mode, (route: route, km: km, eta: eta));
    });

    final results = await Future.wait(futures);

    setState(() {
      for (final entry in results) {
        mapState.candidateRoutes[entry.key] = entry.value.route;
        mapState.candidateDistances[entry.key] = entry.value.km;
        mapState.candidateEtas[entry.key] = entry.value.eta;
      }
      final selected = mapState.routeMode;
      mapState.routePoints = mapState.candidateRoutes[selected] ?? [];
      mapState.routeDistanceKm = mapState.candidateDistances[selected] ?? 0;
      mapState.etaText = mapState.candidateEtas[selected] ?? '--';
      mapState.routeProgress = 0;
    });
  }

  void _selectRouteMode(RouteMode mode) {
    if (mapState.candidateRoutes.isEmpty) return;
    setState(() {
      mapState.routeMode = mode;
      mapState.routePoints = mapState.candidateRoutes[mode] ?? [];
      mapState.routeDistanceKm = mapState.candidateDistances[mode] ?? 0;
      mapState.etaText = mapState.candidateEtas[mode] ?? '--';
    });
  }

  Future<void> _showFullView() async {
    if (mapState.goal == null) return;
    await _generateAllRoutes();
    setState(() {
      mapState.isRouteOverview = true;
      mapState.isFullView = true;
      mapState.isFollowing = false;
      mapState.appMode = AppMode.preview;
      mapState.nextGuideText = 'ルートを選択してください';
    });
  }

  void _startNavigation() {
    if (!NavigationController.canStartNavigation(mapState.routePoints)) return;

    rideTracker.start();
    if (weatherText != null) {
      rideTracker.setWeather(weatherText!, 0);
    }

    setState(() {
      mapState.candidateRoutes.clear();
      mapState.candidateDistances.clear();
      mapState.candidateEtas.clear();
      mapState.isRouteOverview = false;
      mapState.isFollowing = true;
      mapState.appMode = AppMode.navigating;
    });

    setProgrammaticMove();
    CameraService.reset();
    CameraService.updateCamera(
      isFollowing: true,
      isRouteOverview: false,
      mapController: mapController,
      currentPos: currentPos,
      goal: mapState.goal,
      heading: mapState.heading,
      speed: mapState.speed,
      preset: CameraService.presetFromViewMode(mapState.viewMode),
      onProgrammaticMove: setProgrammaticMove,
    );
  }

  void _cancelRoute() async {
    if (rideTracker.isTracking) {
      final report = await rideTracker.stop(mapState.routeDistanceKm);
      if (report != null && mounted) _showRideResult(report);
    }
    setState(() {
      mapState.clearRoute();
      searchController.clear();
    });
  }

  Future<void> _searchPlace() async {
    final result =
        await RouteController.searchPlaceFromText(searchController.text);
    if (result == null) return;

    setState(() {
      mapState.goal = result;
      mapState.isFollowing = false;
    });

    mapController?.animateCamera(CameraUpdate.newLatLngZoom(result, 17));
    await _showFullView();
  }

  // ── モード切替 ──

  void _changeMode() async {
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
      mapState.isFollowing = next != TransportMode.train;
    });

    if (next == TransportMode.train) {
      _showTrainPopup(title: '🚆 電車モード開始', subtitle: '乗過ごし防止 ON');
      await TrainModeService.start(text: '乗過ごし防止 ON');
      Future.delayed(const Duration(seconds: 2), () {
        FlutterForegroundTask.minimizeApp();
      });
    } else {
      _trainAlertFired = false;
      final running = await TrainModeService.isRunning();
      if (running) await TrainModeService.stop();
    }
  }

  void _changeViewMode() {
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
      heading: mapState.heading,
      speed: mapState.speed,
      preset: CameraService.presetFromViewMode(mapState.viewMode),
      onProgrammaticMove: () {},
    );
  }

  // ── 電車ポップアップ ──

  void _showTrainPopup({required String title, required String subtitle}) {
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.88),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(trainPopup!);

    Future.delayed(const Duration(seconds: 2), () {
      trainPopup?.remove();
      trainPopup = null;
    });
  }

  void _showRideResult(RideReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Text(
              report.grade,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: report.safetyScore >= 75 ? Colors.green : report.safetyScore >= 50 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('走行レポート', style: TextStyle(color: Colors.white, fontSize: 16)),
                Text('安全スコア: ${report.safetyScore}点', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _reportRow('距離', '${report.distanceKm.toStringAsFixed(1)} km'),
            _reportRow('時間', '${report.durationMinutes}分'),
            _reportRow('平均速度', '${report.avgSpeedKmh.toStringAsFixed(1)} km/h'),
            _reportRow('最高速度', '${report.maxSpeedKmh.toStringAsFixed(1)} km/h'),
            _reportRow('急ブレーキ', '${report.suddenBrakeCount}回'),
            _reportRow('ハザード', '${report.hazardCount}件'),
            if (report.nightRide) _reportRow('夜間走行', 'あり'),
            if (report.weather != null) _reportRow('天気', report.weather!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── カメラ ──

  void _onCameraIdle() {
    if (dragStartTarget == null || currentCameraTarget == null) return;

    final start = dragStartTarget!;
    final end = currentCameraTarget!;
    final moved = (start.latitude - end.latitude).abs() +
        (start.longitude - end.longitude).abs();

    NavLogger.camera(
      'idle programmatic=$isProgrammaticMove following=${mapState.isFollowing} moved=$moved',
    );

    if (isProgrammaticMove) return;

    if (moved > 0.00002 && mapState.isFollowing) {
      NavLogger.follow('FOLLOW OFF BY DRAG moved=$moved speed=${mapState.speed}');
      setState(() => mapState.isFollowing = false);
      if (mapState.speed < 3) {
        _draggedWhileStopped = true;
      }
    }
  }

  // ── マーカー / ポリライン ──

  Future<void> _loadMarkerIcons() async {
    walkIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(20, 20)),
      'assets/icons/walk_marker.png',
    );
    bikeIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/icons/bike001.png',
    );
    shibaIcon = await createShibaMarker(size: 80);
    if (mounted) setState(() {});
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('me'),
        position: currentPos,
        rotation: mapState.heading,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 10,
        icon: shibaIcon ?? bikeIcon ?? BitmapDescriptor.defaultMarker,
      ),
      if (mapState.goal != null)
        Marker(
          markerId: const MarkerId('goal'),
          position: mapState.goal!,
        ),
      ...osmPois.map((poi) => Marker(
            markerId: MarkerId('osm_${poi.position.latitude}_${poi.position.longitude}'),
            position: poi.position,
            icon: poi.markerIcon,
            infoWindow: InfoWindow(
              title: poi.label,
              snippet: poi.name,
            ),
          )),
      ...hazardReports.map((r) => Marker(
            markerId: MarkerId('hazard_${r.id}'),
            position: r.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              r.type == HazardType.suddenBrake
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueYellow,
            ),
            infoWindow: InfoWindow(
              title: HazardReport.labelFor(r.type),
              snippet: r.note,
            ),
          )),
    };
  }

  static const _routeColors = {
    RouteMode.fast: Color(0xFFFF5722),
    RouteMode.safe: Color(0xFF4CAF50),
    RouteMode.scenic: Color(0xFF2196F3),
  };

  Set<Polyline> _buildPolylines() {
    final candidatePolylines = <Polyline>{};
    if (mapState.appMode == AppMode.preview &&
        mapState.candidateRoutes.length > 1) {
      for (final mode in RouteMode.values) {
        final pts = mapState.candidateRoutes[mode];
        if (pts == null || pts.isEmpty) continue;
        final isSelected = mode == mapState.routeMode;
        candidatePolylines.add(Polyline(
          polylineId: PolylineId('candidate_${mode.name}'),
          points: pts,
          width: isSelected ? 7 : 4,
          color: isSelected
              ? _routeColors[mode]!
              : _routeColors[mode]!.withOpacity(0.35),
          zIndex: isSelected ? 2 : 1,
        ));
      }
    }

    return {
      ...candidatePolylines,
      if (candidatePolylines.isEmpty && mapState.routePoints.isNotEmpty)
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
            currentPos.latitude + 0.0002 * cos(mapState.heading * pi / 180),
            currentPos.longitude + 0.0002 * sin(mapState.heading * pi / 180),
          ),
        ],
        width: 4,
        color: const Color(0xFF4CAF50),
      ),
    };
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapView(
              currentPos: currentPos,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              onMapCreated: (c) {
                mapController = c;
                c.setMapStyle(mapStyle);
              },
              onTap: (pos) async {
                setState(() {
                  mapState.goal = pos;
                  mapState.isFollowing = false;
                });
                await _showFullView();
              },
              onLongPress: (pos) async {
                if (selectingLocationType == 'home') {
                  setState(() => homePos = pos);
                  await LocationStore.saveHome(pos.latitude, pos.longitude);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('自宅を登録しました')),
                  );
                }
                if (selectingLocationType == 'company') {
                  setState(() => companyPos = pos);
                  await LocationStore.saveWork(pos.latitude, pos.longitude);
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
                  'following=${mapState.isFollowing} '
                  'routeOverview=${mapState.isRouteOverview}',
                );
              },
              onCameraIdle: _onCameraIdle,
            ),
          ),
          Positioned(
            top: 45,
            left: 10,
            right: 10,
            child: _buildTopBar(),
          ),
          Positioned(
            bottom: 22,
            left: 8,
            right: 8,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return TopBar(
      controller: searchController,
      speed: mapState.speed,
      dangerValue: 0,
      routeModeText: mapState.routeMode == RouteMode.fast
          ? 'F'
          : mapState.routeMode == RouteMode.safe
              ? 'S'
              : 'C',
      onSearch: _searchPlace,
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
                    mapState.isFollowing = false;
                    mapState.isRouteOverview = true;
                  });
                  await _generateRoute();
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
                    mapState.isFollowing = false;
                    mapState.isRouteOverview = true;
                  });
                  await _generateRoute();
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
        final selected = mode == 'F'
            ? RouteMode.fast
            : mode == 'S'
                ? RouteMode.safe
                : RouteMode.scenic;
        if (mapState.candidateRoutes.isNotEmpty) {
          _selectRouteMode(selected);
        } else {
          setState(() => mapState.routeMode = selected);
          if (mapState.goal != null) _generateRoute();
        }
      },
      onProfile: _showFullView,
      onCancel: _cancelRoute,
      onGo: () async {
        await _showFullView();
        _startNavigation();
      },
      isNavigating: mapState.appMode == AppMode.navigating,
      weatherText: weatherText,
      mapStyleLabel: MapStyles.label(MapStyles.current),
      onMapStyle: () {
        final next = MapStyles.next();
        mapController?.setMapStyle(MapStyles.styleFor(next));
        setState(() {});
      },
      isFullView: mapState.isFullView,
      distanceKm: mapState.routeDistanceKm,
      etaText: mapState.etaText,
      guideText: mapState.nextGuideText,
    );
  }

  Widget _buildBottomBar() {
    return BottomBar(
      nowTime: nowTime,
      speed: mapState.speed,
      showSpeed: false,
      onTimeTap: () {},
      onTimeLongPress: () async {
        final report = await showHazardReportDialog(
          context,
          position: currentPos,
        );
        if (report != null) {
          setState(() => hazardReports.add(report));
        }
      },
      modeText: MapTextHelper.modeText(mapState.transportMode),
      viewText: MapTextHelper.viewText(mapState.viewMode),
      commuteText: CommuteController.label(commutePhase),
      walkMode: mapState.transportMode == TransportMode.walk,
      isTrainMode: mapState.transportMode == TransportMode.train,
      onCurrent: () {
        NavLogger.follow('GPS button tapped');
        _draggedWhileStopped = false;
        setProgrammaticMove();
        setState(() {
          mapState.isRouteOverview = false;
          mapState.isFollowing = true;
        });
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentPos, 19.8),
        );
      },
      onMode: _changeMode,
      onViewMode: _changeViewMode,
      onWait: () {
        FlutterForegroundTask.minimizeApp();
      },
      onWaitLongPress: () {
        _showTrainPopup(title: '🚉 次で降車です', subtitle: '新宿駅まで 240m');
      },
      onSos: () => showSosDialog(
        context,
        currentPos: currentPos,
        transportMode: mapState.transportMode,
      ),
    );
  }
}
