import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('initial unauthenticated state is pending', () async {
    final provider = UserProvider();
    expect(provider.authMode, AuthMode.pending);
    expect(provider.isAuthenticated, isFalse);
  });

  test('login without Supabase initialization fails with error message', () async {
    final provider = UserProvider();

    final loggedIn = await provider.login(
      email: 'user@example.com',
      password: '123456',
    );

    expect(loggedIn, isFalse);
    expect(provider.authMode, AuthMode.pending);
    expect(provider.authError, contains('Supabase is not initialized'));
  });

  test('register without Supabase initialization fails with error message', () async {
    final provider = UserProvider();

    final registered = await provider.register(
      email: 'newuser@example.com',
      password: 'securepass123',
      displayName: 'New User',
    );

    expect(registered, isFalse);
    expect(provider.authMode, AuthMode.pending);
    expect(provider.authError, contains('Supabase is not initialized'));
  });

  test('logout sets auth state back to pending', () async {
    final provider = UserProvider();
    await provider.logout();

    expect(provider.authMode, AuthMode.pending);
    expect(provider.isAuthenticated, isFalse);
  });
}
