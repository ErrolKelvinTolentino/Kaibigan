import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/constants/app_colors.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/routines/flows/progressive_routine_runner.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routine_management_screen.dart';
import 'package:kaibigan_flutter/features/routines/routines_hub_screen.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
    });
  });

  RoutineConfig customRoutine({String id = 'custom-reset'}) {
    return RoutineConfig(
      id: id,
      title: 'Gentle Reset',
      subtitle: 'A short personal sequence',
      type: RoutineType.custom,
      reminderTime: const TimeOfDay(hour: 16, minute: 0),
      primaryColor: AppColors.honeyAmber,
      steps: [
        RoutineStep(
          id: 'first',
          title: 'First activity',
          subtitle: 'Begin here',
          icon: Icons.looks_one_outlined,
          type: StepType.custom,
        ),
        RoutineStep(
          id: 'second',
          title: 'Second activity',
          subtitle: 'Continue here',
          icon: Icons.looks_two_outlined,
          type: StepType.custom,
        ),
      ],
    );
  }

  test('custom routine completion is counted by its real routine id', () {
    final log = RoutineLog(
      id: 'custom-log',
      routineId: 'custom-reset',
      routineType: RoutineType.custom,
      completedAt: DateTime.now(),
    );
    final provider = RoutinesProvider(
      initialLogs: [log],
      syncOnCreate: false,
    )..addCustomRoutine(customRoutine());
    addTearDown(provider.dispose);

    expect(provider.isRoutineCompletedTodayById('custom-reset'), isTrue);
    expect(provider.completedTodayCount, 1);
  });

  test('same-day routine progress restores from local storage', () async {
    final first = RoutinesProvider(syncOnCreate: false);
    first.startRoutineSession('morning');
    first.updateRoutineSession('morning', 2, {'m-focus'});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    first.dispose();

    final restored = RoutinesProvider();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    addTearDown(restored.dispose);

    expect(restored.activeSession?.routineId, 'morning');
    expect(restored.activeSession?.nextStepIndex, 2);
    expect(restored.activeSession?.skippedStepIds, contains('m-focus'));
  });

  test('routine customization survives an app relaunch', () async {
    final first = RoutinesProvider(syncOnCreate: false);
    first.toggleStep('morning', 'm-gratitude');
    first.updateReminderTime('morning', const TimeOfDay(hour: 8, minute: 15));
    first.addCustomRoutine(customRoutine());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    first.dispose();

    final restored = RoutinesProvider();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    addTearDown(restored.dispose);

    final morning = restored.getRoutineById('morning')!;
    expect(
      morning.steps.firstWhere((step) => step.id == 'm-gratitude').isEnabled,
      isFalse,
    );
    expect(morning.reminderTime, const TimeOfDay(hour: 8, minute: 15));
    expect(restored.getRoutineById('custom-reset')?.title, 'Gentle Reset');
  });

  testWidgets('routines menu is clear on phone and opens all activities',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final routines = RoutinesProvider(syncOnCreate: false);
    addTearDown(routines.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider.value(value: routines),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RoutinesHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your daily rhythm'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('recommended-routine-card')), findsOneWidget);
    expect(find.text('Quick practices'), findsOneWidget);

    final seeAll = find.byKey(const ValueKey('see-all-routine-activities'));
    await tester.ensureVisible(seeAll);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('all-routine-activities-screen')),
        findsOneWidget);
    expect(find.text('Choose what you need'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved progress becomes the primary resume action',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final routines = RoutinesProvider(syncOnCreate: false)
      ..updateRoutineSession('morning', 2, {'m-focus'});
    addTearDown(routines.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider.value(value: routines),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RoutinesHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE WHERE YOU LEFT OFF'), findsOneWidget);
    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(find.byKey(const ValueKey('resume-recommended-routine')),
        findsOneWidget);
  });

  testWidgets('routine management remains usable on a narrow phone',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final routines = RoutinesProvider(syncOnCreate: false);
    addTearDown(routines.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: routines,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RoutineManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage routines'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(find.text('Add activity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('runner resumes at the saved activity instead of restarting',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final config = customRoutine(id: 'resume-sequence');
    final routines = RoutinesProvider(syncOnCreate: false)
      ..updateRoutineSession('resume-sequence', 1, const {});
    addTearDown(routines.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider.value(value: routines),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProgressiveRoutineRunner(
            routineType: RoutineType.custom,
            config: config,
            resumeSession: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Second activity'), findsOneWidget);
    expect(find.text('First activity'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
