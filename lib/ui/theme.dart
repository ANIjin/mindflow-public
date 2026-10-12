import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData _build(Tokens t) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: t.bg.computeLuminance() < 0.15 ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: t.accent,
      brightness: t.bg.computeLuminance() < 0.15 ? Brightness.dark : Brightness.light,
      primary: t.accent,
      onPrimary: Colors.white,
      surface: t.card,
      outline: t.hairline,
      secondaryContainer: t.accent.withValues(alpha: 0.22),
      onSecondaryContainer: t.label,
    ),
    scaffoldBackgroundColor: t.bg,
    fontFamily: 'Segoe UI',
    extensions: [t],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Segoe UI',
      bodyColor: t.label,
      displayColor: t.label,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.accent,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: t.lg, vertical: t.sm + 2),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.accent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: t.md + 2, vertical: t.sm + 2),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.accent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        side: BorderSide(color: t.accent.withValues(alpha: 0.3)),
        padding: EdgeInsets.symmetric(horizontal: t.md + 2, vertical: t.sm + 2),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.elevated,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(color: t.secondary, fontSize: t.textSmall),
      hintStyle: TextStyle(color: t.tertiary, fontSize: t.textBody),
      contentPadding: EdgeInsets.symmetric(horizontal: t.md, vertical: t.sm + 2),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        borderSide: BorderSide(color: t.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        borderSide: BorderSide(color: t.focusRing, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      color: t.card,
      elevation: 0,
      shadowColor: const Color(0x18000000),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusLg),
        side: BorderSide(color: t.hairline),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.card,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shadowColor: const Color(0x33000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusXl),
        side: BorderSide(color: t.hairline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.elevated,
      contentTextStyle: TextStyle(color: t.label, fontSize: 13.5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusMd)),
      elevation: 12,
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: TextStyle(color: t.label, fontSize: t.textSmall),
      padding: EdgeInsets.symmetric(horizontal: t.md - 2, vertical: t.sm - 2),
      decoration: BoxDecoration(
        color: t.elevated,
        borderRadius: BorderRadius.circular(t.radiusSm + 2),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.accent,
      linearTrackColor: t.hairline,
      linearMinHeight: 3,
    ),
    dividerTheme: DividerThemeData(
      color: t.hairline,
      thickness: 1,
      space: 1,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(8),
      radius: const Radius.circular(8),
      crossAxisMargin: 2,
      mainAxisMargin: 4,
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.dragged)) {
          return t.label.withValues(alpha: 0.45);
        }
        if (states.contains(WidgetState.hovered)) {
          return t.label.withValues(alpha: 0.35);
        }
        return t.label.withValues(alpha: 0.22);
      }),
      trackColor: WidgetStatePropertyAll(t.elevated.withValues(alpha: 0.4)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.elevated,
      selectedColor: t.accent.withValues(alpha: 0.22),
      disabledColor: t.elevated.withValues(alpha: 0.5),
      secondarySelectedColor: t.accent.withValues(alpha: 0.22),
      labelStyle: TextStyle(color: t.label, fontSize: 13, fontWeight: FontWeight.w500),
      secondaryLabelStyle:
          TextStyle(color: t.label, fontSize: 13, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        side: BorderSide(color: t.hairline),
      ),
      side: BorderSide(color: t.hairline),
      checkmarkColor: t.accent,
      showCheckmark: false,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : t.secondary),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? t.accent
              : t.elevated),
      trackOutlineColor: WidgetStatePropertyAll(t.hairline),
    ),
    // Prefer a slightly denser desktop feel on Windows/macOS/Linux.
    visualDensity: VisualDensity.comfortable,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(t.secondary),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusSm + 2)),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.elevated),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusSm)),
      side: BorderSide(color: t.tertiary),
    ),
  );
}

ThemeData theme() => _build(Tokens.dark());

ThemeData lightTheme() => _build(Tokens.light());

@Deprecated('Use the Tokens theme extension via tk(context). Kept during migration.')
class Apple {
  Apple._();

  static final accent = Tokens.dark().accent;
  static final red = Tokens.dark().red;
  static final green = Tokens.dark().green;
  static final orange = Tokens.dark().orange;
  static final yellow = Tokens.dark().yellow;
  static final purple = Tokens.dark().purple;
  static final pink = Tokens.dark().pink;
  static final teal = Tokens.dark().teal;
  static final indigo = Tokens.dark().indigo;
  static final cyan = Tokens.dark().cyan;
  static final gray = Tokens.dark().gray;

  static final label = Tokens.dark().label;
  static final secondary = Tokens.dark().secondary;
  static final tertiary = Tokens.dark().tertiary;
  static final hairline = Tokens.dark().hairline;
  static final bg = Tokens.dark().bg;
  static final card = Tokens.dark().card;
  static final fill = Tokens.dark().elevated;

  static final softShadow = Tokens.dark().shadowHigh;

  static ThemeData theme() => _build(Tokens.dark());
}
