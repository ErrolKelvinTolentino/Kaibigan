import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_tracker_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MoodTrackerScreen(),
      ),
    );
  }

  testWidgets(
      'selected emotions appear in "what got you feeling this way" reflection step',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Step 1: Mood energy selection
    expect(find.text('Which bee describes you the most right now?'), findsOneWidget);
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2: Emotion selection
    expect(find.text('What emotions are you feeling right now?'), findsOneWidget);
    await tester.ensureVisible(find.text('Calm'));
    await tester.tap(find.text('Calm'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hopeful'));
    await tester.tap(find.text('Hopeful'));
    await tester.pumpAndSettle();

    final continueBtn = find.widgetWithText(ElevatedButton, 'Continue');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Step 3: Reflection step
    // Title includes selected emotions
    expect(find.text('What got you feeling calm and hopeful?'), findsOneWidget);

    // Selected emotions badges appear in the reflection step
    expect(find.byKey(const ValueKey('mood-selected-emotions-reflection')), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('Hopeful'), findsOneWidget);
  });

  testWidgets(
      'reflection step falls back to "What got you feeling this way?" when no emotions selected',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Step 1: Mood energy selection
    final continueStep1 = find.widgetWithText(ElevatedButton, 'Continue');
    await tester.ensureVisible(continueStep1);
    await tester.tap(continueStep1);
    await tester.pumpAndSettle();

    // Step 2: Skip emotion selection
    final continueStep2 = find.widgetWithText(ElevatedButton, 'Continue');
    await tester.ensureVisible(continueStep2);
    await tester.tap(continueStep2);
    await tester.pumpAndSettle();

    // Step 3: Reflection step fallback
    expect(find.text('What got you feeling this way?'), findsOneWidget);
    expect(find.byKey(const ValueKey('mood-selected-emotions-reflection')), findsNothing);
  });
}
