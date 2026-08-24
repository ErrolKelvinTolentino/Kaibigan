class EnvConfig {
  static Future<void> init() async {}

  // These values are public client configuration, supplied at build/run time:
  // flutter run --dart-define-from-file=dart_defines.local.json
  // Private provider secrets (such as GROQ_API_KEY) must never be added here.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mclcasledpioyvmvryzv.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_B51Qk4SOS9m8v3AZnM1RHg_Zke0EF5v',
  );
  static const String passwordResetRedirectUrl =
      String.fromEnvironment(
    'PASSWORD_RESET_REDIRECT_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String oauthRedirectUrl =
      String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const bool googleAuthEnabled =
      bool.fromEnvironment('ENABLE_GOOGLE_AUTH');
}
