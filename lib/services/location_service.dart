import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<void> init() async {
    await Geolocator.requestPermission();
  }

  Stream<Position> getStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    );
  }
}
