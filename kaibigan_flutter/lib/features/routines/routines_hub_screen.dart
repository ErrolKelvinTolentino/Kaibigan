import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/mobile_layout.dart';
import '../../core/widgets/sync_status_banner.dart';
import '../gratitude_garden/garden_screen.dart';
import '../mood_tracking/mood_tracker_screen.dart';
import 'flows/progressive_routine_runner.dart';
import 'routine_management_screen.dart';
import 'routine_model.dart';
import 'routines_provider.dart';
import 'screens/daily_reflection_screen.dart';
import 'screens/grounding_session_screen.dart';
import 'screens/mindfulness_meditation_screen.dart';
import 'screens/sleep_analytics_screen.dart';
import 'screens/todays_focus_screen.dart';
import 'screens/todays_highlight_screen.dart';
import 'widgets/custom_routine_dialog.dart';
import 'widgets/routine_activity_frame.dart';

class RoutinesHubScreen extends StatefulWidget {
  const RoutinesHubScreen({super.key, this.autoplay = true});

  final bool autoplay;

  @override
  State<RoutinesHubScreen> createState() => _RoutinesHubScreenState();
}

class _RoutinesHubScreenState extends State<RoutinesHubScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoplay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoplay());
    }
  }

  Future<void> _autoplay() async {
    final provider = context.read<RoutinesProvider>();
    try {
      await provider.startupReady.timeout(const Duration(seconds: 8));
    } catch (_) {
      return;
    }
    if (!mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        provider.configurationError != null ||
        provider.errorMessage != null) {
      return;
    }
    // Opening Routines is an explicit request, so it may start before the
    // preferred time. Already completed routines remain available to repeat
    // manually, but do not auto-open again.
    final launch =
        provider.eligibleRoutineAt(DateTime.now(), scheduledOnly: false);
    if (launch != null) _launch(context, launch.config, resume: launch.resume);
  }

  void _manage(BuildContext context, [RoutineConfig? routine]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineManagementScreen(
          initialIndex: routine?.type.index ?? 0,
        ),
      ),
    );
  }

  void _launch(BuildContext context, RoutineConfig routine,
      {bool resume = false}) {
    if (!routine.isEnabled || routine.activeStepsCount == 0) {
      _manage(context, routine);
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
    final provider = context.watch<RoutinesProvider>();
    final session = provider.activeSession;
    final saved =
        session == null ? null : provider.getRoutineById(session.routineId);
    final resumable =
        saved != null && saved.isEnabled && saved.activeStepsCount > 0
            ? saved
            : null;
    final recommended = resumable ?? provider.recommendedRoutine;
    final isResuming = resumable != null;
    final practices = _practices(context);
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title: Text(routineText(context, 'Routines', 'Mga gawain', 'Routines')),
        actions: [
          IconButton(
            onPressed: () => _manage(context),
            tooltip: routineText(
                context, 'Manage routines', 'Ayusin ang mga gawain'),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: MobileContent(
            padding: MobileLayout.pageInsets(context, top: 8, bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routineText(
                      context, 'Your daily rhythm', 'Sa sarili mong ritmo'),
                  style: AppTypography.heroHeader(context, isDark: isDark),
                ),
                const SizedBox(height: 6),
                Text(
                  routineText(
                      context,
                      'Small moments of care, at your own pace.',
                      'Maliliit na sandali para alagaan ang sarili.',
                      'Small moments of care, sa sarili mong pace.'),
                  style: AppTypography.bodyMedium(context, isDark: isDark),
                ),
                if (provider.completedTodayCount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 17, color: AppColors.sageGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(routineText(
                            context,
                            '${provider.completedTodayCount} completed today',
                            '${provider.completedTodayCount} ang natapos ngayong araw')),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                if (provider.errorMessage != null) ...[
                  SyncStatusBanner(
                    message: provider.errorMessage!,
                    onRetry: provider.fetchRoutineLogs,
                    margin: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 14),
                ],
                if (recommended != null) ...[
                  _recommendedCard(context, recommended, provider, isResuming),
                  const SizedBox(height: 26),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          routineText(context, 'Quick practices',
                              'Maiikling gawain', 'Quick practices'),
                          style: AppTypography.titleMedium(context,
                              isDark: isDark)),
                    ),
                    TextButton(
                      key: const ValueKey('see-all-routine-activities'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              _AllRoutineActivitiesScreen(practices: practices),
                        ),
                      ),
                      child: Text(routineText(context, 'See all', 'Lahat')),
                    ),
                  ],
                ),
                Text(
                    routineText(
                        context,
                        'Just one activity can be enough.',
                        'Kahit isang gawain lang, sapat na.',
                        'Kahit one activity lang, okay na.'),
                    style: AppTypography.bodySmall(context, isDark: isDark)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, constraints) {
                  final columns =
                      MediaQuery.textScalerOf(context).scale(14) > 20 ? 1 : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final practice in practices.take(4))
                        SizedBox(
                            width: width,
                            child: _PracticeCard(practice: practice)),
                    ],
                  );
                }),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          routineText(
                              context, 'Your routines', 'Mga gawain mo'),
                          style: AppTypography.titleMedium(context,
                              isDark: isDark)),
                    ),
                    IconButton(
                      tooltip: routineText(
                          context, 'Create a routine', 'Bumuo ng gawain'),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CustomRoutineDialog(),
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final routine in provider.allRoutines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.honeyBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('routine-card-${routine.id}'),
                        onTap: () => _launch(context, routine,
                            resume: session?.routineId == routine.id),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 16, 4, 16),
                          child: Row(
                            children: [
                              _RoutineIcon(
                                  type: routine.type,
                                  color: routine.primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(routine.title,
                                        style: TextStyle(
                                            color: foreground,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(
                                      !routine.isEnabled
                                          ? routineText(
                                              context,
                                              'Paused · tap to manage',
                                              'Naka-pause · pindutin para ayusin')
                                          : routine.activeStepsCount == 0
                                              ? routineText(
                                                  context,
                                                  'Add your first activity',
                                                  'Magdagdag ng unang gawain')
                                              : session?.routineId == routine.id
                                                  ? routineText(
                                                      context,
                                                      'Ready when you are · continue',
                                                      'Ipagpatuloy kapag handa ka na')
                                                  : provider
                                                          .isRoutineCompletedTodayById(
                                                              routine.id)
                                                      ? routineText(
                                                          context,
                                                          'Done today · repeat anytime',
                                                          'Natapos ngayon · puwedeng ulitin')
                                                      : routineText(
                                                          context,
                                                          '${routine.activeStepsCount} activities · ~${routine.totalMinutes} min',
                                                          '${routine.activeStepsCount} gawain · ~${routine.totalMinutes} min'),
                                      style: AppTypography.bodySmall(context,
                                          isDark: isDark),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: routineText(
                                    context,
                                    'Edit ${routine.title}',
                                    'Ayusin ang ${routine.title}'),
                                onPressed: () => _manage(context, routine),
                                icon: const Icon(Icons.more_horiz_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recommendedCard(BuildContext context, RoutineConfig routine,
      RoutinesProvider provider, bool isResuming) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = routine.steps.where((step) => step.isEnabled).toList();
    final index = isResuming
        ? provider.activeSession!.nextStepIndex.clamp(0, steps.length)
        : 0;
    final remainingMinutes =
        steps.skip(index).fold(0, (sum, step) => sum + step.estimatedMinutes);
    return Container(
      key: const ValueKey('recommended-routine-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: routine.primaryColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isResuming
                ? routineText(
                    context,
                    'CONTINUE WHERE YOU LEFT OFF',
                    'IPAGPATULOY ANG NASIMULAN',
                    'CONTINUE KUNG SAAN KA HUMINTO')
                : routineText(
                    context, 'A MOMENT FOR YOU', 'SANDALING PARA SA IYO'),
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.1,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(routine.title,
              style: AppTypography.titleLarge(context, isDark: isDark)),
          const SizedBox(height: 6),
          Text(
            isResuming
                ? index == steps.length
                    ? routineText(
                        context,
                        'Your activities are done. Save when ready.',
                        'Tapos na ang mga gawain. I-save kapag handa ka na.')
                    : routineText(
                        context,
                        'Step ${index + 1} of ${steps.length}',
                        'Gawain ${index + 1} sa ${steps.length}')
                : routine.subtitle,
            style: AppTypography.bodyMedium(context, isDark: isDark),
          ),
          const SizedBox(height: 16),
          for (final step in steps.skip(index).take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(step.icon,
                      size: 18,
                      color:
                          isDark ? AppColors.honeyAmber : AppColors.sageGreen),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(step.title,
                          style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          if (steps.length - index > 3)
            Text(
                routineText(context, '+${steps.length - index - 3} more',
                    '+${steps.length - index - 3} pa'),
                style: AppTypography.bodySmall(context, isDark: isDark)),
          if (remainingMinutes > 0) ...[
            const SizedBox(height: 6),
            Text(
                routineText(
                    context,
                    'About $remainingMinutes minutes · pause anytime',
                    'Mga $remainingMinutes minuto · puwedeng huminto muna'),
                style: AppTypography.bodySmall(context, isDark: isDark)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: ValueKey(isResuming
                  ? 'resume-recommended-routine'
                  : 'start-recommended-routine'),
              onPressed: () => _launch(context, routine, resume: isResuming),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.honeyAmber,
                foregroundColor: AppColors.readableOn(AppColors.honeyAmber),
                minimumSize: const Size(0, 52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              icon: Icon(index == steps.length
                  ? Icons.check_rounded
                  : Icons.play_arrow_rounded),
              label: Text(isResuming
                  ? routineText(
                      context, 'Continue routine', 'Ipagpatuloy ang gawain')
                  : provider.isRoutineCompletedTodayById(routine.id)
                      ? routineText(
                          context, 'Enjoy it again', 'Ulitin kung gusto mo')
                      : routineText(
                          context, 'Start routine', 'Simulan ang mga gawain')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineIcon extends StatelessWidget {
  const _RoutineIcon({required this.type, required this.color});
  final RoutineType type;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15)),
        child: Icon(
            switch (type) {
              RoutineType.morning => Icons.wb_sunny_outlined,
              RoutineType.midday => Icons.spa_outlined,
              RoutineType.night => Icons.nights_stay_outlined,
              RoutineType.custom => Icons.favorite_border_rounded,
            },
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.honeyAmber
                : AppColors.textPrimaryLight,
            size: 22),
      );
}

class _Practice {
  const _Practice(this.title, this.subtitle, this.icon, this.screen);
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
}

List<_Practice> _practices(BuildContext context) => [
      _Practice(
          routineText(context, 'Mood check-in', 'Kumusta ka?', 'Mood check-in'),
          routineText(
              context, 'Notice how you feel', 'Pansinin ang nararamdaman mo'),
          Icons.sentiment_satisfied_alt_outlined,
          const MoodTrackerScreen()),
      _Practice(
          routineText(context, 'Breathing', 'Paghinga'),
          routineText(context, 'A gentle reset', 'Sandaling pahinga'),
          Icons.air_rounded,
          const MindfulnessMeditationScreen()),
      _Practice(
          routineText(context, 'Sleep log', 'Tala ng tulog', 'Sleep log'),
          routineText(
              context, 'Understand your rest', 'Kilalanin ang pahinga mo'),
          Icons.bedtime_outlined,
          const SleepAnalyticsScreen()),
      _Practice(
          routineText(context, '5–4–3–2–1 grounding', '5–4–3–2–1 na pagtuon',
              '5–4–3–2–1 grounding'),
          routineText(
              context, 'Return to the present', 'Bumalik sa kasalukuyan'),
          Icons.spa_outlined,
          const GroundingSessionScreen()),
      _Practice(
          routineText(context, "Today's focus", 'Pagtutuunan ngayon'),
          routineText(
              context, 'Choose one intention', 'Pumili ng isang layunin'),
          Icons.lightbulb_outline_rounded,
          const TodaysFocusScreen()),
      _Practice(
          routineText(context, 'Gratitude garden', 'Hardin ng pasasalamat'),
          routineText(context, 'Notice something good',
              'Pansinin ang munting kabutihan'),
          Icons.local_florist_outlined,
          const GardenScreen()),
      _Practice(
          routineText(
              context, "Today's highlight", 'Mahalagang sandali ngayon'),
          routineText(context, 'Remember a small moment',
              'Alalahanin ang munting sandali'),
          Icons.wb_twilight_rounded,
          TodaysHighlightScreen(
              existingHighlight:
                  context.read<RoutinesProvider>().todayHighlight)),
      _Practice(
          routineText(context, 'Daily reflection', 'Pagninilay ngayong araw'),
          routineText(
              context, 'Make room to reflect', 'Bigyan ng oras ang pagninilay'),
          Icons.auto_stories_outlined,
          const DailyReflectionScreen()),
    ];

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.practice});
  final _Practice practice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => practice.screen)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(practice.icon,
                  size: 24,
                  color: isDark ? AppColors.honeyAmber : AppColors.sageGreen),
              const SizedBox(height: 14),
              Text(practice.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(practice.subtitle,
                  style: AppTypography.bodySmall(context, isDark: isDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllRoutineActivitiesScreen extends StatelessWidget {
  const _AllRoutineActivitiesScreen({required this.practices});
  final List<_Practice> practices;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: const ValueKey('all-routine-activities-screen'),
      appBar: AppBar(
          title:
              Text(routineText(context, 'All activities', 'Lahat ng gawain'))),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: MobileContent(
            padding: MobileLayout.pageInsets(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    routineText(context, 'Choose what you need',
                        'Piliin ang kailangan mo'),
                    style: AppTypography.heroHeader(context, isDark: isDark)),
                const SizedBox(height: 8),
                Text(routineText(
                    context,
                    'There is no right order. Start with what feels helpful.',
                    'Walang kailangang sunding pagkakasunod. Piliin ang makatutulong sa iyo.')),
                const SizedBox(height: 20),
                for (final practice in practices) ...[
                  SizedBox(
                      width: double.infinity,
                      child: _PracticeCard(practice: practice)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
