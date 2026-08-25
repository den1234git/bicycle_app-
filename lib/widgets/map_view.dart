import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatelessWidget {
  final LatLng currentPos;

  final Set<Marker> markers;
  final Set<Polyline> polylines;

  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;

  final Function(GoogleMapController) onMapCreated;

  final VoidCallback? onCameraMoveStarted;
  final VoidCallback? onCameraIdle;

  final Function(CameraPosition)? onCameraMove;

  const MapView({
    super.key,
    required this.currentPos,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
    this.onTap,
    this.onLongPress,
    this.onCameraMoveStarted,
    this.onCameraIdle,
    this.onCameraMove,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: currentPos,
        zoom: 15,
      ),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      markers: markers,
      polylines: polylines,
      onMapCreated: onMapCreated,
      onTap: onTap,
      onLongPress: onLongPress,
      onCameraMoveStarted: () {
        onCameraMoveStarted?.call();
      },
      onCameraMove: (position) {
        onCameraMove?.call(position);
      },
      onCameraIdle: () {
        onCameraIdle?.call();
      },
    );
  }
}
