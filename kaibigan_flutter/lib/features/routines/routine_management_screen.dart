import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import 'routine_model.dart';
import 'routines_provider.dart';
import 'widgets/custom_routine_dialog.dart';
import 'widgets/add_action_sheet.dart';

// Standalone feature screens
import 'screens/sleep_tracker_screen.dart';
import 'screens/morning_focus_screen.dart';
import 'screens/grounding_session_screen.dart';
import 'screens/mindfulness_meditation_screen.dart';
import 'screens/night_highlight_screen.dart';
import 'screens/night_mood_screen.dart';
import 'screens/gratitude_planting_screen.dart';

class RoutineManagementScreen extends StatefulWidget {
  final int initialIndex;
  const RoutineManagementScreen({super.key, this.initialIndex = 0});

  @override
  State<RoutineManagementScreen> createState() =>
      _RoutineManagementScreenState();
}

class _RoutineManagementScreenState extends State<RoutineManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openStepScreen(BuildContext context, StepType type) {
    Widget screen;
    switch (type) {
      case StepType.sleepTracker:
        screen = const SleepTrackerScreen();
        break;
      case StepType.journalFocus:
        screen = const MorningFocusScreen();
        break;
      case StepType.grounding:
        screen = const GroundingSessionScreen();
        break;
      case StepType.meditation:
        screen = const MindfulnessMeditationScreen();
        break;
      case StepType.journalHighlight:
        screen = const NightHighlightScreen();
        break;
      case StepType.moodTracker:
        screen = const NightMoodScreen();
        break;
      case StepType.gratitudeGarden:
        screen = const GratitudePlantingScreen();
        break;
      case StepType.custom:
        screen = const MorningFocusScreen();
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _removeStep(
    RoutinesProvider provider,
    RoutineConfig routine,
    RoutineStep step,
  ) async {
    final confirmed = await CozyConfirmSheet.show(
      context,
      title: 'Remove ${step.title}?',
      message:
          'This activity will be removed from ${routine.title}. Other activities will stay as they are.',
      confirmLabel: 'Remove activity',
      cancelLabel: 'Keep it',
    );
    if (confirmed && mounted) {
      provider.removeStepFromRoutine(routine.id, step.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routinesProvider = Provider.of<RoutinesProvider>(context);

    final morningRoutine = routinesProvider.getRoutineById('morning');
    final middayRoutine = routinesProvider.getRoutineById('midday');
    final nightRoutine = routinesProvider.getRoutineById('night');
    final customRoutines = routinesProvider.allRoutines
        .where((r) => r.type == RoutineType.custom)
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage routines',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.sageGreen,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorColor: AppColors.sageGreen,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Morning'),
            Tab(text: 'Mid-Day'),
            Tab(text: 'Night'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (morningRoutine != null)
            _buildRoutineEditor(morningRoutine, routinesProvider, isDark),
          if (middayRoutine != null)
            _buildRoutineEditor(middayRoutine, routinesProvider, isDark),
          if (nightRoutine != null)
            _buildRoutineEditor(nightRoutine, routinesProvider, isDark),
          _buildCustomRoutinesTab(customRoutines, routinesProvider, isDark),
        ],
      ),
    );
  }

  Widget _buildRoutineEditor(
      RoutineConfig routine, RoutinesProvider provider, bool isDark) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Reminder Time & Enable Toggle
          Container(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: routine.primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        routine.type == RoutineType.morning
                            ? Icons.wb_sunny_outlined
                            : (routine.type == RoutineType.midday
                                ? Icons.spa_outlined
                                : Icons.nights_stay_outlined),
                        color: routine.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${routine.activeStepsCount} steps • ~${routine.totalMinutes} mins',
                            style: AppTypography.bodyMedium(context,
                                isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: routine.isEnabled,
                      activeThumbColor: routine.primaryColor,
                      onChanged: (val) =>
                          provider.toggleRoutineEnabled(routine.id),
                    ),
                  ],
                ),
                const Divider(height: 24),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: routine.reminderTime,
                    );
                    if (time != null) {
                      provider.updateReminderTime(routine.id, time);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.alarm_outlined,
                              size: 20,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Preferred routine time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: routine.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            routine.reminderTime.format(context),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: routine.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activities',
                style: AppTypography.titleMedium(context, isDark: isDark),
              ),
              Text(
                'Tap to preview. Long-press and drag to reorder.',
                style: AppTypography.bodySmall(context, isDark: isDark),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddActionSheet(routineId: routine.id),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add activity'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: routine.primaryColor,
                    foregroundColor: AppColors.readableOn(routine.primaryColor),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reorderable Steps List
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: routine.steps.length,
            onReorderItem: (oldIndex, newIndex) {
              provider.reorderSteps(routine.id, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final step = routine.steps[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(step.id),
                index: index,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => _openStepScreen(context, step.type),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: step.isEnabled
                              ? routine.primaryColor.withValues(alpha: 0.15)
                              : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.04)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(step.icon,
                            color: step.isEnabled
                                ? routine.primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                            size: 20),
                      ),
                      title: Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          decoration: step.isEnabled
                              ? null
                              : TextDecoration.lineThrough,
                          color: step.isEnabled
                              ? (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight)
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                      subtitle: Text(
                        step.subtitle,
                        style: AppTypography.bodySmall(context, isDark: isDark),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints.tightFor(
                                width: 36, height: 44),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              step.isEnabled
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: step.isEnabled
                                  ? routine.primaryColor
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                            tooltip: step.isEnabled
                                ? 'Pause ${step.title}'
                                : 'Enable ${step.title}',
                            onPressed: () =>
                                provider.toggleStep(routine.id, step.id),
                          ),
                          IconButton(
                            constraints: const BoxConstraints.tightFor(
                                width: 36, height: 44),
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent.shade200),
                            tooltip: 'Remove step',
                            onPressed: () =>
                                _removeStep(provider, routine, step),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRoutinesTab(List<RoutineConfig> customRoutines,
      RoutinesProvider provider, bool isDark) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text('Your Custom Routines',
                  style: AppTypography.titleMedium(context, isDark: isDark)),
              ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const CustomRoutineDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Custom'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (customRoutines.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.dashboard_customize_outlined,
                        size: 48,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                    const SizedBox(height: 12),
                    Text('No Custom Routines Yet',
                        style:
                            AppTypography.titleSmall(context, isDark: isDark)),
                    const SizedBox(height: 4),
                    Text(
                        'Create tailored routines matching your personal wellness flow.',
                        textAlign: TextAlign.center,
                        style:
                            AppTypography.bodyMedium(context, isDark: isDark)),
                  ],
                ),
              ),
            )
          else
            ...customRoutines.map((routine) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_outline,
                          color: AppColors.sageGreen, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(routine.title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight)),
                          Text('${routine.activeStepsCount} steps',
                              style: AppTypography.bodySmall(context,
                                  isDark: isDark)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => provider.deleteCustomRoutine(routine.id),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
