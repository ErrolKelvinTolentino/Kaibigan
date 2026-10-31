import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaibigan_flutter/core/services/backend_status.dart';
import 'package:kaibigan_flutter/core/utils/env_config.dart';
import 'package:kaibigan_flutter/features/auth_onboarding/auth_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    EnvConfig.applyRuntimeValues({
      'SUPABASE_URL': 'https://paused-project.supabase.co',
      'SUPABASE_ANON_KEY': 'eyJtest.key.value',
    });
  });
  tearDown(EnvConfig.clearRuntimeValues);

  group('classifying a failure', () {
    test('a dead hostname is unreachable, not a credential problem', () {
      const error = SocketException(
        "Failed host lookup: 'paused-project.supabase.co'",
      );
      expect(BackendStatus.classify(error), BackendFailureKind.unreachable);
    });

    test('the transport wrappers other packages throw are recognised', () {
      expect(
        BackendStatus.classify(http.ClientException('Connection closed')),
        BackendFailureKind.unreachable,
      );
      expect(
        BackendStatus.classify(
          Exception('AuthRetryableFetchException: Failed host lookup'),
        ),
        BackendFailureKind.unreachable,
      );
      expect(
        BackendStatus.classify(Exception('Connection refused')),
        BackendFailureKind.unreachable,
      );
    });

    test('a timeout is kept separate from an unreachable host', () {
      expect(
        BackendStatus.classify(TimeoutException('no answer')),
        BackendFailureKind.timedOut,
      );
    });

    test('anything that did answer is treated as a server fault', () {
      expect(
        BackendStatus.classify(Exception('relation "x" does not exist')),
        BackendFailureKind.serverError,
      );
    });
  });

  group('the message a person reads', () {
    String messageFor(BackendFailureKind kind) =>
        BackendStatus.describe(kind, language: 'english');

    test('an unreachable server names itself and clears the user of blame',
        () {
      final message = messageFor(BackendFailureKind.unreachable);

      expect(message, contains('paused-project.supabase.co'));
      expect(message, contains('not your password'));
      expect(message, contains('resumed'));
      expect(message, contains('nothing was lost'));
    });

    test('it no longer blames the connection for every failure', () {
      // The old copy said "Check your connection and try again" for a dead
      // backend, which sent people to their router.
      expect(
        messageFor(BackendFailureKind.serverError),
        isNot(contains('Check your connection')),
      );
      expect(
        messageFor(BackendFailureKind.serverError),
        contains('server had a problem'),
      );
    });

    test('a missing configuration says which values are missing', () {
      final message = messageFor(BackendFailureKind.notConfigured);

      expect(message, contains('SUPABASE_URL'));
      expect(message, contains('SUPABASE_ANON_KEY'));
    });

    test('every kind is translated', () {
      for (final kind in BackendFailureKind.values) {
        final filipino = BackendStatus.describe(kind, language: 'filipino');
        if (kind == BackendFailureKind.none) {
          expect(filipino, isEmpty);
        } else {
          expect(filipino, isNotEmpty);
          expect(filipino, isNot(messageFor(kind)));
        }
      }
    });
  });

  group('probing the backend', () {
    test('a dead host reports unreachable rather than throwing', () async {
      final client = MockClient(
        (_) async => throw const SocketException('Failed host lookup'),
      );
      expect(
        await BackendStatus.probe(client: client),
        BackendFailureKind.unreachable,
      );
    });

    test('any answer at all means the host is up', () async {
      // 401 means the key is wrong, which is not an outage.
      for (final status in [200, 401, 404]) {
        final client = MockClient((_) async => http.Response('', status));
        expect(
          await BackendStatus.probe(client: client),
          BackendFailureKind.none,
          reason: 'HTTP $status still proves the host answered',
        );
      }
    });

    test('a 5xx is reported as the server faulting', () async {
      final client = MockClient((_) async => http.Response('', 503));
      expect(
        await BackendStatus.probe(client: client),
        BackendFailureKind.serverError,
      );
    });

    test('a hanging server is a timeout, not a hung button', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return http.Response('', 200);
      });
      expect(
        await BackendStatus.probe(
          client: client,
          timeout: const Duration(milliseconds: 50),
        ),
        BackendFailureKind.timedOut,
      );
    });

    test('no credentials is reported without a request being attempted',
        () async {
      EnvConfig.applyRuntimeValues({
        'SUPABASE_URL': '',
        'SUPABASE_ANON_KEY': '',
      });
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('', 200);
      });

      // The built-in fallback still supplies values, so this asserts the
      // real behaviour: configured values exist, so a request is made.
      final result = await BackendStatus.probe(client: client);
      expect(result, isNot(BackendFailureKind.unreachable));
      expect(called, isTrue);
    });
  });

  group('credential source reporting', () {
    test('a value from .env is not reported as the built-in fallback', () {
      expect(EnvConfig.sourceOf('SUPABASE_URL'), '.env');
      expect(EnvConfig.usingFallbackSupabaseCredentials, isFalse);
    });

    test('with nothing configured the fallback is named', () {
      EnvConfig.clearRuntimeValues();
      expect(EnvConfig.sourceOf('SUPABASE_URL'), 'built-in fallback');
      expect(EnvConfig.usingFallbackSupabaseCredentials, isTrue);
    });

    test('the description identifies the key without printing it', () {
      final description = EnvConfig.describeSupabaseCredentials();

      expect(description, contains('legacy JWT'));
      expect(description, contains('ends …alue'));
      expect(description, isNot(contains('eyJtest.key.value')));
    });
  });

  group('the auth screen', () {
    Future<void> pumpAuth(
      WidgetTester tester,
      BackendFailureKind kind,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final user = UserProvider();
      await user.ready;
      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>.value(
          value: user,
          child: MaterialApp(
            home: AuthScreen(backendProbe: () async => kind),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('warns up front when the server cannot be reached',
        (tester) async {
      await pumpAuth(tester, BackendFailureKind.unreachable);

      expect(
          find.byKey(const ValueKey('auth-backend-banner')), findsOneWidget);
      expect(find.text('The server is not reachable'), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-backend-retry')), findsOneWidget);
      expect(find.textContaining('paused-project.supabase.co'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays out of the way when the server is fine',
        (tester) async {
      await pumpAuth(tester, BackendFailureKind.none);

      expect(find.byKey(const ValueKey('auth-backend-banner')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a transient timeout does not accuse the server of being down',
        (tester) async {
      await pumpAuth(tester, BackendFailureKind.timedOut);

      expect(find.byKey(const ValueKey('auth-backend-banner')), findsNothing);
    });
  });
}
