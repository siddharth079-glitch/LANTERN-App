import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isMocked;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.isMocked = false,
  });

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';

  String get accuracyLabel => '±${accuracy.toStringAsFixed(1)}m';
}

enum LocationStatus { success, permissionDenied, serviceDisabled, error, stale }

class LocationResult {
  final LocationStatus status;
  final LocationData? data;
  final String? message;

  const LocationResult.success(this.data)
      : status = LocationStatus.success,
        message = null;

  const LocationResult.permissionDenied([this.message = 'Location permission denied by user.'])
      : status = LocationStatus.permissionDenied,
        data = null;

  const LocationResult.serviceDisabled([this.message = 'Device GPS / Location service is turned off.'])
      : status = LocationStatus.serviceDisabled,
        data = null;

  const LocationResult.error(this.message)
      : status = LocationStatus.error,
        data = null;
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.serviceDisabled();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult.permissionDenied();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.permissionDenied(
          'Location permissions are permanently denied. Please enable in Android Settings.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return LocationResult.success(
        LocationData(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          timestamp: pos.timestamp,
          isMocked: pos.isMocked,
        ),
      );
    } catch (e) {
      // Fall back to last known position if fresh fix times out
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          return LocationResult.success(
            LocationData(
              latitude: lastPos.latitude,
              longitude: lastPos.longitude,
              accuracy: lastPos.accuracy,
              timestamp: lastPos.timestamp,
              isMocked: lastPos.isMocked,
            ),
          );
        }
      } catch (_) {}

      return LocationResult.error('Failed to acquire satellite lock: ${e.toString()}');
    }
  }
}
