import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WeatherInfo {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final bool willRain;
  final int? rainInHours;

  WeatherInfo({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.willRain,
    this.rainInHours,
  });

  String get summary {
    final temp = '${temperature.round()}°C';
    final wind = windSpeed > 5 ? ' 風${windSpeed.round()}m/s' : '';
    final rain = willRain ? ' ${rainInHours}時間後に雨' : '';
    return '$temp ${_weatherLabel(weatherCode)}$wind$rain';
  }

  static String _weatherLabel(int code) {
    if (code == 0) return '☀️ 快晴';
    if (code <= 3) return '⛅ くもり';
    if (code <= 48) return '🌫️ 霧';
    if (code <= 57) return '🌧️ 霧雨';
    if (code <= 65) return '🌧️ 雨';
    if (code <= 67) return '🌧️ 冷たい雨';
    if (code <= 77) return '❄️ 雪';
    if (code <= 82) return '🌧️ にわか雨';
    if (code <= 86) return '❄️ にわか雪';
    if (code <= 99) return '⛈️ 雷雨';
    return '🌤️';
  }
}

class WeatherService {
  static Future<WeatherInfo?> fetch(LatLng pos) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${pos.latitude}'
      '&longitude=${pos.longitude}'
      '&current=temperature_2m,weather_code,wind_speed_10m'
      '&hourly=precipitation_probability'
      '&forecast_hours=6'
      '&timezone=Asia%2FTokyo',
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);

      final current = data['current'];
      final hourlyProb = data['hourly']?['precipitation_probability'] as List?;

      bool willRain = false;
      int? rainInHours;
      if (hourlyProb != null) {
        for (int i = 0; i < hourlyProb.length; i++) {
          if ((hourlyProb[i] as num) > 50) {
            willRain = true;
            rainInHours = i + 1;
            break;
          }
        }
      }

      return WeatherInfo(
        temperature: (current['temperature_2m'] as num).toDouble(),
        weatherCode: current['weather_code'] as int,
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        willRain: willRain,
        rainInHours: rainInHours,
      );
    } catch (_) {
      return null;
    }
  }
}
