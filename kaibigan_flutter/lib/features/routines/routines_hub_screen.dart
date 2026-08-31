import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mobile_layout.dart';
import '../../core/widgets/sync_status_banner.dart';
import '../mood_tracking/mood_model.dart';
import '../mood_tracking/mood_tracker_screen.dart';
import '../gratitude_garden/garden_screen.dart';
import 'routine_model.dart';
import 'routines_provider.dart';
import 'routine_management_screen.dart';
import 'flows/progressive_routine_runner.dart';
import 'widgets/custom_routine_dialog.dart';

// Standalone feature screens
import 'screens/sleep_log_flow_screen.dart';
import 'screens/todays_focus_screen.dart';
import 'screens/todays_highlight_screen.dart';
import 'screens/daily_reflection_screen.dart';
import 'screens/grounding_session_screen.dart';
import 'screens/mindfulness_meditation_screen.dart';

class RoutinesHubScreen extends StatelessWidget {
  const RoutinesHubScreen({super.key});

  void _launchRoutine(
    BuildContext context,
    RoutineConfig routine, {
    bool resume = false,
  }) {
    if (!routine.isEnabled || routine.activeStepsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !routine.isEnabled
                ? 'Enable this routine before starting it.'
                : 'Add or enable at least one activity first.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgressiveRoutineRunner(
          routineType: routine.type,
          config: routine,
          resumeSession: resume,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routinesProvider = Provider.of<RoutinesProvider>(context);

    final phase = routinesProvider.currentPhase;
    final activeSession = routinesProvider.activeSession;
    final resumableRoutine = activeSession == null
        ? null
        : routinesProvider.getRoutineById(activeSession.routineId);
    final recommended = resumableRoutine ?? routinesProvider.recommendedRoutine;
    final isResuming = resumableRoutine != null;
    final resumeStepIndex = isResuming && recommended != null
        ? activeSession!.nextStepIndex.clamp(0, recommended.activeStepsCount)
        : 0;
    final resumeAtCompletion = isResuming &&
        recommended != null &&
        resumeStepIndex >= recommended.activeStepsCount;
    final allRoutines = routinesProvider.allRoutines;

    String phaseText;
    IconData phaseIcon;
    Color phaseColor;

    switch (phase) {
      case RoutineType.morning:
        phaseText = 'Morning';
        phaseIcon = Icons.wb_sunny_outlined;
        phaseColor = AppColors.sageGreen;
        break;
      case RoutineType.midday:
        phaseText = 'Mid-day';
        phaseIcon = Icons.spa_outlined;
        phaseColor = AppColors.honeyAmber;
        break;
      case RoutineType.night:
      case RoutineType.custom:
        phaseText = 'Evening';
        phaseIcon = Icons.nights_stay_outlined;
        phaseColor = AppColors.beePrimary;
        break;
    }

    final List<Map<String, dynamic>> standaloneFeatures = [
      {
        'title': "Today's Focus",
        'subtitle': 'Set daily intention',
        'asset': FeatureIconHelper.todaysFocus,
        'icon': Icons.lightbulb_outline,
        'color': AppColors.honeyAmber,
        'screen': const TodaysFocusScreen()
      },
      {
        'title': 'Mood Check-In',
        'subtitle': 'Track energy bees',
        'asset': FeatureIconHelper.moodTracker,
        'icon': Icons.sentiment_satisfied_alt_outlined,
        'color': AppColors.honeyAmber,
        'screen': const MoodTrackerScreen()
      },
      {
        'title': 'Plant Gratitude',
        'subtitle': 'Bloom garden flower',
        'asset': FeatureIconHelper.gratitudeGarden,
        'icon': Icons.local_florist_outlined,
        'color': AppColors.honeyAmber,
        'screen': const GardenScreen()
      },
      {
        'title': 'Sleep Log',
        'subtitle': 'Log rest & sleep hours',
        'asset': FeatureIconHelper.sleepLog,
        'icon': Icons.wb_twilight,
        'color': AppColors.honeyAmber,
        'screen': const SleepLogFlowScreen()
      },
      {
        'title': "Today's Highlight",
        'subtitle': 'Capture 60-char moment',
        'asset': FeatureIconHelper.todaysHighlight,
        'icon': Icons.auto_stories_outlined,
        'color': AppColors.honeyAmber,
        'screen': const TodaysHighlightScreen()
      },
      {
        'title': 'Daily Reflection',
        'subtitle': 'Evening reflection review',
        'asset': FeatureIconHelper.dailyReflection,
        'icon': Icons.spa_outlined,
        'color': AppColors.honeyAmber,
        'screen': const DailyReflectionScreen()
      },
      {
        'title': '5–4–3–2–1 Grounding',
        'subtitle': 'Sensory reset',
        'asset': FeatureIconHelper.grounding,
        'icon': Icons.spa_outlined,
        'color': AppColors.honeyAmber,
        'screen': const GroundingSessionScreen()
      },
      {
        'title': 'Breathing Exercise',
        'subtitle': 'Guided rhythms',
        'asset': FeatureIconHelper.breathing,
        'icon': Icons.air_rounded,
        'color': AppColors.honeyAmber,
        'screen': const MindfulnessMeditationScreen()
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Routines',
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: MobileLayout.pageInsets(context, top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(phaseIcon, size: 16, color: phaseColor),
                        const SizedBox(width: 6),
                        Text(
                          phaseText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: phaseColor,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        'Your daily rhythm',
                        style:
                            AppTypography.heroHeader(context, isDark: isDark),
                      ),
                    ],
                  );
                  final controls = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Today's honest completion summary.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark
                                  ? AppColors.darkCardBorder
                                  : Colors.black.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 16, color: AppColors.sageGreen),
                            const SizedBox(width: 4),
                            Text(
                              '${routinesProvider.completedTodayCount} done',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Gear Icon -> Management Screen
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RoutineManagementScreen()),
                          );
                        },
                        icon: Icon(Icons.settings_outlined,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        tooltip: 'Manage Routines',
                      ),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        heading,
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: controls,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [Expanded(child: heading), controls],
                  );
                },
              ),
              const SizedBox(height: 20),

              if (routinesProvider.errorMessage != null) ...[
                SyncStatusBanner(
                  message: routinesProvider.errorMessage!,
                  onRetry: routinesProvider.fetchRoutineLogs,
                  margin: EdgeInsets.zero,
                ),
                const SizedBox(height: 14),
              ],

              // Active / Recommended Routine Hero Card
              if (recommended != null) ...[
                Container(
                  key: const ValueKey('recommended-routine-card'),
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width <= 360 ? 18 : 22,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: recommended.primaryColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: recommended.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 7,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: recommended.primaryColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isResuming
                                  ? 'CONTINUE WHERE YOU LEFT OFF'
                                  : 'FOR RIGHT NOW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: recommended.primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            isResuming
                                ? resumeAtCompletion
                                    ? 'Ready to finish'
                                    : 'Step ${resumeStepIndex + 1} of ${recommended.activeStepsCount}'
                                : '~${recommended.totalMinutes} mins',
                            style: AppTypography.bodySmall(context,
                                isDark: isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        recommended.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommended.subtitle,
                        style:
                            AppTypography.bodyMedium(context, isDark: isDark),
                      ),
                      const SizedBox(height: 18),

                      // A short preview keeps the card useful without turning
                      // the menu into another long routine screen.
                      ...recommended.steps
                          .where((s) => s.isEnabled)
                          .skip(resumeStepIndex)
                          .take(3)
                          .map((step) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(step.icon,
                                  size: 16, color: recommended.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              Text(
                                '${step.estimatedMinutes}m',
                                style: AppTypography.bodySmall(context,
                                    isDark: isDark),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (recommended.activeStepsCount - resumeStepIndex > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+${recommended.activeStepsCount - resumeStepIndex - 3} more activities',
                            style: AppTypography.bodySmall(
                              context,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Start Routine CTA Button & Manage Button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              key: ValueKey(isResuming
                                  ? 'resume-recommended-routine'
                                  : 'start-recommended-routine'),
                              onPressed: () => _launchRoutine(
                                context,
                                recommended,
                                resume: isResuming,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 22),
                              label: Text(
                                isResuming
                                    ? 'Continue Routine'
                                    : routinesProvider
                                            .isRoutineCompletedTodayById(
                                                recommended.id)
                                        ? 'Repeat Routine'
                                        : 'Start ${recommended.title.split(' ').first} Routine',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: recommended.primaryColor,
                                foregroundColor: AppColors.readableOn(
                                    recommended.primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              int tabIdx = 0;
                              if (recommended.type == RoutineType.midday) {
                                tabIdx = 1;
                              }
                              if (recommended.type == RoutineType.night) {
                                tabIdx = 2;
                              }
                              if (recommended.type == RoutineType.custom) {
                                tabIdx = 3;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RoutineManagementScreen(
                                        initialIndex: tabIdx)),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              side: BorderSide(color: recommended.primaryColor),
                            ),
                            child: Icon(Icons.tune,
                                color: recommended.primaryColor, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.05),
                const SizedBox(height: 28),
              ],

              // Section Header: quick standalone practices.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quick practices',
                      style: AppTypography.titleMedium(
                        context,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('see-all-routine-activities'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _AllRoutineActivitiesScreen(
                          activities: standaloneFeatures,
                        ),
                      ),
                    ),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Choose one activity without starting a full routine.',
                  style: AppTypography.bodySmall(context, isDark: isDark)),
              const SizedBox(height: 12),

              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: standaloneFeatures.length,
                  itemBuilder: (context, index) {
                    final item = standaloneFeatures[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => item['screen'] as Widget),
                        );
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 14),
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: item['asset'] == null
                                  ? Container(
                                      key: ValueKey(
                                        'routine-art-placeholder-${item['title']}',
                                      ),
                                      width: 114,
                                      height: 114,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            (item['color'] as Color)
                                                .withValues(alpha: 0.24),
                                            AppColors.honeyLight,
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData,
                                        color: item['color'] as Color,
                                        size: 44,
                                      ),
                                    )
                                  : Image.asset(
                                      item['asset'] as String,
                                      width: 114,
                                      height: 114,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 114,
                                        height: 114,
                                        decoration: BoxDecoration(
                                          color: (item['color'] as Color)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Icon(item['icon'] as IconData,
                                            color: item['color'] as Color,
                                            size: 48),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Section Header: All Full Routines
              LayoutBuilder(
                builder: (context, constraints) {
                  final addCustom = InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CustomRoutineDialog(),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add,
                              size: 16, color: AppColors.sageGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Add Custom',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sageGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  final title = Text(
                    'Full Routines',
                    style: AppTypography.titleMedium(context, isDark: isDark),
                  );
                  if (constraints.maxWidth < 430) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        Align(
                            alignment: Alignment.centerRight, child: addCustom),
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [title, addCustom],
                  );
                },
              ),
              const SizedBox(height: 14),

              // List of all routines cards
              ...allRoutines.map((routine) {
                final isCompleted =
                    routinesProvider.isRoutineCompletedTodayById(routine.id);
                final isActive = activeSession?.routineId == routine.id;
                final canStart =
                    routine.isEnabled && routine.activeStepsCount > 0;

                return Opacity(
                  opacity: canStart ? 1 : 0.58,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('routine-card-${routine.id}'),
                      onTap: () => _launchRoutine(
                        context,
                        routine,
                        resume: isActive,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(
                          MediaQuery.sizeOf(context).width <= 360 ? 14 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                routine.type == RoutineType.morning
                                    ? FeatureIconHelper.morningRoutine
                                    : (routine.type == RoutineType.midday
                                        ? FeatureIconHelper.midDayRoutine
                                        : (routine.type == RoutineType.night
                                            ? FeatureIconHelper.nightRoutine
                                            : FeatureIconHelper.routines)),
                                width: MediaQuery.sizeOf(context).width <= 360
                                    ? 64
                                    : 92,
                                height: MediaQuery.sizeOf(context).width <= 360
                                    ? 64
                                    : 92,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  routine.type == RoutineType.morning
                                      ? Icons.wb_sunny_outlined
                                      : (routine.type == RoutineType.midday
                                          ? Icons.spa_outlined
                                          : Icons.nights_stay_outlined),
                                  color: routine.primaryColor,
                                  size: 52,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width <= 360
                                  ? 10
                                  : 16,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          routine.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ),
                                      if (isCompleted) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.check_circle,
                                            size: 16,
                                            color: AppColors.sageGreen),
                                      ] else if (isActive) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                            Icons.play_circle_fill_rounded,
                                            size: 17,
                                            color: AppColors.honeyAmber),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    !routine.isEnabled
                                        ? 'Paused in routine settings'
                                        : routine.activeStepsCount == 0
                                            ? 'No activities enabled'
                                            : isActive
                                                ? 'Continue your saved progress'
                                                : '${routine.activeStepsCount} activities • ~${routine.totalMinutes} min',
                                    style: AppTypography.bodySmall(context,
                                        isDark: isDark),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.tune_outlined,
                                  size: 20, color: Colors.grey),
                              tooltip: 'Manage ${routine.title}',
                              onPressed: () {
                                int tabIdx = 0;
                                if (routine.type == RoutineType.midday) {
                                  tabIdx = 1;
                                }
                                if (routine.type == RoutineType.night) {
                                  tabIdx = 2;
                                }
                                if (routine.type == RoutineType.custom) {
                                  tabIdx = 3;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => RoutineManagementScreen(
                                          initialIndex: tabIdx)),
                                );
                              },
                            ),
                            Icon(
                              isActive
                                  ? Icons.play_arrow_rounded
                                  : Icons.chevron_right_rounded,
                              color:
                                  canStart ? routine.primaryColor : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllRoutineActivitiesScreen extends StatelessWidget {
  const _AllRoutineActivitiesScreen({required this.activities});

  final List<Map<String, dynamic>> activities;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: const Text('All activities'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: CustomScrollView(
          key: const ValueKey('all-routine-activities-screen'),
          slivers: [
            SliverPadding(
              padding: MobileLayout.pageInsets(context, top: 10, bottom: 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose what you need',
                      style: AppTypography.heroHeader(context, isDark: isDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Each activity opens on its own. You can stop whenever you need to.',
                      style: AppTypography.bodyMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: MobileLayout.pageInsets(context, top: 0, bottom: 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisExtent: 210,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = activities[index];
                    final color = item['color'] as Color;
                    final title = item['title'] as String;
                    return Material(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('routine-activity-$title'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => item['screen'] as Widget,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Image.asset(
                                    item['asset'] as String,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 92,
                                      height: 92,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData,
                                        color: color,
                                        size: 42,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['subtitle'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall(
                                  context,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: activities.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
