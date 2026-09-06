# Mobile wellness update

## Supabase adjustments

**No new SQL migration or Edge Function deployment is required for this update.**
The app reads the existing mood, routine, journal, and gratitude records through
the current providers. No Supabase functions, authentication, or integrations
were changed as part of this work. Existing database setup still applies.

## What changed

- Routine activities use one activity header, with a compact routine context
  dock and an on-demand plan. Skipping every activity does not record a completed
  routine. Home cards have explicit actions and a weekly-insights entry point.
- The existing greeting card and features carousel design are preserved.
- Streaks count days with saved wellness activity, rather than app opens. A streak
  ending yesterday remains current throughout today. Empty history is zero;
  missing a day does not remove older activity. The home view refreshes its day
  boundary on midnight and when the app resumes.
- Weekly insights include check-ins, sleep, breathing, grounding, routines,
  journals, gratitude, and short reflections. Individual activities expose
  their own recent statistics. The same calculated summary is supplied to Kai
  for the optional weekly reflection.
- Learning uses a compact reader and persistent progression controls, with
  mobile text and translation improvements.

## How analytics work

The window is the last seven local calendar days, including today, compared
with the preceding seven. Future records are excluded. Mood averages weight
each logged day equally; repeated check-ins do not give a day extra weight.
Sleep uses the latest saved sleep entry for each day. Score comparisons require
at least three logged days in each period. Missing data stays unknown.

Sleep quality and sleep duration are separate. The previous parser's invented
seven-hour default has been removed. Existing exact `Slept N hrs/hours` values
can contribute to duration averages. Range entries such as `Less than 1` and
`10+` remain visible in history but do not become exact numbers. No data rewrite
is necessary. Durations cannot be reconstructed when an older record never
stored them.

Breathing and grounding counts use saved completion records, not navigation
clicks. Known breathing duration is extracted only from the app's established
completion templates; unknown durations are omitted and the sample size is
shown. Individual steps are separated from full routine completion records.

Rule-based observations work without an AI request. They describe the available
records and do not claim that more sessions caused better mental health.
Optional activity helpfulness feedback remains the existing device-local,
30-response history; it is not a complete synced treatment-effectiveness measure.

## Verification

From `kaibigan_flutter`, run:

```sh
flutter analyze --no-pub
flutter test --no-pub
```

The analytics tests cover calendar boundaries, missing/invalid/future data,
duplicate IDs, daily weighting, incomplete sleep duration, comparison thresholds,
and 320px layouts with enlarged English, Filipino, and Taglish text. Related
feature suites exercise navigation, persistence failure, lesson flow, and AI
guardrails.

Optional Windows visual previews can be regenerated with:

```sh
flutter test tool/render_mobile_previews_test.dart --update-goldens
```

Previews are written to `output/mobile-*.png`. This offline rendering helper uses
a local system font substitute; verify the final device build with the app's
Quicksand font and real stored data before release.
