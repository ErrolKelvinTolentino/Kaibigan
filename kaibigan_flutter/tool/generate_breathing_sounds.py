"""Generates the seamless ambient loops offered during breathing sessions.

Run from the Flutter project root:

    python tool/generate_breathing_sounds.py

Every loop is synthesised here rather than sampled, so the resulting audio is
original work released with the app under CC0 / public domain. Regenerating is
deterministic: the seed is fixed per track, so re-running produces byte-identical
files and the repository stays diff-clean.

Seamlessness comes from a tail crossfade. Noise is generated for `loop + fade`
seconds and the extra tail is mixed back over the head with equal-power weights,
so the wrap point is continuous and the loudness never dips. Tonal tracks use
frequencies that are exact multiples of 1/loop, which are periodic by
construction and need no crossfade.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 22050
LOOP_SECONDS = 36.0
FADE_SECONDS = 3.5
OUTPUT_DIR = os.path.join("assets", "breathing sounds")

LOOP_SAMPLES = int(SAMPLE_RATE * LOOP_SECONDS)
FADE_SAMPLES = int(SAMPLE_RATE * FADE_SECONDS)


def crossfade_tail(samples):
    """Wraps `LOOP_SAMPLES + FADE_SAMPLES` of audio into a seamless loop."""
    out = list(samples[:LOOP_SAMPLES])
    for i in range(FADE_SAMPLES):
        t = i / FADE_SAMPLES
        head = math.sin(t * math.pi / 2)
        tail = math.cos(t * math.pi / 2)
        out[i] = out[i] * head + samples[LOOP_SAMPLES + i] * tail
    return out


def normalise(samples, peak=0.72):
    loudest = max(abs(value) for value in samples) or 1.0
    scale = peak / loudest
    return [value * scale for value in samples]


def write_wav(name, samples):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, name)
    frames = bytearray()
    for value in samples:
        clipped = max(-1.0, min(1.0, value))
        frames += struct.pack("<h", int(clipped * 32767))
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        handle.writeframes(bytes(frames))
    print(f"{path}  {len(frames) / 1024:.0f} KB")


def one_pole_lowpass(samples, cutoff_hz):
    alpha = 1 - math.exp(-2 * math.pi * cutoff_hz / SAMPLE_RATE)
    out = []
    state = 0.0
    for value in samples:
        state += alpha * (value - state)
        out.append(state)
    return out


def one_pole_highpass(samples, cutoff_hz):
    low = one_pole_lowpass(samples, cutoff_hz)
    return [value - low[i] for i, value in enumerate(samples)]


def white_noise(count, seed):
    rng = random.Random(seed)
    return [rng.uniform(-1.0, 1.0) for _ in range(count)]


def rain():
    """Steady rain on a window: shaped noise plus sparse droplet transients."""
    total = LOOP_SAMPLES + FADE_SAMPLES
    body = one_pole_lowpass(white_noise(total, 20260910), 2600)
    body = one_pole_highpass(body, 220)

    rng = random.Random(11)
    droplets = [0.0] * total
    # Evenly distribute droplets without hard boundaries
    for _ in range(int(LOOP_SECONDS * 30)):
        start = rng.randrange(0, total - 450)
        length = rng.randint(140, 420)
        pitch = rng.uniform(900, 2600)
        gain = rng.uniform(0.15, 0.45)
        for i in range(length):
            index = start + i
            decay = math.exp(-6.0 * i / length)
            droplets[index] += gain * decay * math.sin(
                2 * math.pi * pitch * i / SAMPLE_RATE
            )

    mixed = [body[i] * 1.0 + droplets[i] * 0.5 for i in range(total)]
    return normalise(crossfade_tail(mixed), peak=0.66)


def ocean():
    """Slow shore waves: brown noise under a breathing swell."""
    total = LOOP_SAMPLES + FADE_SAMPLES
    raw = white_noise(total, 5150)
    brown = []
    state = 0.0
    for value in raw:
        state = state * 0.994 + value * 0.06
        brown.append(state)
    brown = one_pole_lowpass(brown, 1100)

    # 3 natural rolling swells over 36s (12s per wave), resting gently in troughs at seams.
    shaped = []
    for i, value in enumerate(brown):
        phase = 2 * math.pi * 3 * i / LOOP_SAMPLES
        swell = 0.38 + 0.62 * (0.5 - 0.5 * math.cos(phase)) ** 1.6
        shaped.append(value * swell)
    return normalise(crossfade_tail(shaped), peak=0.70)


def synth_pad():
    """A warm drone with seamless tail crossfade and slow organic drift."""
    total = LOOP_SAMPLES + FADE_SAMPLES
    base = 4 / LOOP_SECONDS

    def snap(freq):
        return max(1, round(freq / base)) * base

    voices = [
        (snap(110.0), 0.34, 0.0),
        (snap(164.8), 0.22, 0.9),
        (snap(220.0), 0.19, 1.8),
        (snap(329.6), 0.11, 2.6),
        (snap(440.0), 0.07, 0.4),
        (snap(659.2), 0.04, 1.2),
    ]
    tremolo = 1 / LOOP_SECONDS

    out = []
    for i in range(total):
        t = i / SAMPLE_RATE
        value = 0.0
        for freq, gain, phase in voices:
            value += gain * math.sin(2 * math.pi * freq * t + phase)
        swell = 0.82 + 0.18 * math.sin(2 * math.pi * tremolo * t)
        out.append(value * swell)
    return normalise(crossfade_tail(out), peak=0.52)


def chimes():
    """Wind chimes: decaying bell partials struck on the loop's own grid."""
    out = [0.0] * LOOP_SAMPLES
    rng = random.Random(777)
    scale = [523.25, 587.33, 698.46, 783.99, 880.00, 1046.50]

    for _ in range(int(LOOP_SECONDS * 2)):
        start = rng.randrange(0, LOOP_SAMPLES)
        root = rng.choice(scale)
        gain = rng.uniform(0.20, 0.46)
        decay_seconds = rng.uniform(1.4, 3.1)
        length = int(decay_seconds * SAMPLE_RATE)
        for i in range(length):
            decay = math.exp(-4.2 * i / length)
            t = i / SAMPLE_RATE
            sample = (
                math.sin(2 * math.pi * root * t)
                + 0.42 * math.sin(2 * math.pi * root * 2.76 * t)
                + 0.18 * math.sin(2 * math.pi * root * 5.4 * t)
            )
            out[(start + i) % LOOP_SAMPLES] += gain * decay * sample
    return normalise(out, peak=0.58)


def deep_hum():
    """A low, even hum for people who find rain or tones distracting."""
    total = LOOP_SAMPLES + FADE_SAMPLES
    raw = white_noise(total, 90210)
    brown = []
    state = 0.0
    for value in raw:
        state = state * 0.996 + value * 0.04
        brown.append(state)
    brown = one_pole_lowpass(brown, 420)
    return normalise(crossfade_tail(brown), peak=0.62)


def main():
    write_wav("rain.wav", rain())
    write_wav("ocean.wav", ocean())
    write_wav("synth_pad.wav", synth_pad())
    write_wav("chimes.wav", chimes())
    write_wav("deep_hum.wav", deep_hum())


if __name__ == "__main__":
    main()
