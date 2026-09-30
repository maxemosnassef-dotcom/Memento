class MemoryMoment implements Comparable<MemoryMoment> {
  final DateTime utc;

  const MemoryMoment._(this.utc);

  factory MemoryMoment.at(DateTime when) {
    final normalized = when.toUtc();
    final now = DateTime.now().toUtc();
    if (normalized.isAfter(now.add(const Duration(minutes: 5)))) {
      throw ArgumentError('A memory moment cannot be in the future');
    }
    return MemoryMoment._(normalized);
  }

  factory MemoryMoment.fromEpochMs(int millisSinceEpoch) {
    final parsed = DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, isUtc: true);
    return MemoryMoment._(parsed);
  }

  int get epochMs => utc.millisecondsSinceEpoch;
  int get localYear => utc.toLocal().year;
  int get localMonth => utc.toLocal().month;
  int get localDay => utc.toLocal().day;

  bool fallsOnCalendarDay({required int month, required int day}) =>
      localMonth == month && localDay == day;

  bool isBefore(MemoryMoment other) => utc.isBefore(other.utc);

  @override
  int compareTo(MemoryMoment other) => utc.compareTo(other.utc);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MemoryMoment && other.utc == utc;

  @override
  int get hashCode => utc.hashCode;

  @override
  String toString() => 'MemoryMoment($utc)';
}
