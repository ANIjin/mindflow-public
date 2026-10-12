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
  test('findUnlinkedMentions detects plain titles and skips wikilinks', () {
    final body = 'I studied Calculus I and also [[Linear Algebra]] today.';
    final found = findUnlinkedMentions(
        body, ['Calculus I', 'Linear Algebra', 'Physics']);
    expect(found, contains('Calculus I'));
    expect(found, isNot(contains('Linear Algebra')));
    expect(found, isNot(contains('Physics')));
  });

  test('convertMentionToWikilink updates body', () {
    final next =
        convertMentionToWikilink('Read Calculus I notes', 'Calculus I');
    expect(next, 'Read [[Calculus I]] notes');
  });

  testWidgets('backlinks and forward links panels show agent/user links',
      (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('links_panel');
      state = await AppState.openForTest(dir.path);
      final a = MindNode(id: 'a', title: 'Alpha', body: 'See [[Beta]]');
      final b = MindNode(id: 'b', title: 'Beta', body: 'root');
      await state.saveNode(a);
      await state.saveNode(b);
      b.links = ['a'];
      await state.saveNode(b);
    });

    final shell = ShellState(store: state.store);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider.value(value: shell),
        ],
        child: MaterialApp(
          theme: theme(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 600,
              child: PageLinksSidebar(node: state.store.nodes['b']!),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('page-links-sidebar')), findsOneWidget);
    expect(find.byKey(const ValueKey('backlink-a')), findsOneWidget);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider.value(value: shell),
        ],
        child: MaterialApp(
          theme: theme(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 600,
              child: PageLinksSidebar(node: state.store.nodes['a']!),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('forward-b')), findsOneWidget);
  });

  testWidgets('convert unlinked mention updates index', (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('unlinked');
      state = await AppState.openForTest(dir.path);
      await state
          .saveNode(MindNode(id: 'a', title: 'Alpha', body: 'mentions Beta here'));
      await state.saveNode(MindNode(id: 'b', title: 'Beta', body: ''));
    });

    final shell = ShellState(store: state.store);
    final node = state.store.nodes['a']!;
    var converted = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider.value(value: shell),
        ],
        child: MaterialApp(
          theme: theme(),
          home: Scaffold(
            body: PageLinksSidebar(
              node: node,
              onConvertMention: (title) {
                converted = true;
                node.body = convertMentionToWikilink(node.body, title);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('convert-mention-Beta')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('convert-mention-Beta')));
    await tester.pump();
    expect(converted, isTrue);

    await tester.runAsync(() => state.saveNode(node));
    expect(state.store.nodes['a']!.body.contains('[[Beta]]'), isTrue);
    expect(state.store.linkIndex.out['a']?.contains('b'), isTrue);
    expect(state.store.linkIndex.in_['b']?.contains('a'), isTrue);
  });
}
