import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_loading_screen.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_logo.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_state_view.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/auth_screen.dart';
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

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
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
