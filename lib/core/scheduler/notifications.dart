import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../integrations/phone.dart';
import '../models/node.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static bool available = false;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    final offset = DateTime.now().timeZoneOffset;
    final ms = DateTime.now().millisecondsSinceEpoch;
    final loc = tz.timeZoneDatabase.locations.values.firstWhere(
        (l) => l.timeZone(ms).offset == offset.inMilliseconds,
        orElse: () => tz.timeZoneDatabase.locations['UTC']!);
    tz.setLocalLocation(loc);
    try {
      final ok = await _plugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          windows: WindowsInitializationSettings(
            appName: 'MindFlow',
            appUserModelId: 'com.mindflow.mindflow',
            guid: 'b7c9a1d2-3e4f-5a6b-7c8d-9e0f1a2b3c4d',
          ),
        ),
      );
      available = ok == true;
      if (Platform.isIOS) {
        try {
          await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(sound: true, alert: true, badge: true);
        } catch (_) {}
      }
    } catch (_) {
      available = false;
    }
  }

  static int _id(String nodeId, int idx) =>
      ((nodeId.hashCode & 0x3FFFFF) << 4) + idx;

  static final Set<String> _sent = {};

  static Future<void> syncNode(MindNode n) async {
    if (n.status == 'active' && PhoneNotifier.enabled) {
      for (final dt in n.reminders) {
        if (!dt.isAfter(DateTime.now())) continue;
        final key = '${n.id}|${dt.toIso8601String()}';
        if (_sent.add(key)) {
          await PhoneNotifier.send('MindFlow - ${n.title}', _body(n),
              delay: dt, priority: n.priority >= 3 ? 5 : 4);
        }
      }
    }
    if (!available) return;
    try {
      for (int i = 0; i < 16; i++) {
        await _plugin.cancel(_id(n.id, i));
      }
    } catch (_) {}
    if (n.status != 'active') return;
    for (int i = 0; i < n.reminders.length && i < 16; i++) {
      final dt = n.reminders[i];
      if (!dt.isAfter(DateTime.now())) continue;
      try {
        await _plugin.zonedSchedule(
          _id(n.id, i),
          'MindFlow - ${n.title}',
          _body(n),
          tz.TZDateTime.from(dt, tz.local),
          const NotificationDetails(
            iOS: DarwinNotificationDetails(),
            windows: WindowsNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    }
  }

  static Future<void> rescheduleAll(Iterable<MindNode> nodes) async {
    for (final n in nodes) {
      await syncNode(n);
    }
  }

  static String _body(MindNode n) {
    final due =
        n.due != null ? ' due ${n.due!.toIso8601String()}' : '';
    return '${n.type} - priority ${n.priority}$due';
  }
}
