import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusSm + 2),
        gradient: LinearGradient(
          colors: [t.accent, Color.lerp(t.accent, t.purple, 0.45)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: t.accent.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: const Icon(CupertinoIcons.sparkles,
          color: Colors.white, size: 16),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  const SidebarItem(
      {super.key,
      required this.icon,
      required this.label,
      required this.selected,
      this.compact = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.xs / 2, horizontal: t.sm + 2),
      child: InkWell(
        onTap: onTap,
        hoverColor: t.label.withValues(alpha: 0.04),
        focusColor: t.focusRing.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(t.radiusSm + 2),
        child: AnimatedContainer(
          duration: t.fast,
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: t.sm + 2),
          decoration: BoxDecoration(
            color: selected ? t.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(t.radiusSm + 2),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: t.accent.withValues(alpha: 0.13),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? Colors.white : t.secondary),
              if (!compact) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : t.label)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> trailing;
  const PageHeader(this.title,
      {super.key, this.subtitle, this.trailing = const []});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        if (narrow) {
          return Padding(
            padding: EdgeInsets.fromLTRB(t.xl, t.lg - 2, t.xl, t.md - 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: t.textDisplay - 6,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: t.label)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!,
                      style:
                          TextStyle(fontSize: t.textSmall, color: t.secondary)),
                ],
                if (trailing.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: trailing),
                ],
              ],
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(t.xl, t.lg + 4, t.xl, t.md + 2),
          child: Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: t.textDisplay,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: t.label)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: t.textSmall + 1, color: t.secondary)),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: Wrap(spacing: 8, runSpacing: 8, children: trailing),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final bool shadow;
  const SectionCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(14),
      this.margin = EdgeInsets.zero,
      this.color,
      this.shadow = true});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? t.card,
        borderRadius: BorderRadius.circular(t.radiusLg),
        border: Border.all(color: t.hairline),
        boxShadow: shadow ? [t.shadowHigh] : null,
      ),
      child: child,
    );
  }
}

class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
        height: 1,
        color: t.hairline,
        margin: EdgeInsets.symmetric(horizontal: t.md + 2));
  }
}

enum AppleTone { primary, tinted, gray, ghost }

class AppleButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppleTone tone;
  const AppleButton(this.label,
      {super.key,
      this.icon,
      this.onPressed,
      this.tone = AppleTone.primary});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final enabled = onPressed != null;
    Color bg;
    Color fg;
    switch (tone) {
      case AppleTone.primary:
        bg = t.accent;
        fg = Colors.white;
      case AppleTone.tinted:
        bg = t.accent.withValues(alpha: enabled ? 0.12 : 0.06);
        fg = t.accent.withValues(alpha: enabled ? 1 : 0.4);
      case AppleTone.gray:
        bg = t.elevated;
        fg = t.label;
      case AppleTone.ghost:
        bg = Colors.transparent;
        fg = t.accent;
    }
    return AnimatedContainer(
      duration: t.fast,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(t.radiusPill),
        boxShadow: tone == AppleTone.primary
            ? [
                BoxShadow(
                    color: t.accent.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ]
            : null,
      ),
      child: InkWell(
        onTap: onPressed,
        focusColor: t.focusRing.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(t.radiusPill),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.md + 2, vertical: t.sm + 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppleSegmented extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const AppleSegmented(
      {super.key,
      required this.options,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.elevated,
        borderRadius: BorderRadius.circular(t.radiusSm + 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            InkWell(
              onTap: () => onChanged(o),
              borderRadius: BorderRadius.circular(t.radiusSm + 1),
              child: AnimatedContainer(
                duration: t.fast,
                padding: EdgeInsets.symmetric(
                    horizontal: t.md + 2, vertical: t.sm - 2),
                decoration: BoxDecoration(
                  color: o == selected ? t.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(t.radiusSm + 1),
                  boxShadow: o == selected ? [t.shadowLow] : null,
                ),
                child: Text(o,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: o == selected ? t.label : t.secondary)),
              ),
            ),
        ],
      ),
    );
  }
}

class AppleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final double box;
  const AppleIconButton({super.key,
      required this.icon,
      this.onPressed,
      this.color,
      this.size = 16,
      this.box = 30});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    final c = color ?? t.secondary;
    return InkWell(
      onTap: onPressed,
      hoverColor: t.label.withValues(alpha: 0.05),
      focusColor: t.focusRing.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(t.radiusSm + 2),
      child: SizedBox(
        width: box,
        height: box,
        child: Center(child: Icon(icon, size: size, color: c)),
      ),
    );
  }
}

class AppleCheckbox extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  const AppleCheckbox({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value ?? false,
      onChanged: onChanged,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class AppleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AppleSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}

class TagChip extends StatelessWidget {
  final Color color;
  final String label;
  const TagChip(this.color, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

Future<T?> appleDialog<T>(BuildContext context,
    {required String title,
    required Widget content,
    required List<Widget> actions,
    double width = 420}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) {
      final t = tk(ctx);
      return Dialog(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          side: BorderSide(color: t.hairline),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: width.clamp(0.0,
                  MediaQuery.sizeOf(ctx).width - 40)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(t.xl, t.xl, t.xl, t.lg - 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: t.label)),
                const SizedBox(height: 14),
                content,
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget appleField(TextEditingController c, String label,
    {String? hint,
    int maxLines = 1,
    bool obscure = false,
    ValueChanged<String>? onSubmitted}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      maxLines: obscure ? 1 : maxLines,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}

class AppleProgress extends StatelessWidget {
  const AppleProgress({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: const SizedBox(
          height: 3, child: LinearProgressIndicator(minHeight: 3)));
}

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.elevated,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: t.secondary,
        ),
      ),
    );
  }
}
