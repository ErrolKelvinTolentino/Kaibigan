import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The interface cues the app can play.
///
/// Deliberately a small set. One cue per *kind* of moment keeps the app
/// sounding like a single instrument instead of a soundboard, and means a
/// person learns what each one means within a few minutes of use.
enum UiSound {
  /// Any ordinary press. The quietest cue, heard most often.
  tap,

  /// Choosing among options — a chip, a mood, a flower.
  select,

  /// A sheet, dialog or new screen arriving.
  open,

  /// A small thing saved: an entry, a log, a check-in.
  success,

  /// Something substantial finished: a lesson, a routine, a session.
  complete,

  /// Something needs attention. Soft and falling, never a buzz.
  gentle,
}

extension UiSoundAsset on UiSound {
  String get assetPath => switch (this) {
        UiSound.tap => 'ui sounds/tap.wav',
        UiSound.select => 'ui sounds/select.wav',
        UiSound.open => 'ui sounds/open.wav',
        UiSound.success => 'ui sounds/success.wav',
        UiSound.complete => 'ui sounds/complete.wav',
        UiSound.gentle => 'ui sounds/gentle.wav',
      };

  /// Rapid repeats of the same cue are swallowed inside this window, so a fast
  /// tapper hears a rhythm rather than a rattle.
  Duration get minimumGap => switch (this) {
        UiSound.tap => const Duration(milliseconds: 70),
        UiSound.select => const Duration(milliseconds: 90),
        UiSound.open => const Duration(milliseconds: 220),
        _ => const Duration(milliseconds: 320),
      };
}

/// How loud interface sound should be, including off.
///
/// A level rather than a switch: people who want the feedback often still want
/// it quieter than the app's own audio, and a slider would be more precision
/// than the choice deserves.
enum UiSoundLevel { off, soft, balanced, full }

extension UiSoundLevelX on UiSoundLevel {
  double get volume => switch (this) {
        UiSoundLevel.off => 0,
        UiSoundLevel.soft => 0.35,
        UiSoundLevel.balanced => 0.65,
        UiSoundLevel.full => 1.0,
      };

  bool get isSilent => this == UiSoundLevel.off;

  String get label => switch (this) {
        UiSoundLevel.off => 'Off',
        UiSoundLevel.soft => 'Soft',
        UiSoundLevel.balanced => 'Balanced',
        UiSoundLevel.full => 'Full',
      };

  static UiSoundLevel fromStorage(String? value) =>
      UiSoundLevel.values.firstWhere(
        (level) => level.name == value,
        orElse: () => UiSoundLevel.soft,
      );
}

/// Plays short interface cues.
abstract class UiSoundController {
  UiSoundLevel get level;

  /// Plays [sound] unless sound is off or the same cue just played.
  void play(UiSound sound);

  Future<void> setLevel(UiSoundLevel level);

  Future<void> load();

  Future<void> dispose();
}

/// Records requests without touching an audio device. Used by widget tests and
/// anywhere playback is unavailable.
class SilentUiSoundController implements UiSoundController {
  SilentUiSoundController({UiSoundLevel level = UiSoundLevel.soft})
      : _level = level;

  final List<UiSound> played = [];
  UiSoundLevel _level;

  @override
  UiSoundLevel get level => _level;

  @override
  void play(UiSound sound) {
    if (_level.isSilent) return;
    played.add(sound);
  }

  @override
  Future<void> setLevel(UiSoundLevel level) async => _level = level;

  @override
  Future<void> load() async {}

  @override
  Future<void> dispose() async {}
}

/// The real player.
///
/// Interface sound is decoration: every failure is swallowed, and nothing here
/// is ever awaited by the UI, so a device with no working audio behaves
/// exactly as it does today.
class UiSoundPlayer implements UiSoundController {
  UiSoundPlayer();

  static const String preferenceKey = 'ui_sound_level';

  final Map<UiSound, AudioPlayer> _players = {};
  final Map<UiSound, DateTime> _lastPlayed = {};
  UiSoundLevel _level = UiSoundLevel.soft;
  bool _loaded = false;
  bool _disposed = false;

  @override
  UiSoundLevel get level => _level;

  @override
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      _level = UiSoundLevelX.fromStorage(preferences.getString(preferenceKey));
    } catch (_) {
      // The default level is a working default.
    }
  }

  @override
  Future<void> setLevel(UiSoundLevel level) async {
    _level = level;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(preferenceKey, level.name);
    } catch (_) {
      // The in-memory level still governs the next cue.
    }
  }

  @override
  void play(UiSound sound) {
    if (_disposed || _level.isSilent) return;
    final now = DateTime.now();
    final last = _lastPlayed[sound];
    if (last != null && now.difference(last) < sound.minimumGap) return;
    _lastPlayed[sound] = now;
    // Deliberately not awaited: a cue must never delay the interaction that
    // triggered it.
    unawaited(_playNow(sound));
  }

  Future<void> _playNow(UiSound sound) async {
    try {
      final player = _players.putIfAbsent(
        sound,
        // One player per cue, so a tap landing during a success chime does not
        // cut the chime off.
        () => AudioPlayer(playerId: 'kaibigan-ui-${sound.name}')
          ..setPlayerMode(PlayerMode.lowLatency)
          ..setReleaseMode(ReleaseMode.stop),
      );
      await player.stop();
      await player.play(
        AssetSource(sound.assetPath),
        volume: _level.volume,
      );
    } catch (_) {
      // A silent interface is a working interface.
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _players.clear();
  }
}
