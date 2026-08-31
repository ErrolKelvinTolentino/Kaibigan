import 'package:flutter/material.dart';

import '../theme/kaibigan_tokens.dart';

enum KaibiganSurfaceTone { primary, elevated, subtle, accent, botanical }

/// A restrained, reusable surface with Kaibigan's semantic color roles.
class KaibiganSurface extends StatelessWidget {
  const KaibiganSurface({
    super.key,
    required this.child,
    this.tone = KaibiganSurfaceTone.elevated,
    this.padding = const EdgeInsets.all(16),
    this.radius = KaibiganRadius.card,
    this.onTap,
    this.semanticLabel,
    this.showBorder = true,
    this.showShadow = false,
  });

  final Widget child;
  final KaibiganSurfaceTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool showBorder;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final color = switch (tone) {
      KaibiganSurfaceTone.primary => palette.surface,
      KaibiganSurfaceTone.elevated => palette.surfaceElevated,
      KaibiganSurfaceTone.subtle => palette.surfaceSubtle,
      KaibiganSurfaceTone.accent => palette.accentSubtle,
      KaibiganSurfaceTone.botanical => palette.botanicalSubtle,
    };
    final borderColor = switch (tone) {
      KaibiganSurfaceTone.accent => palette.accent.withValues(alpha: 0.26),
      KaibiganSurfaceTone.botanical =>
        palette.botanical.withValues(alpha: 0.24),
      _ => palette.border,
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: showBorder ? BorderSide(color: borderColor) : BorderSide.none,
    );

    Widget result = Material(
      color: color,
      elevation: 0,
      shadowColor: palette.shadow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
    if (semanticLabel != null) {
      result = Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: result,
      );
    }
    return result;
  }
}

class KaibiganSectionHeader extends StatelessWidget {
  const KaibiganSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.action,
  });

  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.kaibigan;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium),
              if (description != null) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  style: text.bodySmall?.copyWith(color: palette.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          action!,
        ],
      ],
    );
  }
}
