"""Generates the interface sound cues used across the app.

Run from the Flutter project root:

    python tool/generate_ui_sounds.py

Like the breathing loops, every cue is synthesised here rather than sampled, so
the audio ships with the app as original work under CC0 / public domain, and
regenerating is deterministic.

Design rules these cues follow, because a wellness app is the wrong place for
sharp interface noise:

* Soft attacks. No click transient — every cue fades in over a few
  milliseconds so it never startles.
* Low-mid register. Partials sit under ~1.6 kHz where the ear is least
  fatigued by repetition.
* Short. A tap is under 120 ms; nothing exceeds 900 ms.
* Consonant. Everything is drawn from one pentatonic set, so two cues landing
  close together still sound like they belong to the same instrument.
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
OUTPUT_DIR = os.path.join("assets", "ui sounds")

# One warm pentatonic set (F major pentatonic, mid-register). Using a single
# scale everywhere is why rapid interactions never turn dissonant.
NOTES = {
    "F3": 174.61,
    "G3": 196.00,
    "A3": 220.00,
    "C4": 261.63,
    "D4": 293.66,
    "F4": 349.23,
    "G4": 392.00,
    "A4": 440.00,
    "C5": 523.25,
}


def envelope(index, total, attack_ms, release_ratio=1.0):
    """Soft attack, exponential decay. Never starts or ends on a step."""
    attack = max(1, int(SAMPLE_RATE * attack_ms / 1000))
    if index < attack:
        # Raised cosine in, so the onset has no edge at all.
        return 0.5 - 0.5 * math.cos(math.pi * index / attack)
    remaining = (index - attack) / max(1, total - attack)
    return math.exp(-release_ratio * 5.5 * remaining)


def tone(frequency, seconds, gain, attack_ms=6.0, release_ratio=1.0,
         partials=((1.0, 1.0), (2.0, 0.22), (3.0, 0.07))):
    """A struck, marimba-like tone: a few decaying partials, no harshness."""
    total = int(SAMPLE_RATE * seconds)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        value = 0.0
        for ratio, weight in partials:
            # Higher partials fade faster, which is what makes it read as wood
            # rather than a synth beep.
            partial_env = envelope(i, total, attack_ms, release_ratio * ratio)
            value += weight * partial_env * math.sin(2 * math.pi * frequency * ratio * t)
        samples.append(value * gain)
    return samples


def mix(*layers):
    length = max(len(layer) for layer in layers)
    out = [0.0] * length
    for layer in layers:
        for i, value in enumerate(layer):
            out[i] += value
    return out


def delay(samples, seconds):
    return [0.0] * int(SAMPLE_RATE * seconds) + samples


def normalise(samples, peak):
    loudest = max(abs(value) for value in samples) or 1.0
    scale = peak / loudest
    return [value * scale for value in samples]


def write_wav(name, samples, peak):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, name)
    frames = bytearray()
    for value in normalise(samples, peak):
        clipped = max(-1.0, min(1.0, value))
        frames += struct.pack("<h", int(clipped * 32767))
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        handle.writeframes(bytes(frames))
    print(f"{path}  {len(frames) / 1024:.0f} KB  {len(frames) / 2 / SAMPLE_RATE * 1000:.0f} ms")


def tap():
    """The everyday cue. Heard hundreds of times a day, so it is the quietest
    and shortest thing here — felt more than listened to."""
    return tone(NOTES["A4"], 0.09, 0.5, attack_ms=3.0, release_ratio=2.6,
                partials=((1.0, 1.0), (2.0, 0.12)))


def select():
    """For choosing among options: same family as the tap, a step brighter so
    a selection is distinguishable from an ordinary press."""
    return tone(NOTES["C5"], 0.12, 0.5, attack_ms=3.5, release_ratio=2.2,
                partials=((1.0, 1.0), (2.0, 0.16), (3.0, 0.05)))


def open_panel():
    """A sheet or page arriving: a low swell rather than a strike."""
    return tone(NOTES["F3"], 0.26, 0.42, attack_ms=38.0, release_ratio=1.1,
                partials=((1.0, 1.0), (2.0, 0.3), (4.0, 0.08)))


def success():
    """Two notes rising a fourth. Warm, not triumphant — most "successes" here
    are small private acts like saving a journal entry."""
    return mix(
        tone(NOTES["C4"], 0.34, 0.42, attack_ms=8.0, release_ratio=1.3),
        delay(tone(NOTES["F4"], 0.46, 0.40, attack_ms=8.0, release_ratio=1.1), 0.10),
    )


def complete():
    """For finishing something substantial — a lesson, a routine. Three notes
    resolving upward, still soft."""
    return mix(
        tone(NOTES["F3"], 0.46, 0.34, attack_ms=10.0, release_ratio=1.0),
        delay(tone(NOTES["A3"], 0.46, 0.32, attack_ms=10.0, release_ratio=1.0), 0.09),
        delay(tone(NOTES["C4"], 0.52, 0.36, attack_ms=10.0, release_ratio=0.9), 0.18),
        delay(tone(NOTES["F4"], 0.60, 0.26, attack_ms=14.0, release_ratio=0.85), 0.28),
    )


def gentle():
    """The "something needs your attention" cue. Deliberately not an error
    buzz: a falling major second, low and unhurried, so a mistake in a mental
    health app never feels like a reprimand."""
    return mix(
        tone(NOTES["G3"], 0.30, 0.40, attack_ms=12.0, release_ratio=1.2),
        delay(tone(NOTES["F3"], 0.42, 0.38, attack_ms=12.0, release_ratio=1.0), 0.12),
    )


def main():
    # Peaks differ per cue so the set is balanced by ear, not by maths: the tap
    # repeats constantly and has to sit well below the rarer, richer cues.
    write_wav("tap.wav", tap(), peak=0.22)
    write_wav("select.wav", select(), peak=0.28)
    write_wav("open.wav", open_panel(), peak=0.30)
    write_wav("success.wav", success(), peak=0.46)
    write_wav("complete.wav", complete(), peak=0.52)
    write_wav("gentle.wav", gentle(), peak=0.36)


if __name__ == "__main__":
    main()
