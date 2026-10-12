import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/theme.dart';
import 'package:mindflow/ui/widgets/link_panels.dart';

void main() {
  testWidgets('linking a note shows on both pages with coverage count',
      (tester) async {
    late AppState state;
    late Directory dir;
    await tester.runAsync(() async {
      dir = Directory.systemTemp.createTempSync('note_assign');
      state = await AppState.openForTest(dir.path);
      await state.saveNode(MindNode(
        id: 'note1',
        title: 'Lecture notes',
        type: 'page',
        body: '# Notes',
      ));
      await state.saveNode(MindNode(
        id: 'hw1',
        title: 'Essay draft',
        type: 'assignment',
        body: '# Essay',
      ));
      await state.linkNoteAssignment('note1', 'hw1');
    });
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    final shell = ShellState(store: state.store)..openPage('hw1');
    final hw = state.store.nodes['hw1']!;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider.value(value: shell),
        ],
        child: MaterialApp(
          theme: theme(),
          home: Scaffold(
            body: PageLinksSidebar(node: hw),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('coverage-count')), findsOneWidget);
    expect(find.textContaining('1 note'), findsOneWidget);
    expect(find.byKey(const ValueKey('coverage-note-note1')), findsOneWidget);

    shell.openPage('note1');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider.value(value: shell),
        ],
        child: MaterialApp(
          theme: theme(),
          home: Scaffold(
            body: PageLinksSidebar(node: state.store.nodes['note1']!),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('coverage-assignment-hw1')), findsOneWidget);
    expect(find.text('Essay draft'), findsWidgets);
  });
}
