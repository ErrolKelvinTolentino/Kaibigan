import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_loading_screen.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_logo.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_state_view.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/auth_screen.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/kai_value_demo_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
    });
  });

  Future<void> pumpAuth(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone login is calm, labeled, and switches to registration',
      (tester) async {
    await pumpAuth(tester, size: const Size(320, 700));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(KaibiganLogo), findsNothing);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('New to Kaibigan?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('switch-to-register')));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide authentication layout keeps the welcome panel responsive',
      (tester) async {
    await pumpAuth(tester, size: const Size(1200, 820));

    expect(find.text('Come as you are.\nWrite what is real.'), findsOneWidget);
    expect(find.byType(KaibiganLogo), findsNothing);
    expect(find.text('Private by design'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid login shows an accessible inline message',
      (tester) async {
    await pumpAuth(tester, size: const Size(320, 700));

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short password uses the requested invalid credentials message',
      (tester) async {
    await pumpAuth(tester, size: const Size(390, 844));
    await tester.enterText(find.byType(TextField).at(0), 'qa@example.com');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.textContaining('at least 6'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed login emails use the same generic message',
      (tester) async {
    await pumpAuth(tester, size: const Size(390, 844));
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    for (final email in [
      'invalid',
      'user@',
      'user@example',
      'user @example.com'
    ]) {
      await tester.enterText(find.byType(TextField).at(0), email);
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid email or password.'), findsOneWidget);
      expect(find.text('Please enter a valid email address.'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration explains each correction in the manual test flow',
      (tester) async {
    await pumpAuth(tester, size: const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('switch-to-register')));
    await tester.pumpAndSettle();

    Future<void> submit() async {
      await tester.ensureVisible(find.text('Register'));
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
    }

    await submit();
    expect(find.text('Please enter your display name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Test User');
    for (final email in [
      'invalid',
      'user@',
      'user@example',
      'user @example.com'
    ]) {
      await tester.enterText(find.byType(TextField).at(1), email);
      await submit();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    }

    await tester.enterText(find.byType(TextField).at(1), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(2), '123');
    await submit();
    expect(
        find.text('Password must be at least 6 characters.'), findsOneWidget);
    expect(find.text('Invalid email or password.'), findsNothing);

    // Changing forms clears registration advice from the login screen.
    await tester.ensureVisible(find.byKey(const ValueKey('switch-to-login')));
    await tester.tap(find.byKey(const ValueKey('switch-to-login')));
    await tester.pumpAndSettle();
    expect(find.text('Password must be at least 6 characters.'), findsNothing);
    expect(find.text('At least 6 characters'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kai demonstrates value before registration is requested',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    bool? registrationRequested;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: KaiValueDemoScreen(
            onContinue: (register) => registrationRequested = register,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MEET KAI — NO ACCOUNT NEEDED'), findsOneWidget);
    expect(find.text('Try one private sample. Nothing here is saved or sent.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('demo-kai-response')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('demo-feeling-overwhelmed')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('demo-kai-response')), findsOneWidget);
    expect(find.textContaining('too much to hold at once'), findsOneWidget);

    final createButton = find.byKey(const ValueKey('demo-create-account'));
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();

    expect(registrationRequested, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup loading is branded text-only and accessible',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const KaibiganLoadingScreen(
          message: 'Preparing your space…',
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(KaibiganWordmark), findsOneWidget);
    expect(find.byType(KaibiganLogo), findsNothing);
    expect(find.byType(KaibiganLoadingMark), findsOneWidget);
    expect(find.text('Preparing your space…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
