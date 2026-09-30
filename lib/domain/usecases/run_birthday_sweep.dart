import '../../core/result.dart';
import '../../core/use_case.dart';
import '../entities/memory.dart';
import '../repositories/alert_throttle.dart';
import '../repositories/contact_repository.dart';
import '../repositories/memory_repository.dart';
import '../repositories/notification_port.dart';
import '../value_objects/month_day.dart';

class BirthdaySweepInput {
  final DateTime nowLocal;

  const BirthdaySweepInput({required this.nowLocal});
}

class BirthdaySweepSummary {
  final int peopleMatched;
  final int alertsDelivered;

  const BirthdaySweepSummary({
    required this.peopleMatched,
    required this.alertsDelivered,
  });
}

class RunBirthdaySweep extends UseCase<BirthdaySweepSummary, BirthdaySweepInput> {
  static const Duration _muteWindow = Duration(hours: 20);

  final ContactRepository _contacts;
  final MemoryRepository _memories;
  final NotificationPort _notifications;
  final AlertThrottle _throttle;

  const RunBirthdaySweep(
    this._contacts,
    this._memories,
    this._notifications,
    this._throttle,
  );

  @override
  Future<Result<BirthdaySweepSummary>> execute(BirthdaySweepInput input) async {
    final now = input.nowLocal;

    final peopleResult = await _contacts.findBirthdaysOn(
      MonthDay.clampedForYear(
        month: now.month,
        day: now.day,
        year: now.year,
      ),
    );
    if (peopleResult.isErr) return Result.err(peopleResult.failureOrNull()!);

    final people = peopleResult.getOrNull()!;
    var delivered = 0;

    for (final person in people) {
      final sharedResult =
          await _memories.findByTaggedContacts({person.id});
      final shared = sharedResult.getOrNull() ?? const <Memory>[];

      final key = 'throttle.birthday.${person.id}.${now.year}';
      if (!await _throttle.shouldDeliver(key: key, muteWindow: _muteWindow)) {
        continue;
      }

      final onTheirDay = person.birthday == null
          ? 0
          : shared
              .where((m) => m.wasTakenOn(person.birthday!))
              .length;

      final result = await _notifications.present(MemoryAlert(
        id: 'birthday-${person.id}-${now.year}',
        title: "It's ${person.displayName}'s birthday",
        summary: shared.isEmpty
            ? 'Reach out today and make a new memory together.'
            : 'You share ${shared.length} memor${shared.length == 1 ? 'y' : 'ies'}'
                ' - $onTheirDay taken on this very day.',
        payload: {'contactId': person.id},
      ));

      if (result.isOk) {
        delivered++;
      } else {
        await _throttle.reset(key);
      }
    }

    return Result.ok(BirthdaySweepSummary(
      peopleMatched: people.length,
      alertsDelivered: delivered,
    ));
  }
}
