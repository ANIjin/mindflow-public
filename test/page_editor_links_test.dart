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
    {required List<MindNode> nodes, String body = ''}) async {
  late AppState state;
  late MindNode primary;
  await tester.runAsync(() async {
    final dir = Directory.systemTemp.createTempSync('page_links');
    state = await AppState.openForTest(dir.path);
    for (final n in nodes) {
      await state.saveNode(n);
    }
    primary = nodes.first;
    if (body.isNotEmpty) {
      primary.body = body;
      await state.saveNode(primary);
    }
  });
  return (state, primary);
}

Future<void> _pump(WidgetTester tester, AppState state, MindNode node) async {
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
  testWidgets('wikilink autocomplete inserts existing page title', (tester) async {
    final (state, node) = await _seed(tester, nodes: [
      MindNode(id: 'a', title: 'Notes', body: ''),
      MindNode(id: 'b', title: 'Calculus I', body: ''),
    ]);
    await _pump(tester, state, node);

    await tester.enterText(
        find.byKey(const ValueKey('block-field-0')), 'See [[Calc');
    await tester.pump();
    expect(find.byKey(const ValueKey('wiki-menu')), findsOneWidget);
    await tester.tap(find.text('Calculus I'));
    await tester.pump();

    final editor = tester.state<PageEditorState>(find.byType(PageEditor));
    await tester.runAsync(() => editor.debugFlushSave());
    await tester.pump();
    expect(state.store.nodes['a']!.body.contains('[[Calculus I]]'), isTrue);
  });

  testWidgets('missing wikilink offers create-page affordance', (tester) async {
    final (state, node) = await _seed(tester, nodes: [
      MindNode(id: 'a', title: 'Notes', body: ''),
    ]);
    await _pump(tester, state, node);

    await tester.enterText(
        find.byKey(const ValueKey('block-field-0')), '[[Missing Page');
    await tester.pump();
    expect(find.byKey(const ValueKey('wiki-create')), findsOneWidget);
  });

  testWidgets('tag autocomplete inserts existing tag', (tester) async {
    final (state, node) = await _seed(tester, nodes: [
      MindNode(id: 'a', title: 'Notes', body: '', tags: ['physics']),
      MindNode(id: 'b', title: 'Lab', body: '#physics notes'),
    ]);
    await _pump(tester, state, node);

    await tester.enterText(
        find.byKey(const ValueKey('block-field-0')), 'topic #phys');
    await tester.pump();
    expect(find.byKey(const ValueKey('tag-menu')), findsOneWidget);
    await tester.tap(find.text('#physics'));
    await tester.pump();

    final editor = tester.state<PageEditorState>(find.byType(PageEditor));
    await tester.runAsync(() => editor.debugFlushSave());
    await tester.pump();
    expect(state.store.nodes['a']!.body.contains('#physics'), isTrue);
  });
}
