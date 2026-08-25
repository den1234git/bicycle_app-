import '../state/map_state.dart';

class ModeController {
  static ViewMode nextViewMode(ViewMode current) {
    return current == ViewMode.walk
        ? ViewMode.bike
        : current == ViewMode.bike
            ? ViewMode.bird
            : ViewMode.walk;
  }

  static RouteMode nextRouteMode(RouteMode current) {
    return current == RouteMode.fast
        ? RouteMode.safe
        : current == RouteMode.safe
            ? RouteMode.scenic
            : RouteMode.fast;
  }
}
