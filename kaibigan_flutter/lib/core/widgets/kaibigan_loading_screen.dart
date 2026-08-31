import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'kaibigan_logo.dart';
import 'kaibigan_state_view.dart';

class KaibiganLoadingScreen extends StatelessWidget {
  const KaibiganLoadingScreen({
    super.key,
    this.message = 'Preparing your space…',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      key: const ValueKey('kaibigan-loading-screen'),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoadingBackdrop(),
          SafeArea(
            child: Center(
              child: Semantics(
                liveRegion: true,
                label: 'Kaibigan. $message',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const KaibiganWordmark(fontSize: 46),
                    const SizedBox(height: 20),
                    const KaibiganLoadingMark(color: AppColors.honeyAmber),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBackdrop extends StatelessWidget {
  const _LoadingBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 0.85,
          colors: isDark
              ? const [Color(0xFF29281F), AppColors.darkBackground]
              : const [Color(0xFFFFF1BD), AppColors.warmCream],
        ),
      ),
    );
  }
}
