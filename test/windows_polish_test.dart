import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/memory/memory_store.dart';
import 'package:mindflow/ui/theme.dart';
import 'package:mindflow/ui/widgets/apple.dart';

void main() {
  test('default settings do not hardcode a personal user name', () {
    expect(MemoryStore('').settings['userName'], '');
  });

  testWidgets('PageHeader wraps trailing controls in narrow panes',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme(),
        home: const Scaffold(
          body: SizedBox(
            width: 520,
            child: PageHeader(
              'Board',
              subtitle: 'Views',
              trailing: [
                Text('One'),
                Text('Two'),
                Text('Three'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Board'), findsOneWidget);
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('theme exposes desktop scrollbar and chip styling', (tester) async {
    late ThemeData captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme(),
        home: Builder(builder: (context) {
          captured = Theme.of(context);
          return const SizedBox();
        }),
      ),
    );
    expect(captured.scrollbarTheme.thickness?.resolve({}), 8);
    expect(captured.chipTheme.selectedColor, isNotNull);
    expect(captured.switchTheme.trackColor, isNotNull);
  });
}
