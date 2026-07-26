import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';
import '../mood_tracking/mood_provider.dart';
import '../journaling/journal_provider.dart';
import '../journaling/journal_list_screen.dart';
import '../journaling/journal_editor_screen.dart';
import '../gratitude_garden/garden_screen.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../comfort_corner/comfort_corner_screen.dart';
import '../mood_tracking/mood_tracker_screen.dart';
import '../future_letters/future_letters_screen.dart';
import '../wellness_journey/journey_screen.dart';
import '../wellness_journey/daily_goals_provider.dart';
import '../settings/settings_screen.dart';
import '../settings/profile_screen.dart';
import 'widgets/emotional_weather_widget.dart';

class HomeScreen extends StatelessWidget {
  final ScrollController _favoritesScrollController = ScrollController();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context);
    final goalsProvider = Provider.of<DailyGoalsProvider>(context);
    final gratitudeProvider = Provider.of<GratitudeProvider>(context);

    final mascot = MascotInfo.getById(userProvider.selectedCompanion);
    final memoryEntry = journalProvider.getMemoryLaneEntry();

    String greetingMsg;
    if (userProvider.preferredLanguage == 'filipino') {
      greetingMsg = mascot.greetingFilipino;
    } else if (userProvider.preferredLanguage == 'english') {
      greetingMsg = mascot.greetingEnglish;
    } else {
      greetingMsg = mascot.greetingTaglish;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Row (Profile on Left, Action Bar & Settings Gear on Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Avatar Icon & User Display Name (Navigates to ProfileScreen)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppColors.darkCardBorder : const Color(0xFF2D2D2D), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                mascot.avatarIcon,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shield, size: 13, color: Colors.blue.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      'kaibigan member',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  userProvider.displayName.toLowerCase().replaceAll(' ', ''),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right: Action Bar (Streak 💧, Smiley 😊, Notifications 🔔, Settings ⚙️)
                  Row(
                    children: [
                      // 1. Streak Indicator (Opens Streak & Water Drops Modal)
                      GestureDetector(
                        onTap: () => _showStreakModal(context, gratitudeProvider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : const Color(0xFFE8F1F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.opacity_rounded, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, size: 18),
                              const SizedBox(width: 2),
                              Text(
                                '1',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.bounceOut, delay: 200.ms),
                      const SizedBox(width: 8),

                      // 2. Quick Mood Check-in Smiley (Opens Quick Mood Sheet)
                      GestureDetector(
                        onTap: () => _showQuickMoodSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.sentiment_satisfied_alt_outlined,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            size: 22,
                          ),
                        ),
                      ).animate().shake(duration: 1000.ms, delay: 400.ms),
                      const SizedBox(width: 8),

                      // 3. Notification Bell (Opens Notifications & Reminders Sheet)
                      GestureDetector(
                        onTap: () => _showNotificationsModal(context),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none_outlined,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              size: 22,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE07A5F), // Coral dot
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(duration: 500.ms, delay: 600.ms),
                      const SizedBox(width: 10),

                      // 4. Dedicated Settings Gear Icon (Navigates to SettingsScreen)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : const Color(0xFFF6F4ED),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.settings_outlined,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C),
                            size: 20,
                          ),
                        ),
                      ).animate().rotate(duration: 800.ms, delay: 800.ms),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Emotional Weather Widget (Navigates to MoodTrackerScreen)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
                ),
                child: EmotionalWeatherWidget(weather: moodProvider.currentEmotionalWeather),
              ),
              const SizedBox(height: 20),

              // Hero Garden Landscape Card (Green Panel -> Direct Route to AI Chat / JournalEditorScreen)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
                ),
                child: Container(
                  height: 230,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [const Color(0xFF1E3A27), const Color(0xFF13251A)]
                          : [const Color(0xFF90B77D), const Color(0xFF425F3B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Layer 1: Background Hills (Rolling Hills Silhouette)
                      Positioned(
                        left: -40,
                        bottom: -60,
                        child: Container(
                          width: 220,
                          height: 160,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF24442E) : const Color(0xFF6B8E63).withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -30,
                        bottom: -50,
                        child: Container(
                          width: 240,
                          height: 150,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A3523) : const Color(0xFF56784E).withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 40,
                        bottom: -80,
                        child: Container(
                          width: 300,
                          height: 160,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF132A1C) : const Color(0xFF3F5E38),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Layer 2: Top-Left Quabble Orange Tag (💧 Goals Completed)
                      Positioned(
                        left: 16,
                        top: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9326), // Quabble Orange
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${goalsProvider.completedCount}/${goalsProvider.goals.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Layer 3: Center Companion Mascot & Storybook Speech Bubble (Tapping opens AI Chat)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              mascot.avatarIcon,
                              style: const TextStyle(fontSize: 54),
                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                             .moveY(begin: 0, end: -6, duration: 2500.ms),
                            const SizedBox(height: 8),
                            // Speech Bubble
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      greetingMsg,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.sageGreen),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Layer 4: Bottom-Right Circular Arrow Button (Opens AI Chat)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF24442E) : const Color(0xFF3F5E38),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // MY Favorites Section (Stacked like Quabble with Web Scroll Chevrons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _showFavoritesModal(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MY',
                          style: AppTypography.heroHeader(context, isDark: isDark),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'favorites',
                              style: AppTypography.titleSmall(context, isDark: isDark),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Web Scroll Chevrons (Left / Right)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _favoritesScrollController.animateTo(
                            (_favoritesScrollController.offset - 180).clamp(0, _favoritesScrollController.position.maxScrollExtent),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : const Color(0xFFF6F4ED),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          _favoritesScrollController.animateTo(
                            (_favoritesScrollController.offset + 180).clamp(0, _favoritesScrollController.position.maxScrollExtent),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : const Color(0xFFF6F4ED),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 118,
                child: ListView(
                  controller: _favoritesScrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFavoriteItem(
                      context,
                      title: 'Gratitude Garden',
                      icon: '🌸',
                      color: AppColors.softRose,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GardenScreen()),
                      ),
                    ),
                    _buildFavoriteItem(
                      context,
                      title: 'Comfort Corner',
                      icon: '🫶',
                      color: AppColors.warmPeach,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ComfortCornerScreen()),
                      ),
                    ),
                    _buildFavoriteItem(
                      context,
                      title: 'Mood Tracker',
                      icon: '☀️',
                      color: AppColors.periwinkle,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
                      ),
                    ),
                    _buildFavoriteItem(
                      context,
                      title: 'AI Journal',
                      icon: '✍️',
                      color: AppColors.sageGreen,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JournalListScreen()),
                      ),
                    ),
                    _buildFavoriteItem(
                      context,
                      title: 'Future Letters',
                      icon: '✉️',
                      color: AppColors.lavenderMist,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FutureLettersScreen()),
                      ),
                    ),
                    _buildFavoriteItem(
                      context,
                      title: 'Wellness Journey',
                      icon: '📈',
                      color: AppColors.softOlive,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JourneyScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Daily Workouts & Goals (Quabble Header Style + Menu Icon)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Workouts & Goals',
                    style: AppTypography.titleMedium(context, isDark: isDark),
                  ),
                  GestureDetector(
                    onTap: () => _showManageGoalsModal(context, goalsProvider),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.menu_rounded,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF2C2C2C),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: goalsProvider.goals.map((goal) {
                    return GestureDetector(
                      onTap: () => goalsProvider.toggleGoal(goal.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            // Checkbox
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: goal.isCompleted 
                                    ? AppColors.sageGreen 
                                    : (isDark ? Colors.black26 : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? AppColors.darkCardBorder : const Color(0xFFD0D0D0),
                                  width: 1.5,
                                ),
                              ),
                              child: goal.isCompleted
                                  ? const Center(
                                      child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(goal.icon, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                goal.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                                  color: goal.isCompleted
                                      ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Memory Lane Feature
              if (memoryEntry != null) ...[
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => JournalEditorScreen(entry: memoryEntry)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📖 Memory Lane',
                        style: AppTypography.titleMedium(context, isDark: isDark),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lavenderMist.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lavenderMist, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, size: 18, color: AppColors.beePrimary),
                                const SizedBox(width: 6),
                                Text(
                                  'A reflection from past entries:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"${memoryEntry.title}"',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              memoryEntry.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(
    BuildContext context, {
    required String title,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Streak & Water Drops Modal Sheet
  void _showStreakModal(BuildContext context, GratitudeProvider gratitudeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥 1 Day Streak!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C))),
              const SizedBox(height: 6),
              const Text('You have logged in today! Keep returning daily to nurture your garden.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F4ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('💧 Total Drops', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${gratitudeProvider.waterDrops} Drops', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sageGreen)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('🌻 Flowers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${gratitudeProvider.flowerCount} Bloomed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFFF9326))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.star_rounded, color: Colors.white),
                  label: const Text('Claim Daily Bonus (+5 💧)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Claimed 5 bonus water drops for checking in!'),
                        backgroundColor: AppColors.sageGreen,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Quick Mood Check-in Sheet
  void _showQuickMoodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final moodProvider = Provider.of<MoodProvider>(context, listen: false);

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How are you feeling right now? 😊', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C))),
              const SizedBox(height: 8),
              const Text('Select your current mood to update your emotional weather.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMoodOption(context, '☀️', 'Joyful', () {
                    moodProvider.logMood(score: 5, label: 'Joyful', note: 'Feeling joyful!');
                    Navigator.pop(context);
                  }),
                  _buildMoodOption(context, '🌤️', 'Calm', () {
                    moodProvider.logMood(score: 4, label: 'Calm', note: 'Feeling calm.');
                    Navigator.pop(context);
                  }),
                  _buildMoodOption(context, '🌧️', 'Sad', () {
                    moodProvider.logMood(score: 2, label: 'Sad', note: 'Feeling down.');
                    Navigator.pop(context);
                  }),
                  _buildMoodOption(context, '⛈️', 'Anxious', () {
                    moodProvider.logMood(score: 1, label: 'Anxious', note: 'Feeling overwhelmed.');
                    Navigator.pop(context);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodOption(BuildContext context, String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F4ED),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sageGreen.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C))),
        ],
      ),
    );
  }

  // 3. Notifications & Reminders Modal
  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.notifications_active_outlined, color: AppColors.sageGreen, size: 22),
                  SizedBox(width: 8),
                  Text('Notifications & Notes 🔔', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C))),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem('🌿 Kai sent a warm thought', 'Remember to breathe deeply today. I\'m always here for you.', '10m ago'),
              const Divider(height: 20),
              _buildNotificationItem('🌸 Gratitude Garden', 'Your garden is blooming! 4 flowers planted this week.', '1h ago'),
              const Divider(height: 20),
              _buildNotificationItem('💧 Daily Reminder', 'Don\'t forget to drink water and check off your wellness goals.', '3h ago'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(String title, String desc, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C))),
            Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
      ],
    );
  }

  // 4. Favorites Directory Modal
  void _showFavoritesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Kaibigan Shortcuts 📂', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C))),
              const SizedBox(height: 14),
              ListTile(
                leading: const Text('🌸', style: TextStyle(fontSize: 24)),
                title: const Text('Gratitude Garden', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Plant flowers of gratitude'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GardenScreen()));
                },
              ),
              ListTile(
                leading: const Text('🫶', style: TextStyle(fontSize: 24)),
                title: const Text('Comfort Corner', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('4-7-8 Breathing & 5-4-3-2-1 Grounding'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ComfortCornerScreen()));
                },
              ),
              ListTile(
                leading: const Text('✍️', style: TextStyle(fontSize: 24)),
                title: const Text('AI Journal & Companion Chat', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Chat with Kai, Ann, or Bee'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalEditorScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 5. Manage Daily Goals Modal
  void _showManageGoalsModal(BuildContext context, DailyGoalsProvider goalsProvider) {
    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Manage Daily Goals 📋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C))),
                  TextButton(
                    onPressed: () {
                      goalsProvider.resetGoals();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Enter new goal (e.g. 🏃 15 min walk)',
                  filled: true,
                  fillColor: const Color(0xFFF6F4ED),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Custom Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      goalsProvider.addGoal(titleController.text.trim(), '✨');
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
