import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'cozy_motion.dart';

/// A shared illustration-led entry point for Kaibigan wellness features.
///
/// When [assetPath] is omitted, the banner intentionally renders an art
/// placeholder with a stable [placeholderLabel] for the final illustration.
class CozyFeatureBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? assetPath;
  final String placeholderLabel;
  final IconData placeholderIcon;
  final Color accent;
  final double height;
  final Alignment imageAlignment;

  const CozyFeatureBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.placeholderLabel,
    required this.placeholderIcon,
    this.assetPath,
    this.accent = AppColors.honeyAmber,
    this.height = 176,
    this.imageAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CozyEntrance(
      child: Semantics(
        label: '$title. $subtitle',
        container: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (assetPath != null)
                  Image.asset(
                    assetPath!,
                    key: ValueKey('feature-art-$placeholderLabel'),
                    fit: BoxFit.cover,
                    alignment: imageAlignment,
                    errorBuilder: (_, __, ___) => _placeholder(isDark),
                  )
                else
                  _placeholder(isDark),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        const Color(0xFF362719).withValues(alpha: 0.72),
                        const Color(0xFF362719).withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.58, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 84,
                  bottom: 17,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          color: Color(0xFFFFE8BD),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.45,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 8)
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      key: ValueKey('art-placeholder-$placeholderLabel'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF344038), const Color(0xFF202B25)]
              : [
                  accent.withValues(alpha: 0.30),
                  AppColors.honeyLight,
                  AppColors.warmCream,
                ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.72, -0.18),
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Icon(placeholderIcon, color: accent, size: 38),
        ),
      ),
    );
  }
}
