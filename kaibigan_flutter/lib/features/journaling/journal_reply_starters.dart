import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// The first-person openers the companion returns with each reply.
///
/// The model has always produced these; until now they were parsed, stored and
/// thrown away. They matter most to someone staring at a blank page after a
/// reply — so they appear only on the turn about to be answered, and only
/// while it is still empty.
class JournalReplyStarters extends StatelessWidget {
  const JournalReplyStarters({
    super.key,
    required this.starters,
    required this.label,
    required this.isDark,
    required this.onSelected,
  });

  final List<String> starters;

  /// Localised eyebrow, e.g. "IF IT HELPS TO START".
  final String label;

  final bool isDark;
  final ValueChanged<String> onSelected;

  /// The starters worth showing right now.
  ///
  /// Returns nothing while a reply is in flight, when this is not the turn the
  /// person is about to answer, or once they have started writing — suggested
  /// words should never compete with their own.
  static List<String> visibleStarters(
    List<String> suggested, {
    required bool isAnsweringTurn,
    required bool activeTurnIsEmpty,
    required bool isBusy,
  }) {
    if (isBusy || !isAnsweringTurn || !activeTurnIsEmpty) return const [];
    return suggested
        .map((starter) => starter.trim())
        .where((starter) => starter.isNotEmpty && starter.length <= 120)
        .take(2)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (starters.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('journal-reply-starters'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 0.9,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: starters
              .map(
                (starter) => Material(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    key: ValueKey('reply-starter-$starter'),
                    onTap: () => onSelected(starter),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 260),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : Colors.black.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.north_east_rounded,
                            size: 13,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              starter,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
