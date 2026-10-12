import 'package:flutter/material.dart';

const Color _seed = Color(0xFF7C3AED);

class Tokens extends ThemeExtension<Tokens> {
  final Color bg;
  final Color card;
  final Color elevated;
  final Color hairline;
  final Color label;
  final Color secondary;
  final Color tertiary;

  final Color accent;
  final Color sidebarHighlight;
  final Color focusRing;
  final Color link;
  final Color graphEdge;
  final Color selection;

  final Color red;
  final Color orange;
  final Color yellow;
  final Color green;
  final Color teal;
  final Color cyan;
  final Color indigo;
  final Color purple;
  final Color pink;
  final Color gray;

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusPill;

  final BoxShadow shadowLow;
  final BoxShadow shadowMid;
  final BoxShadow shadowHigh;

  final Duration fast;
  final Duration normal;
  final Duration slow;

  final double textDisplay;
  final double textTitle;
  final double textHead;
  final double textBody;
  final double textSmall;
  final double textTiny;

  const Tokens({
    required this.bg,
    required this.card,
    required this.elevated,
    required this.hairline,
    required this.label,
    required this.secondary,
    required this.tertiary,
    required this.accent,
    required this.sidebarHighlight,
    required this.focusRing,
    required this.link,
    required this.graphEdge,
    required this.selection,
    required this.red,
    required this.orange,
    required this.yellow,
    required this.green,
    required this.teal,
    required this.cyan,
    required this.indigo,
    required this.purple,
    required this.pink,
    required this.gray,
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
    this.radiusSm = 6,
    this.radiusMd = 10,
    this.radiusLg = 14,
    this.radiusXl = 16,
    this.radiusPill = 999,
    required this.shadowLow,
    required this.shadowMid,
    required this.shadowHigh,
    this.fast = const Duration(milliseconds: 120),
    this.normal = const Duration(milliseconds: 220),
    this.slow = const Duration(milliseconds: 400),
    this.textDisplay = 26,
    this.textTitle = 15,
    this.textHead = 13.5,
    this.textBody = 14,
    this.textSmall = 12,
    this.textTiny = 11,
  });

  static Tokens dark([Color seed = _seed]) => Tokens(
        bg: const Color(0xFF121016),
        card: const Color(0xFF1C1A22),
        elevated: const Color(0xFF26242E),
        hairline: const Color(0xFF3A3844),
        label: const Color(0xFFEDECF2),
        secondary: const Color(0xFF9B98A6),
        tertiary: const Color(0xFF6E6B7A),
        accent: seed,
        sidebarHighlight: seed.withValues(alpha: 0.18),
        focusRing: seed,
        link: Color.lerp(seed, Colors.white, 0.35)!,
        graphEdge: seed.withValues(alpha: 0.35),
        selection: seed.withValues(alpha: 0.25),
        red: const Color(0xFFFF453A),
        orange: const Color(0xFFFF9F0A),
        yellow: const Color(0xFFFFD60A),
        green: const Color(0xFF32D74B),
        teal: const Color(0xFF64D2FF),
        cyan: const Color(0xFF32ADE6),
        indigo: const Color(0xFF367AFF),
        purple: const Color(0xFFBF5AF2),
        pink: const Color(0xFFFF375F),
        gray: const Color(0xFF98989D),
        shadowLow: const BoxShadow(
            color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 1)),
        shadowMid: const BoxShadow(
            color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
        shadowHigh: const BoxShadow(
            color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4)),
      );

  static Tokens light([Color seed = _seed]) => Tokens(
        bg: const Color(0xFFFFFFFF),
        card: const Color(0xFFFAFAFC),
        elevated: const Color(0xFFF1F0F5),
        hairline: const Color(0xFFE4E3EA),
        label: const Color(0xFF201F26),
        secondary: const Color(0xFF6B6875),
        tertiary: const Color(0xFF9A97A4),
        accent: seed,
        sidebarHighlight: seed.withValues(alpha: 0.10),
        focusRing: seed,
        link: seed,
        graphEdge: seed.withValues(alpha: 0.28),
        selection: seed.withValues(alpha: 0.16),
        red: const Color(0xFFFF3B30),
        orange: const Color(0xFFFF9500),
        yellow: const Color(0xFFFFCC00),
        green: const Color(0xFF28C840),
        teal: const Color(0xFF00AEC3),
        cyan: const Color(0xFF32ADE6),
        indigo: const Color(0xFF367AFF),
        purple: const Color(0xFFAC4FD2),
        pink: const Color(0xFFFF2D55),
        gray: const Color(0xFF8E8E93),
        shadowLow: const BoxShadow(
            color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 1)),
        shadowMid: const BoxShadow(
            color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3)),
        shadowHigh: const BoxShadow(
            color: Color(0x29000000), blurRadius: 16, offset: Offset(0, 4)),
      );

  @override
  Tokens copyWith({
    Color? bg,
    Color? card,
    Color? elevated,
    Color? hairline,
    Color? label,
    Color? secondary,
    Color? tertiary,
    Color? accent,
    Color? sidebarHighlight,
    Color? focusRing,
    Color? link,
    Color? graphEdge,
    Color? selection,
    Color? red,
    Color? orange,
    Color? yellow,
    Color? green,
    Color? teal,
    Color? cyan,
    Color? indigo,
    Color? purple,
    Color? pink,
    Color? gray,
    BoxShadow? shadowLow,
    BoxShadow? shadowMid,
    BoxShadow? shadowHigh,
  }) =>
      Tokens(
        bg: bg ?? this.bg,
        card: card ?? this.card,
        elevated: elevated ?? this.elevated,
        hairline: hairline ?? this.hairline,
        label: label ?? this.label,
        secondary: secondary ?? this.secondary,
        tertiary: tertiary ?? this.tertiary,
        accent: accent ?? this.accent,
        sidebarHighlight: sidebarHighlight ?? this.sidebarHighlight,
        focusRing: focusRing ?? this.focusRing,
        link: link ?? this.link,
        graphEdge: graphEdge ?? this.graphEdge,
        selection: selection ?? this.selection,
        red: red ?? this.red,
        orange: orange ?? this.orange,
        yellow: yellow ?? this.yellow,
        green: green ?? this.green,
        teal: teal ?? this.teal,
        cyan: cyan ?? this.cyan,
        indigo: indigo ?? this.indigo,
        purple: purple ?? this.purple,
        pink: pink ?? this.pink,
        gray: gray ?? this.gray,
        xs: xs,
        sm: sm,
        md: md,
        lg: lg,
        xl: xl,
        xxl: xxl,
        radiusSm: radiusSm,
        radiusMd: radiusMd,
        radiusLg: radiusLg,
        radiusXl: radiusXl,
        radiusPill: radiusPill,
        shadowLow: shadowLow ?? this.shadowLow,
        shadowMid: shadowMid ?? this.shadowMid,
        shadowHigh: shadowHigh ?? this.shadowHigh,
        fast: fast,
        normal: normal,
        slow: slow,
        textDisplay: textDisplay,
        textTitle: textTitle,
        textHead: textHead,
        textBody: textBody,
        textSmall: textSmall,
        textTiny: textTiny,
      );

  @override
  Tokens lerp(Tokens? other, double t) => this;
}

Tokens tk(BuildContext context) =>
    Theme.of(context).extension<Tokens>() ?? Tokens.dark();
