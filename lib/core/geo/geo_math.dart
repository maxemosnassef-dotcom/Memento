import 'dart:math' as math;

class GeoMath {
  static const double earthRadiusMeters = 6371008.8;
  static const double _metersPerDegreeLatitude = 111195.0;

  const GeoMath._();

  static double distanceMeters({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final dPhi = _toRadians(lat2 - lat1);
    final dLambda = _toRadians(lng2 - lng1);

    final a = math.pow(math.sin(dPhi / 2), 2) +
        math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static ({double deltaLat, double deltaLng}) degreeSpan({
    required double radiusMeters,
    required double latitude,
  }) {
    final deltaLat = radiusMeters / _metersPerDegreeLatitude;
    final cosAbs = math.cos(_toRadians(latitude)).abs().clamp(0.01, 1.0);
    return (deltaLat: deltaLat, deltaLng: deltaLat / cosAbs);
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
