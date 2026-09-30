import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'data/services/background/background_tasks.dart';
import 'di/injector.dart';
import 'presentation/memories/pages/timeline_page.dart';

late final AppContainer appContainer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  appContainer = await buildContainer();

  await Workmanager().initialize(
    callbackDispatcher,
  );
  await Workmanager().registerPeriodicTask(
    kBirthdayUniqueName,
    kBirthdaySweepTask,
    frequency: const Duration(hours: 12),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  runApp(MementoApp(container: appContainer));
}

class MementoApp extends StatelessWidget {
  final AppContainer container;

  const MementoApp({super.key, required this.container});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEMENTO',
      theme: ThemeData.dark(useMaterial3: true),
      home: TimelinePage(container: container),
    );
  }
}
