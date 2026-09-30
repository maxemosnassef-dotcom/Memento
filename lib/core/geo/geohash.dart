typedef GeoBounds = ({
  double minLat,
  double maxLat,
  double minLng,
  double maxLng,
});

class GeohashCodec {
  static const String _alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const int defaultPrecision = 8;

  const GeohashCodec();

  String encode(double latitude, double longitude, {int precision = defaultPrecision}) {
    if (latitude.isNaN || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'must be within [-90, 90]');
    }
    if (longitude.isNaN || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude', 'must be within [-180, 180]');
    }
    if (precision < 1 || precision > 12) {
      throw ArgumentError.value(precision, 'precision', 'must be within [1, 12]');
    }
    var latMin = -90.0, latMax = 90.0;
    var lngMin = -180.0, lngMax = 180.0;
    var evenBit = true;
    var bitCount = 0;
    var charIndex = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (evenBit) {
        final mid = (lngMin + lngMax) / 2;
        if (longitude >= mid) {
          charIndex = (charIndex << 1) + 1;
          lngMin = mid;
        } else {
          charIndex <<= 1;
          lngMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          charIndex = (charIndex << 1) + 1;
          latMin = mid;
        } else {
          charIndex <<= 1;
          latMax = mid;
        }
      }
      evenBit = !evenBit;
      if (++bitCount == 5) {
        buffer.write(_alphabet[charIndex]);
        bitCount = 0;
        charIndex = 0;
      }
    }
    return buffer.toString();
  }

  GeoBounds bounds(String hash) {
    if (hash.isEmpty) throw ArgumentError.value(hash, 'hash', 'must not be empty');
    var latMin = -90.0, latMax = 90.0;
    var lngMin = -180.0, lngMax = 180.0;
    var evenBit = true;

    for (final ch in hash.toLowerCase().split('')) {
      final idx = _alphabet.indexOf(ch);
      if (idx < 0) {
        throw FormatException('Invalid geohash character: $ch');
      }
      for (var bit = 4; bit >= 0; bit--) {
        final isSet = (idx >> bit) & 1 == 1;
        if (evenBit) {
          final mid = (lngMin + lngMax) / 2;
          if (isSet) {
            lngMin = mid;
          } else {
            lngMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if (isSet) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        evenBit = !evenBit;
      }
    }
    return (
      minLat: latMin,
      maxLat: latMax,
      minLng: lngMin,
      maxLng: lngMax,
    );
  }
}
