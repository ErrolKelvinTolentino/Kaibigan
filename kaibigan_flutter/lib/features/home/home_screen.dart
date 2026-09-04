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
import '../affirmations/affirmation_model.dart';
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
import '../routines/screens/sleep_analytics_screen.dart';
import '../routines/screens/todays_focus_screen.dart';
import '../routines/screens/todays_highlight_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/user_provider.dart';
import '../unified_entries/unified_entries_screen.dart';
import '../weekly_reflection/weekly_reflection_screen.dart';
import 'activity_feedback_store.dart';
import 'activity_usage_store.dart';
import 'widgets/home_favorites_carousel.dart';
import 'widgets/home_streak_greeting_card.dart';
import 'widgets/today_moments_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<DateTime> _loginDates = {};
  Map<String, int> _activityCounts = {};

  @override
  void initState() {
    super.initState();
    _loadActivityStats();
  }

  Future<void> _loadActivityStats() async {
    await ActivityUsageStore.recordTodayLogin();
    final dates = await ActivityUsageStore.loadLoginDates();
    final counts = await ActivityUsageStore.loadActivityCounts();
    if (mounted) {
      setState(() {
        _loginDates = dates;
        _activityCounts = counts;
      });
    }
  }

  int _calculateStreak(Set<DateTime> dates) {
    if (dates.isEmpty) return 1;
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!dates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak > 0 ? streak : 1;
  }

  T? _maybeRead<T extends ChangeNotifier>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  T? _maybeWatch<T extends ChangeNotifier>(BuildContext context) {
    try {
      return context.watch<T>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshHome() async {
    final futures = <Future<void>>[_loadActivityStats()];
    final routines = _maybeRead<RoutinesProvider>(context);
    if (routines != null) futures.add(routines.fetchRoutineLogs());
    final mood = _maybeRead<MoodProvider>(context);
    if (mood != null) futures.add(mood.fetchMoodLogs());
    final journal = _maybeRead<JournalProvider>(context);
    if (journal != null) futures.add(journal.fetchJournalEntries());
    final garden = _maybeRead<GratitudeProvider>(context);
    if (garden != null) futures.add(garden.fetchGratitudeEntries());
    final letters = _maybeRead<LettersProvider>(context);
    if (letters != null) futures.add(letters.fetchLetters());
    await Future.wait(futures);
  }

  Future<void> _openRoutine(
    RoutineConfig routine, {
    required bool resume,
  }) async {
    final result = await Navigator.of(context).push<bool>(
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
    if (mounted && result == true) {
      await _askActivityFeedback(
        activityId: 'routine:${routine.type.name}',
        activityLabel: routine.title,
      );
    }
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

  Future<void> _openHighlight(RoutineLog? highlight) async {
    final before = highlight?.focusOrHighlight ?? '';
    final routines = context.read<RoutinesProvider>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TodaysHighlightScreen(existingHighlight: highlight),
      ),
    );
    if (!mounted) return;
    await routines.fetchRoutineLogs();
    if (!mounted) return;
    final changed = (routines.todayHighlight?.focusOrHighlight ?? '') != before;
    if (result == true || changed) {
      await _askActivityFeedback(
        activityId: 'highlight',
        activityLabel: 'moment you saved',
      );
    }
  }

  Future<void> _askActivityFeedback({
    required String activityId,
    required String activityLabel,
  }) async {
    if (!mounted) return;
    final language = context.read<UserProvider>().language;
    final result = await showModalBottomSheet<ActivityHelpfulness>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            key: const ValueKey('activity-feedback-sheet'),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color:
                    isDark ? AppColors.darkCardBorder : AppColors.honeyBorder,
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const Text(
                  'KAI CHECKS BACK IN',
                  style: TextStyle(
                    color: AppColors.honeyAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LanguageHelper.pick(
                    language,
                    english: 'Did that help?',
                    filipino: 'Nakatulong ba iyon?',
                    taglish: 'Did that help?',
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  LanguageHelper.pick(
                    language,
                    english:
                        'Your answer helps Kai choose what to offer next. No journal text is saved with it.',
                    filipino:
                        'Tutulong ang sagot mo kay Kai na pumili ng susunod na alok. Walang journal text na ise-save rito.',
                    taglish:
                        'Your answer helps Kai choose what to offer next. Walang journal text na ise-save.',
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _FeedbackChoice(
                  key: const ValueKey('activity-helped'),
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  label: LanguageHelper.pick(
                    language,
                    english: 'Yes, a little',
                    filipino: 'Oo, kahit kaunti',
                  ),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    ActivityHelpfulness.helped,
                  ),
                ),
                const SizedBox(height: 8),
                _FeedbackChoice(
                  key: const ValueKey('activity-unsure'),
                  icon: Icons.remove_rounded,
                  label: LanguageHelper.pick(
                    language,
                    english: 'Not sure yet',
                    filipino: 'Hindi pa sigurado',
                  ),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    ActivityHelpfulness.unsure,
                  ),
                ),
                const SizedBox(height: 8),
                _FeedbackChoice(
                  key: const ValueKey('activity-not-helpful'),
                  icon: Icons.swap_horiz_rounded,
                  label: LanguageHelper.pick(
                    language,
                    english: 'No—try something else',
                    filipino: 'Hindi—subukan ang iba',
                  ),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    ActivityHelpfulness.notHelpful,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
    if (result == null || !mounted) return;
    await ActivityFeedbackStore.add(
      ActivityFeedbackRecord(
        activityId: activityId,
        helpfulness: result,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == ActivityHelpfulness.notHelpful
              ? LanguageHelper.pick(
                  language,
                  english: 'Thanks. Kai will try a different kind of support.',
                  filipino:
                      'Salamat. Susubukan ni Kai ang ibang uri ng suporta.',
                )
              : LanguageHelper.pick(
                  language,
                  english: 'Thanks. Kai will remember what felt useful.',
                  filipino: 'Salamat. Tatandaan ni Kai ang nakatulong.',
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>();
    final language = user.language;
    final affirmations = _maybeWatch<AffirmationsProvider>(context);
    final letters = _maybeWatch<LettersProvider>(context);
    final routines = context.watch<RoutinesProvider>();
    final journal = _maybeWatch<JournalProvider>(context);
    final garden = _maybeWatch<GratitudeProvider>(context);
    final mood = _maybeWatch<MoodProvider>(context);

    final activityDates = <DateTime>{
      if (journal != null)
        ...journal.entries.map((entry) {
          final d = entry.createdAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        }),
      if (garden != null)
        ...garden.entries.map((entry) {
          final d = entry.createdAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        }),
      if (mood != null)
        ...mood.logs.map((entry) {
          final d = entry.createdAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        }),
      ...routines.logs.map((entry) {
        final d = entry.completedAt.toLocal();
        return DateTime(d.year, d.month, d.day);
      }),
      ..._loginDates,
    };
    final streakCount = _calculateStreak(activityDates);

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
    final affirmation = affirmations?.homeAffirmationForDay(
          DateTime.now(),
          language: language,
        ) ??
        '';
    final arrivedLetterCount = letters?.letters
            .where((letter) => letter.isReadyToUnlock && !letter.isOpened)
            .length ??
        0;
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
                  key: const ValueKey('home-greeting-block'),
                  padding: EdgeInsets.fromLTRB(
                    pagePadding,
                    8,
                    pagePadding,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(
                      context,
                      user,
                      isDark,
                      streakCount,
                      activityDates,
                      garden,
                    ),
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
                  padding: EdgeInsets.fromLTRB(
                    pagePadding + 2,
                    16,
                    pagePadding + 2,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _sectionHeading(
                      title: LanguageHelper.pick(
                        language,
                        english: 'My Favorites',
                        filipino: 'Aking mga Paborito',
                      ),
                      subtitle: LanguageHelper.pick(
                        language,
                        english: 'Your most used spaces and daily companions',
                        filipino: 'Iyong mga pinakaginagamit na espasyo',
                      ),
                      action: TextButton(
                        key: const ValueKey('see-all-favorites'),
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
                  key: const ValueKey('home-favorites-block'),
                  child: HomeFavoritesCarousel(
                    favorites: _buildFavoritesList(context, language),
                    isDark: isDark,
                    language: language,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    pagePadding + 2,
                    16,
                    pagePadding + 2,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _sectionHeading(
                      title: LanguageHelper.pick(
                        language,
                        english: 'Today’s highlight',
                        filipino: 'Mahalagang sandali ngayon',
                      ),
                      subtitle: LanguageHelper.pick(
                        language,
                        english: 'One moment worth keeping',
                        filipino: 'Isang sandaling nais mong itabi',
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  key: const ValueKey('home-highlight-block'),
                  padding: EdgeInsets.fromLTRB(pagePadding, 4, pagePadding, 8),
                  sliver: SliverToBoxAdapter(
                    child: _buildHighlightCard(
                      context: context,
                      isDark: isDark,
                      highlight: highlight,
                    ),
                  ),
                ),
                if (arrivedLetterCount > 0) ...[
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
                          english: 'A note from your future self',
                          filipino: 'Tala mula sa iyong future self',
                        ),
                        subtitle: LanguageHelper.pick(
                          language,
                          english: 'A message waiting for today',
                          filipino: 'Mensahe para sa araw na ito',
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    key: const ValueKey('home-future-self-block'),
                    padding:
                        EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 6),
                    sliver: SliverToBoxAdapter(
                      child: TodayMomentsCard(
                        key: const ValueKey('home-future-self-note'),
                        language: language,
                        isDark: isDark,
                        category: affirmations?.selectedCategory ??
                            AffirmationCatalog.categories.first,
                        affirmation: affirmation,
                        arrivedLetterCount: arrivedLetterCount,
                        onLettersTap: _openFutureLetters,
                        showAffirmation: false,
                      ),
                    ),
                  ),
                ],
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
                        english: 'Today’s affirmation',
                        filipino: 'Pagpapatibay ngayong araw',
                      ),
                      subtitle: LanguageHelper.pick(
                        language,
                        english: 'A few words to carry with you',
                        filipino: 'Mga salitang dadalhin mo ngayon',
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  key: const ValueKey('home-affirmation-block'),
                  padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 6),
                  sliver: SliverToBoxAdapter(
                    child: TodayMomentsCard(
                      language: language,
                      isDark: isDark,
                      category: affirmations?.selectedCategory ??
                          AffirmationCatalog.categories.first,
                      affirmation: affirmation,
                      arrivedLetterCount: arrivedLetterCount,
                      onLettersTap: _openFutureLetters,
                      showFutureLetter: false,
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
                        english: 'Your routine',
                        filipino: 'Iyong routine',
                      ),
                      subtitle: LanguageHelper.pick(
                        language,
                        english: 'Your daily anchor',
                        filipino: 'Araw-araw mong sandigan',
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  key: const ValueKey('home-routine-block'),
                  padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 6),
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
                        english: 'Activities',
                        filipino: 'Mga activity',
                      ),
                      subtitle: LanguageHelper.pick(
                        language,
                        english: 'Choose what feels useful right now',
                        filipino: 'Piliin ang makakatulong ngayon',
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
                  key: const ValueKey('home-activities-block'),
                  child: _buildActivitiesCarousel(context, isDark),
                ),
                SliverPadding(
                  key: const ValueKey('home-learn-block'),
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
    int streakCount,
    Set<DateTime> activeDates,
    GratitudeProvider? gratitude,
  ) {
    final name =
        user.displayName.trim().isEmpty ? 'Kaibigan' : user.displayName;
    final language = user.language;

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
        HomeStreakGreetingCard(
          name: name,
          language: language,
          isDark: isDark,
          streakCount: streakCount,
          activeDates: activeDates,
          onStreakTap: gratitude == null
              ? null
              : () => _showStreakModal(context, gratitude, streakCount),
        ),
      ],
    );
  }

  void _showStreakModal(
    BuildContext context,
    GratitudeProvider gratitudeProvider,
    int streakCount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = context.read<UserProvider>().language;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFF6B00),
                    size: 28,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    LanguageHelper.pick(
                      language,
                      english: '$streakCount Day Streak!',
                      filipino: '$streakCount Araw na Streak!',
                    ),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF2C2C2C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                LanguageHelper.pick(
                  language,
                  english:
                      'You showed up today! Keep returning daily to nurture your garden and peace of mind.',
                  filipino:
                      'Naglaan ka ng oras ngayon! Magpatuloy araw-araw upang alagaan ang iyong sarili.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkHoneySurface : const Color(0xFFF6F4ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.honeyBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          LanguageHelper.pick(
                            language,
                            english: '🌱 Garden Level',
                            filipino: '🌱 Antas ng Hardin',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${gratitudeProvider.gardenLevel}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.sageGreen,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    Column(
                      children: [
                        Text(
                          LanguageHelper.pick(
                            language,
                            english: '🌸 Garden Blooms',
                            filipino: '🌸 Mga Bulaklak',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${gratitudeProvider.flowerCount}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.honeyAmber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.honeyAmber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.local_florist_rounded, color: Colors.white),
                  label: Text(
                    LanguageHelper.pick(
                      language,
                      english: 'Visit Gratitude Garden',
                      filipino: 'Bisitahin ang Hardin',
                    ),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GardenScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  List<FavoriteActivityData> _buildFavoritesList(
    BuildContext context,
    String language,
  ) {
    final allCandidates = [
      FavoriteActivityData(
        id: 'mood',
        title: LanguageHelper.pick(
          language,
          english: 'Mood Tracker',
          filipino: 'Tala ng Mood',
        ),
        subtitle: LanguageHelper.pick(
          language,
          english: 'Daily check-in',
          filipino: 'Pang-araw-araw na check-in',
        ),
        accent: AppColors.honeyAmber,
        assetPath: FeatureIconHelper.moodTracker,
        placeholderIcon: Icons.sentiment_satisfied_alt_outlined,
        onTap: () {
          ActivityUsageStore.incrementActivityUsage('mood');
          _loadActivityStats();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
          );
        },
        usageCount: _activityCounts['mood'] ?? 10,
      ),
      FavoriteActivityData(
        id: 'gratitude',
        title: LanguageHelper.pick(
          language,
          english: 'Gratitude Garden',
          filipino: 'Hardin ng Pasasalamat',
        ),
        subtitle: LanguageHelper.pick(
          language,
          english: 'Plant a flower',
          filipino: 'Magtanim ng bulaklak',
        ),
        accent: AppColors.softRose,
        assetPath: FeatureIconHelper.gratitudeGarden,
        placeholderIcon: Icons.local_florist_outlined,
        onTap: () {
          ActivityUsageStore.incrementActivityUsage('gratitude');
          _loadActivityStats();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GardenScreen()),
          );
        },
        usageCount: _activityCounts['gratitude'] ?? 8,
      ),
      FavoriteActivityData(
        id: 'journal',
        title: LanguageHelper.pick(
          language,
          english: 'AI Journal',
          filipino: 'AI Talaarawan',
        ),
        subtitle: LanguageHelper.pick(
          language,
          english: 'Reflect freely',
          filipino: 'Malayang magmuni-muni',
        ),
        accent: AppColors.sageGreen,
        assetPath: FeatureIconHelper.journal,
        placeholderIcon: Icons.auto_stories_outlined,
        onTap: () {
          ActivityUsageStore.incrementActivityUsage('journal');
          _loadActivityStats();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalListScreen()),
          );
        },
        usageCount: _activityCounts['journal'] ?? 5,
      ),
      FavoriteActivityData(
        id: 'grounding',
        title: LanguageHelper.pick(
          language,
          english: 'Comfort Corner',
          filipino: 'Sulok ng Kapanatagan',
        ),
        subtitle: LanguageHelper.pick(
          language,
          english: 'Calm & grounding',
          filipino: 'Huminahon at mag-ground',
        ),
        accent: AppColors.warmPeach,
        assetPath: FeatureIconHelper.grounding,
        placeholderIcon: Icons.spa_outlined,
        onTap: () {
          ActivityUsageStore.incrementActivityUsage('grounding');
          _loadActivityStats();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroundingSessionScreen()),
          );
        },
        usageCount: _activityCounts['grounding'] ?? 0,
      ),
      FavoriteActivityData(
        id: 'letters',
        title: LanguageHelper.pick(
          language,
          english: 'Future Letters',
          filipino: 'Liham sa Hinaharap',
        ),
        subtitle: LanguageHelper.pick(
          language,
          english: 'Sealed notes',
          filipino: 'Nakatagong mga liham',
        ),
        accent: AppColors.lavenderMist,
        assetPath: FeatureIconHelper.entries,
        placeholderIcon: Icons.mail_outline_rounded,
        onTap: () {
          ActivityUsageStore.incrementActivityUsage('letters');
          _loadActivityStats();
          _openFutureLetters();
        },
        usageCount: _activityCounts['letters'] ?? 0,
      ),
      FavoriteActivityData(
        id: 'routines',
        title: LanguageHelper.pick(
          language,
          english: 'Routines',
          filipino: 'Mga Routine',
        ),
        subtitle: LanguageHelper.pick(
          language,
          english: 'Daily anchors',
          filipino: 'Araw-araw na gabay',
        ),
        accent: AppColors.honeyGold,
        assetPath: FeatureIconHelper.routines,
        placeholderIcon: Icons.schedule_rounded,
        onTap: () {
          ActivityUsageStore.incrementActivityUsage('routines');
          _loadActivityStats();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoutinesHubScreen()),
          );
        },
        usageCount: _activityCounts['routines'] ?? 0,
      ),
      FavoriteActivityData(
        id: 'sleep',
        title: LanguageHelper.pick(
          language,
          english: 'Sleep Log',
          filipino: 'Tala ng Tulog',
        ),
        subtitle: LanguageHelper.pick(
          language,
          english: 'Night rest',
          filipino: 'Pahinga sa gabi',
        ),
        accent: AppColors.periwinkle,
        assetPath: FeatureIconHelper.sleepLog,
        placeholderIcon: Icons.nights_stay_rounded,
        onTap: () {
          ActivityUsageStore.incrementActivityUsage('sleep');
          _loadActivityStats();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SleepAnalyticsScreen()),
          );
        },
        usageCount: _activityCounts['sleep'] ?? 0,
      ),
    ];

    allCandidates.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return allCandidates.take(3).toList();
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
      onTap: () => _openHighlight(highlight),
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
        assetPath: FeatureIconHelper.weeklyInsights,
        placeholderIcon: Icons.auto_graph_rounded,
        placeholderColor: AppColors.honeyAmber,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeeklyReflectionScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Gratitude', 'Pasasalamat'),
        subtitle: copy('Plant a flower', 'Magtanim ng bulaklak'),
        accent: AppColors.softOlive,
        assetPath: FeatureIconHelper.gratitudeGarden,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GardenScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Mood', 'Damdamin'),
        subtitle: copy('Daily check-in', 'Araw-araw na check-in'),
        accent: AppColors.warmPeach,
        assetPath: FeatureIconHelper.moodTracker,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Today\'s highlight', 'Mahalagang sandali ngayon'),
        subtitle: copy('Keep one moment', 'Itabi ang isang sandali'),
        accent: AppColors.softYellow,
        assetPath: FeatureIconHelper.todaysHighlight,
        placeholderIcon: Icons.auto_awesome_outlined,
        placeholderColor: AppColors.honeyAmber,
        onTap: () {
          _openHighlight(
            context.read<RoutinesProvider>().todayHighlight,
          );
        },
      ),
      _ActivityItem(
        title: copy('AI Journal', 'AI Talaarawan'),
        subtitle: copy('Reflect freely', 'Malayang magnilay'),
        accent: AppColors.honeyAmber,
        assetPath: FeatureIconHelper.journal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalListScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Sleep log', 'Tala ng tulog'),
        subtitle: copy('Rest & energy', 'Pahinga at lakas'),
        accent: AppColors.periwinkle,
        assetPath: FeatureIconHelper.sleepLog,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SleepAnalyticsScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Reflection', 'Pagninilay'),
        subtitle: copy('Evening review', 'Balik-tanaw sa gabi'),
        accent: AppColors.lavenderMist,
        assetPath: FeatureIconHelper.dailyReflection,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyReflectionScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Focus', 'Pokus'),
        subtitle: copy('Mindful priority', 'Mahalagang unahin'),
        accent: AppColors.softYellow,
        assetPath: FeatureIconHelper.todaysFocus,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TodaysFocusScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Future letters', 'Mga liham sa hinaharap'),
        subtitle: copy('Sealed notes', 'Mga selyadong tala'),
        accent: AppColors.warmPeach,
        assetPath: FeatureIconHelper.entries,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FutureLettersScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Affirmations', 'Mga pagpapatibay'),
        subtitle: copy('Supportive reminders', 'Mga paalalang may malasakit'),
        accent: AppColors.softRose,
        assetPath: FeatureIconHelper.affirmations,
        placeholderIcon: Icons.format_quote_rounded,
        placeholderColor: AppColors.honeyAmber,
        onTap: () {
          _openAffirmations();
        },
      ),
      _ActivityItem(
        title: copy('Grounding', 'Pagpapakalma'),
        subtitle: copy('5–4–3–2–1 senses', '5–4–3–2–1 pandama'),
        accent: AppColors.softOlive,
        assetPath: FeatureIconHelper.grounding,
        placeholderIcon: Icons.spa_outlined,
        placeholderColor: AppColors.honeyAmber,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroundingSessionScreen()),
          );
        },
      ),
      _ActivityItem(
        title: copy('Breathe', 'Huminga'),
        subtitle: copy('Guided rhythms', 'Gabay sa paghinga'),
        accent: AppColors.skyBlue,
        assetPath: FeatureIconHelper.breathing,
        placeholderIcon: Icons.air_rounded,
        placeholderColor: AppColors.honeyGold,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MindfulnessMeditationScreen(),
            ),
          );
        },
      ),
      _ActivityItem(
        title: copy('Routines', 'Mga gawain'),
        subtitle: copy('Daily anchors', 'Araw-araw na gabay'),
        accent: AppColors.honeyGold,
        assetPath: FeatureIconHelper.routines,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoutinesHubScreen()),
          );
        },
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
                      key: const ValueKey('learning-preview-art'),
                      width: 82,
                      height: 96,
                      clipBehavior: Clip.antiAlias,
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
                      child: Image.asset(
                        FeatureIconHelper.learn,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.local_library_rounded,
                          size: 42,
                          color: isDark ? honey : AppColors.onHoney,
                        ),
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

class _FeedbackChoice extends StatelessWidget {
  const _FeedbackChoice({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Material(
      color: AppColors.honeyAmber.withValues(alpha: isDark ? 0.12 : 0.08),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.honeyAmber.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.honeyAmber, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.honeyAmber,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
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
