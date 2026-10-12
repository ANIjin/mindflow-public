import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/ui/shell_state.dart';

void main() {
  test('openPage sets current page, adds pane, notifies', () {
    final shell = ShellState();
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.openPage('page-a');

    expect(shell.currentPage, 'page-a');
    expect(shell.panes, ['page-a']);
    expect(shell.activePane, 0);
    expect(notifications, 1);
  });

  test('openPage replaces active pane content and notifies', () {
    final shell = ShellState();
    shell.openPage('page-a');
    shell.openInNewPane('page-b');
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.openPage('page-c');

    expect(shell.panes, ['page-a', 'page-c']);
    expect(shell.currentPage, 'page-c');
    expect(notifications, 1);
  });

  test('openInNewPane adds a second pane and notifies', () {
    final shell = ShellState();
    shell.openPage('page-a');
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.openInNewPane('page-b');

    expect(shell.panes, ['page-a', 'page-b']);
    expect(shell.activePane, 1);
    expect(shell.currentPage, 'page-b');
    expect(notifications, 1);
  });

  test('setActivePane switches current page and notifies', () {
    final shell = ShellState();
    shell.openPage('page-a');
    shell.openInNewPane('page-b');
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.setActivePane(0);

    expect(shell.activePane, 0);
    expect(shell.currentPage, 'page-a');
    expect(notifications, 1);
  });

  test('closePane removes pane, updates current page, notifies', () {
    final shell = ShellState();
    shell.openPage('page-a');
    shell.openInNewPane('page-b');
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.closePane(1);

    expect(shell.panes, ['page-a']);
    expect(shell.currentPage, 'page-a');
    expect(notifications, 1);
  });

  test('closing last pane clears current page and notifies', () {
    final shell = ShellState();
    shell.openPage('page-a');
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.closePane(0);

    expect(shell.panes, isEmpty);
    expect(shell.currentPage, isNull);
    expect(notifications, 1);
  });

  test('toggleSidebar flips collapse and notifies', () {
    final shell = ShellState();
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.toggleSidebar();

    expect(shell.sidebarCollapsed, isTrue);
    expect(notifications, 1);

    shell.toggleSidebar();

    expect(shell.sidebarCollapsed, isFalse);
    expect(notifications, 2);
  });

  test('setSidebarCollapsed with same value does not notify', () {
    final shell = ShellState();
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.setSidebarCollapsed(false);
    expect(notifications, 0);

    shell.setSidebarCollapsed(true);
    expect(shell.sidebarCollapsed, isTrue);
    expect(notifications, 1);
  });

  test('openPage pushes page to top of recents', () {
    final shell = ShellState();
    shell.openPage('page-a');
    shell.openPage('page-b');

    expect(shell.recents, ['page-b', 'page-a']);
  });

  test('reopening a page moves it to top of recents without duplicates', () {
    final shell = ShellState();
    shell.openPage('page-a');
    shell.openPage('page-b');
    shell.openPage('page-c');
    shell.openPage('page-a');

    expect(shell.recents, ['page-a', 'page-c', 'page-b']);
  });

  test('recents list is capped at 10 items', () {
    final shell = ShellState();
    for (int i = 1; i <= 12; i++) {
      shell.openPage('page-$i');
    }

    expect(shell.recents.length, 10);
    expect(shell.recents.first, 'page-12');
    expect(shell.recents.last, 'page-3');
    expect(shell.recents, isNot(contains('page-1')));
    expect(shell.recents, isNot(contains('page-2')));
  });

  test('toggleFavorite adds and removes favorites', () {
    final shell = ShellState();
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.toggleFavorite('page-a');
    expect(shell.favorites.contains('page-a'), isTrue);
    expect(notifications, 1);

    shell.toggleFavorite('page-a');
    expect(shell.favorites.contains('page-a'), isFalse);
    expect(notifications, 2);
  });

  test('toggleExpanded adds and removes expanded nodes', () {
    final shell = ShellState();
    var notifications = 0;
    shell.addListener(() => notifications++);

    shell.toggleExpanded('page-a');
    expect(shell.expanded.contains('page-a'), isTrue);
    expect(notifications, 1);

    shell.toggleExpanded('page-a');
    expect(shell.expanded.contains('page-a'), isFalse);
    expect(notifications, 2);
  });

  testWidgets('ShellState is available on the provider and notifies rebuilds',
      (tester) async {
    final shell = ShellState();
    var builds = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider<ShellState>.value(
        value: shell,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Consumer<ShellState>(
            builder: (context, value, _) {
              builds++;
              return Text(value.currentPage ?? 'none');
            },
          ),
        ),
      ),
    );

    expect(find.text('none'), findsOneWidget);
    expect(builds, 1);

    shell.openPage('page-a');
    await tester.pump();

    expect(find.text('page-a'), findsOneWidget);
    expect(builds, 2);
  });
}
