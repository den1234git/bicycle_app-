enum CommutePhase {
  bike,
  train,
  walk,
  arrived,
}

class CommuteController {
  static CommutePhase next(
    CommutePhase current,
  ) {
    switch (current) {
      case CommutePhase.bike:
        return CommutePhase.train;

      case CommutePhase.train:
        return CommutePhase.walk;

      case CommutePhase.walk:
        return CommutePhase.arrived;

      case CommutePhase.arrived:
        return CommutePhase.arrived;
    }
  }

  static String label(
    CommutePhase phase,
  ) {
    switch (phase) {
      case CommutePhase.bike:
        return '🚲';

      case CommutePhase.train:
        return '🚃';

      case CommutePhase.walk:
        return '🚶';

      case CommutePhase.arrived:
        return '✓';
    }
  }
}
