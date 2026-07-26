import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/env_config.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static Future<void> init() async {
    try {
      final url = EnvConfig.supabaseUrl;
      final anonKey = EnvConfig.supabaseAnonKey;

      if (url.isNotEmpty && !url.contains('xyzcompany') && anonKey.isNotEmpty && anonKey != 'dummy_key') {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
        );
        _isInitialized = true;
        print("Supabase successfully initialized.");
      } else {
        print("Supabase credentials not set or using placeholder. Running in local-first mode.");
      }
    } catch (e) {
      print("Supabase initialization error: $e");
      _isInitialized = false;
    }
  }

  static bool get isInitialized => _isInitialized;
  static SupabaseClient get client => Supabase.instance.client;
}
