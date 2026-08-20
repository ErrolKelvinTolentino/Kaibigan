import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/env_config.dart';

class SupabaseService {
  static bool _isInitialized = false;

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
        debugPrint("Supabase successfully initialized with $url");
      } else {
        debugPrint(
          "Supabase credentials missing or invalid. Supabase is required for authentication and storage.",
        );
      }
    } catch (e) {
      debugPrint("Supabase initialization error: $e");
      _isInitialized = false;
    }
  }

  static bool get isInitialized => _isInitialized;
  static SupabaseClient get client => Supabase.instance.client;
}
