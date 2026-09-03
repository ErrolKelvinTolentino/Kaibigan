import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/constants/app_colors.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_model.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_planting_page.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/flows/progressive_routine_runner.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

class _TestGratitudeProvider extends GratitudeProvider {
  final List<GratitudeEntry> _testEntries = [];

  @override
  List<GratitudeEntry> get entries => List.unmodifiable(_testEntries);

  @override
  Future<GratitudeEntry?> addGratitudeEntry(
    String content, {
    String flowerType = 'anemone',
    bool shareToCommunity = false,
    int? gardenIndex,
  }) async {
    final entry = GratitudeEntry(
      id: 'test-flower-1',
      content: content,
      flowerType: flowerType,
      gardenIndex: gardenIndex ?? 0,
      plotIndex: _testEntries.length,
      createdAt: DateTime.now(),
    );
    _testEntries.add(entry);
    notifyListeners();
    return entry;
  }
}

Widget createTestApp(Widget child, {GratitudeProvider? gratitudeProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => RoutinesProvider()),
      ChangeNotifierProvider(
        create: (_) => gratitudeProvider ?? _TestGratitudeProvider(),
      ),
      ChangeNotifierProvider(create: (_) => MoodProvider()),
      ChangeNotifierProvider(create: (_) => JournalProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
  });

  testWidgets('Current progress is clearly visible during routine activities',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final config = RoutineConfig(
      id: 'test-progress-routine',
      title: 'Morning Routine',
      subtitle: 'Testing progress visibility',
      type: RoutineType.morning,
      reminderTime: const TimeOfDay(hour: 8, minute: 0),
      primaryColor: AppColors.sageGreen,
      steps: [
        RoutineStep(
          id: 'step-1',
          title: 'First Step',
          subtitle: 'Step one',
          icon: Icons.check,
          type: StepType.custom,
        ),
        RoutineStep(
          id: 'step-2',
          title: 'Second Step',
          subtitle: 'Step two',
          icon: Icons.check,
          type: StepType.custom,
        ),
      ],
    );

    await tester.pumpWidget(createTestApp(ProgressiveRoutineRunner(
      routineType: RoutineType.morning,
      config: config,
    )));
    await tester.pumpAndSettle();

    // The routine progress bar and step indicator must be visible on screen
    expect(find.byKey(const ValueKey('routine-activity-progress-bar')),
        findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Morning Routine • First Step'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-activity-progress-0')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('skip-routine-activity')), findsOneWidget);

    // Complete first step
    await tester.tap(find.text('Complete activity'));
    await tester.pumpAndSettle();

    // Now on step 2
    expect(find.byKey(const ValueKey('routine-activity-progress-bar')),
        findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Morning Routine • Second Step'), findsOneWidget);
  });

  testWidgets('Gratitude planting displays bloomed success page before continuing',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var saved = false;

    await tester.pumpWidget(createTestApp(GratitudePlantingPage(
      gardenIndex: 0,
      onSaved: () => saved = true,
    )));
    await tester.pumpAndSettle();

    // Enter note
    await tester.enterText(
      find.byKey(const ValueKey('gratitude-planting-field')),
      'The beautiful morning sunshine.',
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-flower')));
    await tester.pumpAndSettle();

    // Confirm plant
    await tester.tap(find.byKey(const ValueKey('confirm-plant-flower')));
    await tester.pumpAndSettle();

    // The bloomed success page must be shown and NOT cancelled!
    expect(find.byKey(const ValueKey('gratitude-bloomed-step')), findsOneWidget);
    expect(find.textContaining('The beautiful morning sunshine.'), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-after-planting')), findsOneWidget);
    expect(saved, isFalse);

    // Only tapping continue completes the flow
    await tester.tap(find.byKey(const ValueKey('continue-after-planting')));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
  });

  testWidgets(
      'Success page of the last activity is shown before routine completion',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    // Routine where the single/last activity is meditation
    final config = RoutineConfig(
      id: 'last-meditation-routine',
      title: 'Breathing Routine',
      subtitle: 'Single meditation step',
      type: RoutineType.custom,
      reminderTime: const TimeOfDay(hour: 8, minute: 0),
      primaryColor: AppColors.honeyAmber,
      steps: [
        RoutineStep(
          id: 'b-1',
          title: '30-second breathing reset',
          subtitle: 'Breathing reset',
          icon: Icons.air,
          type: StepType.meditation,
        ),
      ],
    );

    await tester.pumpWidget(createTestApp(ProgressiveRoutineRunner(
      routineType: RoutineType.custom,
      config: config,
    )));
    await tester.pumpAndSettle();

    // Begin breathing
    await tester.tap(find.byKey(const ValueKey('begin-routine-breathing-button')));
    await tester.pump();
    expect(find.text('00:30'), findsOneWidget);

    // Fast-forward 30 seconds
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();

    // The breathing success page MUST be shown, NOT cancelled by routine completion!
    expect(find.byKey(const ValueKey('breathing-complete')), findsOneWidget);
    expect(find.text('Routine completed! ✨'), findsNothing);

    // Tap continue on the breathing complete screen
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // NOW routine completion is shown
    expect(find.text('Routine completed! ✨'), findsOneWidget);
    expect(find.byKey(const ValueKey('finish-routine')), findsOneWidget);
  });
}
