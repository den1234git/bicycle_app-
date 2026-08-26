enum MapStyleMode { standard, night, minimal }

class MapStyles {
  static MapStyleMode current = MapStyleMode.standard;

  static MapStyleMode next() {
    current = MapStyleMode.values[(current.index + 1) % MapStyleMode.values.length];
    return current;
  }

  static String label(MapStyleMode mode) {
    switch (mode) {
      case MapStyleMode.standard:
        return '標準';
      case MapStyleMode.night:
        return '夜間';
      case MapStyleMode.minimal:
        return 'シンプル';
    }
  }

  static String get currentStyle => styleFor(current);

  static String styleFor(MapStyleMode mode) {
    switch (mode) {
      case MapStyleMode.standard:
        return _standard;
      case MapStyleMode.night:
        return _night;
      case MapStyleMode.minimal:
        return _minimal;
    }
  }
}

const String mapStyle = _standard;

const String _standard = '''
[
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ff8800"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#ff6600"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';

const String _night = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ff8800"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#ff6600"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]}
]
''';

const String _minimal = '''
[
  {"elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#cccccc"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#aaaaaa"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9e8f5"}]}
]
''';
