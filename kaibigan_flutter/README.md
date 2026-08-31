# Kaibigan Flutter

Kaibigan is a cozy Filipino journal with an optional AI reflection companion.
Writing and saving remain independent from AI generation.

## Local configuration

Copy `.env.example` to the ignored `.env`, add the public Supabase project URL
and anon key, then start the app through the safe local runner:

```sh
dart run tool/run_with_env.dart --web-port=3000
```

The runner defaults to Chrome when multiple devices are connected. Override it
with `-d windows`, `-d edge`, or another Flutter device ID. You can also set
`FLUTTER_DEVICE` in `.env` to change the default.

For the local demonstration, the runner forwards the Gemini and Groq settings
from `.env` and the app calls Gemini directly, then Groq if Gemini is unavailable.
This makes the demo work without deployed Edge Function secrets. These keys are
recoverable from a Flutter build—especially a web build—so use this only for the
demo and rotate/move the keys before publishing. Email secrets are never
forwarded. The existing `dart_defines.local.json` workflow remains available:

```sh
flutter run --dart-define-from-file=dart_defines.local.json
```

For password recovery, set `PASSWORD_RESET_REDIRECT_URL` to an HTTPS URL or
registered app deep link listed in Supabase Auth's allowed redirect URLs. When
Supabase returns a password-recovery session to Kaibigan, the app presents its
new-password screen.

For Google OAuth, set `OAUTH_REDIRECT_URL` to an allowed Supabase Auth redirect
and set `ENABLE_GOOGLE_AUTH` to `true` only after the Google provider has been
configured in Supabase.

## Production AI proxy

When no direct demo key is compiled into the app, it calls the authenticated
`kaibigan-ai` Supabase Edge Function. Configure and deploy it from the repository
root:

```sh
supabase secrets set GEMINI_API_KEY=your_gemini_key GROQ_API_KEY=your_groq_key
supabase functions deploy kaibigan-ai
```

For local Edge Function development, copy the entries from
`supabase/functions/.env.example` into `supabase/.env.local`, paste the keys,
and run:

```sh
supabase functions serve kaibigan-ai --env-file supabase/.env.local
```

Gemini is always attempted first; Groq is the fallback. Optional function
secrets are `GEMINI_MODEL`, `GROQ_FALLBACK_MODEL`, and `ALLOWED_ORIGIN`.

The function enforces JWT authentication, input limits, best-effort per-instance
rate limiting, provider fallbacks, non-storage of model responses, and structured
internal analysis. Journal text and generated responses are not written to logs.
