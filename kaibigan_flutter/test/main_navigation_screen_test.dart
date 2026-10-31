import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/main_navigation_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_hub_screen.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:kaibigan_flutter/features/unified_entries/unified_entries_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'display_name': 'TestUser',
      'preferred_language': 'english',
    });
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => GratitudeProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(
            create: (_) => RoutinesProvider(syncOnCreate: false)),
        ChangeNotifierProvider(create: (_) => LettersProvider()),
        ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }

  testWidgets('bottom nav contains Home, Activities, Records, and Lessons',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final navBarFinder = find.byType(NavigationBar);
    expect(navBarFinder, findsOneWidget);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Lessons'), findsOneWidget);

    // Verify initial selected is Home
    expect(find.byType(HomeScreen), findsOneWidget);

    // Tap Activities
    await tester.tap(find.text('Activities'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivitiesMenuScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('all-activities-menu')), findsOneWidget);

    // Tap Records
    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    expect(find.byType(UnifiedEntriesScreen), findsOneWidget);

    // Tap Lessons
    await tester.tap(find.text('Lessons'));
    await tester.pumpAndSettle();
    expect(find.byType(LearningHubScreen), findsOneWidget);

    // Tap Home back
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
