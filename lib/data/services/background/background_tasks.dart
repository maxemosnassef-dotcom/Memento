import 'package:workmanager/workmanager.dart';

import '../../../core/use_case.dart';
import '../../../di/injector.dart';
import '../../../domain/usecases/run_birthday_sweep.dart';

const String kBirthdaySweepTask = 'memento.task.birthdaySweep';
const String kHotspotSyncTask = 'memento.task.hotspotSync';
const String kBirthdayUniqueName = 'memento.periodic.birthday';

@pragma('vm:entry-point')
Future<void> callbackDispatcher() async {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case kBirthdaySweepTask:
          await _runBirthdaySweep();
          return true;
        case kHotspotSyncTask:
          await _runHotspotSync();
          return true;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  });
}

Future<void> _runBirthdaySweep() async {
  final container = await buildContainer();
  await container.birthdaySweep.execute(
    BirthdaySweepInput(nowLocal: DateTime.now()),
  );
}

Future<void> _runHotspotSync() async {
  final container = await buildContainer();
  await container.hotspotSync.execute(const NoParams());
}
