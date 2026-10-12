import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/core/scheduler/schedule.dart';

void main() {
  test('addClass creates class page with assignments listed', () async {
    final dir = Directory.systemTemp.createTempSync('class_page');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    final state = await AppState.openForTest(dir.path);
    await state.saveNode(MindNode(
      id: 'a1',
      title: 'Lab report',
      type: 'assignment',
      tags: ['Physics'],
    ));

    final slot = ClassSlot(
      id: 'phys-1',
      name: 'Physics',
      weekday: 3,
      startMin: 600,
      endMin: 700,
      location: 'Hall A',
    );
    await state.addClass(slot);

    final pages = state.store.nodes.values
        .where((n) => n.type == 'class' && n.title == 'Physics')
        .toList();
    expect(pages, isNotEmpty);
    final page = pages.first;
    expect(page.spaceId, 'Classes');
    expect(page.body.contains('[[Lab report]]'), isTrue);
    expect(page.body.contains('Hall A'), isTrue);
    expect(page.properties['scheduleId'], 'phys-1');
    expect(state.schedule.slots.any((s) => s.id == 'phys-1'), isTrue);
  });
}
