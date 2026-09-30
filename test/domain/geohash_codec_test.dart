import 'package:flutter_test/flutter_test.dart';
import 'package:memento/core/geo/geohash.dart';

void main() {
  const codec = GeohashCodec();

  group('GeohashCodec.encode', () {
    test('produces the canonical hash for a known coordinate', () {
      final hash = codec.encode(57.64911, 10.40744, precision: 11);
      expect(hash, 'u4pruydqqvj');
    });

    test('truncation prefix property holds across precisions', () {
      final full = codec.encode(57.64911, 10.40744, precision: 11);
      expect(codec.encode(57.64911, 10.40744, precision: 5),
          full.substring(0, 5));
      expect(codec.encode(57.64911, 10.40744), full.substring(0, 8));
    });

    test('rejects out-of-range coordinates', () {
      expect(() => codec.encode(91, 0), throwsArgumentError);
      expect(() => codec.encode(0, -181), throwsArgumentError);
      expect(() => codec.encode(double.nan, 0), throwsArgumentError);
    });

    test('rejects invalid precision', () {
      expect(() => codec.encode(0, 0, precision: 0), throwsArgumentError);
      expect(() => codec.encode(0, 0, precision: 13), throwsArgumentError);
    });
  });

  group('GeohashCodec.bounds', () {
    test('decoded bounds contain the encoded point', () {
      const points = [
        (57.64911, 10.40744),
        (-33.865143, 151.209900),
        (90.0, 180.0),
        (-90.0, -180.0),
        (0.0, 0.0),
      ];
      for (final (lat, lng) in points) {
        final hash = codec.encode(lat, lng, precision: 9);
        final bounds = codec.bounds(hash);
        expect(bounds.minLat, lessThanOrEqualTo(lat));
        expect(lat, lessThanOrEqualTo(bounds.maxLat));
        expect(bounds.minLng, lessThanOrEqualTo(lng));
        expect(lng, lessThanOrEqualTo(bounds.maxLng));
      }
    });

    test('bounds shrink as precision grows', () {
      final coarse = codec.bounds(codec.encode(48.858370, 2.294481, precision: 4));
      final fine = codec.bounds(codec.encode(48.858370, 2.294481, precision: 9));
      expect(fine.maxLat - fine.minLat,
          lessThan(coarse.maxLat - coarse.minLat));
    });

    test('throws on malformed hash characters', () {
      expect(() => codec.bounds('u4pra'), throwsFormatException);
      expect(() => codec.bounds('u4pri'), throwsFormatException);
      expect(() => codec.bounds('u4pro!'), throwsFormatException);
    });
  });
}
