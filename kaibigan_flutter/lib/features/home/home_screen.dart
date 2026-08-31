import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_logo.dart';
import '../../core/widgets/kaibigan_surface.dart';
import '../../core/widgets/mobile_layout.dart';
import '../../core/widgets/sync_status_banner.dart';
import '../affirmations/affirmations_provider.dart';
import '../affirmations/affirmations_screen.dart';
import '../future_letters/future_letters_screen.dart';
import '../future_letters/letters_provider.dart';
import '../gratitude_garden/garden_screen.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../journaling/journal_list_screen.dart';
import '../journaling/journal_provider.dart';
import '../mental_health_learning/learning_catalog.dart';
import '../mental_health_learning/learning_hub_screen.dart';
import '../mood_tracking/mood_model.dart';
import '../mood_tracking/mood_provider.dart';
import '../mood_tracking/mood_tracker_screen.dart';
import '../routines/flows/progressive_routine_runner.dart';
import '../routines/routine_model.dart';
import '../routines/routines_hub_screen.dart';
import '../routines/routines_provider.dart';
import '../routines/screens/daily_reflection_screen.dart';
import '../routines/screens/grounding_session_screen.dart';
import '../routines/screens/mindfulness_meditation_screen.dart';
import '../routines/screens/sleep_log_flow_screen.dart';
import '../routines/screens/todays_focus_screen.dart';
import '../routines/screens/todays_highlight_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/user_provider.dart';
import '../unified_entries/unified_entries_screen.dart';
import '../weekly_reflection/weekly_reflection_screen.dart';
import 'adaptive_support_recommendation.dart';
import 'widgets/adaptive_support_card.dart';
import 'widgets/today_moments_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _refreshHome() async {
    await Future.wait([
      context.read<RoutinesProvider>().fetchRoutineLogs(),
      context.read<MoodProvider>().fetchMoodLogs(),
      context.read<JournalProvider>().fetchJournalEntries(),
      context.read<GratitudeProvider>().fetchGratitudeEntries(),
      context.read<LettersProvider>().fetchLetters(),
    ]);
  }

  Future<void> _openRoutine(
    RoutineConfig routine, {
    required bool resume,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProgressiveRoutineRunner(
          routineType: routine.type,
          config: routine,
          resumeSession: resume,
        ),
      ),
    );
    if (!mounted) return;
    await context.read<RoutinesProvider>().fetchRoutineLogs();
  }

  void _openAdaptiveSupport(AdaptiveSupportKind kind) {
    final screen = switch (kind) {
      AdaptiveSupportKind.checkIn => const MoodTrackerScreen(),
      AdaptiveSupportKind.grounding => const GroundingSessionScreen(),
      AdaptiveSupportKind.breathing => const MindfulnessMeditationScreen(),
      AdaptiveSupportKind.reflection => const DailyReflectionScreen(),
      AdaptiveSupportKind.gratitude => const GardenScreen(),
      AdaptiveSupportKind.focus => const TodaysFocusScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openAffirmations() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AffirmationsScreen()),
    );
  }

  void _openFutureLetters() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FutureLettersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>();
    final language = user.language;
    final affirmations = context.watch<AffirmationsProvider>();
    final letters = context.watch<LettersProvider>();
    final mood = context.watch<MoodProvider>();
    final routines = context.watch<RoutinesProvider>();
    final activeSession = routines.activeSession;
    final activeRoutine = activeSession == null
        ? null
        : routines.getRoutineById(activeSession.routineId);
    final routine = activeRoutine ?? routines.recommendedRoutine;
    final descriptor =
        _RoutineDescriptor.forType(routine?.type ?? routines.currentPhase);
    final routineCompleted =
        routine != null && routines.isRoutineCompletedTodayById(routine.id);
    final isResuming = activeRoutine != null && !routineCompleted;
    final highlight = routines.todayHighlight;
    final adaptiveSupport = AdaptiveSupportEngine.recommend(
      logs: mood.logs,
      now: DateTime.now(),
    );
    final affirmation = affirmations.homeAffirmationForDay(DateTime.now());
    final arrivedLetterCount = letters.letters
        .where((letter) => letter.isReadyToUnlock && !letter.isOpened)
        .length;
    final pagePadding = MobileLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF1C201D), AppColors.darkBackground]
                : const [Color(0xFFFFFCF5), AppColors.warmCream],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.honeyAmber,
            onRefresh: _refreshHome,
            child: CustomScrollView(
              key: const ValueKey('home-scroll-view'),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding,
                    8,
                    pagePadding,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(context, user, isDark),
                  ),
                ),
                if (routines.errorMessage != null)
                  SliverPadding(
                    padding:
                        EdgeInsets.fromLTRB(pagePadding, 4, pagePadding, 8),
                    sliver: SliverToBoxAdapter(
                      child: SyncStatusBanner(
                        message: routines.errorMessage!,
                        onRetry: routines.fetchRoutineLogs,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pagePadding, 8, pagePadding, 6),
                  sliver: SliverToBoxAdapter(
                    child: TodayMomentsCard(
                      language: language,
                      isDark: isDark,
                      category: affirmations.selectedCategory,
                      affirmation: affirmation,
                      arrivedLetterCount: arrivedLetterCount,
                      onLettersTap: _openFutureLetters,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pagePadding, 6, pagePadding, 6),
                  sliver: SliverToBoxAdapter(
                    child: AdaptiveSupportCard(
                      recommendation: adaptiveSupport,
                      language: language,
                      isDark: isDark,
                      onTap: () => _openAdaptiveSupport(adaptiveSupport.kind),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding + 2,
                    18,
                    pagePadding + 2,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _sectionHeading(
                      title: LanguageHelper.pick(
                        language,
                        english: 'Your day',
                        filipino: 'Ang araw mo',
                      ),
                      subtitle: LanguageHelper.pick(
                        language,
                        english: 'Two small anchors for today',
                        filipino: 'Dalawang munting gabay para ngayon',
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pagePadding, 4, pagePadding, 6),
                  sliver: SliverToBoxAdapter(
                    child: _buildRoutineCard(
                      context: context,
                      isDark: isDark,
                      descriptor: descriptor,
                      routine: routine,
                      session: isResuming ? activeSession : null,
                      resuming: isResuming,
                      completed: routineCompleted,
                      loading: routines.isLoading,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pagePadding, 6, pagePadding, 6),
                  sliver: SliverToBoxAdapter(
                    child: _buildHighlightCard(
                      context: context,
                      isDark: isDark,
                      highlight: highlight,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding + 2,
                    20,
                    pagePadding + 2,
                    10,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _sectionHeading(
                      title: LanguageHelper.pick(
                        language,
                        english: 'Wellness Activities',
                        filipino: 'Mga gawain para sa kalusugan',
                      ),
                      subtitle: LanguageHelper.pick(
                        language,
                        english: 'Choose what feels useful right now',
                        filipino: 'Piliin ang makakatulong sa sandaling ito',
                      ),
                      action: TextButton(
                        key: const ValueKey('see-all-activities'),
                        onPressed: () => _openActivitiesMenu(context),
                        child: Text(
                          LanguageHelper.pick(
                            language,
                            english: 'See all',
                            filipino: 'Tingnan lahat',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildActivitiesCarousel(context, isDark),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding + 2,
                    22,
                    pagePadding + 2,
                    10,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _sectionHeading(
                      title: LanguageHelper.pick(
                        language,
                        english: 'Learn about mental health',
                        filipino: 'Matuto tungkol sa mental health',
                      ),
                      subtitle: LanguageHelper.pick(
                        language,
                        english: 'Clear, trusted guidance at your own pace',
                        filipino:
                            'Malinaw at mapagkakatiwalaang gabay sa sarili mong pace',
                      ),
                      action: TextButton(
                        key: const ValueKey('open-learning-hub'),
                        onPressed: () => _openLearningHub(context),
                        child: Text(
                          LanguageHelper.pick(
                            language,
                            english: 'Explore',
                            filipino: 'Tuklasin',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding,
                    0,
                    pagePadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildLearningPreview(context, isDark),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserProvider user,
    bool isDark,
  ) {
    final name =
        user.displayName.trim().isEmpty ? 'Kaibigan' : user.displayName;
    final language = user.language;

    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Row(
                children: [
                  KaibiganLogo(size: 34),
                  SizedBox(width: 7),
                  Flexible(child: KaibiganWordmark(fontSize: 20)),
                ],
              ),
            ),
            _headerButton(
              isDark: isDark,
              icon: Icons.auto_stories_outlined,
              tooltip: LanguageHelper.pick(
                language,
                english: 'All entries',
                filipino: 'Lahat ng tala',
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UnifiedEntriesScreen(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _headerButton(
              key: const ValueKey('home-settings-button'),
              isDark: isDark,
              icon: Icons.settings_outlined,
              tooltip: LanguageHelper.pick(
                language,
                english: 'Open settings and profile',
                filipino: 'Buksan ang settings at profile',
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF292A23), Color(0xFF22251F)]
                  : const [Color(0xFFFFF7E5), Color(0xFFFFFCF6)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.honeyBorder.withValues(alpha: 0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.honeyAmber.withValues(
                  alpha: isDark ? 0.05 : 0.07,
                ),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.honeyAmber.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: const TextStyle(
                    color: AppColors.honeyAmber,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: LanguageHelper.pick(
                    language,
                    english: 'Hi, ',
                    filipino: 'Kumusta, ',
                    taglish: 'Kamusta, ',
                  ),
                  children: [
                    TextSpan(
                      text: name,
                      style: const TextStyle(color: AppColors.honeyAmber),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary,
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                LanguageHelper.pick(
                  language,
                  english: 'What would feel supportive today?',
                  filipino: 'Ano ang makakatulong sa iyo ngayon?',
                  taglish: 'Ano ang makakatulong sa iyo today?',
                ),
                style: TextStyle(
                  color: secondary,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading({
    required String title,
    required String subtitle,
    Widget? action,
  }) =>
      KaibiganSectionHeader(
        title: title,
        description: subtitle,
        action: action,
      );

  Widget _buildRoutineCard({
    required BuildContext context,
    required bool isDark,
    required _RoutineDescriptor descriptor,
    required RoutineConfig? routine,
    required RoutineSessionState? session,
    required bool resuming,
    required bool completed,
    required bool loading,
  }) {
    final language = context.read<UserProvider>().language;
    final isDefaultRoutine = routine?.id == descriptor.type.name;
    final routineTitle = !isDefaultRoutine && routine != null
        ? routine.title
        : language == 'filipino'
            ? switch (descriptor.type) {
                RoutineType.morning => 'Pokus sa Umaga',
                RoutineType.midday => 'Pahinga sa Tanghali',
                _ => 'Pagninilay sa Gabi',
              }
            : descriptor.title;
    final defaultSubtitle = language == 'filipino'
        ? switch (descriptor.type) {
            RoutineType.morning =>
              'Piliin ang layunin at simulan ang araw nang malinaw.',
            RoutineType.midday =>
              'Huminga at maglaan ng sandali para sa pasasalamat.',
            _ => 'Itala ang mahalagang sandali at dahan-dahang magpahinga.',
          }
        : descriptor.subtitle;
    final activeSteps = routine?.steps
            .where((step) => step.isEnabled)
            .toList(growable: false) ??
        const <RoutineStep>[];
    final resumeIndex =
        session?.nextStepIndex.clamp(0, activeSteps.length) ?? 0;
    final resumeSubtitle = resumeIndex >= activeSteps.length
        ? LanguageHelper.pick(
            language,
            english: 'Your activities are done. Finish when you are ready.',
            filipino: 'Tapos na ang mga activity. Tapusin kapag handa ka na.',
          )
        : LanguageHelper.pick(
            language,
            english:
                'Continue with ${activeSteps[resumeIndex].title} • ${resumeIndex + 1}/${activeSteps.length}',
            filipino:
                'Ituloy ang ${activeSteps[resumeIndex].title} • ${resumeIndex + 1}/${activeSteps.length}',
          );
    final routineSubtitle = resuming
        ? resumeSubtitle
        : !isDefaultRoutine && routine != null
            ? routine.subtitle
            : defaultSubtitle;
    const accent = AppColors.honeyAmber;
    return Semantics(
      button: !completed && routine != null,
      label: completed
          ? LanguageHelper.pick(
              language,
              english: '$routineTitle completed today',
              filipino: 'Natapos ang $routineTitle ngayong araw',
            )
          : resuming
              ? LanguageHelper.pick(
                  language,
                  english: 'Resume $routineTitle',
                  filipino: 'Ituloy ang $routineTitle',
                )
              : LanguageHelper.pick(
                  language,
                  english: 'Start $routineTitle',
                  filipino: 'Simulan ang $routineTitle',
                ),
      child: InkWell(
        key: const ValueKey('home-routine-card'),
        onTap: completed || loading || routine == null
            ? null
            : () => _openRoutine(routine, resume: resuming),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          key: const ValueKey('home-routine-surface'),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: completed
                  ? isDark
                      ? const [Color(0xFF3B3321), Color(0xFF24251F)]
                      : const [Color(0xFFFFEDB2), Color(0xFFFFFBEC)]
                  : resuming
                      ? isDark
                          ? const [Color(0xFF4B351C), Color(0xFF28271F)]
                          : const [Color(0xFFFFD875), Color(0xFFFFF1C6)]
                      : isDark
                          ? const [Color(0xFF3E301D), Color(0xFF292A23)]
                          : const [Color(0xFFFFE39B), Color(0xFFFFF6DC)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: completed ? 0.32 : 0.60),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.12 : 0.18),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.11),
                            accent.withValues(alpha: 0.10),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.92),
                            AppColors.pollenGlow.withValues(alpha: 0.44),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.70),
                  ),
                ),
                child: completed
                    ? Icon(Icons.check_rounded, size: 34, color: accent)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.asset(
                          descriptor.asset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            descriptor.icon,
                            size: 32,
                            color: accent,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? accent.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        completed
                            ? LanguageHelper.pick(
                                language,
                                english: 'COMPLETED TODAY',
                                filipino: 'TAPOS NA NGAYON',
                              )
                            : resuming
                                ? LanguageHelper.pick(
                                    language,
                                    english: 'RESUME ROUTINE',
                                    filipino: 'ITULOY ANG ROUTINE',
                                  )
                                : LanguageHelper.pick(
                                    language,
                                    english: 'TODAY\'S ROUTINE',
                                    filipino: 'GAWAIN NGAYON',
                                  ),
                        style: TextStyle(
                          color: accent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.65,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      completed
                          ? LanguageHelper.pick(
                              language,
                              english: 'You showed up for yourself',
                              filipino: 'Naglaan ka ng oras para sa sarili',
                            )
                          : routineTitle,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      completed
                          ? LanguageHelper.pick(
                              language,
                              english:
                                  'Your next gentle reset arrives tomorrow.',
                              filipino:
                                  'Bukas muli ang susunod mong mahinahong pahinga.',
                            )
                          : routineSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              else
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: completed ? accent.withValues(alpha: 0.14) : accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed
                        ? Icons.verified_rounded
                        : resuming
                            ? Icons.play_arrow_rounded
                            : Icons.arrow_forward_rounded,
                    size: 20,
                    color: completed ? accent : AppColors.onHoney,
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.05);
  }

  Widget _buildHighlightCard({
    required BuildContext context,
    required bool isDark,
    required RoutineLog? highlight,
  }) {
    final language = context.read<UserProvider>().language;
    final hasHighlight = highlight != null;
    return InkWell(
      key: const ValueKey('home-highlight-card'),
      onTap: () async {
        final routinesProvider = context.read<RoutinesProvider>();
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => TodaysHighlightScreen(
              existingHighlight: highlight,
            ),
          ),
        );
        if (!mounted) return;
        await routinesProvider.fetchRoutineLogs();
      },
      borderRadius: BorderRadius.circular(26),
      child: Container(
        key: const ValueKey('home-highlight-surface'),
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasHighlight
                ? isDark
                    ? const [Color(0xFF56381D), Color(0xFF29211D)]
                    : const [Color(0xFFE99B42), Color(0xFFB85F31)]
                : isDark
                    ? const [Color(0xFF352A28), Color(0xFF272625)]
                    : const [Color(0xFFFFE3D0), Color(0xFFF9E9DF)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: hasHighlight
                ? AppColors.pollenGlow.withValues(alpha: 0.58)
                : AppColors.warmPeach.withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: (hasHighlight ? AppColors.honeyAmber : Colors.black)
                  .withValues(alpha: isDark ? 0.16 : 0.09),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -38,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (hasHighlight
                              ? AppColors.pollenGlow
                              : AppColors.warmPeach)
                          .withValues(alpha: 0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  size: 58,
                  color: (hasHighlight ? Colors.white : AppColors.warmPeach)
                      .withValues(alpha: 0.10),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasHighlight
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasHighlight
                            ? Icons.light_mode_rounded
                            : Icons.auto_awesome_outlined,
                        size: 18,
                        color: hasHighlight
                            ? const Color(0xFFFFD991)
                            : AppColors.warmPeach,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LanguageHelper.pick(
                          language,
                          english: 'Highlight of the day',
                          filipino: 'Mahalagang sandali ngayong araw',
                        ),
                        style: TextStyle(
                          color: hasHighlight
                              ? Colors.white
                              : isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: hasHighlight
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white
                                .withValues(alpha: isDark ? 0.05 : 0.60),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasHighlight
                                ? Icons.edit_outlined
                                : Icons.add_rounded,
                            size: 13,
                            color: hasHighlight
                                ? Colors.white70
                                : AppColors.honeyAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasHighlight
                                ? LanguageHelper.pick(
                                    language,
                                    english: 'Edit',
                                    filipino: 'Baguhin',
                                  )
                                : LanguageHelper.pick(
                                    language,
                                    english: 'Add',
                                    filipino: 'Idagdag',
                                  ),
                            style: TextStyle(
                              color: hasHighlight
                                  ? Colors.white70
                                  : AppColors.honeyAmber,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  hasHighlight
                      ? '“${highlight.focusOrHighlight!.trim()}”'
                      : LanguageHelper.pick(
                          language,
                          english: 'Keep one beautiful detail from today.',
                          filipino:
                              'Itala ang isang magandang detalye mula ngayon.',
                        ),
                  style: hasHighlight
                      ? TextStyle(
                          color: Colors.white,
                          fontFamily: 'serif',
                          fontSize: 20,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        )
                      : TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontSize: 17,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                  maxLines: hasHighlight ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  hasHighlight
                      ? LanguageHelper.pick(
                          language,
                          english:
                              'Saved ${DateFormat('h:mm a').format(highlight.completedAt.toLocal())}',
                          filipino:
                              'Na-save ${DateFormat('h:mm a').format(highlight.completedAt.toLocal())}',
                        )
                      : LanguageHelper.pick(
                          language,
                          english:
                              'A sentence is enough. Capture a win, a feeling, or a quiet moment.',
                          filipino:
                              'Sapat na ang isang pangungusap—tagumpay, damdamin, o tahimik na sandali.',
                        ),
                  style: TextStyle(
                    color: hasHighlight
                        ? Colors.white60
                        : isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _headerButton({
    Key? key,
    required bool isDark,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      key: key,
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isDark ? AppColors.darkCardBorder : const Color(0xFFEFEAE1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 21,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }

  List<_ActivityItem> _activities(BuildContext context) {
    final language = context.read<UserProvider>().language;
    String copy(String english, String filipino) => LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
        );
    return [
      _ActivityItem(
        title: copy('Weekly reflection', 'Lingguhang pagninilay'),
        subtitle: copy('Connect your week', 'Pag-ugnayin ang linggo'),
        accent: AppColors.lavenderMist,
        placeholderIcon: Icons.auto_graph_rounded,
        placeholderColor: AppColors.honeyAmber,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WeeklyReflectionScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('Gratitude', 'Pasasalamat'),
        subtitle: copy('Plant a flower', 'Magtanim ng bulaklak'),
        accent: AppColors.softOlive,
        assetPath: FeatureIconHelper.gratitudeGarden,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GardenScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('Mood', 'Damdamin'),
        subtitle: copy('Daily check-in', 'Araw-araw na check-in'),
        accent: AppColors.warmPeach,
        assetPath: FeatureIconHelper.moodTracker,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('AI Journal', 'AI Talaarawan'),
        subtitle: copy('Reflect freely', 'Malayang magnilay'),
        accent: AppColors.honeyAmber,
        assetPath: FeatureIconHelper.journal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JournalListScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('Sleep log', 'Tala ng tulog'),
        subtitle: copy('Rest & energy', 'Pahinga at lakas'),
        accent: AppColors.periwinkle,
        assetPath: FeatureIconHelper.sleepLog,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SleepLogFlowScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('Reflection', 'Pagninilay'),
        subtitle: copy('Evening review', 'Balik-tanaw sa gabi'),
        accent: AppColors.lavenderMist,
        assetPath: FeatureIconHelper.dailyReflection,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyReflectionScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('Focus', 'Pokus'),
        subtitle: copy('Mindful priority', 'Mahalagang unahin'),
        accent: AppColors.softYellow,
        assetPath: FeatureIconHelper.todaysFocus,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TodaysFocusScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('Future letters', 'Mga liham sa hinaharap'),
        subtitle: copy('Sealed notes', 'Mga selyadong tala'),
        accent: AppColors.warmPeach,
        assetPath: FeatureIconHelper.entries,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FutureLettersScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('Affirmations', 'Mga pagpapatibay'),
        subtitle: copy('Supportive reminders', 'Mga paalalang may malasakit'),
        accent: AppColors.softRose,
        placeholderIcon: Icons.format_quote_rounded,
        placeholderColor: AppColors.honeyAmber,
        onTap: _openAffirmations,
      ),
      _ActivityItem(
        title: copy('Grounding', 'Pagpapakalma'),
        subtitle: copy('5–4–3–2–1 senses', '5–4–3–2–1 pandama'),
        accent: AppColors.softOlive,
        assetPath: 'assets/feature icons/Grounding.png',
        placeholderIcon: Icons.spa_outlined,
        placeholderColor: AppColors.honeyAmber,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GroundingSessionScreen()),
        ),
      ),
      _ActivityItem(
        title: copy('Breathe', 'Huminga'),
        subtitle: copy('Guided rhythms', 'Gabay sa paghinga'),
        accent: AppColors.skyBlue,
        assetPath: 'assets/feature icons/Breathing.png',
        placeholderIcon: Icons.air_rounded,
        placeholderColor: AppColors.honeyGold,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MindfulnessMeditationScreen(),
          ),
        ),
      ),
      _ActivityItem(
        title: copy('Routines', 'Mga gawain'),
        subtitle: copy('Daily anchors', 'Araw-araw na gabay'),
        accent: AppColors.honeyGold,
        assetPath: FeatureIconHelper.routines,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoutinesHubScreen()),
        ),
      ),
    ];
  }

  void _openActivitiesMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ActivitiesMenuScreen(
          activities: _activities(context),
        ),
      ),
    );
  }

  void _openLearningHub(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: KaibiganMotion.reveal,
        reverseTransitionDuration: KaibiganMotion.standard,
        pageBuilder: (_, __, ___) => const LearningHubScreen(),
        transitionsBuilder: (context, animation, _, child) {
          if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
            return child;
          }
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: KaibiganMotion.enter,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: KaibiganMotion.enter,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLearningPreview(BuildContext context, bool isDark) {
    final language = context.read<UserProvider>().language;
    final featured = LearningCatalog.lessons[1];
    final primary = isDark ? AppColors.textPrimaryDark : AppColors.onHoney;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.onHoney.withValues(alpha: 0.76);
    final honey = isDark ? AppColors.warmHoney : AppColors.honeyAmber;
    final radius = BorderRadius.circular(28);

    return Material(
      key: const ValueKey('mental-health-learning-section'),
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: LanguageHelper.pick(
          language,
          english: 'Open mental health learning',
          filipino: 'Buksan ang mental health learning',
        ),
        child: InkWell(
          onTap: () => _openLearningHub(context),
          child: Ink(
            key: const ValueKey('learning-preview-surface'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF4B361D), Color(0xFF292821)]
                    : const [Color(0xFFFFD35F), Color(0xFFF3B744)],
              ),
              borderRadius: radius,
              border: Border.all(
                color: isDark
                    ? AppColors.darkHoneyBorder
                    : Colors.white.withValues(alpha: 0.64),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.honeyAmber
                      .withValues(alpha: isDark ? 0.12 : 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 11),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 24,
                  top: -28,
                  child: Row(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Icon(
                          Icons.hexagon_rounded,
                          size: 32,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 82,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white
                                .withValues(alpha: isDark ? 0.12 : 0.82),
                            Colors.white
                                .withValues(alpha: isDark ? 0.05 : 0.48),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.26),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.local_library_rounded,
                            size: 42,
                            color: isDark ? honey : AppColors.onHoney,
                          ),
                          Positioned(
                            right: 11,
                            top: 12,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color:
                                  isDark ? AppColors.warmHoney : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              LanguageHelper.pick(
                                language,
                                english:
                                    '${LearningCatalog.lessons.length} guided lessons',
                                filipino:
                                    '${LearningCatalog.lessons.length} guided lesson',
                              ).toUpperCase(),
                              style: TextStyle(
                                color: primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.65,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            featured.title.resolve(language),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primary,
                              fontSize: 17,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            featured.summary.resolve(language),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.honeyAmber : AppColors.onHoney,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: isDark ? AppColors.onHoney : Colors.white,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesCarousel(BuildContext context, bool isDark) {
    final activities = _activities(context);
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SizedBox(
      key: const ValueKey('wellness-activities-carousel'),
      height: 194,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final item = activities[index];
          return Semantics(
            button: true,
            label: '${item.title}. ${item.subtitle}',
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(23),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: item.onTap,
                  child: Ink(
                    key: ValueKey('wellness-activity-surface-$index'),
                    width: 148,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Color.alphaBlend(
                                  item.accent.withValues(alpha: 0.16),
                                  AppColors.darkCard,
                                ),
                                AppColors.darkCard,
                              ]
                            : [
                                Color.alphaBlend(
                                  item.accent.withValues(alpha: 0.18),
                                  Colors.white,
                                ),
                                Colors.white,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: item.accent.withValues(alpha: 0.34),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.accent.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ActivityArtwork(
                          item: item,
                          width: double.infinity,
                          height: 121,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(11, 8, 9, 7),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: foreground,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: secondary,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: item.accent.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: item.accent,
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }
}

class _ActivitiesMenuScreen extends StatelessWidget {
  const _ActivitiesMenuScreen({required this.activities});

  final List<_ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = context.watch<UserProvider>().language;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageHelper.pick(
            language,
            english: 'All activities',
            filipino: 'Lahat ng gawain',
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: GridView.builder(
          key: const ValueKey('all-activities-menu'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 174,
          ),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final item = activities[index];
            return Semantics(
              button: true,
              label: '${item.title}. ${item.subtitle}',
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.honeyBorder.withValues(alpha: 0.72),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ActivityArtwork(
                        item: item,
                        width: double.infinity,
                        height: 108,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: secondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActivityArtwork extends StatelessWidget {
  const _ActivityArtwork({
    required this.item,
    required this.width,
    required this.height,
  });

  final _ActivityItem item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(15),
        bottomRight: Radius.circular(15),
      ),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color.alphaBlend(
                      item.accent.withValues(alpha: 0.24),
                      AppColors.darkHoneySurface,
                    ),
                    AppColors.darkCard,
                  ]
                : [
                    Color.alphaBlend(
                      item.accent.withValues(alpha: 0.28),
                      AppColors.honeyLight,
                    ),
                    AppColors.honeyLight,
                  ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.assetPath == null)
              Icon(
                item.placeholderIcon,
                color: item.placeholderColor,
                size: height * 0.34,
              )
            else
              Image.asset(
                item.assetPath!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) => Icon(
                  item.placeholderIcon,
                  color: item.placeholderColor,
                  size: height * 0.34,
                ),
              ),
            Positioned(
              right: 9,
              top: 9,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.82),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.accent.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  Icons.hexagon_rounded,
                  size: 11,
                  color: item.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineDescriptor {
  final RoutineType type;
  final String title;
  final String subtitle;
  final String asset;
  final Color accent;
  final IconData icon;

  const _RoutineDescriptor({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.accent,
    required this.icon,
  });

  factory _RoutineDescriptor.forType(RoutineType type) {
    switch (type) {
      case RoutineType.morning:
        return const _RoutineDescriptor(
          type: RoutineType.morning,
          title: 'Morning Focus Routine',
          subtitle: 'Choose your intention and begin with clarity.',
          asset: FeatureIconHelper.morningRoutine,
          accent: AppColors.honeyAmber,
          icon: Icons.wb_sunny_rounded,
        );
      case RoutineType.midday:
        return const _RoutineDescriptor(
          type: RoutineType.midday,
          title: 'Mid-Day Reset Routine',
          subtitle: 'Check in, breathe, and make space for gratitude.',
          asset: FeatureIconHelper.midDayRoutine,
          accent: AppColors.honeyGold,
          icon: Icons.spa_rounded,
        );
      case RoutineType.night:
      case RoutineType.custom:
        return const _RoutineDescriptor(
          type: RoutineType.night,
          title: 'Night Reflection Routine',
          subtitle: 'Keep today’s highlight and gently unwind.',
          asset: FeatureIconHelper.nightRoutine,
          accent: AppColors.honeyAmber,
          icon: Icons.nights_stay_rounded,
        );
    }
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String? assetPath;
  final IconData placeholderIcon;
  final Color placeholderColor;
  final Color accent;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    this.assetPath,
    this.placeholderIcon = Icons.spa_rounded,
    this.placeholderColor = AppColors.honeyAmber,
    this.accent = AppColors.honeyAmber,
    required this.onTap,
  });
}
