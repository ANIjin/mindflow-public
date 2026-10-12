import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/core/models/node.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/theme.dart';
import 'package:mindflow/ui/widgets/sidebar.dart';

Widget _wrap(ShellState shell, MemoryStore store,
    {Size size = const Size(400, 800)}) {
  return MaterialApp(
    theme: theme(),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: ChangeNotifierProvider<ShellState>.value(
        value: shell,
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: SidebarNav(store: store),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('nested page tree renders children under parent with expand/collapse',
      (tester) async {
    late Directory dir;
    late MemoryStore store;
    await tester.runAsync(() async {
      dir = Directory.systemTemp.createTempSync('sidebar_test');
      store = await MemoryStore.open(dir.path);
      await store.saveNode(
          MindNode(id: 'a', title: 'Alpha', spaceId: 'Courses'));
      await store.saveNode(MindNode(id: 'b', title: 'Beta', parentId: 'a'));
      await store.saveNode(MindNode(id: 'c', title: 'Gamma', parentId: 'a'));
    });
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    final shell = ShellState(store: store);

    await tester.pumpWidget(_wrap(shell, store));

    expect(find.text('SPACE: COURSES'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.byKey(const ValueKey('page-b')), findsNothing);
    expect(find.byKey(const ValueKey('page-c')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('expand-a')));
    await tester.pump();

    expect(find.byKey(const ValueKey('page-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-c')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('expand-a')));
    await tester.pump();

    expect(find.byKey(const ValueKey('page-b')), findsNothing);
    expect(find.byKey(const ValueKey('page-c')), findsNothing);
    expect(shell.expanded.contains('a'), isFalse);

    await tester.tap(find.byKey(const ValueKey('expand-a')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('page-b')));
    await tester.pump();

    expect(shell.currentPage, 'b');
    expect(shell.recents.first, 'b');
  });

  testWidgets('recents section is capped at 10 items', (tester) async {
    late Directory dir;
    late MemoryStore store;
    await tester.runAsync(() async {
      dir = Directory.systemTemp.createTempSync('sidebar_recents');
      store = await MemoryStore.open(dir.path);
      for (int i = 1; i <= 12; i++) {
        await store.saveNode(MindNode(id: 'p$i', title: 'P$i'));
      }
    });
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    final shell = ShellState(store: store);
    for (int i = 1; i <= 12; i++) {
      shell.openPage('p$i');
    }

    expect(shell.recents.length, 10);
    expect(shell.recents.first, 'p12');
    expect(shell.recents.last, 'p3');
    expect(shell.recents, isNot(contains('p1')));
    expect(shell.recents, isNot(contains('p2')));

    await tester.pumpWidget(_wrap(shell, store));

    expect(find.text('RECENTS'), findsOneWidget);
    expect(find.text('P12', skipOffstage: false), findsWidgets);
    expect(find.text('P3', skipOffstage: false), findsWidgets);
  });

  testWidgets('favorites section shows favorited pages', (tester) async {
    late Directory dir;
    late MemoryStore store;
    await tester.runAsync(() async {
      dir = Directory.systemTemp.createTempSync('sidebar_favs');
      store = await MemoryStore.open(dir.path);
      await store.saveNode(MindNode(id: 'a', title: 'Alpha'));
      await store.saveNode(MindNode(id: 'b', title: 'Beta'));
    });
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });

    final shell = ShellState(store: store);

    await tester.pumpWidget(_wrap(shell, store));

    expect(find.text('FAVORITES'), findsNothing);

    shell.toggleFavorite('b');
    await tester.pump();

    expect(find.text('FAVORITES'), findsOneWidget);
    expect(find.text('Beta'), findsNWidgets(2));
  });
}
