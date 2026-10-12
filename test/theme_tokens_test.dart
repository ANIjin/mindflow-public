import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindflow/ui/theme.dart';
import 'package:mindflow/ui/tokens.dart';

const seed = Color(0xFF7C3AED);

void main() {
  test('theme() produces a dark theme from tokens with purple accent', () {
    final td = theme();
    final t = td.extension<Tokens>();
    expect(t, isNotNull);
    expect(td.brightness, Brightness.dark);
    expect(t!.accent, seed);
    expect(t.focusRing, seed);
    expect(t.sidebarHighlight, seed.withValues(alpha: 0.18));
    expect(t.link, Color.lerp(seed, Colors.white, 0.35));
    expect(t.graphEdge, seed.withValues(alpha: 0.35));
    expect(t.bg.computeLuminance() < 0.15, isTrue);
    expect(td.scaffoldBackgroundColor, t.bg);
    expect(td.textTheme.bodyMedium?.color, t.label);
  });

  test('lightTheme() produces a light theme from the same purple seed', () {
    final td = lightTheme();
    final t = td.extension<Tokens>();
    expect(t, isNotNull);
    expect(td.brightness, Brightness.light);
    expect(t!.accent, seed);
    expect(t.focusRing, seed);
    expect(t.link, seed);
    expect(t.bg.computeLuminance() > 0.5, isTrue);
  });

  test('light and dark share spacing, radius, type scale, motion tokens', () {
    final d = Tokens.dark();
    final l = Tokens.light();
    expect(d.xs, l.xs);
    expect(d.sm, l.sm);
    expect(d.md, l.md);
    expect(d.lg, l.lg);
    expect(d.radiusMd, l.radiusMd);
    expect(d.textDisplay, l.textDisplay);
    expect(d.textBody, l.textBody);
    expect(d.fast, l.fast);
    expect(d.normal, l.normal);
    expect(d.slow, l.slow);
  });

  test('tokens carry elevation shadows', () {
    final t = Tokens.dark();
    expect(t.shadowLow.blurRadius < t.shadowMid.blurRadius, isTrue);
    expect(t.shadowMid.blurRadius < t.shadowHigh.blurRadius, isTrue);
  });

  testWidgets('first launch: tk() yields dark tokens with purple accent',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: lightTheme(),
      darkTheme: theme(),
      themeMode: ThemeMode.dark,
      home: Builder(
        builder: (ctx) {
          final t = tk(ctx);
          return Text('${t.accent.value}', style: TextStyle(color: t.label));
        },
      ),
    ));
    expect(find.text('${seed.value}'), findsOneWidget);
    expect(tk(tester.element(find.text('${seed.value}')))
        .bg
        .computeLuminance() < 0.15, isTrue);
  });

  test('Apple alias is deprecated and maps to dark tokens', () {
    expect(Apple.accent, seed);
    expect(Apple.bg, Tokens.dark().bg);
    expect(Apple.label, Tokens.dark().label);
  });
}
