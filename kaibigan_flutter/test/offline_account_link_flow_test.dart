import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaibigan_flutter/core/services/offline_mode.dart';
import 'package:kaibigan_flutter/core/services/supabase_service.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'offline journal follows a real password sign-in into its account history',
      () async {
    SharedPreferences.setMockInitialValues({});
    OfflineMode.setEnabledForTesting(true);
    const owner = '391fd198-4d9d-4c31-9a1b-aad2a009df3a';
    final journals = <Map<String, dynamic>>[];
    final requests = <http.Request>[];
    String segment(Map<String, dynamic> value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final jwt = '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({
          'sub': owner,
          'exp': DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
          'role': 'authenticated',
          'aud': 'authenticated'
        })}.test-signature';
    final account = {
      'id': owner,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'qa@example.com',
      'created_at': '2026-10-19T00:00:00Z',
      'app_metadata': {'provider': 'email'},
      'user_metadata': {'display_name': 'QA Account'}
    };
    final client = SupabaseClient('https://qa.invalid', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
      requests.add(request);
      Object body = [];
      if (request.url.path == '/auth/v1/token') {
        body = {
          'access_token': jwt,
          'refresh_token': 'test-refresh',
          'expires_in': 3600,
          'token_type': 'bearer',
          'user': account
        };
      } else if (request.url.path == '/rest/v1/profiles') {
        final profile = {
          'id': owner,
          'display_name': 'QA Account',
          'has_completed_setup': true,
          'has_seen_tutorial': true
        };
        body = request.headers['Accept']?.contains('object') == true
            ? profile
            : [profile];
      } else if (request.url.path == '/rest/v1/journal_entries') {
        if (request.method == 'POST') {
          final rows =
              List<Map<String, dynamic>>.from(jsonDecode(request.body) as List);
          for (final row in rows) {
            expect(row['user_id'], owner);
            expect(row.containsKey('_source_id'), isFalse);
            if (!journals.any((old) => old['id'] == row['id'])) {
              journals.add(row);
            }
          }
        } else {
          body = journals;
        }
      }
      final encoded = jsonEncode(body);
      return http.Response(encoded, 200, request: request, headers: {
        'content-type': 'application/json',
        'content-length': utf8.encode(encoded).length.toString()
      });
    }));
    SupabaseService.setClientForTesting(client);
    final user = UserProvider();
    await user.ready;
    await user.continueOffline();
    final writer = JournalProvider();
    await writer.fetchJournalEntries();
    final entry = await writer.addJournalEntry(
        title: 'Local journal',
        content: 'Keep my actual writing.',
        companionId: 'kai',
        mood: '');
    expect(entry, isNotNull);
    await user.leaveOfflineMode(importLocalData: true);
    expect(user.hasPendingLocalImport, isTrue);
    expect(
        await user.login(
            email: 'qa@example.com', password: 'ValidPassword!2026'),
        isTrue);
    expect(user.isAuthenticated, isTrue);
    expect(user.hasPendingLocalImport, isFalse);
    expect(user.localImportError, isNull);
    final reader = JournalProvider();
    await reader.fetchJournalEntries();
    expect(reader.allEntries.single.id, entry!.id);
    expect(reader.allEntries.single.content, 'Keep my actual writing.');
    expect(journals, hasLength(1));
    final upload = requests.singleWhere((request) =>
        request.url.path.endsWith('/journal_entries') &&
        request.method == 'POST');
    expect(upload.headers['Prefer'], contains('resolution=ignore-duplicates'));
    writer.dispose();
    reader.dispose();
    user.dispose();
    await client.dispose();
    SupabaseService.setClientForTesting(null);
    OfflineMode.setEnabledForTesting(false);
  });
}
