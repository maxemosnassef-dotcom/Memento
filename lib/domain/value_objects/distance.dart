class Distance implements Comparable<Distance> {
  static const double maxMeters = 100000;

  final double meters;

  const Distance._(this.meters);

  factory Distance.ofMeters(double value) {
    if (value.isNaN || value <= 0 || value > maxMeters) {
      throw ArgumentError.value(
        value,
        'distance',
        'must be within (0, $maxMeters] meters',
      );
    }
    return Distance._(value);
  }

  factory Distance.ofKilometers(double km) => Distance.ofMeters(km * 1000);

  @override
  int compareTo(Distance other) => meters.compareTo(other.meters);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Distance && other.meters == meters;

  @override
  int get hashCode => meters.hashCode;

  @override
  String toString() => 'Distance(${meters}m)';
}
