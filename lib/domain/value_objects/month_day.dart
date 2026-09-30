class MonthDay implements Comparable<MonthDay> {
  final int month;
  final int day;

  const MonthDay._(this.month, this.day);

  factory MonthDay.of({required int month, required int day}) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be within [1, 12]');
    }
    final maxDay = daysInMonth(month: month, leapYearAllowed: true);
    if (day < 1 || day > maxDay) {
      throw ArgumentError.value(day, 'day', 'invalid for month $month');
    }
    return MonthDay._(month, day);
  }

  factory MonthDay.clampedForYear({
    required int month,
    required int day,
    required int year,
  }) {
    var effectiveDay = day;
    if (month == DateTime.february && day == 29 && !isLeapYear(year)) {
      effectiveDay = 28;
    }
    return MonthDay._(month, effectiveDay);
  }

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static const List<int> _daysPerMonth = [
    31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
  ];

  static int daysInMonth({required int month, required bool leapYearAllowed}) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be within [1, 12]');
    }
    if (month == DateTime.february && !leapYearAllowed) return 28;
    return _daysPerMonth[month - 1];
  }

  @override
  int compareTo(MonthDay other) {
    final byMonth = month.compareTo(other.month);
    return byMonth != 0 ? byMonth : day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthDay && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(month, day);

  @override
  String toString() => 'MonthDay($month-$day)';
}
