import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/theme/garden_appearance.dart';
import 'package:kaibigan_flutter/features/settings/settings_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy dark-mode preference migrates to the theme setting', () async {
    SharedPreferences.setMockInitialValues({'is_dark_mode': true});
    final provider = UserProvider();
    await provider.ready;

    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.isDarkMode, isTrue);
  });

  test('garden lighting defaults to syncing with local time', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = UserProvider();
    await provider.ready;

    expect(provider.gardenAppearance, GardenAppearance.syncWithTime);
  });

  testWidgets('settings changes the whole app to dark mode immediately',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'theme_mode': 'light',
    });
    final provider = UserProvider();
    await provider.ready;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: Consumer<UserProvider>(
          builder: (context, user, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: user.themeMode,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    expect(find.text('Use device setting'), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-mode-dark')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('theme-mode-dark')));
    await tester.pumpAndSettle();

    expect(provider.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
      Brightness.dark,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('theme_mode'), 'dark');
    expect(preferences.getBool('is_dark_mode'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings persists a manual garden lighting choice',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
    });
    final provider = UserProvider();
    await provider.ready;
    await provider.continueOffline();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sync with time'), findsOneWidget);
    await tester.tap(find.text('Garden lighting'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('garden-appearance-night')),
    );
    await tester.pumpAndSettle();

    expect(provider.gardenAppearance, GardenAppearance.night);
    final reopened = UserProvider();
    await reopened.ready;
    expect(reopened.gardenAppearance, GardenAppearance.night);
    reopened.dispose();
    expect(tester.takeException(), isNull);
  });
}
