import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'env_loader_web.dart'
    if (dart.library.io) 'env_loader_io.dart' as platform_env;

class EnvConfig {
  static final Map<String, String> _runtimeValues = <String, String>{};

  static Future<void> init() async {
    _runtimeValues.clear();

    // 1. Try loading via flutter_dotenv (reads .env bundled into assets)
    try {
      await dotenv.load(fileName: '.env');
      for (final entry in dotenv.env.entries) {
        if (entry.value.trim().isNotEmpty) {
          _runtimeValues[entry.key] = entry.value.trim();
        }
      }
    } catch (_) {
      try {
        await dotenv.load(fileName: 'assets/.env');
        for (final entry in dotenv.env.entries) {
          if (entry.value.trim().isNotEmpty) {
            _runtimeValues[entry.key] = entry.value.trim();
          }
        }
      } catch (_) {}
    }

    // 2. Try loading raw .env content from rootBundle
    try {
      final assetContent = await rootBundle.loadString('.env');
      if (assetContent.trim().isNotEmpty) {
        for (final entry in _parseDotEnv(assetContent).entries) {
          _runtimeValues[entry.key] = entry.value;
        }
      }
    } catch (_) {
      try {
        final assetContent = await rootBundle.loadString('assets/.env');
        if (assetContent.trim().isNotEmpty) {
          for (final entry in _parseDotEnv(assetContent).entries) {
            _runtimeValues[entry.key] = entry.value;
          }
        }
      } catch (_) {}
    }

    // 3. On desktop / local / tests, search workspace directories for .env (no-op on web)
    try {
      final fsEnv = await platform_env.loadFileSystemEnv(_parseDotEnv);
      for (final entry in fsEnv.entries) {
        _runtimeValues[entry.key] = entry.value;
      }
    } catch (_) {}

    // 4. On non-web platforms, read from Platform environment (empty on web)
    try {
      final platformMap = platform_env.getPlatformEnvironment();
      for (final entry in platformMap.entries) {
        if (entry.value.trim().isNotEmpty) {
          _runtimeValues[entry.key] = entry.value.trim();
        }
      }
    } catch (_) {}
  }

  static void applyRuntimeValues(Map<String, String> values) {
    _runtimeValues
      ..clear()
      ..addAll({
        for (final entry in values.entries)
          if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
            entry.key: entry.value.trim(),
      });
  }

  static void clearRuntimeValues() => _runtimeValues.clear();

  static const String _defaultSupabaseUrl =
      'https://mclcasledpioyvmvryzv.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'sb_publishable_B51Qk4SOS9m8v3AZnM1RHg_Zke0EF5v';

  static String get supabaseUrl => _readString(
        'SUPABASE_URL',
        defaultValue: _defaultSupabaseUrl,
      );
  static String get supabaseAnonKey => _readString(
        'SUPABASE_ANON_KEY',
        defaultValue: _defaultSupabaseAnonKey,
      );
  static String get passwordResetRedirectUrl =>
      _redirectUrl(_readString('PASSWORD_RESET_REDIRECT_URL'));
  static String get oauthRedirectUrl =>
      _redirectUrl(_readString('OAUTH_REDIRECT_URL'));
  static bool get googleAuthEnabled => _readBool(
        'ENABLE_GOOGLE_AUTH',
        defaultValue: false,
      );

  static String get geminiApiKey {
    final key = _readString('GEMINI_API_KEY');
    if (key.isNotEmpty) return key;
    return _readString('GOOGLE_API_KEY');
  }

  static String get geminiModel {
    final explicit = _readString('GEMINI_MODEL');
    if (explicit.isNotEmpty) return explicit;
    final primary = _readString('PRIMARY_AI_MODEL');
    if (primary.isNotEmpty) return primary;
    return 'gemini-3.5-flash-lite';
  }

  static String get groqApiKey => _readString('GROQ_API_KEY');

  static String get groqFallbackModel {
    final explicit = _readString('GROQ_FALLBACK_MODEL');
    if (explicit.isNotEmpty) return explicit;
    final fallback = _readString('FALLBACK_AI_MODEL');
    if (fallback.isNotEmpty) return fallback;
    return 'openai/gpt-oss-120b';
  }

  // Direct provider keys are a local-development convenience only. Release
  // builds always use the authenticated Edge Function so secrets cannot be
  // accidentally shipped inside the app bundle.
  static bool get hasDirectAiProvider =>
      kDebugMode &&
      (geminiApiKey.trim().isNotEmpty || groqApiKey.trim().isNotEmpty);

  static String _readBuildEnvironment(String key) => switch (key) {
        'SUPABASE_URL' => const String.fromEnvironment('SUPABASE_URL'),
        'SUPABASE_ANON_KEY' =>
          const String.fromEnvironment('SUPABASE_ANON_KEY'),
        'PASSWORD_RESET_REDIRECT_URL' =>
          const String.fromEnvironment('PASSWORD_RESET_REDIRECT_URL'),
        'OAUTH_REDIRECT_URL' =>
          const String.fromEnvironment('OAUTH_REDIRECT_URL'),
        'ENABLE_GOOGLE_AUTH' =>
          const String.fromEnvironment('ENABLE_GOOGLE_AUTH'),
        'GEMINI_API_KEY' => const String.fromEnvironment('GEMINI_API_KEY'),
        'GOOGLE_API_KEY' => const String.fromEnvironment('GOOGLE_API_KEY'),
        'GEMINI_MODEL' => const String.fromEnvironment('GEMINI_MODEL'),
        'PRIMARY_AI_MODEL' => const String.fromEnvironment('PRIMARY_AI_MODEL'),
        'GROQ_API_KEY' => const String.fromEnvironment('GROQ_API_KEY'),
        'GROQ_FALLBACK_MODEL' =>
          const String.fromEnvironment('GROQ_FALLBACK_MODEL'),
        'FALLBACK_AI_MODEL' =>
          const String.fromEnvironment('FALLBACK_AI_MODEL'),
        _ => '',
      };

  static String _readString(String key, {String defaultValue = ''}) {
    final buildValue = _readBuildEnvironment(key);
    if (buildValue.trim().isNotEmpty) return buildValue.trim();

    final runtimeValue = _runtimeValues[key];
    if (runtimeValue != null && runtimeValue.trim().isNotEmpty) {
      return runtimeValue.trim();
    }

    try {
      final dotenvValue = dotenv.maybeGet(key);
      if (dotenvValue != null && dotenvValue.trim().isNotEmpty) {
        return dotenvValue.trim();
      }
    } catch (_) {}

    try {
      final platformValue = platform_env.getPlatformEnvironment()[key];
      if (platformValue != null && platformValue.trim().isNotEmpty) {
        return platformValue.trim();
      }
    } catch (_) {}

    return defaultValue;
  }

  static bool _readBool(String key, {required bool defaultValue}) {
    final buildValue = _readBuildEnvironment(key);
    if (buildValue.trim().isNotEmpty) {
      return _parseBool(buildValue);
    }

    final runtimeValue = _runtimeValues[key];
    if (runtimeValue != null && runtimeValue.trim().isNotEmpty) {
      return _parseBool(runtimeValue);
    }

    try {
      final dotenvValue = dotenv.maybeGet(key);
      if (dotenvValue != null && dotenvValue.trim().isNotEmpty) {
        return _parseBool(dotenvValue);
      }
    } catch (_) {}

    try {
      final platformValue = platform_env.getPlatformEnvironment()[key];
      if (platformValue != null && platformValue.trim().isNotEmpty) {
        return _parseBool(platformValue);
      }
    } catch (_) {}

    return defaultValue;
  }

  static bool _parseBool(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  static String _redirectUrl(String override) {
    if (override.trim().isNotEmpty) return override.trim();
    if (kIsWeb) return Uri.base.resolve('auth-callback').toString();
    return 'com.kaibigan.app://auth-callback';
  }

  static Map<String, String> _parseDotEnv(String source) {
    final values = <String, String>{};

    for (var line in source.split(RegExp(r'\r?\n'))) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.startsWith('export ')) {
        line = line.substring('export '.length).trimLeft();
      }

      final separator = line.indexOf('=');
      if (separator <= 0) continue;

      final key = line.substring(0, separator).trim();
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) continue;

      var value = line.substring(separator + 1).trim();
      if (value.length >= 2) {
        final first = value[0];
        final last = value[value.length - 1];
        if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
          value = value.substring(1, value.length - 1);
        }
      }

      values[key] = value;
    }

    return values;
  }
}
