import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'database.dart';

/// Auto-logging service with fixes:
/// - Requires explicit user consent before collecting location
/// - Deduplicates: only logs once per day per type
/// - Has proper error handling for permission denied
class AutoLogger {
  final AppDatabase _db;

  AutoLogger(this._db);

  /// Run auto-logging for today. Returns number of logs created.
  /// [locationConsent] must be true for location to be logged.
  Future<int> logToday({required bool locationConsent}) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    int created = 0;

    if (locationConsent) {
      final coords = await _logLocation(dateStr);
      if (coords != null) {
        created++;
        created += await _logWeather(dateStr, coords.$1, coords.$2);
      }
    }

    return created;
  }

  /// Returns (lat, lng) if location was newly logged, null if skipped/failed.
  Future<(double, double)?> _logLocation(String dateStr) async {
    if (await _db.hasLogForDateAndType(dateStr, 'location')) {
      // Already logged — return existing coords for weather
      return null;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // ~1km precision for privacy
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reduce precision for privacy (round to ~1km)
      final lat = (position.latitude * 100).roundToDouble() / 100;
      final lng = (position.longitude * 100).roundToDouble() / 100;

      await _db.addLog(
        date: dateStr,
        type: 'location',
        data: {'latitude': lat, 'longitude': lng},
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      return (lat, lng);
    } catch (_) {
      return null;
    }
  }

  Future<int> _logWeather(String dateStr, double lat, double lng) async {
    if (await _db.hasLogForDateAndType(dateStr, 'weather')) return 0;

    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lng'
        '&current=temperature_2m,weather_code'
        '&timezone=auto',
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return 0;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>?;
      if (current == null) return 0;

      final temp = (current['temperature_2m'] as num?)?.round();
      final code = (current['weather_code'] as num?)?.toInt();
      if (temp == null || code == null) return 0;

      await _db.addLog(
        date: dateStr,
        type: 'weather',
        data: {'temp': temp, 'condition': _wmoToCondition(code)},
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      return 1;
    } catch (_) {
      return 0;
    }
  }

  /// Maps WMO weather code to a human-readable condition string.
  static String _wmoToCondition(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain Showers';
    if (code <= 86) return 'Snow Showers';
    return 'Thunderstorm';
  }
}
