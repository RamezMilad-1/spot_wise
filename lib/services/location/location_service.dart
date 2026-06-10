import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// GPS access via `geolocator`, with graceful degradation: if location is off,
/// denied, or unavailable (e.g. desktop without permission) it returns null and
/// callers fall back to a sensible default centre.
class LocationService {
  /// Used when the device can't give us a position (Cairo — a seeded city).
  static const LatLng fallbackCenter = LatLng(30.0444, 31.2357);

  Future<LatLng?> getCurrent() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  double distanceMeters(LatLng a, LatLng b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );
}
