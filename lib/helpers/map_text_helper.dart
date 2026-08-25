import '../state/map_state.dart';

class MapTextHelper {
  static String modeText(TransportMode mode) {
    switch (mode) {
      case TransportMode.bike:
        return "🚲";
      case TransportMode.train:
        return "🚃";
      case TransportMode.walk:
        return "🚶";
    }
  }

  static String viewText(dynamic mode) {
    switch (mode.toString()) {
      case 'ViewMode.walk':
        return "🚶";
      case 'ViewMode.bike':
        return "🚲";
      default:
        return "🐤";
    }
  }

  static String routeModeText(RouteMode mode) {
    switch (mode) {
      case RouteMode.fast:
        return "F";
      case RouteMode.safe:
        return "S";
      case RouteMode.scenic:
        return "C";
    }
  }
}
