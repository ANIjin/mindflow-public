import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindflow/core/integrations/connector.dart';
import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/core/scheduler/schedule.dart';

void main() {
  test('schedule add and lookup by weekday', () async {
    final dir = Directory.systemTemp.createTempSync('mf_sched');
    final s = await ScheduleStore.open(dir.path);
    await s.addSlot(ClassSlot(
        id: 'a', name: 'Chemistry', weekday: 3, startMin: 600, endMin: 690));
    final wed = s.onDay(DateTime(2026, 10, 7));
    expect(wed.length, 1);
    expect(wed.first.name, 'Chemistry');
    expect(s.onDay(DateTime(2026, 10, 8)), isEmpty);
    dir.deleteSync(recursive: true);
  });

  test('ics import expands weekly recurrence', () async {
    final dir = Directory.systemTemp.createTempSync('mf_ics');
    final s = await ScheduleStore.open(dir.path);
    const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Linear Algebra
DTSTART:20261005T100000
DURATION:PT75M
RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR
END:VEVENT
END:VCALENDAR''';
    final n = await s.importIcs(ics);
    expect(n, 3);
    expect(s.onDay(DateTime(2026, 10, 5)).first.name, 'Linear Algebra');
    expect(s.onDay(DateTime(2026, 10, 7)).first.startMin, 600);
    dir.deleteSync(recursive: true);
  });

  test('integration settings defaults exist and sync is safe when disabled',
      () async {
    final dir = Directory.systemTemp.createTempSync('mf_int');
    final store = await MemoryStore.open(dir.path);
    final integ = store.settings['integrations'] as Map;
    expect(integ['blackboard'], isNotNull);
    expect(integ['aktiv'], isNotNull);
    expect(integ['outlook'], isNotNull);
    final mgr = IntegrationManager(store);
    expect(await mgr.sync(), 0);
    dir.deleteSync(recursive: true);
  });
}
