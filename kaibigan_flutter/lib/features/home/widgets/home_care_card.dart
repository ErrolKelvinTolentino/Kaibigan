import 'package:flutter/material.dart';
import '../../../core/theme/kaibigan_tokens.dart';

/// Quiet, content-sized home cards with a clear, reachable primary action.
class HomeCareCard extends StatelessWidget {
  const HomeCareCard(
      {super.key,
      required this.surfaceKey,
      required this.icon,
      required this.title,
      required this.description,
      required this.action,
      required this.onTap,
      this.detail,
      this.secondary,
      this.onSecondary,
      this.busy = false,
      this.highlighted = false});
  final Key surfaceKey;
  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback? onTap;
  final String? detail;
  final String? secondary;
  final VoidCallback? onSecondary;
  final bool busy;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Material(
      key: surfaceKey,
      color: highlighted ? palette.accentSubtle : palette.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: palette.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: palette.accentSubtle,
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(icon, size: 22, color: palette.accent)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: text.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          if (detail != null) ...[
                            const SizedBox(height: 4),
                            Text(detail!,
                                style: text.bodySmall
                                    ?.copyWith(color: palette.textSecondary))
                          ],
                        ])),
                  ]),
                  const SizedBox(height: 14),
                  Text(description,
                      style: text.bodyMedium?.copyWith(
                          height: 1.5, color: palette.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: busy ? null : onTap,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14)),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(action, textAlign: TextAlign.center)),
                  if (secondary != null)
                    TextButton(
                        onPressed: onSecondary,
                        style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48)),
                        child: Text(secondary!, textAlign: TextAlign.center)),
                ])),
      ),
    );
  }
}
