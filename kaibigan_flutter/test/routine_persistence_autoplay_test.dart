import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/constants/app_colors.dart';
import 'package:kaibigan_flutter/features/routines/flows/progressive_routine_runner.dart';
import 'package:kaibigan_flutter/features/routines/routine_management_screen.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_hub_screen.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

RoutineConfig personalRoutine() => RoutineConfig(
      id: 'personal-reset',
      title: 'Personal reset',
      subtitle: 'Two small activities',
      type: RoutineType.custom,
      reminderTime: const TimeOfDay(hour: 10, minute: 0),
      primaryColor: AppColors.sageGreen,
      steps: [
        RoutineStep(
            id: 'first',
            title: 'First activity',
            subtitle: 'First prompt',
            icon: Icons.star_outline,
            type: StepType.custom),
        RoutineStep(
            id: 'second',
            title: 'Second activity',
            subtitle: 'Second prompt',
            icon: Icons.star_outline,
            type: StepType.custom),
      ],
    );

Widget app(RoutinesProvider routines, Widget home) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider.value(value: routines),
      ],
      child: MaterialApp(home: home),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(
      {'preferred_language': 'english'}));

  test('downward reordering, rapid changes and custom routines survive reload',
      () async {
    final routines = RoutinesProvider(syncOnCreate: false);
    final originalIds =
        routines.getRoutineById('morning')!.steps.map((s) => s.id).toList();
    routines.reorderSteps('morning', 0, 1);
    expect(routines.getRoutineById('morning')!.steps[1].id, originalIds.first);
    routines.toggleStep('morning', originalIds.first);
    routines.updateReminderTime(
        'morning', const TimeOfDay(hour: 9, minute: 15));
    routines.addCustomRoutine(personalRoutine());
    routines.toggleRoutineEnabled('night');
    await routines.flushConfigurationWrites();
    expect(routines.configurationError, isNull);
    expect(routines.isSavingConfigurations, isFalse);
    routines.dispose();

    final restored = RoutinesProvider();
    await restored.ready;
    addTearDown(restored.dispose);
    final morning = restored.getRoutineById('morning')!;
    expect(morning.steps[1].id, originalIds.first);
    expect(morning.steps[1].isEnabled, isFalse);
    expect(morning.reminderTime, const TimeOfDay(hour: 9, minute: 15));
    expect(restored.getRoutineById('night')!.isEnabled, isFalse);
    expect(restored.getRoutineById('personal-reset')!.steps, hasLength(2));
  });

  test('startup edits preserve untouched saved configurations and deletions',
      () async {
    final first = RoutinesProvider(syncOnCreate: false);
    first.addCustomRoutine(personalRoutine());
    first.updateReminderTime('night', const TimeOfDay(hour: 22, minute: 10));
    await first.flushConfigurationWrites();
    first.dispose();
    final prefs = await SharedPreferences.getInstance();
    final delayedRead = Completer<SharedPreferences>();
    final routines =
        RoutinesProvider(preferencesLoader: () => delayedRead.future);
    routines.toggleStep('morning', 'm-focus');
    delayedRead.complete(prefs);
    await routines.ready;
    await routines.flushConfigurationWrites();
    routines.deleteCustomRoutine('personal-reset');
    await routines.flushConfigurationWrites();
    routines.dispose();
    final restored = RoutinesProvider();
    await restored.ready;
    addTearDown(restored.dispose);
    expect(
        restored
            .getRoutineById('morning')!
            .steps
            .firstWhere((s) => s.id == 'm-focus')
            .isEnabled,
        isFalse);
    expect(restored.getRoutineById('night')!.reminderTime,
        const TimeOfDay(hour: 22, minute: 10));
    expect(restored.getRoutineById('personal-reset'), isNull);
  });

  testWidgets(
      'opening Routines waits for saved settings then autoplays the resumed activity once',
      (tester) async {
    final first = RoutinesProvider(syncOnCreate: false);
    for (final id in ['morning', 'midday', 'night']) {
      first.toggleRoutineEnabled(id);
    }
    first.addCustomRoutine(personalRoutine());
    await first.flushConfigurationWrites();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('routine_active_session_v1_local',
        '{"routineId":"personal-reset","nextStepIndex":1,"skippedStepIds":[],"updatedAt":"${DateTime.now().toIso8601String()}"}');
    first.dispose();

    final delayedRead = Completer<SharedPreferences>();
    final restored =
        RoutinesProvider(preferencesLoader: () => delayedRead.future);
    await tester.pumpWidget(app(restored, const RoutinesHubScreen()));
    await tester.pump();
    expect(find.byType(ProgressiveRoutineRunner), findsNothing);
    delayedRead.complete(prefs);
    await tester.pumpAndSettle();
    expect(find.text('Second prompt'), findsOneWidget);
    expect(find.text('First prompt'), findsNothing);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close routine'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutinesHubScreen), findsOneWidget);
    expect(find.byType(ProgressiveRoutineRunner), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    restored.dispose();
  });

  testWidgets(
      'configuration storage failure is visible and retry persists changes',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    var unavailable = false;
    final routines = RoutinesProvider(preferencesLoader: () async {
      if (unavailable) throw StateError('Storage unavailable');
      return prefs;
    });
    await routines.ready;
    unavailable = true;
    routines.toggleStep('morning', 'm-focus');
    await routines.flushConfigurationWrites();
    expect(routines.configurationError, isNotNull);
    await tester.pumpWidget(app(routines, const RoutineManagementScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-config-save-error')),
        findsOneWidget);
    unavailable = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(routines.configurationError, isNull);
    expect(find.text('Changes saved on this device'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    routines.dispose();
    final restored = RoutinesProvider();
    await restored.ready;
    expect(
        restored
            .getRoutineById('morning')!
            .steps
            .firstWhere((s) => s.id == 'm-focus')
            .isEnabled,
        isFalse);
    restored.dispose();
  });

  test('a failed startup read cannot overwrite saved routines before retry',
      () async {
    final first = RoutinesProvider(syncOnCreate: false);
    first.addCustomRoutine(personalRoutine());
    await first.flushConfigurationWrites();
    first.dispose();
    final prefs = await SharedPreferences.getInstance();
    final original = prefs.getString('routine_configurations_v1_local');
    var unavailable = true;
    final routines = RoutinesProvider(preferencesLoader: () async {
      if (unavailable) throw StateError('Storage unavailable');
      return prefs;
    });
    await routines.ready;
    routines.toggleStep('morning', 'm-focus');
    await routines.flushConfigurationWrites();
    expect(prefs.getString('routine_configurations_v1_local'), original);
    unavailable = false;
    await routines.saveConfigurations();
    expect(routines.configurationError, isNull);
    expect(routines.getRoutineById('personal-reset'), isNotNull);
    routines.dispose();
  });

  testWidgets(
      'fresh autoplay follows the saved order and skips disabled activities',
      (tester) async {
    final first = RoutinesProvider(syncOnCreate: false);
    for (final id in ['morning', 'midday', 'night']) {
      first.toggleRoutineEnabled(id);
    }
    first.addCustomRoutine(personalRoutine());
    first.reorderSteps('personal-reset', 0, 1);
    first.toggleStep('personal-reset', 'first');
    await first.flushConfigurationWrites();
    first.dispose();

    final restored = RoutinesProvider();
    await tester.pumpWidget(app(restored, const RoutinesHubScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Second prompt'), findsOneWidget);
    expect(find.text('First prompt'), findsNothing);
    expect(restored.activeSession?.nextStepIndex, 0);
    expect(restored.activeSession?.routineId, 'personal-reset');
    await tester.pumpWidget(const SizedBox.shrink());
    restored.dispose();
  });
}
