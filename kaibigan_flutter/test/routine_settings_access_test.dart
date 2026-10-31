import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/features/routines/flows/progressive_routine_runner.dart';
import 'package:kaibigan_flutter/features/routines/routine_management_screen.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/settings_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
        'preferred_language': 'english',
        'affirmation_category_id': 'self_worth'
      }));

  Future<void> open(WidgetTester tester, Widget home, RoutinesProvider routines,
      {double textScale = 1}) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider.value(value: routines),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: home,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!),
        )));
    await tester.pumpAndSettle();
  }

  for (final disabled in [false, true]) {
    testWidgets(
        'Home opens routine settings with routines ${disabled ? 'disabled' : 'enabled'} without starting a session',
        (tester) async {
      final routines = RoutinesProvider(syncOnCreate: false);
      await routines.ready;
      if (disabled) {
        for (final routine in routines.allRoutines) {
          if (routine.isEnabled) routines.toggleRoutineEnabled(routine.id);
        }
        await routines.flushConfigurationWrites();
      }
      await open(tester, const HomeScreen(), routines, textScale: 1.6);
      final button = find.byKey(const ValueKey('home-routine-settings'));
      await tester.scrollUntilVisible(button.hitTestable(), 220,
          scrollable: find
              .descendant(
                  of: find.byKey(const ValueKey('home-scroll-view')),
                  matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(RoutineManagementScreen), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(find.byType(ProgressiveRoutineRunner), findsNothing);
      expect(routines.activeSession, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      routines.dispose();
    });
  }

  testWidgets(
      'Settings opens the same routine editor and keeps an unfinished session',
      (tester) async {
    final routines = RoutinesProvider(syncOnCreate: false);
    await routines.ready;
    routines.updateRoutineSession('morning', 1, const {});
    final session = routines.activeSession;
    await open(tester, const SettingsScreen(), routines);
    final tile = find.byKey(const ValueKey('settings-routine-settings'));
    await tester.ensureVisible(tile);
    await tester.tap(
        find.descendant(of: tile, matching: find.text('Routine settings')));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineManagementScreen), findsOneWidget);
    expect(find.byType(ProgressiveRoutineRunner), findsNothing);
    expect(routines.activeSession?.routineId, session?.routineId);
    expect(routines.activeSession?.nextStepIndex, session?.nextStepIndex);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    routines.dispose();
  });
}
