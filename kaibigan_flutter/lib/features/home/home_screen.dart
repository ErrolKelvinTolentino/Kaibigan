import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';
import '../settings/settings_screen.dart';
import '../unified_entries/unified_entries_screen.dart';
import '../gratitude_garden/garden_screen.dart';
import '../mood_tracking/mood_tracker_screen.dart';
import '../mood_tracking/mood_model.dart';
import '../journaling/journal_list_screen.dart';
import '../routines/routine_model.dart';
import '../routines/routines_hub_screen.dart';
import '../routines/screens/sleep_log_flow_screen.dart';
import '../routines/screens/todays_highlight_screen.dart';
import '../routines/screens/todays_focus_screen.dart';
import '../routines/screens/daily_reflection_screen.dart';
import '../routines/flows/progressive_routine_runner.dart';
import '../future_letters/future_letters_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d').format(now);

    // Determine current time routine
    final hour = now.hour;
    final RoutineType recommendedRoutineType;
    final String routineTitle;
    final String routineSubtitle;
    final String routineAsset;

    if (hour >= 5 && hour < 12) {
      recommendedRoutineType = RoutineType.morning;
      routineTitle = "Morning Focus Routine";
      routineSubtitle = "Set your daily intention and ground your energy.";
      routineAsset = FeatureIconHelper.morningRoutine;
    } else if (hour >= 12 && hour < 17) {
      recommendedRoutineType = RoutineType.midday;
      routineTitle = "Mid-Day Reset Routine";
      routineSubtitle = "Check your mood and water a gratitude flower.";
      routineAsset = FeatureIconHelper.midDayRoutine;
    } else {
      recommendedRoutineType = RoutineType.night;
      routineTitle = "Night Reflection Routine";
      routineSubtitle = "Capture today's highlight and unwind your mind.";
      routineAsset = FeatureIconHelper.nightRoutine;
    }

    // Companion greeting based on language
    final greeting = userProvider.language == 'filipino'
        ? mascot.greetingFilipino
        : (userProvider.language == 'taglish' ? mascot.greetingTaglish : mascot.greetingEnglish);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar / Header
            SliverPadding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Kamusta, ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              userProvider.displayName.isEmpty ? 'Kaibigan' : userProvider.displayName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.honeyAmber,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Top Action Icons (Entries & Settings)
                    Row(
                      children: [
                        _buildHeaderIconButton(
                          context,
                          icon: Icons.auto_stories_rounded,
                          tooltip: 'All Entries',
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UnifiedEntriesScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildHeaderIconButton(
                          context,
                          icon: Icons.tune_rounded,
                          tooltip: 'Settings',
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Companion Check-In Bubble Card
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mascot.primaryColor.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          mascot.materialIcon,
                          color: mascot.primaryColor,
                          size: 26,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: mascot.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: mascot.primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Companion',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              greeting,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, end: 0),
              ),
            ),
            
            // Time-Aware Recommended Routine Card
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProgressiveRoutineRunner(routineType: recommendedRoutineType),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2E2619), const Color(0xFF222824)]
                            : [const Color(0xFFFDF5E6), const Color(0xFFFAF0DC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.honeyGold.withValues(alpha: isDark ? 0.35 : 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.honeyGold.withValues(alpha: isDark ? 0.12 : 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            routineAsset,
                            width: 62,
                            height: 62,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_sunny_rounded, size: 40, color: AppColors.honeyGold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.honeyGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Recommended Routine',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.honeyAmber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                routineTitle,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                routineSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.honeyAmber),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Section Title: Activities Carousel
            SliverPadding(
              padding: const EdgeInsets.only(left: 22, right: 22, top: 16, bottom: 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wellness Activities',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UnifiedEntriesScreen()),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: Text(
                        'All Entries →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.honeyAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Wellness Activities Carousel
            SliverToBoxAdapter(
              child: _buildActivitiesCarousel(context, isDark),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GardenScreen())),
      ),
      _ActivityItem(
        title: 'Mood',
        subtitle: '5 Beemojis',
        assetPath: FeatureIconHelper.moodTracker,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodTrackerScreen())),
      ),
      _ActivityItem(
        title: 'AI Journal',
        subtitle: 'Reflect note',
        assetPath: FeatureIconHelper.journal,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalListScreen())),
      ),
      _ActivityItem(
        title: 'Sleep Log',
        subtitle: 'Rest & energy',
        assetPath: FeatureIconHelper.sleepLog,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepLogFlowScreen())),
      ),
      _ActivityItem(
        title: 'Daily Reflection',
        subtitle: 'Evening review',
        assetPath: FeatureIconHelper.dailyReflection,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyReflectionScreen())),
      ),
      _ActivityItem(
        title: "Highlight",
        subtitle: 'One joyful spark',
        assetPath: FeatureIconHelper.todaysHighlight,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaysHighlightScreen())),
      ),
      _ActivityItem(
        title: "Today's Focus",
        subtitle: 'Mindful priority',
        assetPath: FeatureIconHelper.todaysFocus,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodaysFocusScreen())),
      ),
      _ActivityItem(
        title: 'Future Letters',
        subtitle: 'Sealed notes',
        assetPath: FeatureIconHelper.entries,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FutureLettersScreen())),
      ),
      _ActivityItem(
        title: 'Routines',
        subtitle: 'Daily anchors',
        assetPath: FeatureIconHelper.routines,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutinesHubScreen())),
      ),
    ];

    return SizedBox(
      height: 195,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final item = activities[index];
          return _buildActivityCarouselCard(
            context,
            title: item.title,
            subtitle: item.subtitle,
            assetPath: item.assetPath,
            isDark: isDark,
            onTap: item.onTap,
          );
        },
      ),
    );
  }

  Widget _buildActivityCarouselCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String assetPath,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        margin: const EdgeInsets.only(right: 16),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                assetPath,
                width: 126,
                height: 126,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 126,
                  height: 126,
                  decoration: BoxDecoration(
                    color: AppColors.honeyGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.spa_rounded, color: AppColors.honeyGold, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String assetPath;
  final VoidCallback onTap;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.onTap,
  });
}
