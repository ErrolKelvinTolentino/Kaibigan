# Interface sound cues

Six short cues the app plays for taps, saves and completions. They are wired up
by `lib/core/services/ui_sound_service.dart` and switched on or off from
**Settings → Sound**.

**They are not sampled recordings.** Every cue is synthesised by
[`tool/generate_ui_sounds.py`](../../tool/generate_ui_sounds.py) from decaying
sine partials, so the audio is original work shipped with the app under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (public domain),
with no third-party sample licence or attribution to track.

| File | Played when | Character |
| --- | --- | --- |
| `tap.wav` | Any ordinary press | 90 ms, the quietest cue in the set |
| `select.wav` | Choosing an option, mood or flower | 120 ms, one step brighter than a tap |
| `open.wav` | A screen, sheet or dialog arriving | A low swell rather than a strike |
| `success.wav` | An entry, log or check-in saved | Two notes rising a fourth |
| `complete.wav` | A lesson, routine or session finished | Four notes resolving upward |
| `gentle.wav` | Something needs a second look | A falling major second — never a buzz |

All files are mono, 44 100 Hz, 16-bit PCM; the set totals under 220 KB.

## Why they sound the way they do

* **Soft attacks.** Each cue fades in over a few milliseconds, so nothing has a
  click transient to startle someone who is already anxious.
* **One scale.** Everything is drawn from F major pentatonic, so two cues that
  land close together still sound consonant.
* **Low-mid register.** Partials stay under about 1.6 kHz, the range least
  fatiguing to hear repeatedly.
* **Balanced by ear, not by maths.** Peak levels differ per cue: the tap is
  heard hundreds of times a day and sits well below the rarer, richer ones.

## Regenerating

From the `kaibigan_flutter` directory:

```bash
python tool/generate_ui_sounds.py
```

The script is deterministic, so re-running it reproduces byte-identical files
and leaves the repository diff-clean.
