import '../../core/geo/geohash.dart';

class GeoAnchor {
  static const GeohashCodec _codec = GeohashCodec();

  final double latitude;
  final double longitude;
  final String geohash;

  const GeoAnchor._(this.latitude, this.longitude, this.geohash);

  factory GeoAnchor.of({required double latitude, required double longitude}) {
    if (latitude.isNaN || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'must be within [-90, 90]');
    }
    if (longitude.isNaN || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude', 'must be within [-180, 180]');
    }
    return GeoAnchor._(
      latitude,
      longitude,
      _codec.encode(latitude, longitude),
    );
  }

  String geohashAt(int precision) =>
      _codec.encode(latitude, longitude, precision: precision);

  GeoBounds boundsAtPrecision(int precision) =>
      _codec.bounds(geohashAt(precision));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoAnchor &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoAnchor($latitude, $longitude, $geohash)';
}
