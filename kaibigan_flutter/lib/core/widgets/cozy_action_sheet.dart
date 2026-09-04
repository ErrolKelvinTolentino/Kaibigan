import 'package:flutter/material.dart';

import '../theme/kaibigan_tokens.dart';
import 'mobile_layout.dart';

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
    final palette = context.kaibigan;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: palette.scrim,
      builder: (sheetContext) => MobileSheetBody(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            MobileLayout.horizontalPadding(sheetContext),
            12,
            MobileLayout.horizontalPadding(sheetContext),
            18 + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: palette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 34,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
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
                            ? [palette.accentSubtle, palette.botanicalSubtle]
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
                          ? palette.surface.withValues(alpha: 0.78)
                          : Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.border,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 42)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.botanicalSubtle,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  eyebrow,
                  style: TextStyle(
                    color: palette.botanical,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 23,
                  height: 1.16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: palette.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: palette.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 17,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          detail,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    secondaryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

    return result ?? false;
  }
}
