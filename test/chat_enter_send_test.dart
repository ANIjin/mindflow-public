import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/ui/chat_page.dart';
import 'package:mindflow/ui/theme.dart';

Future<AppState> _openState() async {
  final dir = Directory.systemTemp.createTempSync('chat_enter');
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });
  return AppState.openForTest(dir.path);
}

void main() {
  testWidgets('Enter sends the chat message; field clears', (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      state = await _openState();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: theme(),
          home: const Scaffold(body: ChatPage()),
        ),
      ),
    );
    await tester.pump();

    final field = find.byKey(const ValueKey('chat-input'));
    expect(field, findsOneWidget);
    await tester.enterText(field, 'What day is it?');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text('What day is it?'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(state.chat.where((m) => m.role == 'user').length, 1);
    expect(state.chat.first.content, 'What day is it?');

    // Let the in-flight agent call settle (will error without a live model).
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
  });

  testWidgets('Shift+Enter does not send', (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      state = await _openState();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: theme(),
          home: const Scaffold(body: ChatPage()),
        ),
      ),
    );
    await tester.pump();

    final field = find.byKey(const ValueKey('chat-input'));
    await tester.tap(field);
    await tester.enterText(field, 'line one');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(state.chat, isEmpty);
  });
}
