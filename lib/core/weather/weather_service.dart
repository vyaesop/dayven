import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  const WeatherData({
    required this.temperatureC,
    required this.description,
    required this.icon,
    required this.color,
    required this.city,
  });

  final double temperatureC;
  final String description;
  final IconData icon;
  final Color color;
  final String city;

  int get temperatureF => (temperatureC * 9 / 5 + 32).round();
}

class WeatherService {
  static const _prefsKey = 'weather_cache_v1';
  static const _locationKey = 'weather_location_v1';

  static WeatherService? _instance;
  static WeatherService get instance => _instance ??= WeatherService._();
  WeatherService._();

  WeatherData? _cached;
  String? _cachedDate;

  Future<WeatherData?> getWeather() async {
    final today = _dateString(DateTime.now());
    if (_cached != null && _cachedDate == today) return _cached;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map['date'] == today) {
          _cached = _fromMap(map);
          _cachedDate = today;
          return _cached;
        }
      }
    } catch (_) {}

    return _fetch();
  }

  Future<WeatherData?> _fetch() async {
    try {
      final loc = await _getLocation();
      if (loc == null) return null;

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${loc['lat']}&longitude=${loc['lon']}'
        '&current_weather=true',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final cw = body['current_weather'] as Map<String, dynamic>;
      final tempC = (cw['temperature'] as num).toDouble();
      final code = (cw['weathercode'] as num).toInt();
      final (desc, icon, color) = _fromWmo(code);

      final data = WeatherData(
        temperatureC: tempC,
        description: desc,
        icon: icon,
        color: color,
        city: loc['city'] as String? ?? '',
      );

      _cached = data;
      _cachedDate = _dateString(DateTime.now());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode({
        'date': _cachedDate,
        'tempC': tempC,
        'desc': desc,
        'city': data.city,
        'code': code,
      }));

      return data;
    } catch (e) {
      debugPrint('WeatherService fetch error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_locationKey);
      if (cached != null) {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        // Location cache is valid for 7 days.
        final savedDay = map['day'] as int? ?? 0;
        if (DateTime.now().millisecondsSinceEpoch - savedDay < 7 * 86400000) {
          return map;
        }
      }
    } catch (_) {}

    try {
      final res = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final loc = {
        'lat': body['latitude'],
        'lon': body['longitude'],
        'city': body['city'],
        'country': body['country_code'],
        'day': DateTime.now().millisecondsSinceEpoch,
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locationKey, jsonEncode(loc));
      return loc;
    } catch (e) {
      debugPrint('WeatherService location error: $e');
      return null;
    }
  }

  WeatherData _fromMap(Map<String, dynamic> map) {
    final code = (map['code'] as num?)?.toInt() ?? 0;
    final (desc, icon, color) = _fromWmo(code);
    return WeatherData(
      temperatureC: (map['tempC'] as num).toDouble(),
      description: desc,
      icon: icon,
      color: color,
      city: map['city'] as String? ?? '',
    );
  }

  // WMO Weather interpretation codes → (description, icon, color)
  (String, IconData, Color) _fromWmo(int code) {
    if (code == 0) return ('clear', Icons.wb_sunny_rounded, const Color(0xFFE1C06C));
    if (code <= 2) return ('partly cloudy', Icons.wb_cloudy_rounded, const Color(0xFFB0A8C8));
    if (code == 3) return ('overcast', Icons.cloud_rounded, const Color(0xFFB0A8C8));
    if (code <= 48) return ('foggy', Icons.cloud_rounded, const Color(0xFF9BA8A8));
    if (code <= 67) return ('rain', Icons.water_drop_rounded, const Color(0xFF6BBCB8));
    if (code <= 77) return ('snow', Icons.ac_unit_rounded, const Color(0xFFADD8E6));
    if (code <= 82) return ('showers', Icons.water_drop_rounded, const Color(0xFF6BBCB8));
    if (code <= 86) return ('snow showers', Icons.ac_unit_rounded, const Color(0xFFADD8E6));
    return ('thunderstorm', Icons.thunderstorm_rounded, const Color(0xFF8B7BAA));
  }

  String _dateString(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
