import 'package:flutter_test/flutter_test.dart';

import '../tool/run_with_env.dart';

void main() {
  group('parseDotEnv', () {
    test('supports comments, export, quoted values, and equals in values', () {
      final values = parseDotEnv('''
# Local configuration
SUPABASE_URL=https://example.supabase.co
export SUPABASE_ANON_KEY="public=value"
ENABLE_GOOGLE_AUTH='true'
not a valid line
''');

      expect(values['SUPABASE_URL'], 'https://example.supabase.co');
      expect(values['SUPABASE_ANON_KEY'], 'public=value');
      expect(values['ENABLE_GOOGLE_AUTH'], 'true');
      expect(values, hasLength(3));
    });
  });

  test('forwards demo AI configuration but still excludes unrelated secrets',
      () {
    final values = flutterEnvironment({
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'public-key',
      'ENABLE_GOOGLE_AUTH': 'false',
      'GEMINI_API_KEY': 'private-gemini-key',
      'GROQ_API_KEY': 'private-groq-key',
      'GMAIL_SMTP_APP_PASSWORD': 'private-mail-password',
    });

    expect(values['SUPABASE_URL'], 'https://example.supabase.co');
    expect(values['SUPABASE_ANON_KEY'], 'public-key');
    expect(values['ENABLE_GOOGLE_AUTH'], 'false');
    expect(values['GEMINI_API_KEY'], 'private-gemini-key');
    expect(values['GROQ_API_KEY'], 'private-groq-key');
    expect(values, isNot(contains('GMAIL_SMTP_APP_PASSWORD')));
  });

  test('maps legacy model names used by existing local env files', () {
    final values = flutterEnvironment({
      'PRIMARY_AI_MODEL': 'gemini-demo-model',
      'FALLBACK_AI_MODEL': 'groq-demo-model',
    });

    expect(values['GEMINI_MODEL'], 'gemini-demo-model');
    expect(values['GROQ_FALLBACK_MODEL'], 'groq-demo-model');
  });

  group('device selection', () {
    test('defaults to Chrome when no device was supplied', () {
      final arguments = buildFlutterArguments(
        values: const {'SUPABASE_URL': 'https://example.supabase.co'},
        arguments: const ['--web-port=3000'],
      );

      expect(arguments.take(3), ['run', '-d', 'chrome']);
      expect(arguments, contains('--web-port=3000'));
    });

    test('preserves an explicit device without adding another one', () {
      final arguments = buildFlutterArguments(
        values: const {},
        arguments: const ['-d', 'windows'],
      );

      expect(arguments, ['run', '-d', 'windows']);
    });

    test('supports long-form device selection', () {
      expect(hasDeviceSelection(['--device-id=edge']), isTrue);
      expect(hasDeviceSelection(['--web-port=3000']), isFalse);
    });
  });
}
