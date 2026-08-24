import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/sync_status_banner.dart';
import '../companion/companion_model.dart';
import '../future_letters/future_letters_screen.dart';
import '../gratitude_garden/garden_screen.dart';
import '../journaling/journal_list_screen.dart';
import '../mood_tracking/mood_model.dart';
import '../mood_tracking/mood_tracker_screen.dart';
import '../routines/flows/progressive_routine_runner.dart';
import '../routines/routine_model.dart';
import '../routines/routines_hub_screen.dart';
import '../routines/routines_provider.dart';
import '../routines/screens/daily_reflection_screen.dart';
import '../routines/screens/sleep_log_flow_screen.dart';
import '../routines/screens/todays_focus_screen.dart';
import '../routines/screens/todays_highlight_screen.dart';
import '../settings/profile_screen.dart';
import '../settings/user_provider.dart';
import '../unified_entries/unified_entries_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _autoLaunchCheckStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoLaunchCheckStarted) return;
    _autoLaunchCheckStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareDailyRoutine());
  }

  Future<void> _prepareDailyRoutine() async {
    final provider = context.read<RoutinesProvider>();
    if (provider.logs.isEmpty && !provider.isLoading) {
      await provider.fetchRoutineLogs();
    } else if (provider.isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    if (!mounted) return;

    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (userId == null) return;

    final routineType = provider.currentPhase;
    if (provider.isRoutineCompletedToday(routineType)) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final launchKey = 'daily_routine_autoplay_${userId}_$today';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(launchKey) == true || !mounted) return;

    await prefs.setBool(launchKey, true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await _openRoutine(routineType);
  }

  Future<void> _openRoutine(RoutineType type) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProgressiveRoutineRunner(routineType: type),
      ),
    );
    if (!mounted) return;
    await context.read<RoutinesProvider>().fetchRoutineLogs();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>();
    final routines = context.watch<RoutinesProvider>();
    final mascot = MascotInfo.getById(user.selectedCompanion);
    final descriptor = _RoutineDescriptor.forType(routines.currentPhase);
    final routineCompleted = routines.isRoutineCompletedToday(descriptor.type);
    final highlight = routines.todayHighlight;

    final greeting = user.language == 'filipino'
        ? mascot.greetingFilipino
        : user.language == 'taglish'
            ? mascot.greetingTaglish
            : mascot.greetingEnglish;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.sageGreen,
          onRefresh: routines.fetchRoutineLogs,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(context, user, isDark),
                ),
              ),
              if (routines.errorMessage != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: SyncStatusBanner(
                      message: routines.errorMessage!,
                      onRetry: routines.fetchRoutineLogs,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _buildCompanionCard(
                    isDark: isDark,
                    mascot: mascot,
                    greeting: greeting,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _buildRoutineCard(
                    context: context,
                    isDark: isDark,
                    descriptor: descriptor,
                    completed: routineCompleted,
                    loading: routines.isLoading,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _buildHighlightCard(
                    context: context,
                    isDark: isDark,
                    highlight: highlight,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Wellness Activities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UnifiedEntriesScreen(),
                          ),
                        ),
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            color: AppColors.honeyAmber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildActivitiesCarousel(context, isDark),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
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
    final initial = name.characters.first.toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  text: 'Kamusta, ',
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
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        _headerButton(
          isDark: isDark,
          icon: Icons.auto_stories_rounded,
          tooltip: 'All entries',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UnifiedEntriesScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'Open profile',
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8DFAF), Color(0xFFE9B96A)],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.honeyAmber.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF714A17),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanionCard({
    required bool isDark,
    required MascotInfo mascot,
    required String greeting,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : const Color(0xFFEFEAE1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.035),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: mascot.primaryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              mascot.materialIcon,
              color: mascot.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mascot.name,
                      style: TextStyle(
                        color: mascot.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: mascot.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Companion',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  greeting,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 13.5,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.04);
  }

  Widget _buildRoutineCard({
    required BuildContext context,
    required bool isDark,
    required _RoutineDescriptor descriptor,
    required bool completed,
    required bool loading,
  }) {
    final accent = completed ? AppColors.sageGreen : descriptor.accent;
    return Semantics(
      button: !completed,
      label: completed
          ? '${descriptor.title} completed today'
          : 'Start ${descriptor.title}',
      child: InkWell(
        onTap:
            completed || loading ? null : () => _openRoutine(descriptor.type),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: completed
                  ? isDark
                      ? const [Color(0xFF27382D), Color(0xFF202C25)]
                      : const [Color(0xFFE8F2E8), Color(0xFFF4F7EE)]
                  : isDark
                      ? const [Color(0xFF342B1D), Color(0xFF252A25)]
                      : const [Color(0xFFFFF4DC), Color(0xFFF8EACD)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: completed ? 0.38 : 0.48),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.10 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.60),
                  borderRadius: BorderRadius.circular(19),
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
                        color: accent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        completed ? 'COMPLETED TODAY' : 'TODAY\'S ROUTINE',
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
                          ? 'You showed up for yourself'
                          : descriptor.title,
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
                          ? 'Your next gentle reset arrives tomorrow.'
                          : descriptor.subtitle,
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
                Icon(
                  completed
                      ? Icons.verified_rounded
                      : Icons.arrow_forward_rounded,
                  size: 21,
                  color: accent,
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
    final hasHighlight = highlight != null;
    return InkWell(
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasHighlight
                ? isDark
                    ? const [Color(0xFF28352D), Color(0xFF18251F)]
                    : const [Color(0xFF385D4B), Color(0xFF223D34)]
                : isDark
                    ? const [Color(0xFF282C2A), Color(0xFF222824)]
                    : const [Color(0xFFF5F0E7), Color(0xFFEDE8DE)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: hasHighlight
                ? const Color(0xFF8FB29C).withValues(alpha: 0.45)
                : AppColors.honeyGold.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: (hasHighlight ? AppColors.sageGreen : Colors.black)
                  .withValues(alpha: isDark ? 0.16 : 0.09),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -14,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 92,
                color: (hasHighlight ? Colors.white : AppColors.honeyAmber)
                    .withValues(alpha: 0.06),
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
                            ? Colors.white.withValues(alpha: 0.10)
                            : AppColors.honeyGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasHighlight
                            ? Icons.light_mode_rounded
                            : Icons.auto_awesome_outlined,
                        size: 18,
                        color: hasHighlight
                            ? const Color(0xFFFFD991)
                            : AppColors.honeyAmber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Highlight of the day',
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
                                : AppColors.sageGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasHighlight ? 'Edit' : 'Add',
                            style: TextStyle(
                              color: hasHighlight
                                  ? Colors.white70
                                  : AppColors.sageGreen,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  hasHighlight
                      ? '“${highlight.focusOrHighlight!.trim()}”'
                      : 'Keep one beautiful detail from today.',
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
                ),
                const SizedBox(height: 8),
                Text(
                  hasHighlight
                      ? 'Saved ${DateFormat('h:mm a').format(highlight.completedAt.toLocal())}'
                      : 'A sentence is enough. Capture a win, a feeling, or a quiet moment.',
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
    required bool isDark,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
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

  Widget _buildActivitiesCarousel(BuildContext context, bool isDark) {
    final activities = [
      _ActivityItem(
        title: 'Gratitude',
        subtitle: 'Plant a flower',
        assetPath: FeatureIconHelper.gratitudeGarden,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GardenScreen()),
        ),
      ),
      _ActivityItem(
        title: 'Mood',
        subtitle: 'Daily check-in',
        assetPath: FeatureIconHelper.moodTracker,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
        ),
      ),
      _ActivityItem(
        title: 'AI Journal',
        subtitle: 'Reflect freely',
        assetPath: FeatureIconHelper.journal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JournalListScreen()),
        ),
      ),
      _ActivityItem(
        title: 'Sleep Log',
        subtitle: 'Rest & energy',
        assetPath: FeatureIconHelper.sleepLog,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SleepLogFlowScreen()),
        ),
      ),
      _ActivityItem(
        title: 'Reflection',
        subtitle: 'Evening review',
        assetPath: FeatureIconHelper.dailyReflection,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyReflectionScreen()),
        ),
      ),
      _ActivityItem(
        title: 'Focus',
        subtitle: 'Mindful priority',
        assetPath: FeatureIconHelper.todaysFocus,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TodaysFocusScreen()),
        ),
      ),
      _ActivityItem(
        title: 'Future Letters',
        subtitle: 'Sealed notes',
        assetPath: FeatureIconHelper.entries,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FutureLettersScreen()),
        ),
      ),
      _ActivityItem(
        title: 'Routines',
        subtitle: 'Daily anchors',
        assetPath: FeatureIconHelper.routines,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoutinesHubScreen()),
        ),
      ),
    ];

    return SizedBox(
      height: 194,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final item = activities[index];
          return InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 132,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      item.assetPath,
                      width: 126,
                      height: 126,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 126,
                        height: 126,
                        color: AppColors.honeyGold.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: AppColors.honeyAmber,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
          accent: AppColors.softRose,
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
  final String assetPath;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.onTap,
  });
}
