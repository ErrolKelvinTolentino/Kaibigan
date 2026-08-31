import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Adds very soft pollen glows across the app without intercepting gestures.
/// It sits above every route so even legacy feature pages share the same
/// atmosphere while their layouts remain unchanged.
class CozyAppFrame extends StatelessWidget {
  final Widget child;

  const CozyAppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ExcludeSemantics(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Stack(
                children: [
                  Positioned(
                    top: -92,
                    right: -92,
                    child: _GlowOrb(
                      size: 260,
                      color:
                          (isDark ? AppColors.warmHoney : AppColors.pollenGlow)
                              .withValues(alpha: isDark ? 0.045 : 0.075),
                    ),
                  ),
                  Positioned(
                    bottom: -110,
                    left: -120,
                    child: _GlowOrb(
                      size: 300,
                      color: AppColors.honeyAmber
                          .withValues(alpha: isDark ? 0.025 : 0.035),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}
