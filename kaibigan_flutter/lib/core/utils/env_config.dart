import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // If .env file fails or is missing, proceed gracefully
      print("Warning: Could not load .env file. $e");
    }
  }

  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: 'https://xyzcompany.supabase.co');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: 'dummy_key');
  static String get groqApiKey => dotenv.get('GROQ_API_KEY', fallback: '');
  static String get primaryAiModel => dotenv.get('PRIMARY_AI_MODEL', fallback: 'llama-3.3-70b-versatile');
  static String get fallbackAiModel => dotenv.get('FALLBACK_AI_MODEL', fallback: 'llama-3.1-8b-instant');
}
