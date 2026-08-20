# Kaibigan Flutter

Kaibigan is a cozy Filipino journal with an optional AI reflection companion.
Writing and saving remain independent from AI generation.

## Local configuration

Copy `dart_defines.example.json` to the ignored `dart_defines.local.json`, then
add the public Supabase project URL and anon key. Run the app with:

```sh
flutter run --dart-define-from-file=dart_defines.local.json
```

Do not place private AI provider keys in Flutter configuration or assets.

For password recovery, set `PASSWORD_RESET_REDIRECT_URL` to an HTTPS URL or
registered app deep link listed in Supabase Auth's allowed redirect URLs. When
Supabase returns a password-recovery session to Kaibigan, the app presents its
new-password screen.

For Google OAuth, set `OAUTH_REDIRECT_URL` to an allowed Supabase Auth redirect
and set `ENABLE_GOOGLE_AUTH` to `true` only after the Google provider has been
configured in Supabase. For the local web demo, run with a fixed port:

```sh
flutter run -d chrome --web-port=3000 --dart-define-from-file=dart_defines.local.json
```

## Secure AI proxy

The app calls the authenticated `kaibigan-ai` Supabase Edge Function. Configure
and deploy it from the repository root:

```sh
supabase secrets set GROQ_API_KEY=your_server_side_key
supabase functions deploy kaibigan-ai
```

Optional function secrets are `PRIMARY_AI_MODEL`, `FALLBACK_AI_MODEL`,
`REASONING_AI_MODEL`, and `ALLOWED_ORIGIN`.

The function enforces JWT authentication, input limits, best-effort per-instance
rate limiting, provider fallbacks, non-storage of model responses, and structured
internal analysis. Journal text and generated responses are not written to logs.
