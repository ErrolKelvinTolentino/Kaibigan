import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ambient_sound_service.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/routines/screens/grounding_session_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/mindfulness_meditation_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget featureUnderTest(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => RoutinesProvider(),
      child: MaterialApp(home: child),
    );
  }

  testWidgets('grounding guides users through all five senses', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      featureUnderTest(const GroundingSessionScreen()),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('feature-art-grounding-landscape')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('begin-grounding-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('grounding-step-5')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notice-5')));
    await tester.pump();
    expect(find.text('1 of 5 noticed'), findsOneWidget);

    for (final count in [4, 3, 2, 1]) {
      await tester.tap(
        find.byKey(const ValueKey('grounding-continue-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('grounding-step-$count')), findsOneWidget);
    }

    await tester.tap(
      find.byKey(const ValueKey('grounding-continue-button')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('grounding-complete')), findsOneWidget);
    expect(find.text('You are here.'), findsOneWidget);
  });

  testWidgets('breathing supports pattern, duration, and pause controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      featureUnderTest(const MindfulnessMeditationScreen()),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('feature-art-breathing-landscape')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Box breathing'));
    await tester.tap(find.text('Box breathing'));
    await tester.ensureVisible(
      find.byKey(const ValueKey('breathing-duration-2')),
    );
    await tester.tap(find.byKey(const ValueKey('breathing-duration-2')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('begin-breathing-button')),
    );
    await tester.tap(find.byKey(const ValueKey('begin-breathing-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('breathing-session')), findsOneWidget);
    expect(find.text('Inhale'), findsWidgets);
    expect(find.text('Box breathing'), findsWidgets);

    final startingScale = tester
        .widget<Transform>(find.byKey(const ValueKey('breath-orb-scale')))
        .transform
        .storage[0];
    await tester.pump(const Duration(seconds: 1));
    final gentleScale = tester
        .widget<Transform>(find.byKey(const ValueKey('breath-orb-scale')))
        .transform
        .storage[0];
    await tester.pump(const Duration(seconds: 1));
    final laterScale = tester
        .widget<Transform>(find.byKey(const ValueKey('breath-orb-scale')))
        .transform
        .storage[0];
    expect(gentleScale, greaterThan(startingScale));
    expect(gentleScale, lessThan(1.13));
    expect(laterScale, greaterThan(gentleScale));

    await tester.tap(find.byKey(const ValueKey('breathing-pause-button')));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('routine grounding uses a compact 3-2-1 flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var completed = false;

    await tester.pumpWidget(
      featureUnderTest(
        GroundingSessionScreen(
          routineMode: true,
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('grounding-intro')), findsNothing);
    expect(find.byKey(const ValueKey('grounding-step-3')), findsOneWidget);
    for (final nextCount in [2, 1]) {
      await tester.tap(
        find.byKey(const ValueKey('grounding-continue-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('grounding-step-$nextCount')),
        findsOneWidget,
      );
    }
    await tester.tap(find.byKey(const ValueKey('grounding-continue-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('grounding-complete')), findsOneWidget);
    expect(completed, isFalse);
    await tester.tap(find.text('Return feeling steadier'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('routine breathing is capped at thirty seconds', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var completed = false;

    await tester.pumpWidget(
      featureUnderTest(
        MindfulnessMeditationScreen(
          routineMode: true,
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A 30-second reset'), findsOneWidget);
    expect(find.byKey(const ValueKey('breathing-duration-1')), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('begin-routine-breathing-button')),
    );
    await tester.pump();
    expect(find.text('00:30'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('breathing-complete')), findsOneWidget);
    expect(completed, isFalse);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets(
      'each breathing option names its method and the need it answers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      featureUnderTest(
        MindfulnessMeditationScreen(
          soundPlayer: SilentAmbientSoundController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final method in const [
      'Extended exhale',
      'Physiological sigh',
      'Box breathing',
      '4-7-8 breathing',
      'Coherent breathing',
    ]) {
      await tester.scrollUntilVisible(find.text(method), 200);
      expect(find.text(method), findsOneWidget);
    }

    // The need, the timing and the rate are all stated up front, so the choice
    // is not made on a vague mood word.
    expect(find.text('To quiet a racing mind at bedtime'), findsOneWidget);
    expect(find.text('4-7-8'), findsOneWidget);
    // 4-7-8 runs a 19-second cycle, about three breaths a minute.
    expect(find.text('3/min'), findsOneWidget);
    expect(
      find.textContaining('slows your heart rate'),
      findsOneWidget,
    );
  });

  testWidgets('a background sound can be chosen and starts with the session',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final ambience = SilentAmbientSoundController();

    await tester.pumpWidget(
      featureUnderTest(
        MindfulnessMeditationScreen(soundPlayer: ambience),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('breathing-sound-picker')),
      200,
    );
    expect(find.byKey(const ValueKey('breathing-sound-none')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('breathing-sound-rain')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Covers noisy rooms'),
      findsOneWidget,
      reason: 'the picker says what each sound is good for',
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('begin-breathing-button')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('begin-breathing-button')));
    await tester.pump();

    expect(ambience.requestedSoundIds, contains('rain'));
    expect(ambience.current.id, 'rain');

    // Muting mid-session is one tap and does not open the picker again.
    await tester.tap(find.byKey(const ValueKey('breathing-sound-toggle')));
    await tester.pump();
    expect(ambience.current.id, 'none');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
