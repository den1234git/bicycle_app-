import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

enum OsmPoiType {
  bicycleParking,
  bicycleShop,
  drinkingWater,
  toilet,
}

class OsmPoi {
  final OsmPoiType type;
  final LatLng position;
  final String? name;

  OsmPoi({required this.type, required this.position, this.name});

  String get label {
    switch (type) {
      case OsmPoiType.bicycleParking:
        return '駐輪場';
      case OsmPoiType.bicycleShop:
        return '自転車店';
      case OsmPoiType.drinkingWater:
        return '給水所';
      case OsmPoiType.toilet:
        return 'トイレ';
    }
  }

  BitmapDescriptor get markerIcon {
    switch (type) {
      case OsmPoiType.bicycleParking:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case OsmPoiType.bicycleShop:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case OsmPoiType.drinkingWater:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case OsmPoiType.toilet:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }
}

class OsmDataService {
  static Future<List<OsmPoi>> fetchNearby(LatLng pos, {double radiusM = 500}) async {
    final query = '''
[out:json][timeout:10];
(
  node["amenity"="bicycle_parking"](around:$radiusM,${pos.latitude},${pos.longitude});
  node["shop"="bicycle"](around:$radiusM,${pos.latitude},${pos.longitude});
  node["amenity"="drinking_water"](around:$radiusM,${pos.latitude},${pos.longitude});
  node["amenity"="toilets"](around:$radiusM,${pos.latitude},${pos.longitude});
);
out body;
''';

    final url = Uri.parse('https://overpass-api.de/api/interpreter');

    try {
      final res = await http.post(url, body: {'data': query});
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final elements = data['elements'] as List;

      return elements.map((e) {
        final tags = e['tags'] as Map<String, dynamic>? ?? {};
        final lat = (e['lat'] as num).toDouble();
        final lng = (e['lon'] as num).toDouble();

        OsmPoiType type;
        if (tags['shop'] == 'bicycle') {
          type = OsmPoiType.bicycleShop;
        } else if (tags['amenity'] == 'bicycle_parking') {
          type = OsmPoiType.bicycleParking;
        } else if (tags['amenity'] == 'drinking_water') {
          type = OsmPoiType.drinkingWater;
        } else {
          type = OsmPoiType.toilet;
        }

        return OsmPoi(
          type: type,
          position: LatLng(lat, lng),
          name: tags['name'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
