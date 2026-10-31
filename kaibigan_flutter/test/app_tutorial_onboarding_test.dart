import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/app_tutorial_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget testApp({required Widget child, UserProvider? userProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (_) => userProvider ?? UserProvider(),
        ),
        ChangeNotifierProvider<AffirmationsProvider>(
          create: (_) => AffirmationsProvider(),
        ),
        ChangeNotifierProvider<JournalProvider>(
          create: (_) => JournalProvider(),
        ),
        ChangeNotifierProvider<GratitudeProvider>(
          create: (_) => GratitudeProvider(),
        ),
        ChangeNotifierProvider<LettersProvider>(
          create: (_) => LettersProvider(),
        ),
        ChangeNotifierProvider<MoodProvider>(
          create: (_) => MoodProvider(),
        ),
        ChangeNotifierProvider<RoutinesProvider>(
          create: (_) => RoutinesProvider(syncOnCreate: false),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AppTutorialScreen navigates 4 slides and finishes on Get Started',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    var completed = false;

    await tester.pumpWidget(
      testApp(
        child: AppTutorialScreen(
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Slide 1: Companion
    expect(find.text('Kaibigan Tour'), findsOneWidget);
    expect(find.textContaining('Meet Kai, your companion'), findsOneWidget);
    expect(find.text('100% Private'), findsOneWidget);

    // Slide 2: Daily Check-in & Moments
    await tester.tap(find.byKey(const ValueKey('tutorial-next-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Daily Check-in & Moments'), findsOneWidget);
    expect(find.text('Mood Tracker'), findsOneWidget);

    // Slide 3: Calming Activities
    await tester.tap(find.byKey(const ValueKey('tutorial-next-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Calming Activities'), findsOneWidget);
    expect(find.text('Guided Breathing'), findsOneWidget);

    // Slide 4: Records & Lessons
    await tester.tap(find.byKey(const ValueKey('tutorial-next-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Records & Lessons'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.byKey(const ValueKey('tutorial-next-button')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });

  testWidgets('AppTutorialScreen skip button completes immediately',
      (tester) async {
    var completed = false;

    await tester.pumpWidget(
      testApp(
        child: AppTutorialScreen(
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tutorial-skip-button')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
  });

  testWidgets(
      'HomeScreen shows welcome tutorial card for fresh accounts and hides on dismiss',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Maria',
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });

    final user = UserProvider();
    await user.ready;
    expect(user.hasSeenAppTutorial, isFalse);

    await tester.pumpWidget(testApp(child: const HomeScreen(), userProvider: user));
    await tester.pumpAndSettle();

    // The onboarding card is present on a new account
    expect(find.byKey(const ValueKey('home-onboarding-welcome-card')),
        findsOneWidget);
    expect(find.textContaining('Welcome to Kaibigan, Maria!'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-onboarding-tour-button')),
        findsOneWidget);

    // Dismissing it marks it completed and hides the card
    await tester.tap(find.byKey(const ValueKey('dismiss-onboarding-welcome-card')));
    await tester.pumpAndSettle();

    expect(user.hasSeenAppTutorial, isTrue);
    expect(find.byKey(const ValueKey('home-onboarding-welcome-card')),
        findsNothing);
  });

  testWidgets(
      'HomeScreen shows starter subtitle without fake usage rankings on zero-usage account',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Maria',
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });

    final user = UserProvider();
    await user.ready;

    await tester.pumpWidget(testApp(child: const HomeScreen(), userProvider: user));
    await tester.pumpAndSettle();

    // Fresh accounts see My Favorites with beginner starter guidance
    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.textContaining('Default starter spaces'), findsOneWidget);

    // Badges guide beginners rather than boasting fake usage counts
    expect(find.text('Start Here'), findsOneWidget);
    expect(find.text('★ #1 Most Used'), findsNothing);
  });
}
