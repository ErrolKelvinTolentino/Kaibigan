import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/routines/screens/grounding_session_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/mindfulness_meditation_screen.dart';
import 'package:provider/provider.dart';

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

    expect(completed, isTrue);
    expect(find.byKey(const ValueKey('grounding-complete')), findsNothing);
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
    expect(completed, isTrue);
  });
}
