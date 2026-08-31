import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/future_letters/future_letters_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_logo.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/flows/progressive_routine_runner.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/screens/grounding_session_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/todays_highlight_screen.dart';
import 'package:kaibigan_flutter/features/settings/settings_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
      'routine home state remembers only today’s real completion and highlight',
      () {
    final now = DateTime.now();
    final provider = RoutinesProvider(
      syncOnCreate: false,
      initialLogs: [
        RoutineLog(
          id: 'sleep-note',
          routineId: 'sleep_${now.millisecondsSinceEpoch}',
          routineType: RoutineType.night,
          completedAt: now,
          focusOrHighlight: 'Slept 8 hours',
        ),
        RoutineLog(
          id: 'today-highlight',
          routineId: 'highlight_${now.millisecondsSinceEpoch}',
          routineType: RoutineType.night,
          completedAt: now.subtract(const Duration(minutes: 20)),
          focusOrHighlight: 'An earlier quiet moment.',
        ),
        RoutineLog(
          id: 'latest-highlight',
          routineId: 'highlight_${now.millisecondsSinceEpoch + 1}',
          routineType: RoutineType.night,
          completedAt: now.subtract(const Duration(minutes: 2)),
          focusOrHighlight: 'A quiet dinner together.',
        ),
        RoutineLog(
          id: 'today-routine',
          routineId: 'night',
          routineType: RoutineType.night,
          completedAt: now,
        ),
        RoutineLog(
          id: 'old-highlight',
          routineId: 'highlight_old',
          routineType: RoutineType.night,
          completedAt: now.subtract(const Duration(days: 1)),
          focusOrHighlight: 'Yesterday only',
        ),
      ],
    );

    expect(provider.isRoutineCompletedToday(RoutineType.night), isTrue);
    expect(
        provider.todayHighlight?.focusOrHighlight, 'A quiet dinner together.');
  });

  testWidgets('home resumes the saved routine instead of restarting it',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Errol',
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final routines = RoutinesProvider(syncOnCreate: false);
    final routine = RoutineConfig(
      id: 'home-resume-test',
      title: 'My saved routine',
      subtitle: 'Continue where I stopped',
      type: RoutineType.custom,
      reminderTime: const TimeOfDay(hour: 9, minute: 0),
      primaryColor: Colors.amber,
      steps: [
        RoutineStep(
          id: 'first',
          title: 'First activity',
          subtitle: 'Already finished',
          icon: Icons.looks_one_rounded,
          type: StepType.custom,
        ),
        RoutineStep(
          id: 'second',
          title: 'Second activity',
          subtitle: 'Continue here',
          icon: Icons.looks_two_rounded,
          type: StepType.custom,
        ),
      ],
    );
    routines.addCustomRoutine(routine);
    routines.updateRoutineSession(routine.id, 1, const {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => LettersProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
          ChangeNotifierProvider<RoutinesProvider>.value(value: routines),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RESUME ROUTINE'), findsOneWidget);
    expect(find.textContaining('Second activity'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-routine-card')));
    await tester.pumpAndSettle();

    expect(
      find.byType(ProgressiveRoutineRunner, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Continue here'), findsOneWidget);
    expect(routines.activeSession?.nextStepIndex, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home displays and edits the latest dedicated highlight',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Errol',
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final routines = RoutinesProvider(
      syncOnCreate: false,
      initialLogs: [
        RoutineLog(
          id: 'older-highlight',
          routineId: 'highlight_older',
          routineType: RoutineType.night,
          completedAt: now.subtract(const Duration(hours: 1)),
          focusOrHighlight: 'Older moment',
        ),
        RoutineLog(
          id: 'latest-highlight',
          routineId: 'highlight_latest',
          routineType: RoutineType.night,
          completedAt: now,
          focusOrHighlight: 'Latest bright moment',
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => LettersProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
          ChangeNotifierProvider<RoutinesProvider>.value(value: routines),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Latest bright moment'), findsOneWidget);
    expect(find.textContaining('Older moment'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-highlight-card')),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.drag(
      find.byKey(const ValueKey('home-scroll-view')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-highlight-card')));
    await tester.pumpAndSettle();

    expect(find.byType(TodaysHighlightScreen), findsOneWidget);
    expect(find.text('Latest bright moment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home is a complete navigation surface without a bottom bar',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Errol',
      'selected_companion': 'kai',
      'preferred_language': 'taglish',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => LettersProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
          ChangeNotifierProvider(create: (_) => RoutinesProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kamusta, Errol', findRichText: true), findsOneWidget);
    expect(find.text('Highlight of the day'), findsOneWidget);
    expect(find.text('A NOTE FOR TODAY'), findsOneWidget);
    expect(find.text('Kai'), findsNothing);
    expect(find.byType(ProgressiveRoutineRunner), findsNothing);
    expect(find.byKey(const ValueKey('home-settings-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('adaptive-support-card')),
      160,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Ano kaya ang makakatulong?'), findsOneWidget);
    expect(find.text('Mag-check in muna'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('adaptive-support-card')))
          .height,
      lessThanOrEqualTo(150),
    );

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('wellness-activities-carousel')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('see-all-activities')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('see-all-activities')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('all-activities-menu')), findsOneWidget);
    expect(find.text('All activities'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('English preference translates the home greeting',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Errol',
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => LettersProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
          ChangeNotifierProvider(create: (_) => RoutinesProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi, Errol', findRichText: true), findsOneWidget);
    expect(find.text('Kamusta, Errol', findRichText: true), findsNothing);

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wellness Activities'), findsOneWidget);
  });

  testWidgets('adaptive card opens grounding for a high-stress check-in',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Errol',
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final latest = MoodLog(
      id: 'recent-high-stress',
      moodScore: 3,
      moodLabel: 'Okay',
      stressLevel: 5,
      energyLevel: 3,
      sleepQuality: 3,
      anxietyLevel: 4,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => LettersProvider()),
          ChangeNotifierProvider<MoodProvider>(
            create: (_) => _FakeMoodProvider([latest]),
          ),
          ChangeNotifierProvider(create: (_) => RoutinesProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Come back to the present'), findsOneWidget);
    expect(find.textContaining('Mood 3/5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('adaptive-support-action')));
    await tester.pumpAndSettle();

    expect(find.byType(GroundingSessionScreen), findsOneWidget);
  });

  testWidgets('home surfaces an arrived Future Letter without a navbar',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Errol',
      'selected_companion': 'kai',
      'preferred_language': 'english',
      'affirmation_category_id': 'self_worth',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final arrived = FutureLetter(
      id: 'arrived-letter',
      title: 'A note for today',
      content: 'You made it here.',
      deliverAt: DateTime.now().subtract(const Duration(minutes: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider<LettersProvider>(
            create: (_) => _FakeLettersProvider([arrived]),
          ),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
          ChangeNotifierProvider(create: (_) => RoutinesProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today’s affirmation'), findsNothing);
    expect(
        find.byKey(const ValueKey('today-affirmation-quote')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('today-affirmation-action')), findsNothing);
    expect(find.text('A Future Letter has arrived'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('arrived-future-letter-action')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FutureLettersScreen), findsOneWidget);
  });

  testWidgets('home remains usable on a narrow phone with larger text',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Errol',
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => LettersProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
          ChangeNotifierProvider(create: (_) => RoutinesProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.25),
            ),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(KaibiganLogo), findsOneWidget);
    expect(find.byType(KaibiganWordmark), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wellness-activities-carousel')),
      500,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('wellness-activities-carousel')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mental-health-learning-section')),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mental-health-learning-section')),
      findsOneWidget,
    );
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeMoodProvider extends MoodProvider {
  final List<MoodLog> _fakeLogs;

  _FakeMoodProvider(this._fakeLogs);

  @override
  List<MoodLog> get logs => List.unmodifiable(_fakeLogs);
}

class _FakeLettersProvider extends LettersProvider {
  final List<FutureLetter> _fakeLetters;

  _FakeLettersProvider(this._fakeLetters);

  @override
  List<FutureLetter> get letters => List.unmodifiable(_fakeLetters);
}
