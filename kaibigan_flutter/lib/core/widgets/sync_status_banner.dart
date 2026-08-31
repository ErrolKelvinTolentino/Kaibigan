import 'package:flutter/material.dart';

import '../theme/kaibigan_tokens.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({
    super.key,
    required this.message,
    required this.onRetry,
    this.backgroundColor,
    this.foregroundColor,
    this.margin = const EdgeInsets.fromLTRB(20, 4, 20, 8),
  });

  final String message;
  final Future<void> Function() onRetry;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final resolvedForeground = foregroundColor ?? palette.warning;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: backgroundColor ?? palette.accentSubtle,
          borderRadius: BorderRadius.circular(KaibiganRadius.control),
          border: Border.all(
            color: resolvedForeground.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: resolvedForeground,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor ?? palette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: resolvedForeground,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
