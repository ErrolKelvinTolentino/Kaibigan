import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/constants/app_colors.dart';
import 'package:kaibigan_flutter/core/constants/app_typography.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/theme/kaibigan_tokens.dart';
import 'package:kaibigan_flutter/core/widgets/cozy_confirm_sheet.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_screen.dart';
import 'package:kaibigan_flutter/features/comfort_corner/comfort_corner_screen.dart';
import 'package:kaibigan_flutter/features/comfort_corner/comfort_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/garden_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/future_letters_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_list_screen.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_tracker_screen.dart';
import 'package:kaibigan_flutter/features/routines/routines_hub_screen.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/settings_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:kaibigan_flutter/features/unified_entries/unified_entries_screen.dart';
import 'package:kaibigan_flutter/features/wellness_journey/journey_screen.dart';
import 'package:kaibigan_flutter/features/weekly_reflection/weekly_reflection_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('bee design system provides consistent tactile component themes', () {
    expect(
        const CozyPageTransitionsBuilder(), isA<CozyPageTransitionsBuilder>());
    expect(AppColors.pollenGlow, const Color(0xFFFFE7A3));
    expect(AppColors.honeySurface, const Color(0xFFFFFCF5));
    double contrast(Color a, Color b) {
      final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
      final darker = identical(lighter, a) ? b : a;
      return (lighter.computeLuminance() + 0.05) /
          (darker.computeLuminance() + 0.05);
    }

    expect(
      contrast(
        KaibiganPalette.light.accent,
        KaibiganPalette.light.onAccent,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(
        KaibiganPalette.dark.accent,
        KaibiganPalette.dark.onAccent,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(
        KaibiganPalette.dark.textPrimary,
        KaibiganPalette.dark.background,
      ),
      greaterThanOrEqualTo(7),
    );
    expect(
      contrast(
        KaibiganPalette.dark.textSecondary,
        KaibiganPalette.dark.background,
      ),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.onHoney, AppColors.honeyAmber),
      greaterThanOrEqualTo(4.5),
    );
    for (final accent in [
      AppColors.honeyAmber,
      AppColors.honeyGold,
      AppColors.sageGreen,
      AppColors.softRose,
      AppColors.skyBlue,
      AppColors.lavenderMist,
    ]) {
      expect(
        contrast(AppColors.readableOn(accent), accent),
        greaterThanOrEqualTo(4.5),
        reason: 'Readable foreground for $accent',
      );
    }
  });

  testWidgets('wellness journey has a responsive honest empty state on phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => GratitudeProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: AppColors.honeyAmber,
          ),
          home: const JourneyScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Your Journey'), findsOneWidget);
    expect(find.text('Notice how you are growing'), findsOneWidget);
    expect(find.text('Start today'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your first moment starts here'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comfort corner guides breathing and grounding without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ComfortProvider(),
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: AppColors.honeyAmber,
          ),
          home: const ComfortCornerScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Come back to yourself'), findsOneWidget);
    expect(find.text('4–7–8 guided breathing'), findsOneWidget);
    expect(find.text('5 Things You Can See'), findsOneWidget);

    await tester.ensureVisible(find.text('Next sense'));
    await tester.tap(find.text('Next sense'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('4 Things You Can Touch'), findsOneWidget);
    expect(find.text('2 of 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary hubs fit a 320px phone without persistent navigation',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'display_name': 'Friend',
    });
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final screens = <Widget>[
      const AffirmationsScreen(),
      const MoodTrackerScreen(),
      const RoutinesHubScreen(),
      const JournalListScreen(),
      const UnifiedEntriesScreen(),
      const SettingsScreen(),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => GratitudeProvider()),
            ChangeNotifierProvider(create: (_) => MoodProvider()),
            ChangeNotifierProvider(create: (_) => RoutinesProvider()),
          ],
          child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    }
  });

  testWidgets(
      'night theme keeps primary mobile flows readable and free of overflow',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'display_name': 'Friend',
      'is_dark_mode': true,
    });
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final screens = <Widget>[
      const AffirmationsScreen(),
      const MoodTrackerScreen(),
      const RoutinesHubScreen(),
      const JournalListScreen(),
      const GardenScreen(),
      const FutureLettersScreen(),
      const UnifiedEntriesScreen(),
      const WeeklyReflectionScreen(),
      const SettingsScreen(),
    ];

    for (final screen in screens) {
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
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.2),
              ),
              child: child!,
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    }
  });

  testWidgets('legacy typography defaults follow the active night theme',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Text(
            'Night copy',
            style: AppTypography.titleLarge(context),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Night copy'));
    expect(text.style?.color, KaibiganPalette.dark.textPrimary);
  });

  testWidgets('confirmation sheet reflows on a narrow phone with large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => CozyConfirmSheet.show(
                  context,
                  title: 'Remove this saved reflection?',
                  message:
                      'This cannot be undone, but the rest of your journal stays safe.',
                  confirmLabel: 'Remove reflection',
                  cancelLabel: 'Keep reflection',
                ),
                child: const Text('Open confirmation'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();

    expect(find.text('Remove reflection'), findsOneWidget);
    expect(find.text('Keep reflection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mood check-in shows every mood and feeling without disclosure',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'display_name': 'Friend',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MoodTrackerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.byTooltip('View mood history'), findsOneWidget);
    expect(find.byKey(const ValueKey('mood-expression-list')), findsOneWidget);

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Inspired'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Drained'), findsOneWidget);
    expect(find.text('More feelings'), findsNothing);
    expect(find.text('Show fewer feelings'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
