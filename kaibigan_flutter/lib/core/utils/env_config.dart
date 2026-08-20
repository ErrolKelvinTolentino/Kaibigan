class EnvConfig {
  static Future<void> init() async {}

  // These values are public client configuration, supplied at build/run time:
  // flutter run --dart-define-from-file=dart_defines.local.json
  // Private provider secrets (such as GROQ_API_KEY) must never be added here.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String passwordResetRedirectUrl =
      String.fromEnvironment('PASSWORD_RESET_REDIRECT_URL');
  static const String oauthRedirectUrl =
      String.fromEnvironment('OAUTH_REDIRECT_URL');
  static const bool googleAuthEnabled =
      bool.fromEnvironment('ENABLE_GOOGLE_AUTH');
}
