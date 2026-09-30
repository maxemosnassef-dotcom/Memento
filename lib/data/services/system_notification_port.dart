import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/error/failures.dart';
import '../../core/result.dart';
import '../../domain/repositories/notification_port.dart';

class SystemNotificationPort implements NotificationPort {
  static const String _channelId = 'memento.alerts';
  static const String _channelName = 'Memento rediscovery alerts';

  final FlutterLocalNotificationsPlugin _plugin;

  SystemNotificationPort(this._plugin);

  Future<void> initialize() async {
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Birthday and place-based memory alerts',
          importance: Importance.high,
        ));
  }

  @override
  Future<bool> isAuthorized() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  @override
  Future<bool> requestAuthorization() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<Result<void>> present(MemoryAlert notification) async {
    try {
      await _plugin.show(
        notification.id.hashCode & 0x7fffffff,
        notification.title,
        notification.summary,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Birthday and place-based memory alerts',
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.private,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.timeSensitive,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(notification.payload),
      );
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.err(NotificationFailure('$e'));
    }
  }

  @override
  Future<Result<void>> dismiss(String alertId) async {
    try {
      await _plugin.cancel(alertId.hashCode & 0x7fffffff);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.err(NotificationFailure('$e'));
    }
  }
}
