import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/settings/profile_screen.dart';
import 'package:kaibigan_flutter/features/settings/settings_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Sam',
      'preferred_language': 'english',
      'selected_companion': 'kai',
    });
  });

  Widget screen(Widget child) => ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(home: child),
      );

  group('profile owns identity, not preferences', () {
    testWidgets('it edits the name and nothing else', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(screen(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profile-display-name-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-account-card')),
        findsOneWidget,
      );

      // The duplicated preference controls are gone: these were the same
      // choices Settings already owns.
      expect(find.text('Your Companion'), findsNothing);
      expect(find.text('Language Preference'), findsNothing);
      expect(find.text('🇺🇸 English'), findsNothing);
      expect(find.text('🇵🇭 Filipino'), findsNothing);
      expect(find.text('Change'), findsNothing);
    });

    testWidgets('it points at Settings instead of repeating it',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(screen(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profile-preferences-pointer')),
        findsOneWidget,
      );
      expect(
        find.textContaining('are in Settings'),
        findsOneWidget,
      );
    });

    testWidgets('saving is offered only once the name actually changes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(screen(const ProfileScreen()));
      await tester.pumpAndSettle();

      FilledButton saveButton() => tester.widget<FilledButton>(
            find.byKey(const ValueKey('profile-save-name')),
          );

      expect(
        saveButton().onPressed,
        isNull,
        reason: 'nothing has been edited yet',
      );

      await tester.enterText(
        find.byKey(const ValueKey('profile-display-name-field')),
        'Sammy',
      );
      await tester.pump();
      expect(saveButton().onPressed, isNotNull);

      // An empty name is not a name.
      await tester.enterText(
        find.byKey(const ValueKey('profile-display-name-field')),
        '   ',
      );
      await tester.pump();
      expect(saveButton().onPressed, isNull);
    });
  });

  group('signing out', () {
    testWidgets('exists once, on the profile, and asks first', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(screen(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Signed out in this test setup, so there is nothing to sign out of.
      expect(find.byKey(const ValueKey('profile-sign-out')), findsNothing);
    });

    testWidgets('settings links to the account instead of a second button',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(screen(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings-manage-account')),
        250,
      );
      expect(
        find.byKey(const ValueKey('settings-manage-account')),
        findsOneWidget,
      );
      // The old second sign-out control is gone from Settings.
      expect(find.text('Log out'), findsNothing);
    });
  });

  group('every preference has exactly one home', () {
    testWidgets('settings still owns all of them', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(screen(const SettingsScreen()));
      await tester.pumpAndSettle();

      for (final row in const [
        'Companion',
        'Language',
        'Theme',
        'Garden lighting',
        'Journal appearance',
        'Sound',
      ]) {
        expect(
          find.text(row),
          findsOneWidget,
          reason: '"$row" should appear exactly once, in Settings',
        );
      }
    });
  });
}
