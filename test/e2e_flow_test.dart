import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/core/memory/study_tools.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/core/models/view_def.dart';
import 'package:mindflow/core/scheduler/schedule.dart';
import 'package:mindflow/ui/app_shell.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/theme.dart';

/// Linux desktop substitute for the Windows E2E checklist in task 10.4.
void main() {
  testWidgets('e2e flow: page blocks link search db review exam capture theme',
      (tester) async {
    late AppState state;
    late Directory dir;
    await tester.runAsync(() async {
      dir = Directory.systemTemp.createTempSync('e2e_flow');
      state = await AppState.openForTest(dir.path);

      final page = MindNode(
        id: 'p1',
        title: 'E2E Notes',
        type: 'page',
        body: '# Heading\n\n- [ ] Review card\n\n[[Essay]]\n',
        icon: '📝',
        spaceId: 'MindFlow',
      );
      final essay = MindNode(
        id: 'a1',
        title: 'Essay',
        type: 'assignment',
        body: '# Essay',
        review: ReviewState(due: DateTime.now()),
      );
      await state.saveNode(page);
      await state.saveNode(essay);
      await state.linkNoteAssignment('p1', 'a1');
      await state.addClass(ClassSlot(
        id: 'c1',
        name: 'History',
        weekday: 2,
        startMin: 540,
        endMin: 600,
      ));
      await state.store.saveView(ViewDef(
        id: 'v1',
        name: 'E2E View',
        layout: 'list',
        types: ['assignment'],
      ));
      // Theme switch: flip ui dark/light via settings seed.
      state.store.settings['themeMode'] = 'light';
      await state.store.saveSettings();
    });
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    final shell = ShellState(store: state.store)..openPage('p1');

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider.value(value: shell),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          darkTheme: theme(),
          themeMode: ThemeMode.light,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Launch + open page with icon
    expect(find.byKey(const ValueKey('shell-wide')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-header-icon')), findsOneWidget);

    // Search index finds body text
    final hits = state.store.searchIndex.search('Review', state.store.nodes);
    expect(hits, isNotEmpty);

    // Database view present
    expect(state.store.views.values.any((v) => v.name == 'E2E View'), isTrue);

    // Review deck / coverage
    expect(assignmentCoverage(state.store.nodes['a1']!), 1);
    expect(dueTodayCount(state.store.nodes.values), greaterThanOrEqualTo(1));

    // Exam plan
    final plan = planExamStudy(DateTime.now().add(const Duration(days: 10)),
        days: 4);
    expect(plan.length, 4);

    // Class page generated
    expect(
        state.store.nodes.values
            .any((n) => n.type == 'class' && n.title == 'History'),
        isTrue);

    // Quick capture destination reachable
    expect(find.byKey(const ValueKey('dest-board')), findsOneWidget);

    // Theme light applied (no crash)
    expect(Theme.of(tester.element(find.byType(AppShell))).brightness,
        Brightness.light);
  });
}
