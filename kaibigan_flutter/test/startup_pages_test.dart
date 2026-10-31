import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/mascot_selection_screen.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/reset_password_screen.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/startup_home_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/main_navigation_screen.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/flows/progressive_routine_runner.dart';
import 'package:kaibigan_flutter/features/routines/routine_launch_policy.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:kaibigan_flutter/features/settings/settings_screen.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/auth_screen.dart';
import 'package:kaibigan_flutter/core/services/ui_sound_service.dart';
import 'package:kaibigan_flutter/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecoveryUser extends UserProvider {
  @override
  bool get isPasswordRecovery => true;
}

class StartupRoutines extends RoutinesProvider {
  StartupRoutines({this.offer = false}) : super(syncOnCreate: false);
  final bool offer;
  int claims = 0;

  @override
  Future<RoutineLaunch?> claimStartupRoutine({DateTime? now}) async {
    claims++;
    if (!offer) return null;
    return RoutineLaunch(RoutineConfig(
        id: 'test-reset',
        title: 'Small reset',
        subtitle: 'A saved routine',
        type: RoutineType.custom,
        reminderTime: const TimeOfDay(hour: 12, minute: 0),
        primaryColor: Colors.green,
        steps: [
          RoutineStep(
              id: 'test-step',
              title: 'A quiet pause',
              subtitle: 'Take a moment here',
              icon: Icons.spa_outlined,
              type: StepType.custom)
        ]));
  }
}

class SlowStartupRoutines extends StartupRoutines {
  final history = Completer<void>();
  @override
  Future<void> get startupReady => history.future;
}

Widget app(UserProvider user, RoutinesProvider routines) =>
    MultiProvider(providers: [
      ChangeNotifierProvider<UserProvider>.value(value: user),
      ChangeNotifierProvider<RoutinesProvider>.value(value: routines),
      ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
      ChangeNotifierProvider(create: (_) => JournalProvider()),
      ChangeNotifierProvider(create: (_) => GratitudeProvider()),
      ChangeNotifierProvider(create: (_) => MoodProvider()),
      ChangeNotifierProvider(create: (_) => LettersProvider()),
    ], child: const MaterialApp(home: AuthGate()));

void main() {
  testWidgets('slow routine history falls back to Home and cannot launch late',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'offline_mode_enabled': true,
      'companion_setup_v1_offline:guest': true,
      'user_pref_offline:guest_selected_companion': 'kai',
      'user_pref_offline:guest_preferred_language': 'english',
    });
    final user = UserProvider();
    await user.ready;
    final routines = SlowStartupRoutines();
    await tester.pumpWidget(app(user, routines));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(routines.claims, 0);
    routines.history.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ProgressiveRoutineRunner), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    user.dispose();
    routines.dispose();
  });
  testWidgets(
      'leaving offline mode removes protected routes and resets navigation',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'offline_mode_enabled': true,
      'companion_setup_v1_offline:guest': true,
      'user_pref_offline:guest_selected_companion': 'kai',
      'user_pref_offline:guest_preferred_language': 'english',
      'user_pref_offline:guest_kai_value_demo_seen_v1': true,
    });
    final seed = RoutinesProvider(syncOnCreate: false);
    for (final id in ['morning', 'midday', 'night']) {
      seed.toggleRoutineEnabled(id);
    }
    await seed.flushConfigurationWrites();
    seed.dispose();
    await tester
        .pumpWidget(KaibiganApp(soundController: SilentUiSoundController()));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    final gateContext = tester.element(find.byType(AuthGate));
    final user = gateContext.read<UserProvider>();
    Navigator.of(gateContext)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await user.leaveOfflineMode();
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  setUp(() => SharedPreferences.setMockInitialValues({
        'preferred_language': 'english',
        'kai_value_demo_seen_v1': true,
      }));

  testWidgets(
      'new offline user completes setup under the gate and first lands on Home',
      (tester) async {
    final user = UserProvider();
    await user.ready;
    await user.continueOffline();
    final routines = StartupRoutines(offer: true);
    await tester.pumpWidget(app(user, routines));
    await tester.pumpAndSettle();
    expect(find.byType(MascotSelectionScreen), findsOneWidget);
    expect(find.byType(ProgressiveRoutineRunner), findsNothing);
    await tester.tap(find.text('Magsimula tayo, Kai'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthGate), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(routines.claims, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    user.dispose();
    routines.dispose();
  });

  testWidgets(
      'returning offline user gets one routine and returns to Home after pausing',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'offline_mode_enabled': true,
      'companion_setup_v1_offline:guest': true,
      'user_pref_offline:guest_selected_companion': 'kai',
      'user_pref_offline:guest_preferred_language': 'english',
      'user_pref_offline:guest_kai_value_demo_seen_v1': true,
    });
    final user = UserProvider();
    await user.ready;
    final routines = StartupRoutines(offer: true);
    await tester.pumpWidget(app(user, routines));
    await tester.pumpAndSettle();
    expect(find.text('Take a moment here'), findsOneWidget);
    expect(find.byType(StartupHomeScreen, skipOffstage: false), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close routine'));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(routines.claims, 1);
    user.completeKaiValueDemo();
    await tester.pumpAndSettle();
    expect(routines.claims, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    user.dispose();
    routines.dispose();
  });

  testWidgets('password recovery takes priority over setup and routines',
      (tester) async {
    final user = RecoveryUser();
    await user.ready;
    await user.continueOffline();
    final routines = StartupRoutines(offer: true);
    await tester.pumpWidget(app(user, routines));
    await tester.pumpAndSettle();
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.byType(MascotSelectionScreen), findsNothing);
    expect(routines.claims, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    user.dispose();
    routines.dispose();
  });
}
