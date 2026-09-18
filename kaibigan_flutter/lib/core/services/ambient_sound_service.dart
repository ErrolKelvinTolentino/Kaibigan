import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// One selectable background sound for a breathing session.
@immutable
class AmbientSound {
  const AmbientSound({
    required this.id,
    required this.label,
    required this.description,
    this.assetPath,
    this.volume = 0.5,
  });

  final String id;
  final String label;

  /// What this sound is good for, so the choice is a decision, not a guess.
  final String description;

  /// Null for silence.
  final String? assetPath;

  /// Per-track level, balancing loops that differ in perceived loudness.
  final double volume;

  bool get isSilent => assetPath == null;
}

/// The ambience catalogue. Every loop is synthesised by
/// `tool/generate_breathing_sounds.py` and released with the app as CC0, so
/// nothing here depends on a third-party sample licence.
class AmbientSounds {
  const AmbientSounds._();

  static const silence = AmbientSound(
    id: 'none',
    label: 'Silence',
    description: 'No sound. Best if you are somewhere already quiet.',
  );

  static const all = <AmbientSound>[
    silence,
    AmbientSound(
      id: 'rain',
      label: 'Rain',
      description: 'Steady rainfall. Covers noisy rooms and busy streets.',
      assetPath: 'breathing sounds/rain.wav',
      volume: 0.42,
    ),
    AmbientSound(
      id: 'ocean',
      label: 'Ocean',
      description: 'Slow waves that rise and fall. Good to pace a long exhale.',
      assetPath: 'breathing sounds/ocean.wav',
      volume: 0.55,
    ),
    AmbientSound(
      id: 'synth',
      label: 'Synth pad',
      description: 'A warm, unchanging drone. Least distracting for focus.',
      assetPath: 'breathing sounds/synth_pad.wav',
      volume: 0.34,
    ),
    AmbientSound(
      id: 'chimes',
      label: 'Chimes',
      description: 'Soft wind chimes at random. Gentle if silence feels tense.',
      assetPath: 'breathing sounds/chimes.wav',
      volume: 0.40,
    ),
    AmbientSound(
      id: 'hum',
      label: 'Deep hum',
      description: 'A low, even hum. Steadying when rain feels too busy.',
      assetPath: 'breathing sounds/deep_hum.wav',
      volume: 0.46,
    ),
  ];

  static AmbientSound byId(String id) => all.firstWhere(
        (sound) => sound.id == id,
        orElse: () => silence,
      );
}

/// Plays one looping ambience track at a time.
abstract class AmbientSoundController {
  AmbientSound get current;

  Future<void> play(AmbientSound sound);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

/// Records requests without touching an audio device. Used by widget tests and
/// as the fallback wherever playback is unavailable.
class SilentAmbientSoundController implements AmbientSoundController {
  final List<String> requestedSoundIds = [];

  AmbientSound _current = AmbientSounds.silence;

  @override
  AmbientSound get current => _current;

  @override
  Future<void> play(AmbientSound sound) async {
    _current = sound;
    requestedSoundIds.add(sound.id);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// The real player.
///
/// Audio is a comfort, never a requirement: every failure is swallowed so a
/// device without working playback still runs the breathing session normally.
class AmbientSoundPlayer implements AmbientSoundController {
  AmbientSoundPlayer({AudioPlayer? player})
      : _player = player ?? AudioPlayer(playerId: 'kaibigan-ambience');

  final AudioPlayer _player;
  AmbientSound _current = AmbientSounds.silence;
  bool _disposed = false;

  @override
  AmbientSound get current => _current;

  @override
  Future<void> play(AmbientSound sound) async {
    if (_disposed) return;
    _current = sound;
    try {
      await _player.stop();
      if (sound.isSilent) return;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(sound.volume);
      await _player.play(AssetSource(sound.assetPath!), volume: sound.volume);
    } catch (_) {
      // A silent session is a working session.
    }
  }

  @override
  Future<void> pause() async {
    if (_disposed || _current.isSilent) return;
    try {
      await _player.pause();
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    if (_disposed || _current.isSilent) return;
    try {
      await _player.resume();
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.stop();
      await _player.dispose();
    } catch (_) {}
  }
}
