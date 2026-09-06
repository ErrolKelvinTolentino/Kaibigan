import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/language_helper.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';

String routineText(
  BuildContext context,
  String english,
  String filipino, [
  String? taglish,
]) =>
    LanguageHelper.pick(
      context.watch<UserProvider?>()?.language ?? 'english',
      english: english,
      filipino: filipino,
      taglish: taglish,
    );

/// The activity owns its header and progress. Routine context lives in one
/// quiet, thumb-reachable dock, with the full plan available on demand.
class RoutineActivityFrame extends StatelessWidget {
  const RoutineActivityFrame({
    super.key,
    required this.routine,
    required this.steps,
    required this.currentIndex,
    required this.skippedStepIds,
    required this.onSkip,
    required this.onPause,
    required this.child,
  });

  final RoutineConfig routine;
  final List<RoutineStep> steps;
  final int currentIndex;
  final Set<String> skippedStepIds;
  final VoidCallback onSkip;
  final VoidCallback onPause;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final stepLabel = routineText(
      context,
      'Step ${currentIndex + 1} of ${steps.length}',
      'Gawain ${currentIndex + 1} sa ${steps.length}',
      'Step ${currentIndex + 1} sa ${steps.length}',
    );

    return Scaffold(
      // Let the activity's own Scaffold handle the keyboard exactly once.
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: !keyboardOpen,
              child: child,
            ),
          ),
          if (!keyboardOpen)
            Material(
              key: const ValueKey('routine-context-dock'),
              color: isDark ? AppColors.darkCard : AppColors.warmCream,
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.honeyBorder,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: '$stepLabel, ${routine.title}',
                          child: InkWell(
                            key: const ValueKey('show-routine-plan'),
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => showRoutinePlan(
                              context,
                              routine: routine,
                              steps: steps,
                              currentIndex: currentIndex,
                              skippedStepIds: skippedStepIds,
                              onPause: onPause,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.format_list_bulleted_rounded,
                                      size: 20, color: textColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(stepLabel,
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700)),
                                        Text(
                                          routine.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_up_rounded,
                                      size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('skip-routine-activity'),
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: textColor,
                          minimumSize: const Size(56, 48),
                        ),
                        child: Text(routineText(context, 'Skip', 'Laktawan')),
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

Future<void> showRoutinePlan(
  BuildContext context, {
  required RoutineConfig routine,
  required List<RoutineStep> steps,
  required int currentIndex,
  required Set<String> skippedStepIds,
  VoidCallback? onPause,
}) async {
  final pause = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          maxWidth: 600,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(routine.title,
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(routineText(
              sheetContext,
              'One small step at a time. You can skip or pause whenever you need.',
              'Isa-isang gawain lang. Maaari kang lumaktaw o huminto muna anumang oras.',
              'One small step at a time. Puwedeng mag-skip o mag-pause kung kailangan.',
            )),
            const SizedBox(height: 16),
            for (var index = 0; index < steps.length; index++)
              Builder(builder: (context) {
                final step = steps[index];
                final skipped = skippedStepIds.contains(step.id);
                final completed = index < currentIndex && !skipped;
                final current = index == currentIndex;
                final label = skipped
                    ? routineText(context, 'Skipped', 'Nilaktawan')
                    : completed
                        ? routineText(context, 'Completed', 'Natapos')
                        : current
                            ? routineText(context, 'Now', 'Kasalukuyan', 'Ngayon')
                            : routineText(context, 'Up next', 'Susunod');
                return Container(
                  key: ValueKey('routine-plan-${step.id}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: current
                        ? routine.primaryColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    leading: Icon(
                      skipped
                          ? Icons.skip_next_rounded
                          : completed
                              ? Icons.check_circle_outline_rounded
                              : step.icon,
                      color: completed
                          ? AppColors.sageGreen
                          : isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                    ),
                    title: Text(step.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('$label · ~${step.estimatedMinutes} min'),
                  ),
                );
              }),
            const SizedBox(height: 12),
            if (onPause != null) ...[
              OutlinedButton.icon(
                key: const ValueKey('pause-routine-from-plan'),
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.pause_rounded),
                label: Text(routineText(sheetContext, 'Pause routine',
                    'Ipagpatuloy mamaya', 'I-pause muna')),
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: Text(routineText(sheetContext, 'Back to activity',
                  'Bumalik sa gawain', 'Balik sa activity')),
            ),
          ],
        ),
      );
    },
  );
  if (pause == true && context.mounted) onPause?.call();
}
