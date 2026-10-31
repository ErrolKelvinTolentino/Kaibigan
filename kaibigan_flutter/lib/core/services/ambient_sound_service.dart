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
  int _transitionToken = 0;

  @override
  AmbientSound get current => _current;

  Future<void> _fadeVolume({
    required int token,
    required double from,
    required double to,
    required Duration duration,
  }) async {
    const steps = 6;
    final stepDuration = Duration(
      milliseconds: (duration.inMilliseconds / steps).round(),
    );
    for (var i = 1; i <= steps; i++) {
      if (_disposed || token != _transitionToken) return;
      final progress = i / steps;
      final currentVol = from + (to - from) * progress;
      try {
        await _player.setVolume(currentVol.clamp(0.0, 1.0));
      } catch (_) {}
      await Future<void>.delayed(stepDuration);
    }
  }

  @override
  Future<void> play(AmbientSound sound) async {
    if (_disposed) return;
    final token = ++_transitionToken;
    final wasPlaying = !_current.isSilent;
    final previousSound = _current;
    _current = sound;

    try {
      if (wasPlaying && !sound.isSilent && previousSound.id == sound.id) {
        await _fadeVolume(
          token: token,
          from: 0.0,
          to: sound.volume,
          duration: const Duration(milliseconds: 200),
        );
        return;
      }

      if (wasPlaying) {
        await _fadeVolume(
          token: token,
          from: previousSound.volume,
          to: 0.0,
          duration: const Duration(milliseconds: 200),
        );
        if (_disposed || token != _transitionToken) return;
        await _player.stop();
      } else {
        await _player.stop();
      }

      if (sound.isSilent) return;
      if (_disposed || token != _transitionToken) return;

      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.0);
      await _player.play(AssetSource(sound.assetPath!), volume: 0.0);

      await _fadeVolume(
        token: token,
        from: 0.0,
        to: sound.volume,
        duration: const Duration(milliseconds: 300),
      );
    } catch (_) {
      // A silent session is a working session.
    }
  }

  @override
  Future<void> pause() async {
    if (_disposed || _current.isSilent) return;
    final token = ++_transitionToken;
    try {
      await _fadeVolume(
        token: token,
        from: _current.volume,
        to: 0.0,
        duration: const Duration(milliseconds: 180),
      );
      if (!_disposed && token == _transitionToken) {
        await _player.pause();
      }
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    if (_disposed || _current.isSilent) return;
    final token = ++_transitionToken;
    try {
      await _player.setVolume(0.0);
      await _player.resume();
      await _fadeVolume(
        token: token,
        from: 0.0,
        to: _current.volume,
        duration: const Duration(milliseconds: 250),
      );
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    final token = ++_transitionToken;
    try {
      if (!_current.isSilent) {
        await _fadeVolume(
          token: token,
          from: _current.volume,
          to: 0.0,
          duration: const Duration(milliseconds: 200),
        );
      }
      if (!_disposed && token == _transitionToken) {
        await _player.stop();
      }
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _transitionToken++;
    try {
      await _player.stop();
      await _player.dispose();
    } catch (_) {}
  }
}
