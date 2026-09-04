import 'package:flutter/material.dart';
import '../theme/kaibigan_tokens.dart';
import 'mobile_layout.dart';

class CozyConfirmSheet {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Let Go',
    String cancelLabel = 'Keep Entry',
    IconData icon = Icons.delete_outline_rounded,
    bool isDestructive = true,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MobileSheetBody(
        topMargin: 72,
        child: Builder(builder: (context) {
          final palette = context.kaibigan;
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: MobileLayout.horizontalPadding(ctx),
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),

                // Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? palette.danger.withValues(alpha: 0.12)
                        : palette.accentSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: isDestructive ? palette.danger : palette.accent,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackActions = constraints.maxWidth < 330 ||
                        MediaQuery.textScalerOf(context).scale(14) > 18;
                    final cancel = SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.botanicalSubtle,
                          foregroundColor: palette.botanical,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: palette.botanical.withValues(alpha: 0.32),
                            ),
                          ),
                        ),
                        child: Text(cancelLabel),
                      ),
                    );
                    final confirm = SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDestructive ? palette.danger : palette.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(confirmLabel),
                      ),
                    );
                    if (stackActions) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [confirm, const SizedBox(height: 10), cancel],
                      );
                    }
                    return Row(children: [
                      // Cancel / Keep Button (Primary peaceful action)
                      Expanded(child: cancel),
                      const SizedBox(width: 12),
                      Expanded(child: confirm),
                    ]);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
        }),
      ),
    );

    return result ?? false;
  }
}
