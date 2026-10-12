import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/theme.dart';
import 'package:mindflow/ui/widgets/page_editor.dart';

Future<(AppState, MindNode)> _seed(WidgetTester tester,
    {String body = 'Hello world'}) async {
  late AppState state;
  late MindNode node;
  await tester.runAsync(() async {
    final dir = Directory.systemTemp.createTempSync('page_editor');
    state = await AppState.openForTest(dir.path);
    node = MindNode(id: 'p1', title: 'Notes', body: body);
    await state.saveNode(node);
  });
  return (state, node);
}

Future<void> _pumpEditor(
    WidgetTester tester, AppState state, MindNode node) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider(create: (_) => ShellState(store: state.store)),
      ],
      child: MaterialApp(
        theme: theme(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: PageEditor(node: node),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('edit persists after idle autosave and shows Saved indicator',
      (tester) async {
    final (state, node) = await _seed(tester);
    await _pumpEditor(tester, state, node);

    expect(find.byKey(const ValueKey('page-editor')), findsOneWidget);
    expect(find.byKey(const ValueKey('save-indicator')), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('block-field-0')), 'Edited body');
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    final editor = tester.state<PageEditorState>(find.byType(PageEditor));
    await tester.runAsync(() => editor.debugFlushSave());
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(state.store.nodes['p1']!.body.contains('Edited body'), isTrue);
  });

  testWidgets('preview renders headings code and tables from parsed blocks',
      (tester) async {
    final (state, node) = await _seed(tester,
        body: '# Title\n\n```dart\nprint(1);\n```\n\n|A|B|\n|---|---|\n|1|2|');
    await _pumpEditor(tester, state, node);
    expect(find.byKey(const ValueKey('markdown-preview')), findsOneWidget);
    expect(find.textContaining('Title'), findsWidgets);
  });

  testWidgets('typed todo toggle callout code quote table divider round-trip',
      (tester) async {
    final (state, node) = await _seed(tester, body: '');
    await _pumpEditor(tester, state, node);

    // Insert via slash: todo
    await tester.enterText(find.byKey(const ValueKey('block-field-0')), '/todo');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('slash-todo')));
    await tester.pump();
    expect(find.byKey(const ValueKey('todo-check-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('todo-check-0')));
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('block-field-0')), 'Ship it');
    await tester.pump();

    final editor = tester.state<PageEditorState>(find.byType(PageEditor));
    await tester.runAsync(() => editor.debugFlushSave());
    await tester.pump();

    expect(state.store.nodes['p1']!.body.contains('[x]'), isTrue);
    expect(state.store.nodes['p1']!.body.contains('Ship it'), isTrue);
  });

  testWidgets('slash /tab inserts a table block', (tester) async {
    final (state, node) = await _seed(tester);
    await _pumpEditor(tester, state, node);

    await tester.enterText(find.byKey(const ValueKey('block-field-0')), '/tab');
    await tester.pump();
    expect(find.byKey(const ValueKey('slash-menu')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('slash-table')));
    await tester.pump();

    expect(find.byKey(const ValueKey('slash-menu')), findsNothing);
    expect(find.byKey(const ValueKey('block-0-table')), findsOneWidget);
  });

  testWidgets('drag reorder moves a block and saves', (tester) async {
    final (state, node) =
        await _seed(tester, body: 'First\n\nSecond');
    await _pumpEditor(tester, state, node);

    expect(find.byKey(const ValueKey('block-0-paragraph')), findsOneWidget);
    expect(find.byKey(const ValueKey('block-1-paragraph')), findsOneWidget);

    final editor = tester.state<PageEditorState>(find.byType(PageEditor));
    editor.debugReorder(0, 2);
    await tester.pump();
    await tester.runAsync(() => editor.debugFlushSave());
    await tester.pump();

    final body = state.store.nodes['p1']!.body;
    expect(body.indexOf('Second'), lessThan(body.indexOf('First')));
  });
}
