import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/ui/app_shell.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/theme.dart';

void main() {
  testWidgets('page icon shows in header and sidebar', (tester) async {
    late AppState state;
    late Directory dir;
    await tester.runAsync(() async {
      dir = Directory.systemTemp.createTempSync('page_meta');
      state = await AppState.openForTest(dir.path);
      await state.saveNode(MindNode(
        id: 'meta1',
        title: 'Icon Page',
        type: 'page',
        spaceId: 'MindFlow',
        icon: '🎯',
      ));
    });
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    final shell = ShellState(store: state.store)..openPage('meta1');

    tester.view.physicalSize = const Size(1100, 800);
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
          theme: theme(),
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('page-header-icon')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-meta1')), findsWidgets);
    // Icon appears in both header and sidebar entry.
    expect(find.text('🎯'), findsWidgets);
    expect(tester.widgetList(find.text('🎯')).length, greaterThanOrEqualTo(2));
  });
}
