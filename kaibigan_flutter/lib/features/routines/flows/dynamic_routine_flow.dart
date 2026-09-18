import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/language_helper.dart';
import '../../mood_tracking/mood_model.dart';
import '../../mood_tracking/mood_tracker_screen.dart';
import '../../../core/services/ui_sound_service.dart';
import '../../../core/widgets/kaibigan_sound_scope.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';
import '../widgets/routine_activity_frame.dart';
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
  bool _completionCuePlayed = false;
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
          return RoutineActivityFrame(
            routine: widget.config,
            steps: steps,
            skippedStepIds: Set.unmodifiable(_skippedStepIds),
            onPause: () => Navigator.of(activityContext).pop(),
            currentIndex: _currentStepIndex,
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
        TodaysHighlightScreen(
          existingHighlight: context.read<RoutinesProvider>().todayHighlight,
          onCompleted: onCompleted,
        ),
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
    if (_activeSteps.every((step) => _skippedStepIds.contains(step.id))) {
      context.read<RoutinesProvider>().clearRoutineSession(widget.config.id);
      Navigator.pop(context);
      return;
    }
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
        title: Text(widget.config.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (steps.isNotEmpty)
            IconButton(
              tooltip: routineText(context, 'View routine', 'Tingnan ang mga gawain'),
              onPressed: () => showRoutinePlan(
                context,
                routine: widget.config,
                steps: steps,
                currentIndex: _currentStepIndex,
                skippedStepIds: _skippedStepIds,
              ),
              icon: const Icon(Icons.format_list_bulleted_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                _isPaused
                    ? routineText(context, 'Routine paused', 'Pahinga muna', 'Naka-pause ang routine')
                    : routineText(context, 'A little time for you', 'Sandaling para sa iyo'),
                style: AppTypography.titleLarge(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 9),
              Text(
                _isPaused
                    ? routineText(context, 'Completed activities are saved. Continue when you feel ready.', 'Naka-save ang mga natapos mong gawain. Magpatuloy kapag handa ka na.', 'Saved na ang mga natapos mong activity. Continue kapag ready ka na.')
                    : routineText(context, 'Take this at your own pace.', 'Gawin ito sa sarili mong bilis.'),
                style: AppTypography.bodyMedium(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              RoutineProgressStrip(
                keyPrefix: 'routine-progress',
                steps: _activeSteps,
                currentIndex: _currentStepIndex,
                skippedStepIds: _skippedStepIds,
                color: widget.config.primaryColor,
                isDark: isDark,
                height: 7,
              ),
              const SizedBox(height: 8),
              Text(
                routineText(
                  context,
                  'Step ${_currentStepIndex + 1} of ${_activeSteps.length}',
                  'Gawain ${_currentStepIndex + 1} sa ${_activeSteps.length}',
                ),
                style: AppTypography.bodySmall(context, isDark: isDark),
              ),
              const SizedBox(height: 18),
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
                    label: Text(routineText(context, 'Continue activity', 'Ipagpatuloy ang gawain')), 
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.config.primaryColor,
                      foregroundColor: AppColors.readableOn(widget.config.primaryColor),
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

  /// Plays once as the closing screen appears, not on every rebuild of it.
  void _playCompletionCue() {
    if (_completionCuePlayed) return;
    _completionCuePlayed = true;
    KaibiganSoundScope.play(context, UiSound.complete);
  }

  Widget _buildCompletion(bool isDark) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playCompletionCue();
    });
    final user = context.watch<UserProvider>();
    final language = user.language;
    final completedCount = _activeSteps.length - _skippedStepIds.length;
    final allSkipped = completedCount == 0;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 60).clamp(0, double.infinity),
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
                  english: allSkipped ? 'A pause is okay, too' : 'Routine completed! ✨',
                  filipino: allSkipped ? 'Ayos lang magpahinga muna' : 'Natapos mo ang mga gawain! ✨',
                  taglish: allSkipped ? 'Okay lang mag-pause' : 'Tapos na ang routine! ✨',
                ),
                style: AppTypography.heroHeader(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                LanguageHelper.pick(
                  language,
                  english: allSkipped
                      ? 'You skipped ${_skippedStepIds.length} activities. You can come back when it feels right.'
                      : _skippedStepIds.isEmpty
                      ? 'Well done, ${user.displayName}. You made time for every activity.'
                      : 'Well done, ${user.displayName}. You finished at your own pace and skipped ${_skippedStepIds.length} ${_skippedStepIds.length == 1 ? 'activity' : 'activities'}.',
                  filipino: allSkipped
                      ? 'Nilaktawan mo ang ${_skippedStepIds.length} gawain. Maaari kang bumalik kapag handa ka na.'
                      : _skippedStepIds.isEmpty
                          ? 'Salamat sa paglalaan ng oras para sa sarili, ${user.displayName}.'
                          : 'Natapos mo ang $completedCount gawain at nilaktawan ang ${_skippedStepIds.length}. Ikaw ang pumipili ng makatutulong sa iyo.',
                  taglish: allSkipped
                      ? 'You skipped ${_skippedStepIds.length} activities. Balik ka kapag ready ka na.'
                      : 'You made time for yourself, ${user.displayName}. Natapos mo ang $completedCount activities.',
                ),
                style: AppTypography.bodyMedium(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: double.infinity,
                // Content may grow with accessibility text settings.
                child: FilledButton(
                  key: const ValueKey('finish-routine'),
                  onPressed: _isFinishing ? null : _finishRoutine,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.config.primaryColor,
                    foregroundColor: AppColors.readableOn(widget.config.primaryColor),
                    minimumSize: const Size(0, 54),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                            english: allSkipped ? 'Return to routines' : 'Save & finish',
                            filipino: allSkipped ? 'Bumalik sa mga gawain' : 'I-save at tapusin',
                            taglish: allSkipped ? 'Balik sa routines' : 'Save at tapusin',
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
              routineText(context, 'No active activities', 'Wala pang napiling gawain'),
              style: AppTypography.titleLarge(context, isDark: isDark),
            ),
            const SizedBox(height: 8),
            Text(
              routineText(context, 'Add or enable an activity before starting this routine.', 'Magdagdag o pumili muna ng gawain bago magsimula.'),
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
        title: Text(step.title, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                      label: Text(routineText(context, 'Complete activity', 'Tapusin ang gawain')), 
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.readableOn(accent),
                      ),
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
