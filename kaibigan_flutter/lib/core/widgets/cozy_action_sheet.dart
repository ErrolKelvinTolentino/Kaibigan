import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';

class CozyActionSheet {
  static Future<bool> show(
    BuildContext context, {
    required String eyebrow,
    required String title,
    required String message,
    required String primaryLabel,
    String secondaryLabel = 'Maybe later',
    String emoji = '✨',
    String? detail,
    bool isDismissible = true,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.only(top: 48),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            18 + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : const Color(0xFFFFFDF8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.honeyGold.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.14),
                blurRadius: 34,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD9D2C7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [Color(0xFF3D3627), Color(0xFF29362D)]
                            : const [Color(0xFFFFEEC9), Color(0xFFE9F2E5)],
                      ),
                    ),
                  ),
                  Container(
                    width: 78,
                    height: 78,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.66),
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 42)),
                  ),
                ],
              ).animate().fadeIn(duration: 240.ms).scale(
                    begin: const Offset(0.78, 0.78),
                    duration: 520.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sageGreen
                      .withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.sageGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ).animate().fadeIn(delay: 90.ms).slideY(begin: 0.18),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: 23,
                  height: 1.16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.45,
                ),
              ).animate().fadeIn(delay: 130.ms).slideY(begin: 0.12),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 14,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 170.ms),
              if (detail != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.045)
                        : const Color(0xFFF7F2E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : AppColors.honeyGold.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 17,
                        color: AppColors.honeyAmber,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          detail,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.honeyGold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        primaryLabel,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.12),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.sageGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    secondaryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }
}
