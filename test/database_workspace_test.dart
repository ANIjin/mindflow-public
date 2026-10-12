import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/core/models/view_def.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/theme.dart';
import 'package:mindflow/ui/widgets/database_workspace.dart';

void main() {
  testWidgets('database workspace shows views with counts and layouts',
      (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('db_ws');
      state = await AppState.openForTest(dir.path);
      await state.saveNode(MindNode(
          id: '1', title: 'One', type: 'assignment', status: 'active'));
      await state.saveNode(
          MindNode(id: '2', title: 'Two', type: 'goal', status: 'active'));
      await state.store.saveView(ViewDef(
        id: 'v1',
        name: 'All',
        layout: 'table',
        order: 0,
      ));
      await state.store.saveView(ViewDef(
        id: 'v2',
        name: 'Assignments',
        layout: 'list',
        types: ['assignment'],
        order: 1,
      ));
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider(
              create: (_) => ShellState(store: state.store)),
        ],
        child: MaterialApp(
          theme: theme(),
          home: const Scaffold(body: DatabaseWorkspace()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('database-workspace')), findsOneWidget);
    expect(find.textContaining('All'), findsWidgets);
    expect(find.byKey(const ValueKey('layout-table-view')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('layout-list')));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(find.byKey(const ValueKey('layout-list-view')), findsOneWidget);

    // Inline checkoff without opening page
    await tester.tap(find.byKey(const ValueKey('list-status-1')));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    expect(state.store.nodes['1']!.status, 'done');
  });
}
