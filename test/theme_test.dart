import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/app_state.dart';
import 'package:mindflow/ui/app_shell.dart';
import 'package:mindflow/ui/shell_state.dart';
import 'package:mindflow/ui/tokens.dart';
import 'package:mindflow/ui/theme.dart';

void main() {
  test('theme() and lightTheme() produce both themes from the same tokens', () {
    final dark = theme();
    final light = lightTheme();
    final dt = dark.extension<Tokens>()!;
    final lt = light.extension<Tokens>()!;
    expect(dark.brightness, Brightness.dark);
    expect(light.brightness, Brightness.light);
    expect(dt.accent, lt.accent);
    expect(dt.focusRing, lt.focusRing);
    expect(dt.accent, const Color(0xFF7C3AED));
    expect(dt.bg, isNot(lt.bg));
    expect(dt.textBody, lt.textBody);
    expect(dt.normal, lt.normal);
    expect(dt.radiusLg, lt.radiusLg);
  });

  testWidgets('first launch renders dark with the purple accent',
      (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('mf_theme');
      state = await AppState.openForTest(dir.path);
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider(
              create: (_) => ShellState(store: state.store)),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          darkTheme: theme(),
          themeMode: ThemeMode.dark,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump();
    final ctx = tester.element(find.byType(AppShell));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    expect(tk(ctx).accent, const Color(0xFF7C3AED));
  });

  testWidgets('light mode renders screens with the purple accent',
      (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('mf_theme_light');
      state = await AppState.openForTest(dir.path);
      state.store.settings['theme'] = 'light';
      await state.store.saveSettings();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          ChangeNotifierProvider(
              create: (_) => ShellState(store: state.store)),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          darkTheme: theme(),
          themeMode: ThemeMode.light,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pump();
    final ctx = tester.element(find.byType(AppShell));
    expect(Theme.of(ctx).brightness, Brightness.light);
    expect(tk(ctx).accent, const Color(0xFF7C3AED));
  });
}
