import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/trackers/model/tracker.dart';
import '../../features/trackers/model/tracker_settings.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const _channelId = 'due_reminders';
  static const _channelName = 'Due reminders';
  static const _channelDescription =
      'Notifications sent before tracker due dates';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: settings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final macGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? true) &&
        (iosGranted ?? true) &&
        (macGranted ?? true);
  }

  Future<void> syncForAllTrackers(Box<dynamic> box) async {
    await initialize();
    await _plugin.cancelAll();

    final settings = TrackerSettings.fromMap(box.get('settings'));
    if (!settings.notificationsEnabled) return;

    final raw = box.get('trackkars', defaultValue: {}) as Map;
    final trackkars = raw.values
        .map((value) => Tracker.fromMap(value))
        .where((tracker) => !tracker.archived)
        .toList();

    for (final tracker in trackkars) {
      await _scheduleTrackerReminders(tracker, settings.reminderDaysBefore);
    }
  }

  Future<void> _scheduleTrackerReminders(
    Tracker tracker,
    int reminderDaysBefore,
  ) async {
    final now = tz.TZDateTime.now(tz.local);

    for (var monthOffset = 0; monthOffset < 12; monthOffset++) {
      final monthDate = DateTime(now.year, now.month + monthOffset, 1);
      final dueDate = recurringDueDateForMonth(tracker.dueDate, monthDate);
      final reminderDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - reminderDaysBefore,
        9,
      );

      final scheduledAt = tz.TZDateTime.from(reminderDate, tz.local);
      if (scheduledAt.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        id: _notificationId(tracker.id, dueDate.year, dueDate.month),
        title: '${tracker.title} due soon',
        body:
            'Due on ${dueDate.day}/${dueDate.month}/${dueDate.year} in $reminderDaysBefore day${reminderDaysBefore == 1 ? '' : 's'}.',
        scheduledDate: scheduledAt,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  int _notificationId(String trackerId, int year, int month) {
    return Object.hash(trackerId, year, month) & 0x7fffffff;
  }
}
