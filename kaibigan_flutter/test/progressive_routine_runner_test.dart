import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/constants/app_colors.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_planting_page.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/garden_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_tracker_screen.dart';
import 'package:kaibigan_flutter/features/routines/flows/progressive_routine_runner.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/routines/widgets/routine_activity_frame.dart';
import 'package:kaibigan_flutter/features/routines/screens/grounding_session_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/mindfulness_meditation_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/sleep_log_flow_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/todays_focus_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/todays_highlight_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
  });

  Widget testApp({RoutineConfig? config, Iterable<RoutineLog> initialLogs = const []}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(
          create: (_) => RoutinesProvider(
            initialLogs: initialLogs,
            syncOnCreate: initialLogs.isEmpty,
          ),
        ),
        ChangeNotifierProvider(create: (_) => GratitudeProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProgressiveRoutineRunner(
          routineType: config?.type ?? RoutineType.morning,
          config: config,
        ),
      ),
    );
  }

  Future<void> pumpRoutine(
    WidgetTester tester, {
    RoutineConfig? config,
    Iterable<RoutineLog> initialLogs = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(testApp(config: config, initialLogs: initialLogs));
    await tester.pumpAndSettle();
  }

  RoutineConfig configFor(StepType type) {
    return RoutineConfig(
      id: 'parity-${type.name}',
      title: 'Parity Routine',
      subtitle: 'Test the canonical activity route',
      type: RoutineType.custom,
      reminderTime: const TimeOfDay(hour: 8, minute: 0),
      primaryColor: AppColors.honeyAmber,
      steps: [
        RoutineStep(
          id: 'step-${type.name}',
          title: 'Canonical ${type.name}',
          subtitle: 'Uses the full feature',
          icon: Icons.check_circle_outline_rounded,
          type: type,
        ),
      ],
    );
  }

  testWidgets('autoplay opens the real first activity and pauses on close',
      (tester) async {
    await pumpRoutine(tester);

    expect(find.byType(GratitudePlantingPage), findsOneWidget);
    expect(find.byType(GardenScreen), findsNothing);
    expect(find.text('A gratitude moment'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Routine paused'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('resume-routine-activity')), findsOneWidget);

    // One progress segment per activity in the routine, so the count follows
    // the routine's real shape rather than a number frozen into the test.
    final strip = tester.widget<RoutineProgressStrip>(
      find.byType(RoutineProgressStrip),
    );
    final stepCount = strip.steps.length;
    expect(stepCount, greaterThan(1));
    for (var index = 0; index < stepCount; index++) {
      expect(find.byKey(ValueKey('routine-progress-$index')), findsOneWidget);
    }
    expect(
      find.byKey(ValueKey('routine-progress-$stepCount')),
      findsNothing,
    );
  });

  testWidgets('autoplay advances only after an activity reports completion',
      (tester) async {
    final config = RoutineConfig(
      id: 'custom-sequence',
      title: 'Custom Sequence',
      subtitle: 'Two explicit completion steps',
      type: RoutineType.custom,
      reminderTime: const TimeOfDay(hour: 8, minute: 0),
      primaryColor: AppColors.honeyAmber,
      steps: [
        RoutineStep(
          id: 'first',
          title: 'First activity',
          subtitle: 'First prompt',
          icon: Icons.looks_one_outlined,
          type: StepType.custom,
        ),
        RoutineStep(
          id: 'second',
          title: 'Second activity',
          subtitle: 'Second prompt',
          icon: Icons.looks_two_outlined,
          type: StepType.custom,
        ),
      ],
    );

    await pumpRoutine(tester, config: config);
    expect(find.text('First activity'), findsOneWidget);

    await tester.tap(find.text('Complete activity'));
    await tester.pumpAndSettle();
    expect(find.text('Second activity'), findsOneWidget);

    await tester.tap(find.text('Complete activity'));
    await tester.pumpAndSettle();
    expect(find.text('Routine completed! ✨'), findsOneWidget);
    expect(find.byKey(const ValueKey('finish-routine')), findsOneWidget);
  });

  testWidgets('routine highlight reopens with today\'s saved text',
      (tester) async {
    final now = DateTime.now();
    final config = configFor(StepType.journalHighlight);

    await pumpRoutine(
      tester,
      config: config,
      initialLogs: [
        RoutineLog(
          id: 'today-highlight',
          routineId: 'highlight_${now.millisecondsSinceEpoch}',
          routineType: RoutineType.night,
          completedAt: now,
          focusOrHighlight: 'I put the kettle on and felt calm.',
        ),
      ],
    );

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller?.text,
        'I put the kettle on and felt calm.');
    expect(find.text('Update this moment'), findsOneWidget);
  });

  testWidgets('today\'s focus explains its purpose', (tester) async {
    await pumpRoutine(tester, config: configFor(StepType.journalFocus));

    expect(
      find.text(
        'Purpose: choose one meaningful intention to gently guide your attention today.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('every routine activity can be skipped without being completed',
      (tester) async {
    final config = RoutineConfig(
      id: 'skippable-sequence',
      title: 'Skippable Sequence',
      subtitle: 'Two optional activities',
      type: RoutineType.custom,
      reminderTime: const TimeOfDay(hour: 8, minute: 0),
      primaryColor: AppColors.honeyAmber,
      steps: [
        RoutineStep(
          id: 'first-skip',
          title: 'First optional activity',
          subtitle: 'First prompt',
          icon: Icons.looks_one_outlined,
          type: StepType.custom,
        ),
        RoutineStep(
          id: 'second-skip',
          title: 'Second optional activity',
          subtitle: 'Second prompt',
          icon: Icons.looks_two_outlined,
          type: StepType.custom,
        ),
      ],
    );

    await pumpRoutine(tester, config: config);
    expect(find.text('First optional activity'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skip-routine-activity')));
    await tester.pumpAndSettle();

    expect(find.text('Second optional activity'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skip-routine-activity')));
    await tester.pumpAndSettle();

    // Skipping everything is not a completed routine, and the closing screen
    // says so rather than congratulating work that never happened.
    expect(find.text('A pause is okay, too'), findsOneWidget);
    expect(find.text('Routine completed! ✨'), findsNothing);
    expect(find.textContaining('skipped 2 activities'), findsOneWidget);
  });

  final canonicalScreens = <StepType, Type>{
    StepType.gratitudeGarden: GratitudePlantingPage,
    StepType.journalFocus: TodaysFocusScreen,
    StepType.journalHighlight: TodaysHighlightScreen,
    StepType.moodTracker: MoodTrackerScreen,
    StepType.grounding: GroundingSessionScreen,
    StepType.meditation: MindfulnessMeditationScreen,
    StepType.sleepTracker: SleepLogFlowScreen,
  };

  for (final entry in canonicalScreens.entries) {
    testWidgets('autoplay maps ${entry.key.name} to its canonical screen',
        (tester) async {
      await pumpRoutine(tester, config: configFor(entry.key));

      expect(find.byType(entry.value), findsOneWidget);
      expect(
        find.byKey(const ValueKey('skip-routine-activity')),
        findsOneWidget,
      );
      if (entry.key == StepType.grounding) {
        expect(find.byKey(const ValueKey('grounding-step-3')), findsOneWidget);
        expect(find.byKey(const ValueKey('grounding-intro')), findsNothing);
      }
      if (entry.key == StepType.meditation) {
        expect(
          find.byKey(const ValueKey('breathing-routine-setup')),
          findsOneWidget,
        );
        expect(find.text('A 30-second reset'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
