import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/app_lifecycle_service.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/main_navigation_screen.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
    AppLifecycleService.sendToBackgroundResultForTesting = null;
  });

  tearDown(() {
    AppLifecycleService.sendToBackgroundResultForTesting = null;
  });

  Widget app(Widget home) => MultiProvider(
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
        child: MaterialApp(theme: AppTheme.lightTheme, home: home),
      );

  testWidgets('pressing back on secondary tab navigates to home first',
      (tester) async {
    await tester.pumpWidget(app(const MainNavigationScreen()));
    await tester.pumpAndSettle();

    // Tap on Journal tab (index 1)
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    // Simulate system back gesture
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Navigates back to home tab (index 0) without exit snackbar
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.text('Press back again to exit'), findsNothing);
  });

  testWidgets('first back press on home shows exit hint snackbar',
      (tester) async {
    await tester.pumpWidget(app(const MainNavigationScreen()));
    await tester.pumpAndSettle();

    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pump();

    expect(find.text('Press back again to exit'), findsOneWidget);
  });

  testWidgets('second back press within 2 seconds calls sendToBackground',
      (tester) async {
    AppLifecycleService.sendToBackgroundResultForTesting = true;

    await tester.pumpWidget(app(const MainNavigationScreen()));
    await tester.pumpAndSettle();

    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

    // First back press shows hint
    await widgetsAppState.didPopRoute();
    await tester.pump();
    expect(find.text('Press back again to exit'), findsOneWidget);

    // Second back press triggers exit / send to background
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Exit snackbar is dismissed
    expect(find.text('Press back again to exit'), findsNothing);
  });

  testWidgets('second back press after 2 seconds re-prompts exit hint',
      (tester) async {
    await tester.pumpWidget(app(const MainNavigationScreen()));
    await tester.pumpAndSettle();

    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

    // First back press
    await widgetsAppState.didPopRoute();
    await tester.pump();
    expect(find.text('Press back again to exit'), findsOneWidget);

    // Wait past 2 seconds timeout
    await tester.pump(const Duration(seconds: 3));

    // Second back press after timeout should show hint again, not exit
    await widgetsAppState.didPopRoute();
    await tester.pump();
    expect(find.text('Press back again to exit'), findsOneWidget);
  });
}
