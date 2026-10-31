import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/env_config.dart';

class SupabaseService {
  static bool _isInitialized = false;
  static SupabaseClient? _testClient;
  static final ValueNotifier<bool> _initialization = ValueNotifier(false);
  static ValueListenable<bool> get initializationState => _initialization;

  static Future<void> init() async {
    try {
      final url = EnvConfig.supabaseUrl;
      final anonKey = EnvConfig.supabaseAnonKey;

      if (url.isNotEmpty &&
          !url.contains('xyzcompany') &&
          !url.contains('your-supabase-project') &&
          anonKey.isNotEmpty &&
          anonKey != 'dummy_key' &&
          anonKey != 'your_supabase_anon_key_here') {
        await Supabase.initialize(
          url: url,
          publishableKey: anonKey,
        );
        _isInitialized = true;
        _initialization.value = true;
        // "Initialized" only means a client object exists; no request has
        // been made yet, so this line says nothing about whether the project
        // is actually up. Reachability is checked separately.
        debugPrint(
          'Supabase client created for $url '
          '(${EnvConfig.describeSupabaseCredentials()}). '
          'Not yet contacted — this does not mean the project is reachable.',
        );
        if (EnvConfig.usingFallbackSupabaseCredentials) {
          debugPrint(
            'WARNING: using the credentials compiled into env_config.dart. '
            'No .env or --dart-define value was found, so this build may be '
            'talking to a different project than you expect.',
          );
        }
      } else {
        debugPrint(
          "Supabase credentials missing or invalid. Supabase is required for authentication and storage.",
        );
      }
    } catch (e) {
      debugPrint("Supabase initialization error: $e");
      _isInitialized = false;
      _initialization.value = false;
    }
  }

  static bool get isInitialized => _isInitialized || _testClient != null;
  static SupabaseClient get client => _testClient ?? Supabase.instance.client;

  @visibleForTesting
  static void setClientForTesting(SupabaseClient? client) {
    _testClient = client;
    _initialization.value = isInitialized;
  }
}
