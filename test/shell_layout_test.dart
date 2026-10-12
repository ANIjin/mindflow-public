import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/ui/app_shell.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/theme.dart';

Future<(AppState, Directory)> _openState(WidgetTester tester) async {
  late Directory dir;
  late AppState state;
  await tester.runAsync(() async {
    dir = Directory.systemTemp.createTempSync('shell_layout');
    state = await AppState.openForTest(dir.path);
  });
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });
  return (state, dir);
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required AppState state,
  ShellState? shell,
}) async {
  final s = shell ?? ShellState(store: state.store);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: s),
      ],
      child: MaterialApp(
        theme: theme(),
        home: const AppShell(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('wide layout (≥700px) shows sidebar and content simultaneously',
      (tester) async {
    final (state, _) = await _openState(tester);
    await _pumpShell(tester, size: const Size(1000, 800), state: state);

    expect(find.byKey(const ValueKey('shell-wide')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-narrow')), findsNothing);
    expect(find.byKey(const ValueKey('sidebar-full')), findsOneWidget);
    expect(find.byKey(const ValueKey('dest-board')), findsOneWidget);
    expect(find.byKey(const ValueKey('dest-calendar')), findsOneWidget);
    expect(find.byKey(const ValueKey('dest-chat')), findsOneWidget);
    expect(find.byKey(const ValueKey('dest-settings')), findsOneWidget);
  });

  testWidgets('narrow layout (<700px) shows single pane with drawer toggle',
      (tester) async {
    final (state, _) = await _openState(tester);
    await _pumpShell(tester, size: const Size(400, 800), state: state);

    expect(find.byKey(const ValueKey('shell-narrow')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-wide')), findsNothing);
    expect(find.byKey(const ValueKey('drawer-toggle')), findsOneWidget);
  });

  testWidgets('sidebar collapses to icon rail on wide layout', (tester) async {
    final (state, _) = await _openState(tester);
    final shell = ShellState(store: state.store);

    await _pumpShell(tester,
        size: const Size(1000, 800), state: state, shell: shell);

    expect(find.byKey(const ValueKey('sidebar-full')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
    await tester.pumpAndSettle();

    expect(shell.sidebarCollapsed, isTrue);
    expect(find.byKey(const ValueKey('icon-rail')), findsOneWidget);
  });

  testWidgets('Ctrl+K opens the command palette', (tester) async {
    final (state, _) = await _openState(tester);
    await _pumpShell(tester, size: const Size(1000, 800), state: state);

    expect(find.byKey(const ValueKey('command-palette')), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump();

    expect(find.byKey(const ValueKey('command-palette')), findsOneWidget);
    expect(find.byKey(const ValueKey('palette-input')), findsOneWidget);
  });

  testWidgets('Tab focuses interactive controls with focus indicators',
      (tester) async {
    final (state, _) = await _openState(tester);
    await _pumpShell(tester, size: const Size(1000, 800), state: state);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final focused = FocusManager.instance.primaryFocus;
    expect(focused, isNotNull);
    expect(focused!.context, isNotNull);
    expect(find.byType(InkWell), findsWidgets);
  });

  testWidgets('destination buttons switch board/calendar/chat/settings',
      (tester) async {
    final (state, _) = await _openState(tester);
    final shell = ShellState(store: state.store);

    await _pumpShell(tester,
        size: const Size(1000, 800), state: state, shell: shell);

    await tester.tap(find.byKey(const ValueKey('dest-calendar')));
    await tester.pump();
    expect(shell.destination, ShellDestination.calendar);

    await tester.tap(find.byKey(const ValueKey('dest-chat')));
    await tester.pump();
    expect(shell.destination, ShellDestination.chat);

    await tester.tap(find.byKey(const ValueKey('dest-settings')));
    await tester.pump();
    expect(shell.destination, ShellDestination.settings);

    await tester.tap(find.byKey(const ValueKey('dest-board')).first);
    await tester.pump();
    expect(shell.destination, ShellDestination.board);
  });
}
