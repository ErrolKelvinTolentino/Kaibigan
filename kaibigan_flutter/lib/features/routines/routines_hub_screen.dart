import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
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

  void _launchRoutine(BuildContext context, RoutineConfig routine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgressiveRoutineRunner(routineType: routine.type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routinesProvider = Provider.of<RoutinesProvider>(context);

    final phase = routinesProvider.currentPhase;
    final recommended = routinesProvider.recommendedRoutine;
    final allRoutines = routinesProvider.allRoutines;

    String phaseText;
    IconData phaseIcon;
    Color phaseColor;

    switch (phase) {
      case RoutineType.morning:
        phaseText = 'Morning Phase';
        phaseIcon = Icons.wb_sunny_outlined;
        phaseColor = AppColors.sageGreen;
        break;
      case RoutineType.midday:
        phaseText = 'Mid-Day Phase';
        phaseIcon = Icons.spa_outlined;
        phaseColor = AppColors.softRose;
        break;
      case RoutineType.night:
      case RoutineType.custom:
        phaseText = 'Night Phase';
        phaseIcon = Icons.nights_stay_outlined;
        phaseColor = AppColors.beePrimary;
        break;
    }

    final List<Map<String, dynamic>> standaloneFeatures = [
      {'title': "Today's Focus", 'subtitle': 'Set daily intention', 'asset': FeatureIconHelper.todaysFocus, 'icon': Icons.lightbulb_outline, 'color': AppColors.sageGreen, 'screen': const TodaysFocusScreen()},
      {'title': 'Mood Check-In', 'subtitle': 'Track energy bees', 'asset': FeatureIconHelper.moodTracker, 'icon': Icons.sentiment_satisfied_alt_outlined, 'color': AppColors.honeyGold, 'screen': const MoodTrackerScreen()},
      {'title': 'Plant Gratitude', 'subtitle': 'Bloom garden flower', 'asset': FeatureIconHelper.gratitudeGarden, 'icon': Icons.local_florist_outlined, 'color': AppColors.sageGreen, 'screen': const GardenScreen()},
      {'title': 'Sleep Log', 'subtitle': 'Log rest & sleep hours', 'asset': FeatureIconHelper.sleepLog, 'icon': Icons.wb_twilight, 'color': AppColors.skyBlue, 'screen': const SleepLogFlowScreen()},
      {'title': "Today's Highlight", 'subtitle': 'Capture 60-char moment', 'asset': FeatureIconHelper.todaysHighlight, 'icon': Icons.auto_stories_outlined, 'color': AppColors.softYellow, 'screen': const TodaysHighlightScreen()},
      {'title': 'Daily Reflection', 'subtitle': 'Evening reflection review', 'asset': FeatureIconHelper.dailyReflection, 'icon': Icons.spa_outlined, 'color': AppColors.softRose, 'screen': const DailyReflectionScreen()},
      {'title': 'Sensory Grounding', 'subtitle': '5-4-3-2-1 reset', 'asset': FeatureIconHelper.dailyReflection, 'icon': Icons.spa_outlined, 'color': AppColors.softRose, 'screen': const GroundingSessionScreen()},
      {'title': 'Box Breathing', 'subtitle': 'Mindfulness timer', 'asset': FeatureIconHelper.midDayRoutine, 'icon': Icons.air, 'color': AppColors.softRose, 'screen': const MindfulnessMeditationScreen()},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daily Routines Hub',
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Daily Routines',
                        style: AppTypography.heroHeader(context, isDark: isDark),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Streak Counter Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, size: 16, color: Colors.orangeAccent),
                            const SizedBox(width: 4),
                            Text(
                              '${routinesProvider.streakDays}d Streak',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                            MaterialPageRoute(builder: (_) => const RoutineManagementScreen()),
                          );
                        },
                        icon: Icon(Icons.settings_outlined, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        tooltip: 'Manage Routines',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active / Recommended Routine Hero Card
              if (recommended != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: recommended.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'RECOMMENDED NOW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: recommended.primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            '~${recommended.totalMinutes} mins',
                            style: AppTypography.bodySmall(context, isDark: isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        recommended.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommended.subtitle,
                        style: AppTypography.bodyMedium(context, isDark: isDark),
                      ),
                      const SizedBox(height: 18),

                      // Steps List Preview
                      ...recommended.steps.where((s) => s.isEnabled).map((step) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(step.icon, size: 16, color: recommended.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              Text(
                                '${step.estimatedMinutes}m',
                                style: AppTypography.bodySmall(context, isDark: isDark),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),

                      // Start Routine CTA Button & Manage Button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _launchRoutine(context, recommended),
                              icon: const Icon(Icons.play_arrow_rounded, size: 22),
                              label: Text(
                                routinesProvider.isRoutineCompletedToday(recommended.type)
                                    ? 'Repeat Routine'
                                    : 'Start ${recommended.title.split(' ').first} Routine',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: recommended.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              int tabIdx = 0;
                              if (recommended.type == RoutineType.midday) tabIdx = 1;
                              if (recommended.type == RoutineType.night) tabIdx = 2;
                              if (recommended.type == RoutineType.custom) tabIdx = 3;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RoutineManagementScreen(initialIndex: tabIdx)),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: BorderSide(color: recommended.primaryColor),
                            ),
                            child: Icon(Icons.tune, color: recommended.primaryColor, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.05),
                const SizedBox(height: 28),
              ],

              // Section Header: Individual Routine Feature Pages
              Text('Individual Feature Practices', style: AppTypography.titleMedium(context, isDark: isDark)),
              const SizedBox(height: 4),
              Text('Practice any specific routine feature standalone:', style: AppTypography.bodySmall(context, isDark: isDark)),
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
                          MaterialPageRoute(builder: (_) => item['screen'] as Widget),
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
                              child: Image.asset(
                                item['asset'] as String,
                                width: 114,
                                height: 114,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 114,
                                  height: 114,
                                  decoration: BoxDecoration(
                                    color: (item['color'] as Color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 48),
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
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Full Routines', style: AppTypography.titleMedium(context, isDark: isDark)),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CustomRoutineDialog(),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16, color: AppColors.sageGreen),
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
                ],
              ),
              const SizedBox(height: 14),

              // List of all routines cards
              ...allRoutines.map((routine) {
                final isCompleted = routinesProvider.isRoutineCompletedToday(routine.type);

                return GestureDetector(
                  onTap: () => _launchRoutine(context, routine),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06),
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
                            width: 92,
                            height: 92,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              routine.type == RoutineType.morning
                                  ? Icons.wb_sunny_outlined
                                  : (routine.type == RoutineType.midday ? Icons.spa_outlined : Icons.nights_stay_outlined),
                              color: routine.primaryColor,
                              size: 52,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    routine.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (isCompleted) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle, size: 16, color: AppColors.sageGreen),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${routine.activeStepsCount} steps • ~${routine.totalMinutes} mins',
                                style: AppTypography.bodySmall(context, isDark: isDark),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune_outlined, size: 20, color: Colors.grey),
                          tooltip: 'Manage ${routine.title}',
                          onPressed: () {
                            int tabIdx = 0;
                            if (routine.type == RoutineType.midday) tabIdx = 1;
                            if (routine.type == RoutineType.night) tabIdx = 2;
                            if (routine.type == RoutineType.custom) tabIdx = 3;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RoutineManagementScreen(initialIndex: tabIdx)),
                            );
                          },
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
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
