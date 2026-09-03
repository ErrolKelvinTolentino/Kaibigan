import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/future_letters/future_letters_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_logo.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/flows/progressive_routine_runner.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
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
          id: 'placeholder-highlight',
          routineId: 'highlight_placeholder',
          routineType: RoutineType.night,
          completedAt: now.subtract(const Duration(minutes: 1)),
          focusOrHighlight: 'Sample',
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

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-routine-card')),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
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

    expect(find.byKey(const ValueKey('daily-path-details')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('see-all-activities')),
      500,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('see-all-activities')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('see-all-activities')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today\'s highlight'));
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
    expect(find.text('Today with Kai'), findsNothing);
    expect(find.byKey(const ValueKey('companion-loop-overview')), findsNothing);
    expect(find.byKey(const ValueKey('daily-path-details')), findsNothing);
    expect(find.text('Today’s highlight'), findsOneWidget);
    expect(find.byType(ProgressiveRoutineRunner), findsNothing);
    expect(find.byKey(const ValueKey('home-settings-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('adaptive-support-card')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wellness-activities-carousel')),
      240,
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

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('wellness-activities-carousel')),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Activities'), findsOneWidget);
  });

  testWidgets('mood data does not replace the requested home hierarchy',
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

    expect(find.byKey(const ValueKey('adaptive-support-card')), findsNothing);
    expect(find.text('Today’s highlight'), findsOneWidget);
    expect(find.text('Today with Kai'), findsNothing);
  });
  testWidgets('home does not surface a saved journal as a Kai workflow',
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
          ChangeNotifierProvider(create: (_) => LettersProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
          ChangeNotifierProvider(create: (_) => RoutinesProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Talk with Kai'), findsNothing);
    expect(find.text('Continue with Kai'), findsNothing);
    expect(find.byKey(const ValueKey('daily-path-details')), findsNothing);
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

    final home = tester.widget<CustomScrollView>(
      find.byKey(const ValueKey('home-scroll-view')),
    );
    final orderedBlocks = home.slivers
        .map((sliver) => sliver.key)
        .whereType<ValueKey<String>>()
        .map((key) => key.value)
        .where((key) => key.endsWith('-block'))
        .toList();
    expect(
      orderedBlocks,
      [
        'home-greeting-block',
        'home-favorites-block',
        'home-highlight-block',
        'home-future-self-block',
        'home-affirmation-block',
        'home-routine-block',
        'home-activities-block',
        'home-learn-block',
      ],
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home-future-self-note')),
      220,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('home-future-self-note')),
      findsOneWidget,
    );
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

class _FakeLettersProvider extends LettersProvider {
  final List<FutureLetter> _fakeLetters;

  _FakeLettersProvider(this._fakeLetters);

  @override
  List<FutureLetter> get letters => List.unmodifiable(_fakeLetters);
}
