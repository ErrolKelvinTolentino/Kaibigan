import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/offline_mode.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/startup_destination.dart';
import 'package:kaibigan_flutter/features/routines/routine_launch_policy.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OfflineMode.setEnabledForTesting(false);
  });
  tearDown(() => OfflineMode.setEnabledForTesting(false));

  test('page priority is loading, recovery, access/setup, then intro/sign-in',
      () {
    StartupDestination choose(
            {bool loaded = true,
            bool recovery = false,
            bool access = false,
            bool setup = false,
            bool seen = false}) =>
        StartupDestinationPolicy.choose(
            loaded: loaded,
            recovery: recovery,
            canUseApp: access,
            setupComplete: setup,
            demoSeen: seen);
    expect(choose(loaded: false, recovery: true, access: true),
        StartupDestination.loading);
    expect(choose(recovery: true, access: true), StartupDestination.recovery);
    expect(choose(), StartupDestination.demo);
    expect(choose(seen: true), StartupDestination.authentication);
    expect(choose(access: true), StartupDestination.setup);
    expect(choose(access: true, setup: true), StartupDestination.home);
  });

  test('offline companion setup is remembered and legacy choices are retained',
      () async {
    final user = UserProvider();
    await user.ready;
    await user.continueOffline();
    expect(user.hasCompletedSetup, isFalse);
    expect(await user.completeCompanionSetup(), isTrue);
    expect(user.completedSetupThisSession, isTrue);
    user.dispose();
    final restored = UserProvider();
    await restored.ready;
    expect(restored.canUseApp, isTrue);
    expect(restored.hasCompletedSetup, isTrue);
    expect(restored.completedSetupThisSession, isFalse);
    restored.dispose();
    SharedPreferences.setMockInitialValues({
      'offline_mode_enabled': true,
      'selected_companion': 'ann',
      'preferred_language': 'english',
    });
    final legacy = UserProvider();
    await legacy.ready;
    expect(legacy.hasCompletedSetup, isTrue);
    expect(legacy.selectedCompanion, 'ann');
    legacy.dispose();
  });

  test(
      'unreadable settings or history suppress autoplay without deleting the original',
      () async {
    SharedPreferences.setMockInitialValues(
        {'routine_configurations_v1_local': 'unreadable'});
    final badSettings = RoutinesProvider();
    await badSettings.startupReady;
    expect(
        await badSettings.claimStartupRoutine(now: DateTime(2026, 10, 12, 8)),
        isNull);
    expect(badSettings.configurationError, isNotNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('routine_configurations_v1_local'), 'unreadable');
    await badSettings.saveConfigurations();
    expect(badSettings.configurationError, isNull);
    badSettings.dispose();

    SharedPreferences.setMockInitialValues(
        {'kaibigan_local_routine_logs_guest': 'unreadable'});
    final badHistory = RoutinesProvider();
    await badHistory.startupReady;
    expect(await badHistory.claimStartupRoutine(now: DateTime(2026, 10, 12, 8)),
        isNull);
    expect(badHistory.errorMessage, isNotNull);
    badHistory.dispose();
  });

  test('phase boundaries match morning, midday and night periods', () {
    for (final pair in <(int, int, RoutineType)>[
      (4, 59, RoutineType.night),
      (5, 0, RoutineType.morning),
      (11, 59, RoutineType.morning),
      (12, 0, RoutineType.midday),
      (16, 59, RoutineType.midday),
      (17, 0, RoutineType.night),
    ]) {
      expect(
          RoutineLaunchPolicy.phaseAt(DateTime(2026, 10, 12, pair.$1, pair.$2)),
          pair.$3);
    }
  });

  test('startup only launches the current routine after its preferred time',
      () async {
    final routines = RoutinesProvider(syncOnCreate: false);
    addTearDown(routines.dispose);
    expect(await routines.claimStartupRoutine(now: DateTime(2026, 10, 12, 7)),
        isNull);
    expect(
        (await routines.claimStartupRoutine(now: DateTime(2026, 10, 12, 8)))!
            .config
            .id,
        'morning');
    expect(
        await routines.claimStartupRoutine(now: DateTime(2026, 10, 12, 12, 30)),
        isNull);
    expect(
        (await routines.claimStartupRoutine(now: DateTime(2026, 10, 12, 13)))!
            .config
            .id,
        'midday');
  });

  test('completed, disabled and empty routines are not automatic candidates',
      () async {
    final routines = RoutinesProvider(syncOnCreate: false, initialLogs: [
      RoutineLog(
          id: 'done',
          routineId: 'morning',
          routineType: RoutineType.morning,
          completedAt: DateTime(2026, 10, 12, 8)),
    ]);
    addTearDown(routines.dispose);
    expect(await routines.claimStartupRoutine(now: DateTime(2026, 10, 12, 9)),
        isNull);
    routines.toggleRoutineEnabled('midday');
    expect(await routines.claimStartupRoutine(now: DateTime(2026, 10, 12, 14)),
        isNull);
    for (final step in routines.getRoutineById('night')!.steps) {
      routines.toggleStep('night', step.id);
    }
    expect(await routines.claimStartupRoutine(now: DateTime(2026, 10, 12, 22)),
        isNull);
    await routines.flushConfigurationWrites();
  });

  test(
      'a startup offer survives relaunch and concurrent claims launch only once',
      () async {
    final first = RoutinesProvider(syncOnCreate: false);
    final offers = await Future.wait([
      first.claimStartupRoutine(now: DateTime(2026, 10, 12, 8)),
      first.claimStartupRoutine(now: DateTime(2026, 10, 12, 8)),
    ]);
    expect(offers.whereType<RoutineLaunch>(), hasLength(1));
    first.dispose();
    final restored = RoutinesProvider();
    await restored.startupReady;
    addTearDown(restored.dispose);
    expect(await restored.claimStartupRoutine(now: DateTime(2026, 10, 12, 9)),
        isNull);
    expect(
        (await restored.claimStartupRoutine(now: DateTime(2026, 10, 13, 8)))!
            .config
            .id,
        'morning');
  });

  test('night completion remains completed across midnight', () {
    final routines = RoutinesProvider(syncOnCreate: false, initialLogs: [
      RoutineLog(
          id: 'last-night',
          routineId: 'night',
          routineType: RoutineType.night,
          completedAt: DateTime(2026, 10, 11, 23)),
    ]);
    addTearDown(routines.dispose);
    expect(routines.eligibleRoutineAt(DateTime(2026, 10, 12, 1)), isNull);
    expect(routines.eligibleRoutineAt(DateTime(2026, 10, 12, 22))!.config.id,
        'night');
    expect(RoutineLaunchPolicy.offerKey(DateTime(2026, 10, 11, 23)),
        RoutineLaunchPolicy.offerKey(DateTime(2026, 10, 12, 1)));
  });

  test(
      'night session resumes after midnight but expires after the night period',
      () {
    final routines = RoutinesProvider(syncOnCreate: false);
    addTearDown(routines.dispose);
    final night = routines.getRoutineById('night')!;
    final session = RoutineSessionState(
        routineId: 'night',
        nextStepIndex: 2,
        skippedStepIds: {},
        updatedAt: DateTime(2026, 10, 11, 23));
    expect(
        RoutineLaunchPolicy.sessionIsCurrent(
            session, night, DateTime(2026, 10, 12, 1)),
        isTrue);
    expect(
        RoutineLaunchPolicy.sessionIsCurrent(
            session, night, DateTime(2026, 10, 12, 6)),
        isFalse);
  });

  test('a night session started after midnight expires at 5 AM', () {
    final routines = RoutinesProvider(syncOnCreate: false);
    addTearDown(routines.dispose);
    final session = RoutineSessionState(
        routineId: 'night',
        nextStepIndex: 1,
        skippedStepIds: {},
        updatedAt: DateTime(2026, 10, 12, 1));
    expect(
        RoutineLaunchPolicy.sessionIsCurrent(session,
            routines.getRoutineById('night')!, DateTime(2026, 10, 12, 6)),
        isFalse);
  });

  test('custom routine preferred time must match the current phase', () {
    final routines = RoutinesProvider(syncOnCreate: false);
    addTearDown(routines.dispose);
    final custom = routines.getRoutineById('morning')!.copyWith(
        id: 'custom',
        type: RoutineType.custom,
        reminderTime: const TimeOfDay(hour: 14, minute: 0));
    expect(
        RoutineLaunchPolicy.isDue(custom, DateTime(2026, 10, 12, 9)), isFalse);
    expect(
        RoutineLaunchPolicy.isDue(custom, DateTime(2026, 10, 12, 15)), isTrue);
    expect(
        RoutineLaunchPolicy.isDue(custom, DateTime(2026, 10, 12, 22)), isFalse);
  });
}
