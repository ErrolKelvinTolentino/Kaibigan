class EnvConfig {
  static Future<void> init() async {}

  // Values are supplied at build/run time by `tool/run_with_env.dart` or a
  // dart-define file. AI keys are intentionally supported for the local demo;
  // move them to Supabase Edge Function secrets before a public release.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mclcasledpioyvmvryzv.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_B51Qk4SOS9m8v3AZnM1RHg_Zke0EF5v',
  );
  static const String passwordResetRedirectUrl = String.fromEnvironment(
    'PASSWORD_RESET_REDIRECT_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String oauthRedirectUrl = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const bool googleAuthEnabled =
      bool.fromEnvironment('ENABLE_GOOGLE_AUTH');

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String groqFallbackModel = String.fromEnvironment(
    'GROQ_FALLBACK_MODEL',
    defaultValue: 'openai/gpt-oss-120b',
  );

  static bool get hasDirectAiProvider =>
      geminiApiKey.trim().isNotEmpty || groqApiKey.trim().isNotEmpty;
}
