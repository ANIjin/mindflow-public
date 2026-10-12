import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/ui/graph_page.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/theme.dart';

void main() {
  testWidgets('graph renders nodes and selecting one opens the page',
      (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('graph');
      state = await AppState.openForTest(dir.path);
      await state.saveNode(MindNode(id: 'a', title: 'Alpha', body: '[[Beta]]'));
      await state.saveNode(MindNode(id: 'b', title: 'Beta', body: ''));
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
          home: const Scaffold(body: GraphViewPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('graph-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('graph-node-a')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('graph-node-a')));
    await tester.pump();
    expect(shell.currentPage, 'a');
    expect(shell.destination, ShellDestination.page);
  });
}
