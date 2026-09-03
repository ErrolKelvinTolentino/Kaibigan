import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/utils/env_config.dart';

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

  test('loads runtime env values when no dart-define value is supplied', () {
    EnvConfig.applyRuntimeValues({
      'SUPABASE_URL': 'https://runtime.supabase.co',
      'SUPABASE_ANON_KEY': 'runtime-anon-key',
      'ENABLE_GOOGLE_AUTH': 'true',
      'GEMINI_API_KEY': 'runtime-gemini-key',
      'PRIMARY_AI_MODEL': 'primary-model',
      'FALLBACK_AI_MODEL': 'fallback-model',
    });

    try {
      expect(EnvConfig.supabaseUrl, 'https://runtime.supabase.co');
      expect(EnvConfig.supabaseAnonKey, 'runtime-anon-key');
      expect(EnvConfig.googleAuthEnabled, isTrue);
      expect(EnvConfig.geminiApiKey, 'runtime-gemini-key');
      expect(EnvConfig.geminiModel, 'primary-model');
      expect(EnvConfig.groqFallbackModel, 'fallback-model');
    } finally {
      EnvConfig.clearRuntimeValues();
    }
  });

  test('EnvConfig falls back to GOOGLE_API_KEY if GEMINI_API_KEY is not set', () {
    EnvConfig.applyRuntimeValues({
      'GOOGLE_API_KEY': 'google-fallback-key',
    });

    try {
      expect(EnvConfig.geminiApiKey, 'google-fallback-key');
    } finally {
      EnvConfig.clearRuntimeValues();
    }
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
