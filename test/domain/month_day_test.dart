import 'package:flutter_test/flutter_test.dart';
import 'package:memento/domain/value_objects/month_day.dart';

void main() {
  group('MonthDay.of', () {
    test('accepts valid calendar days', () {
      expect(MonthDay.of(month: 2, day: 29).day, 29);
      expect(MonthDay.of(month: 4, day: 30).day, 30);
      expect(MonthDay.of(month: 12, day: 31).day, 31);
    });

    test('rejects impossible dates', () {
      expect(() => MonthDay.of(month: 13, day: 1), throwsArgumentError);
      expect(() => MonthDay.of(month: 4, day: 31), throwsArgumentError);
      expect(() => MonthDay.of(month: 1, day: 0), throwsArgumentError);
    });
  });

  group('MonthDay.clampedForYear', () {
    test('keeps February 29 on leap years', () {
      final leap = MonthDay.clampedForYear(
          month: DateTime.february, day: 29, year: 2024);
      expect(leap.day, 29);
    });

    test('clamps February 29 to February 28 on non-leap years', () {
      final nonLeap = MonthDay.clampedForYear(
          month: DateTime.february, day: 29, year: 2025);
      expect(nonLeap.month, DateTime.february);
      expect(nonLeap.day, 28);
    });

    test('leaves ordinary dates untouched', () {
      final md = MonthDay.clampedForYear(month: 7, day: 14, year: 2100);
      expect(md.month, 7);
      expect(md.day, 14);
    });
  });

  group('isLeapYear', () {
    test('applies Gregorian rules', () {
      expect(MonthDay.isLeapYear(2000), isTrue);
      expect(MonthDay.isLeapYear(1900), isFalse);
      expect(MonthDay.isLeapYear(2024), isTrue);
      expect(MonthDay.isLeapYear(2026), isFalse);
    });
  });

  group('Comparable', () {
    test('orders by month then day', () {
      final jan = MonthDay.of(month: 1, day: 20);
      final feb = MonthDay.of(month: 2, day: 3);
      final febLater = MonthDay.of(month: 2, day: 27);
      expect(jan.compareTo(feb), isNegative);
      expect(feb.compareTo(febLater), isNegative);
      expect(MonthDay.of(month: 2, day: 3).compareTo(MonthDay.of(month: 2, day: 3)), 0);
    });
  });
}
