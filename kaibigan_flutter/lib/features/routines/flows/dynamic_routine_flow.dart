import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/language_helper.dart';
import '../../mood_tracking/mood_model.dart';
import '../../mood_tracking/mood_tracker_screen.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';
import '../screens/gratitude_planting_screen.dart';
import '../screens/grounding_session_screen.dart';
import '../screens/mindfulness_meditation_screen.dart';
import '../screens/sleep_log_flow_screen.dart';
import '../screens/todays_focus_screen.dart';
import '../screens/todays_highlight_screen.dart';

/// Sequences the canonical feature screens in the order saved by the user.
///
/// This class intentionally contains no substitute gratitude, mood, focus,
/// grounding, breathing, highlight, or sleep forms. Each step uses the same
/// screen and persistence path as a direct launch from the rest of the app.
class DynamicRoutineFlow extends StatefulWidget {
  const DynamicRoutineFlow({
    super.key,
    required this.config,
    this.resumeSession = false,
  });

  final RoutineConfig config;
  final bool resumeSession;

  @override
  State<DynamicRoutineFlow> createState() => _DynamicRoutineFlowState();
}

class _DynamicRoutineFlowState extends State<DynamicRoutineFlow> {
  int _currentStepIndex = 0;
  bool _isLaunching = false;
  bool _isPaused = false;
  bool _isFinishing = false;
  final Set<String> _skippedStepIds = {};

  List<RoutineStep> get _activeSteps => widget.config.steps
      .where((step) => step.isEnabled)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final provider = context.read<RoutinesProvider>();
    final session =
        widget.resumeSession ? provider.sessionFor(widget.config.id) : null;
    if (session != null) {
      _currentStepIndex = session.nextStepIndex.clamp(0, _activeSteps.length);
      _skippedStepIds.addAll(session.skippedStepIds);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (session == null) provider.startRoutineSession(widget.config.id);
      if (_activeSteps.isNotEmpty) _launchCurrentActivity();
    });
  }

  Future<void> _launchCurrentActivity() async {
    final steps = _activeSteps;
    if (!mounted || _isLaunching || _currentStepIndex >= steps.length) return;
    setState(() {
      _isLaunching = true;
      _isPaused = false;
    });

    final step = steps[_currentStepIndex];
    final outcome = await Navigator.of(context).push<Object?>(
      PageRouteBuilder<Object?>(
        settings: RouteSettings(name: 'routine-activity-${step.type.name}'),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (activityContext, animation, secondaryAnimation) {
          void skipActivity() => Navigator.of(activityContext).pop(
                _RoutineActivityOutcome.skipped,
              );
          return _RoutineActivityFrame(
            routineTitle: widget.config.title,
            stepTitle: step.title,
            currentIndex: _currentStepIndex,
            totalSteps: steps.length,
            accent: widget.config.primaryColor,
            onSkip: skipActivity,
            child: _activityFor(
              step,
              onSkipped: skipActivity,
              onCompleted: () => Navigator.of(activityContext).pop(
                _RoutineActivityOutcome.completed,
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    if (!mounted) return;
    final shouldAdvance = outcome == _RoutineActivityOutcome.completed ||
        outcome == _RoutineActivityOutcome.skipped ||
        outcome == true;
    if (shouldAdvance) {
      if (outcome == _RoutineActivityOutcome.skipped) {
        _skippedStepIds.add(step.id);
      }
      setState(() {
        _currentStepIndex++;
        _isLaunching = false;
        _isPaused = false;
      });
      context.read<RoutinesProvider>().updateRoutineSession(
            widget.config.id,
            _currentStepIndex,
            _skippedStepIds,
          );
      if (_currentStepIndex < steps.length) {
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (mounted) _launchCurrentActivity();
      }
    } else {
      setState(() {
        _isLaunching = false;
        _isPaused = true;
      });
    }
  }

  Widget _activityFor(
    RoutineStep step, {
    required VoidCallback onCompleted,
    required VoidCallback onSkipped,
  }) {
    return switch (step.type) {
      StepType.gratitudeGarden => GratitudePlantingScreen(
          onCompleted: onCompleted,
          onSkipped: onSkipped,
        ),
      StepType.journalFocus => TodaysFocusScreen(onCompleted: onCompleted),
      StepType.journalHighlight =>
        TodaysHighlightScreen(onCompleted: onCompleted),
      StepType.moodTracker => MoodTrackerScreen(onCompleted: onCompleted),
      StepType.grounding => GroundingSessionScreen(
          onCompleted: onCompleted,
          routineMode: true,
        ),
      StepType.meditation => MindfulnessMeditationScreen(
          onCompleted: onCompleted,
          routineMode: true,
        ),
      StepType.sleepTracker => SleepLogFlowScreen(onCompleted: onCompleted),
      StepType.custom => _CustomRoutineActivity(
          step: step,
          accent: widget.config.primaryColor,
          onCompleted: onCompleted,
        ),
    };
  }

  Future<void> _finishRoutine() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    final provider = context.read<RoutinesProvider>();
    final saved = await provider.addLog(
      RoutineLog(
        id: '',
        routineId: widget.config.id,
        routineType: widget.config.type,
        completedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() => _isFinishing = false);
    if (saved) {
      provider.clearRoutineSession(widget.config.id);
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Your routine completion could not be saved. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _activeSteps;
    final onCompletion = _currentStepIndex >= steps.length;
    final progressIndex = onCompletion ? steps.length : _currentStepIndex;
    final currentStep =
        onCompletion || steps.isEmpty ? null : steps[_currentStepIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close routine',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(widget.config.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _RoutineProgress(
                stepCount: steps.length,
                activeIndex: progressIndex,
                accent: widget.config.primaryColor,
                isDark: isDark,
              ),
            ),
            Expanded(
              child: steps.isEmpty
                  ? _buildEmptyState(isDark)
                  : onCompletion
                      ? _buildCompletion(isDark)
                      : _buildWaitingState(currentStep!, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingState(RoutineStep step, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: widget.config.primaryColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.icon,
                  size: 38,
                  color: widget.config.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isPaused ? 'Routine paused' : 'Opening your activity…',
                style: AppTypography.titleLarge(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 9),
              Text(
                _isPaused
                    ? 'Your progress is safe. Resume when you feel ready.'
                    : 'Autoplay uses the full ${step.title} experience.',
                style: AppTypography.bodyMedium(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.honeyBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(step.icon, color: widget.config.primaryColor),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            step.subtitle,
                            style: AppTypography.bodySmall(
                              context,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isPaused) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('resume-routine-activity'),
                    onPressed: _launchCurrentActivity,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Resume ${step.title}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.config.primaryColor,
                    ),
                  ),
                ),
              ],
              if (_isLaunching) ...[
                const SizedBox(height: 24),
                CircularProgressIndicator(color: widget.config.primaryColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletion(bool isDark) {
    final user = context.watch<UserProvider>();
    final language = user.language;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - 40,
            maxWidth: 460,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: widget.config.primaryColor
                      .withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: widget.config.primaryColor
                          .withValues(alpha: isDark ? 0.18 : 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    FeatureIconHelper.routines,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.stars_rounded,
                      size: 80,
                      color: widget.config.primaryColor,
                    ),
                  ),
                ),
              ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                LanguageHelper.pick(
                  language,
                  english: 'Routine completed! ✨',
                  filipino: 'Tapos na ang routine! ✨',
                ),
                style: AppTypography.heroHeader(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                LanguageHelper.pick(
                  language,
                  english: _skippedStepIds.isEmpty
                      ? 'Well done, ${user.displayName}. You made time for every activity.'
                      : 'Well done, ${user.displayName}. You finished at your own pace and skipped ${_skippedStepIds.length} ${_skippedStepIds.length == 1 ? 'activity' : 'activities'}.',
                  filipino: _skippedStepIds.isEmpty
                      ? 'Mahusay, ${user.displayName}. Naglaan ka ng oras para sa bawat activity.'
                      : 'Mahusay, ${user.displayName}. Natapos mo sa sarili mong pace at nilaktawan ang ${_skippedStepIds.length} ${_skippedStepIds.length == 1 ? 'activity' : 'activities'}.',
                ),
                style: AppTypography.bodyMedium(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  key: const ValueKey('finish-routine'),
                  onPressed: _isFinishing ? null : _finishRoutine,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.config.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isFinishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          LanguageHelper.pick(
                            language,
                            english: 'Finish & return home',
                            filipino: 'Tapusin at bumalik sa home',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.playlist_remove_rounded,
              size: 52,
              color: AppColors.sageGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'No active activities',
              style: AppTypography.titleLarge(context, isDark: isDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Add or enable an activity before starting this routine.',
              style: AppTypography.bodyMedium(context, isDark: isDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _RoutineActivityOutcome { completed, skipped }

class _RoutineActivityFrame extends StatelessWidget {
  const _RoutineActivityFrame({
    required this.routineTitle,
    required this.stepTitle,
    required this.currentIndex,
    required this.totalSteps,
    required this.accent,
    required this.onSkip,
    required this.child,
  });

  final String routineTitle;
  final String stepTitle;
  final int currentIndex;
  final int totalSteps;
  final Color accent;
  final VoidCallback onSkip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.warmCream;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              key: const ValueKey('routine-activity-progress-bar'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Step ${currentIndex + 1} of $totalSteps',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$routineTitle • $stepTitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Skip $stepTitle and continue the routine',
                        child: TextButton.icon(
                          key: const ValueKey('skip-routine-activity'),
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.skip_next_rounded, size: 18),
                          label: const Text(
                            'Skip',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _RoutineProgress(
                    keyPrefix: 'routine-activity-progress-',
                    stepCount: totalSteps - 1,
                    activeIndex: currentIndex,
                    accent: accent,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RoutineProgress extends StatelessWidget {
  const _RoutineProgress({
    this.keyPrefix = 'routine-progress-',
    required this.stepCount,
    required this.activeIndex,
    required this.accent,
    required this.isDark,
  });

  final String keyPrefix;
  final int stepCount;
  final int activeIndex;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepCount + 1, (index) {
        final active = index == activeIndex;
        final passed = index < activeIndex;
        return Expanded(
          child: AnimatedContainer(
            key: ValueKey('$keyPrefix$index'),
            duration: const Duration(milliseconds: 240),
            height: active ? 6 : 4,
            margin: EdgeInsets.only(right: index == stepCount ? 0 : 6),
            decoration: BoxDecoration(
              color: active || passed
                  ? accent
                  : (isDark ? Colors.white12 : Colors.black12),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _CustomRoutineActivity extends StatelessWidget {
  const _CustomRoutineActivity({
    required this.step,
    required this.accent,
    required this.onCompleted,
  });

  final RoutineStep step;
  final Color accent;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(step.title),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step.icon, color: accent, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    step.customPrompt?.trim().isNotEmpty == true
                        ? step.customPrompt!
                        : step.subtitle,
                    style: AppTypography.titleMedium(
                      context,
                      isDark: isDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onCompleted,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Complete activity'),
                      style: FilledButton.styleFrom(backgroundColor: accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
