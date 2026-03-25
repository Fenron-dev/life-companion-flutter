import 'package:geolocator/geolocator.dart';
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
      created += await _logLocation(dateStr);
    }

    return created;
  }

  Future<int> _logLocation(String dateStr) async {
    // Check if already logged today
    if (await _db.hasLogForDateAndType(dateStr, 'location')) {
      return 0;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 0;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return 0;
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

      return 1;
    } catch (_) {
      return 0;
    }
  }
}
