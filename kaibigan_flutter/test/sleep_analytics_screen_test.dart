import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/constants/app_colors.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/theme/kaibigan_tokens.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/routines/screens/sleep_analytics_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/sleep_log_flow_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Friend',
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
  });

  group('ParsedSleepLog', () {
    test('correctly parses sleep feeling, hours and description', () {
      final now = DateTime.now();
      final log = RoutineLog(
        id: 'log-1',
        routineId: 'sleep_123',
        routineType: RoutineType.morning,
        sleepFeeling: SleepFeeling.energized,
        focusOrHighlight: 'Slept 8 hrs: Fully recharged and excited',
        completedAt: now,
      );

      final parsed = ParsedSleepLog.tryParse(log);
      expect(parsed, isNotNull);
      expect(parsed!.feeling, SleepFeeling.energized);
      expect(parsed.hours, 8.0);
      expect(parsed.description, 'Slept 8 hrs: Fully recharged and excited');
    });

    test('handles less than 1 hour and 10+ hours formats', () {
      final now = DateTime.now();
      final log1 = RoutineLog(
        id: 'log-short',
        routineId: 'sleep_short',
        routineType: RoutineType.morning,
        sleepFeeling: SleepFeeling.restless,
        focusOrHighlight: 'Slept Less than 1 hrs: Tossed and turned',
        completedAt: now,
      );
      final log2 = RoutineLog(
        id: 'log-long',
        routineId: 'sleep_long',
        routineType: RoutineType.morning,
        sleepFeeling: SleepFeeling.wellRested,
        focusOrHighlight: 'Slept 10+ hrs: Deep rest',
        completedAt: now,
      );

      final parsed1 = ParsedSleepLog.tryParse(log1);
      final parsed2 = ParsedSleepLog.tryParse(log2);

      expect(parsed1?.hours, 0.5);
      expect(parsed2?.hours, 10.0);
    });

    test('returns null for non-sleep routine logs', () {
      final log = RoutineLog(
        id: 'focus-log',
        routineId: 'm-focus',
        routineType: RoutineType.morning,
        focusOrHighlight: 'Finish the presentation today',
        completedAt: DateTime.now(),
      );

      final parsed = ParsedSleepLog.tryParse(log);
      expect(parsed, isNull);
    });
  });

  group('SleepAnalyticsScreen widget', () {
    Widget buildScreen({List<RoutineLog> initialLogs = const []}) {
      final routinesProvider = RoutinesProvider(
        initialLogs: initialLogs,
        syncOnCreate: false,
      );
      final userProvider = UserProvider();

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<RoutinesProvider>.value(
              value: routinesProvider),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepAnalyticsScreen(),
        ),
      );
    }

    testWidgets('shows empty state when no sleep logs exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen(initialLogs: []));
      await tester.pumpAndSettle();

      expect(find.text('Sleep Analytics'), findsOneWidget);
      expect(find.text('No sleep logs yet'), findsOneWidget);
      expect(find.text('Log Your First Sleep'), findsOneWidget);
      expect(find.text('Log Sleep'), findsOneWidget);
    });

    testWidgets(
        'renders analytics cards, clear seven-night summary, and distribution',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final now = DateTime.now();
      final logs = [
        RoutineLog(
          id: 's-1',
          routineId: 'sleep_1',
          routineType: RoutineType.morning,
          sleepFeeling: SleepFeeling.wellRested,
          focusOrHighlight: 'Slept 8 hrs: Woke up feeling peaceful and clear',
          completedAt: now,
        ),
        RoutineLog(
          id: 's-2',
          routineId: 'sleep_2',
          routineType: RoutineType.morning,
          sleepFeeling: SleepFeeling.energized,
          focusOrHighlight: 'Slept 7.5 hrs: Fully recharged and excited',
          completedAt: now.subtract(const Duration(days: 1)),
        ),
        RoutineLog(
          id: 's-3',
          routineId: 'sleep_3',
          routineType: RoutineType.morning,
          sleepFeeling: SleepFeeling.moderate,
          focusOrHighlight: 'Slept 6 hrs: Slept okay, ready for the day',
          completedAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      await tester.pumpWidget(buildScreen(initialLogs: logs));
      await tester.pumpAndSettle();

      expect(find.text('Sleep Analytics'), findsOneWidget);
      expect(find.text("Kai's Sleep Check"), findsOneWidget);
      expect(find.text('Average Rest'), findsOneWidget);
      expect(find.text('7.2 hrs'),
          findsOneWidget); // (8 + 7.5 + 6) / 3 = 7.166 -> 7.2
      expect(find.text('Your last 7 nights'), findsOneWidget);
      expect(
        find.text(
          'Each row shows what you logged and how it compares with your 7–9 hour guide.',
        ),
        findsOneWidget,
      );
      expect(find.text('3 of 7 logged'), findsOneWidget);
      expect(find.byKey(const ValueKey('sleep-rhythm-list')), findsOneWidget);
      expect(find.textContaining('Within guide'), findsNWidgets(2));
      expect(find.textContaining('Below guide'), findsOneWidget);
      expect(find.text('7-Day Sleep Rhythm'), findsNothing);
      expect(find.text('Tap a day for details'), findsNothing);
      expect(find.text('Sleep Quality Distribution'), findsOneWidget);
      expect(find.text('Sleep Hygiene Principles'), findsOneWidget);

      final principleTitle = tester.widget<Text>(
        find.text('Anchor your wake time'),
      );
      expect(
        principleTitle.style?.color,
        AppTheme.lightTheme.extension<KaibiganPalette>()!.textPrimary,
      );

      final logButton = tester.widget<FloatingActionButton>(
        find.byKey(const ValueKey('sleep-log-button')),
      );
      expect(logButton.backgroundColor, AppColors.honeyGold);
      expect(logButton.foregroundColor, AppColors.onHoney);
    });

    testWidgets('switches to history tab and displays past logs',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final now = DateTime.now();
      final logs = [
        RoutineLog(
          id: 's-1',
          routineId: 'sleep_1',
          routineType: RoutineType.morning,
          sleepFeeling: SleepFeeling.wellRested,
          focusOrHighlight: 'Slept 8 hrs: Peaceful morning',
          completedAt: now,
        ),
      ];

      await tester.pumpWidget(buildScreen(initialLogs: logs));
      await tester.pumpAndSettle();

      // Tap on the History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('Well Rested'), findsWidgets);
      expect(find.text('8.0 hrs'), findsOneWidget);
      expect(find.text('Slept 8 hrs: Peaceful morning'), findsOneWidget);
    });

    testWidgets('tapping Log Sleep opens SleepLogFlowScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen(initialLogs: []));
      await tester.pumpAndSettle();

      // Tap the floating Log Sleep button
      await tester.tap(find.text('Log Sleep'));
      await tester.pumpAndSettle();

      expect(find.byType(SleepLogFlowScreen), findsOneWidget);
      expect(find.text('How was your sleep last night?'), findsOneWidget);
    });
  });

  group('SleepLogFlowScreen widget', () {
    Widget buildLogger() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<RoutinesProvider>(
            create: (_) => RoutinesProvider(
              initialLogs: const [],
              syncOnCreate: false,
            ),
          ),
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepLogFlowScreen(),
        ),
      );
    }

    testWidgets('stays usable on a compact phone through duration selection',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildLogger());
      await tester.pumpAndSettle();

      expect(find.text('How was your sleep last night?'), findsOneWidget);
      await tester.tap(find.text('Fully Energized'));
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('About how long did you sleep?'), findsOneWidget);
      expect(find.text('Fully Energized  •  7 hours'), findsOneWidget);

      await tester.tap(find.text('8 h'));
      await tester.pump();

      expect(find.text('8 hours'), findsOneWidget);
      expect(find.text('Fully Energized  •  8 hours'), findsOneWidget);
    });
  });
}
