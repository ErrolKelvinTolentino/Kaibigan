# Kaibigan database contract

The schema is based on the app's actual persistence paths, not every planned
feature. There are eight active public tables after the September 3 alignment.

| Table | Purpose / current reader and writer |
| --- | --- |
| `profiles` | Account identity and companion/language preferences (`UserProvider`). Its ID belongs to `auth.users`. |
| `journal_entries` | Journal text, standalone AI replies, favorites/tags, ordered `conversation_turns` JSON, and the saved look-back `summary` JSON of recap/moments/advice (`JournalProvider`). |
| `gratitude_entries` | Gratitude text, flower type and stable 10-slot garden placement (`GratitudeProvider`). No watering/growth mechanic. |
| `mood_logs` | Mood, stress, energy, sleep quality and anxiety check-ins (`MoodProvider`). |
| `future_letters` | Letters, delivery dates and opened status (`LettersProvider`). |
| `routine_logs` | Actual completed routines and standalone activities, including sleep/focus/highlight/breathing (`RoutinesProvider`). |
| `user_memories` | User-controlled AI personalization summaries (`AIMemoryService`). |
| `learning_progress` | Per-account lesson completion, viewed/helpful idea indexes, and resume position (`LearningProgressStore` / `LearningProgressSync`). |

## What was removed

- `daily_goals`: no current UI consumes the old provider. The provider and its
  startup registration were removed too.
- `routine_configs`: the app already persists custom routines, reminder settings,
  step order and enabled states locally. This unused cloud table lacked the full
  configuration model. It is not a dependency of `routine_logs.routine_id`.
- `gratitude_entries.water_count` and any leftover `growth_stage`: obsolete mechanics.
- `journal_entries.reflection_seed_stage`: no screen uses this old growth score.

The migration drops the two unused tables **only if they are empty**. It does not
delete personal journal, gratitude, mood, routine, letter or memory records. The
obsolete counter/stage values themselves are removed, so keep a backup if their
history matters. Other schemas and unknown tables are not touched.

## Why there are not more tables

- **Streaks:** computed from dated activity records in the user's local calendar.
  Journey uses journal/gratitude/mood dates; routine streaks use routine logs.
  Storing another counter would duplicate data and drift after edits/deletions.
- **Lesson content:** shipped offline in `LearningCatalog`. The new table saves
  personal progress, not a second copy of all lesson text.
- **AI replies:** journal conversations use `conversation_turns` (ordered objects
  with `user`, `assistant`, `companion`) plus a readable `ai_response` summary.
  No separate redundant generic AI-response table is needed. Lesson questions
  remain transient and are not silently added to journal/history or AI memory.
- **Weekly reflections:** continue to be cached on-device, as does activity/reply
  feedback. This migration does not silently upload that data.
- **Routine configuration/session, appearance and onboarding:** remain local.

## Deploy to an existing Supabase project

1. Take/export a database backup first. Retire old builds or schedule maintenance:
   old clients that still write removed columns are not compatible with this cleanup.
2. Run `supabase/migrations/20260903010000_align_active_features.sql` as one script
   in the project's SQL Editor (or use the normal Supabase migration pipeline).
   Do **not** paste the context-only schema export or use `supabase_setup.sql`
   to update an existing database.
3. The transaction stops and rolls back if unused tables contain rows, ownership
   is missing, a profile has no auth user, garden slots fall outside 0–9, duplicate
   garden positions exist, scores are invalid, or legacy conversation JSON cannot
   be decoded. Inspect/export/repair the affected data; do not bypass guards by
   deleting user records indiscriminately. If the editor keeps the connection in
   an aborted transaction, issue `ROLLBACK;` before retrying.
4. Deploy the matching Flutter build. Verify sign-in/profile creation, journal
   create/edit/read, flower planting, lessons across two devices and account deletion.

For a brand-new project only, use `database/supabase_setup.sql`. Historical
migrations are retained unchanged for reproducibility; the new migration is the
authoritative upgrade. Live Supabase is not changed merely by editing these files.

### Conversation compatibility

The migration copies valid `__KAIBIGAN_TURNS_V1__` encoded responses into the JSON
column while preserving the original `ai_response` text. The new app reads both
formats and writes structured turns on subsequent saves. It does not guess how
ambiguous legacy paragraphs should be split. Older malformed responses block
migration instead of being discarded.

### Lesson progress and privacy

Signed-in progress is cached under that account ID, with field-level pending
updates retried on subsequent learning reads/writes. New devices fetch account
progress. Concurrent changes to the same field across devices use last-write-wins;
this is not a collaborative editing protocol.

Older unscoped device preferences have no trustworthy owner: they remain on-device
and readable in the unsigned/local path but are **not automatically uploaded or
assigned to the next account that signs in**. Signed-in progress starts from that
account's cloud/cache data. Guest progress does not sync. Offline operation retains
pending changes; failed network writes do not erase them.

## Security and validation

Every active table has owner-only authenticated RLS, no anonymous table grants,
non-null ownership, indexed owner queries and cascading account deletion. The
alignment replaces existing policies on these eight tables with the owner policy;
review any custom admin-sharing policy before deployment. Server triggers maintain
`updated_at` where the app stores it. No triggers generate fabricated activity.

`database/tests/validate_schema.mjs` runs real PostgreSQL SQL in an isolated PGlite
database with minimal test auth roles. It validates fresh/upgrade parity, safe
reruns, original-content preservation, RLS, score checks, timestamp triggers,
cascades and rollback guards. It does not access the production project.

Run it with Node and an installed `@electric-sql/pglite` package:

```text
node database/tests/validate_schema.mjs <absolute-path-to-pglite/dist/index.js>
```

App coverage includes `learning_progress_sync_test.dart`,
`journal_conversation_model_test.dart`, `mental_health_learning_test.dart`,
`demo_seed_manifest_test.dart` and the garden/entry tests.
