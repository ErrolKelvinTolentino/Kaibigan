# Breathing session ambience

These five loops are the background sounds offered on the breathing screen.

**They are not sampled recordings.** Every file is synthesised from scratch by
[`tool/generate_breathing_sounds.py`](../../tool/generate_breathing_sounds.py)
— filtered noise, additive sine partials and decaying bell tones — so the audio
is original work shipped with the app under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (public domain).
Nothing here depends on a third-party sample licence or attribution.

| File | Offered as | Built from |
| --- | --- | --- |
| `rain.wav` | Rain | Band-limited noise plus sparse droplet transients |
| `ocean.wav` | Ocean | Brown noise under a two-per-loop swell |
| `synth_pad.wav` | Synth pad | Six loop-periodic sine partials with a slow tremolo |
| `chimes.wav` | Chimes | Pentatonic bell strikes wrapped around the loop |
| `deep_hum.wav` | Deep hum | Low-passed brown noise |

Each file is 8 seconds, mono, 22 050 Hz, 16-bit PCM. The loops are seamless: a
tail crossfade (or exact harmonic periodicity, for the tonal tracks) makes the
wrap point continuous, so nothing clicks when a track repeats.

## Regenerating

From the `kaibigan_flutter` directory:

```bash
python tool/generate_breathing_sounds.py
```

The script is deterministic — each track has a fixed seed — so re-running it
reproduces byte-identical files and leaves the repository diff-clean.
