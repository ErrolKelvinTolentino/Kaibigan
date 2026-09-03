import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/home/activity_usage_store.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/features/home/widgets/home_favorites_carousel.dart';
import 'package:kaibigan_flutter/features/home/widgets/home_streak_greeting_card.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActivityUsageStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('records today login and loads active dates', () async {
      await ActivityUsageStore.recordTodayLogin();
      final dates = await ActivityUsageStore.loadLoginDates();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(dates.contains(today), isTrue);
    });

    test('increments activity clicks and retrieves count', () async {
      expect(await ActivityUsageStore.loadActivityCounts(), isEmpty);
      await ActivityUsageStore.incrementActivityUsage('mood');
      await ActivityUsageStore.incrementActivityUsage('mood');
      await ActivityUsageStore.incrementActivityUsage('gratitude');

      final counts = await ActivityUsageStore.loadActivityCounts();
      expect(counts['mood'], 2);
      expect(counts['gratitude'], 1);
    });
  });

  group('HomeStreakGreetingCard Widget', () {
    testWidgets('renders greeting name, fire streak badge, and 7 day strip',
        (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomeStreakGreetingCard(
              name: 'Errol',
              language: 'english',
              isDark: false,
              streakCount: 5,
              activeDates: {today},
            ),
          ),
        ),
      );

      expect(find.textContaining('Errol'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-streak-badge')), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);

      expect(find.byKey(const ValueKey('home-7-day-streak-row')), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });
  });

  group('Home Favorites Carousel Widget', () {
    testWidgets('displays only 3 most used activities', (tester) async {
      var tapped = false;
      final favorites = [
        FavoriteActivityData(
          id: 'mood',
          title: 'Mood',
          subtitle: 'Daily check-in',
          accent: Colors.orange,
          assetPath: 'assets/images/characters/routine_focus.png',
          onTap: () => tapped = true,
          usageCount: 10,
        ),
        FavoriteActivityData(
          id: 'gratitude',
          title: 'Gratitude',
          subtitle: 'Plant a flower',
          accent: Colors.green,
          assetPath: 'assets/images/characters/routine_focus.png',
          onTap: () {},
          usageCount: 8,
        ),
        FavoriteActivityData(
          id: 'journal',
          title: 'AI Journal',
          subtitle: 'Reflect freely',
          accent: Colors.amber,
          assetPath: 'assets/images/characters/routine_focus.png',
          onTap: () {},
          usageCount: 5,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HomeFavoritesCarousel(
              favorites: favorites,
              isDark: false,
              language: 'english',
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('home-favorites-carousel')), findsOneWidget);
      expect(find.byKey(const ValueKey('favorite-activity-card-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('favorite-activity-card-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('favorite-activity-card-2')), findsOneWidget);
      expect(find.text('★ #1 Most Used'), findsOneWidget);
      expect(find.text('★ #2 Favorite'), findsOneWidget);
      expect(find.text('★ #3 Frequent'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('favorite-activity-card-0')));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('HomeScreen Integration with Streak and Favorites', () {
    testWidgets('renders streak card and favorites carousel on HomeScreen',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'display_name': 'Errol',
        'selected_companion': 'kai',
        'preferred_language': 'english',
      });
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => GratitudeProvider()),
            ChangeNotifierProvider(create: (_) => LettersProvider()),
            ChangeNotifierProvider(create: (_) => MoodProvider()),
            ChangeNotifierProvider(create: (_) => RoutinesProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home-greeting-streak-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-streak-badge')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-7-day-streak-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-favorites-carousel')), findsOneWidget);
      expect(find.text('My Favorites'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
