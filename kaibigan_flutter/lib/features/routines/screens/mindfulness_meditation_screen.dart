import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/ambient_sound_service.dart';
import '../../../core/services/ui_sound_service.dart';
import '../../../core/widgets/kaibigan_sound_scope.dart';
import '../../../core/widgets/cozy_confirm_sheet.dart';
import '../../../core/widgets/cozy_feature_banner.dart';
import '../../mood_tracking/mood_model.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

const String _soundPreferenceKey = 'breathing_ambient_sound';

class MindfulnessMeditationScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool routineMode;

  /// Injected in tests so no real audio device is touched.
  final AmbientSoundController? soundPlayer;

  const MindfulnessMeditationScreen({
    super.key,
    this.onCompleted,
    this.routineMode = false,
    this.soundPlayer,
  });

  @override
  State<MindfulnessMeditationScreen> createState() =>
      _MindfulnessMeditationScreenState();
}

class _MindfulnessMeditationScreenState
    extends State<MindfulnessMeditationScreen>
    with SingleTickerProviderStateMixin {
  /// Named techniques rather than moods, so the choice can be made on what is
  /// actually happening right now. Each card states the method and the need it
  /// answers; the counts are the ones the technique is normally taught with.
  static const _patterns = [
    _BreathPattern(
      id: 'extended_exhale',
      title: 'Extended exhale',
      need: 'To come down after stress',
      purpose:
          'The out-breath is longer than the in-breath, which is the part of '
          'the cycle that slows your heart rate. The everyday choice when you '
          'are wound up and want to settle.',
      phases: [
        _BreathPhase(
          label: 'Inhale',
          seconds: 4,
          scale: 1.13,
          guidance: 'Breathe in through nose',
        ),
        _BreathPhase(
          label: 'Exhale',
          seconds: 6,
          scale: 0.78,
          guidance: 'Slow exhale through mouth',
        ),
      ],
    ),
    _BreathPattern(
      id: 'physiological_sigh',
      title: 'Physiological sigh',
      need: 'To drop a spike of panic fast',
      purpose:
          'Two stacked inhales reopen collapsed air sacs, then one long exhale '
          'clears the CO₂ behind that spike. The quickest of these methods — '
          'often enough after one or two rounds.',
      phases: [
        _BreathPhase(
          label: 'Inhale',
          seconds: 3,
          scale: 1.08,
          guidance: 'Breathe in through nose',
        ),
        _BreathPhase(
          label: 'Top up',
          seconds: 1,
          scale: 1.17,
          guidance: 'Sniff again',
        ),
        _BreathPhase(
          label: 'Exhale',
          seconds: 7,
          scale: 0.76,
          guidance: 'Long, slow sigh out',
        ),
      ],
    ),
    _BreathPattern(
      id: 'box',
      title: 'Box breathing',
      need: 'To stay clear-headed under pressure',
      purpose:
          'Four equal counts, taught to people who need to think straight while '
          'stressed. Use it before an exam, a shift, or a hard conversation — '
          'it steadies you without making you drowsy.',
      phases: [
        _BreathPhase(
          label: 'Inhale',
          seconds: 4,
          scale: 1.13,
          guidance: 'In through your nose',
        ),
        _BreathPhase(
          label: 'Hold',
          seconds: 4,
          scale: 1.13,
          guidance: 'Gently hold',
        ),
        _BreathPhase(
          label: 'Exhale',
          seconds: 4,
          scale: 0.78,
          guidance: 'Steady breath out',
        ),
        _BreathPhase(
          label: 'Rest',
          seconds: 4,
          scale: 0.78,
          guidance: 'Rest and stay empty',
        ),
      ],
    ),
    _BreathPattern(
      id: 'four_seven_eight',
      title: '4-7-8 breathing',
      need: 'To quiet a racing mind at bedtime',
      purpose:
          'A long hold and a very long exhale. The count is demanding enough to '
          'occupy a mind that keeps looping, which is why it is usually taught '
          'for falling asleep. Four rounds is the standard dose.',
      phases: [
        _BreathPhase(
          label: 'Inhale',
          seconds: 4,
          scale: 1.13,
          guidance: 'Quietly breathe in',
        ),
        _BreathPhase(
          label: 'Hold',
          seconds: 7,
          scale: 1.13,
          guidance: 'Hold breath gently',
        ),
        _BreathPhase(
          label: 'Exhale',
          seconds: 8,
          scale: 0.74,
          guidance: 'Exhale with a soft whoosh',
        ),
      ],
    ),
    _BreathPattern(
      id: 'coherent',
      title: 'Coherent breathing',
      need: 'To steady ongoing anxiety',
      purpose:
          'Five in, five out — about six breaths a minute, the rate at which '
          'heart rate and breath fall into step. Nothing dramatic happens fast; '
          'this one rewards five or ten unbroken minutes.',
      phases: [
        _BreathPhase(
          label: 'Inhale',
          seconds: 5,
          scale: 1.11,
          guidance: 'Smooth breath in',
        ),
        _BreathPhase(
          label: 'Exhale',
          seconds: 5,
          scale: 0.80,
          guidance: 'Smooth breath out',
        ),
      ],
    ),
  ];

  /// The routine reset uses the plainest method so the copy on that screen
  /// stays true to what the session actually does.
  static const _routinePatternId = 'extended_exhale';

  _BreathPattern _pattern = _patterns.first;
  int _durationMinutes = 1;
  int _view = 0; // 0 setup, 1 session, 2 complete
  int _phaseIndex = 0;
  int _phaseSecondsLeft = 4;
  int _totalSecondsLeft = 60;
  bool _running = false;
  Timer? _timer;
  bool _recorded = false;
  late final AnimationController _breathController;
  Animation<double> _breathScale = const AlwaysStoppedAnimation(0.78);
  late final AmbientSoundController _ambience =
      widget.soundPlayer ?? AmbientSoundPlayer();
  AmbientSound _sound = AmbientSounds.silence;
  AmbientSound? _mutedSound;
  bool _soundLoaded = false;

  _BreathPhase get _phase => _pattern.phases[_phaseIndex];
  int get _targetSeconds => widget.routineMode ? 30 : _durationMinutes * 60;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.routineMode) {
      _pattern = _patterns.firstWhere(
        (pattern) => pattern.id == _routinePatternId,
        orElse: () => _patterns.first,
      );
    }
    _restoreSoundChoice();
  }

  Future<void> _restoreSoundChoice() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_soundPreferenceKey);
      if (!mounted || saved == null) {
        if (mounted) setState(() => _soundLoaded = true);
        return;
      }
      setState(() {
        _sound = AmbientSounds.byId(saved);
        _soundLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _soundLoaded = true);
    }
  }

  /// Mid-session the volume button only has to answer "not this, not now", so
  /// it mutes and restores the last real choice instead of opening the picker.
  void _toggleSessionSound() {
    if (!_sound.isSilent) {
      _mutedSound = _sound;
      unawaited(_selectSound(AmbientSounds.silence));
      return;
    }
    unawaited(_selectSound(_mutedSound ?? AmbientSounds.all[1]));
  }

  Future<void> _selectSound(AmbientSound sound) async {
    setState(() => _sound = sound);
    unawaited(
      _view == 1 && _running ? _ambience.play(sound) : _ambience.stop(),
    );
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_soundPreferenceKey, sound.id);
    } catch (_) {
      // A remembered preference is a convenience, not a requirement.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    unawaited(
      widget.soundPlayer == null ? _ambience.dispose() : _ambience.stop(),
    );
    super.dispose();
  }

  void _animateCurrentPhase({double? from}) {
    final start = from ?? _breathScale.value;
    _breathController.stop();
    _breathController.duration = Duration(seconds: _phase.seconds);
    _breathScale = Tween<double>(begin: start, end: _phase.scale).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOutSine,
      ),
    );
    _breathController.forward(from: 0);
  }

  void _begin() {
    _timer?.cancel();
    setState(() {
      _view = 1;
      _phaseIndex = 0;
      _phaseSecondsLeft = _pattern.phases.first.seconds;
      _totalSecondsLeft = _targetSeconds;
      _running = true;
      _recorded = false;
    });
    _animateCurrentPhase(from: 0.78);
    _startTimer();
    unawaited(_ambience.play(_sound));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || !_running) return;
    if (_totalSecondsLeft <= 1) {
      _complete();
      return;
    }

    var phaseChanged = false;
    setState(() {
      _totalSecondsLeft--;
      if (_phaseSecondsLeft <= 1) {
        _phaseIndex = (_phaseIndex + 1) % _pattern.phases.length;
        _phaseSecondsLeft = _phase.seconds;
        phaseChanged = true;
      } else {
        _phaseSecondsLeft--;
      }
    });
    if (phaseChanged) _animateCurrentPhase();
  }

  void _togglePause() {
    setState(() => _running = !_running);
    if (_running) {
      _breathController.forward();
      _startTimer();
      unawaited(_ambience.resume());
    } else {
      _timer?.cancel();
      _breathController.stop();
      unawaited(_ambience.pause());
    }
  }

  Future<void> _complete() async {
    _timer?.cancel();
    _breathController.stop();
    // Deliberately not awaited: a device whose audio stack is slow or missing
    // must not hold up the completion screen.
    unawaited(_ambience.stop());
    if (mounted) {
      KaibiganSoundScope.play(context, UiSound.complete);
      setState(() {
        _running = false;
        _totalSecondsLeft = 0;
        _view = 2;
      });
    }
    if (_recorded || !mounted) return;
    _recorded = true;
    await context.read<RoutinesProvider>().addLog(
          RoutineLog(
            id: '',
            routineId: 'breathing_${DateTime.now().millisecondsSinceEpoch}',
            routineType: RoutineType.midday,
            completedAt: DateTime.now(),
            focusOrHighlight: widget.routineMode
                ? 'Completed a 30-second ${_pattern.title} breathing reset.'
                : 'Completed $_durationMinutes minute ${_pattern.title} breathing exercise.',
          ),
        );
  }

  Future<void> _close() async {
    if (_view == 1 && _totalSecondsLeft < _targetSeconds) {
      final leave = await CozyConfirmSheet.show(
        context,
        title: 'End this breathing session?',
        message: 'Your progress in this session will not be saved.',
        confirmLabel: 'End session',
        cancelLabel: 'Keep breathing',
        icon: Icons.air_rounded,
      );
      if (!leave || !mounted) return;
    }
    _timer?.cancel();
    unawaited(_ambience.stop());
    if (mounted) Navigator.pop(context);
  }

  void _done() {
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: Column(
          children: [
            _BreathingHeader(
              view: _view,
              isDark: isDark,
              onClose: _close,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 750),
                reverseDuration: const Duration(milliseconds: 550),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.985, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: switch (_view) {
                  0 => _buildSetup(isDark),
                  1 => _buildSession(isDark),
                  _ => _buildComplete(isDark),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetup(bool isDark) {
    if (widget.routineMode) return _buildRoutineSetup(isDark);
    return SingleChildScrollView(
      key: const ValueKey('breathing-setup'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CozyFeatureBanner(
            eyebrow: 'Make room for one breath',
            title: 'Breathe with the rhythm',
            subtitle: 'Pick the method that fits the moment. '
                'The guide does the counting.',
            assetPath: FeatureIconHelper.breathing,
            placeholderLabel: 'breathing-landscape',
            placeholderIcon: Icons.air_rounded,
            accent: AppColors.honeyAmber,
            height: 170,
          ),
          const SizedBox(height: 24),
          Text('Choose a method',
              style: AppTypography.titleMedium(context, isDark: isDark)),
          const SizedBox(height: 7),
          Text(
            'These are established breathing techniques, each one for a '
            'different situation. Pick by what you need right now.',
            style: AppTypography.bodyMedium(context, isDark: isDark).copyWith(
              color: (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)
                  .withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 16),
          ..._patterns.map((pattern) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PatternCard(
                  pattern: pattern,
                  selected: _pattern.id == pattern.id,
                  isDark: isDark,
                  onTap: () => setState(() => _pattern = pattern),
                ),
              )),
          const SizedBox(height: 20),
          Text('BACKGROUND SOUND', style: _sectionLabel(isDark)),
          const SizedBox(height: 7),
          Text(
            'Optional. Sound plays on a loop while you breathe and stops when '
            'the session ends.',
            style: AppTypography.bodySmall(context, isDark: isDark).copyWith(
              color: (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)
                  .withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 11),
          _SoundPicker(
            key: const ValueKey('breathing-sound-picker'),
            selected: _sound,
            enabled: _soundLoaded,
            isDark: isDark,
            onSelected: _selectSound,
          ),
          const SizedBox(height: 20),
          Text('HOW LONG?', style: _sectionLabel(isDark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 5, 10].map((minutes) {
              final selected = _durationMinutes == minutes;
              return ChoiceChip(
                key: ValueKey('breathing-duration-$minutes'),
                selected: selected,
                label: Text('$minutes min'),
                onSelected: (_) => setState(() => _durationMinutes = minutes),
                selectedColor: AppColors.honeyAmber,
                backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected
                      ? AppColors.honeyAmber
                      : (isDark
                          ? AppColors.darkCardBorder
                          : const Color(0xFFE8E0D6)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('begin-breathing-button'),
            onPressed: _begin,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.honeyAmber,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19)),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Begin breathing',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineSetup(bool isDark) {
    return Center(
      key: const ValueKey('breathing-routine-setup'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: AppColors.honeyGold.withValues(
                    alpha: isDark ? 0.2 : 0.13,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.air_rounded,
                  color: AppColors.honeyAmber,
                  size: 48,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'A 30-second reset',
                style: AppTypography.titleLarge(context, isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 9),
              Text(
                'Three rounds of extended exhale: in for 4, out for 6. The '
                'longer out-breath is what slows your heart rate. The routine '
                'continues automatically when you finish.',
                style: AppTypography.bodyMedium(context, isDark: isDark)
                    .copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '30 SEC  •  EXTENDED EXHALE 4-6',
                style: _sectionLabel(isDark).copyWith(
                  color: AppColors.honeyAmber,
                ),
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                key: const ValueKey('begin-routine-breathing-button'),
                onPressed: _begin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: AppColors.honeyAmber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Start three breaths',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSession(bool isDark) {
    final minutes = (_totalSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_totalSecondsLeft % 60).toString().padLeft(2, '0');
    final sessionProgress =
        (1 - (_totalSecondsLeft / _targetSeconds)).clamp(0.0, 1.0);
    return Padding(
      key: const ValueKey('breathing-session'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _SessionPill(
                  icon: Icons.tune_rounded,
                  label: _pattern.title,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SessionPill(
                  icon: Icons.schedule_rounded,
                  label: '$minutes:$seconds',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: const ValueKey('breathing-sound-toggle'),
                tooltip: _sound.isSilent
                    ? 'Turn on background sound'
                    : 'Mute ${_sound.label}',
                onPressed: _toggleSessionSound,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : const Color(0xFFE8E0D6),
                  ),
                ),
                icon: Icon(
                  _sound.isSilent
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  size: 18,
                  color: AppColors.honeyAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: sessionProgress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFEDE5D8),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.honeyAmber),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: _pattern.phases.asMap().entries.map((entry) {
              final active = entry.key == _phaseIndex;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                  margin: EdgeInsets.only(
                    right: entry.key == _pattern.phases.length - 1 ? 0 : 6,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.honeyAmber.withValues(
                            alpha: isDark ? 0.23 : 0.13,
                          )
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? AppColors.honeyAmber
                          : (isDark
                              ? AppColors.darkCardBorder
                              : const Color(0xFFE8E0D6)),
                    ),
                  ),
                  child: Text(
                    entry.value.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active
                          ? AppColors.honeyAmber
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                      fontSize: 9.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: Duration(milliseconds: _phase.seconds <= 2 ? 200 : 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Text(
              _running ? _phase.label : 'Paused',
              key: ValueKey('breathing-phase-${_phase.label}-$_running'),
              style: const TextStyle(
                color: AppColors.honeyAmber,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox.square(
            dimension: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, _) => SizedBox.square(
                    dimension: 220,
                    child: CircularProgressIndicator(
                      value: (1.0 - _breathController.value).clamp(0.0, 1.0),
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      color: AppColors.honeyAmber,
                      backgroundColor: AppColors.honeyAmber.withValues(
                        alpha: isDark ? 0.13 : 0.10,
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _breathScale,
                  builder: (context, child) => Transform.scale(
                    key: const ValueKey('breath-orb-scale'),
                    scale: _breathScale.value,
                    child: child,
                  ),
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFFF2C66F),
                                const Color(0xFFA96E1E),
                              ]
                            : [AppColors.honeyLight, AppColors.warmHoney],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.58),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.honeyGold.withValues(alpha: 0.24),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOutQuad,
                            switchOutCurve: Curves.easeInQuad,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.90, end: 1.0)
                                    .animate(animation),
                                child: child,
                              ),
                            ),
                            child: Text(
                              '$_phaseSecondsLeft',
                              key: ValueKey(
                                'breathing-count-$_phaseSecondsLeft',
                              ),
                              style: const TextStyle(
                                color: AppColors.beeDark,
                                fontSize: 48,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'seconds',
                            style: TextStyle(
                              color: AppColors.beeDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: Duration(milliseconds: _phase.seconds <= 2 ? 200 : 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Text(
              _running ? _phase.guidance : 'Take your time. Resume when ready.',
              key: ValueKey('breathing-guidance-${_phase.label}-$_running'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge(context, isDark: isDark),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _close,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(88, 54),
                  foregroundColor: AppColors.honeyAmber,
                  side: BorderSide(
                    color: AppColors.honeyAmber.withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19)),
                ),
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text(
                  'End',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('breathing-pause-button'),
                  onPressed: _togglePause,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: AppColors.honeyAmber,
                    foregroundColor: AppColors.onHoney,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19)),
                  ),
                  icon: Icon(_running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(
                    _running ? 'Pause' : 'Resume',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplete(bool isDark) {
    return LayoutBuilder(
      key: const ValueKey('breathing-complete'),
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: AppColors.honeyGold
                      .withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.honeyAmber
                          .withValues(alpha: isDark ? 0.18 : 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    FeatureIconHelper.breathing,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.air_rounded,
                      color: AppColors.honeyAmber,
                      size: 80,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, curve: Curves.easeInOutCubic)
                  .scale(
                    begin: const Offset(.97, .97),
                    duration: 900.ms,
                    curve: Curves.easeInOutCubic,
                  ),
              const SizedBox(height: 24),
              Text('One breath quieter.',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge(context, isDark: isDark)),
              const SizedBox(height: 12),
              Text(
                widget.routineMode
                    ? 'You completed your 30-second ${_pattern.title.toLowerCase()} reset. Notice what feels different before moving on.'
                    : 'You completed a $_durationMinutes minute ${_pattern.title.toLowerCase()} practice. Notice what feels different before moving on.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(context, isDark: isDark)
                    .copyWith(height: 1.55),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _done,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: AppColors.honeyAmber,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(widget.routineMode ? 'Continue' : 'Return to my day',
                    style:
                        const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionLabel(bool isDark) => TextStyle(
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.15,
      );
}

class _BreathingHeader extends StatelessWidget {
  final int view;
  final bool isDark;
  final VoidCallback onClose;

  const _BreathingHeader(
      {required this.view, required this.isDark, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breathing exercise',
                  style: TextStyle(
                    color: AppColors.honeyAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  view == 0
                      ? 'Choose a rhythm'
                      : view == 1
                          ? 'Follow the guide'
                          : 'Session complete',
                  style: AppTypography.bodySmall(context, isDark: isDark),
                ),
              ],
            ),
          ),
          Icon(
            view == 2 ? Icons.check_circle_outline_rounded : Icons.air_rounded,
            color: AppColors.honeyAmber,
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final _BreathPattern pattern;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _PatternCard({
    required this.pattern,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.honeyGold.withValues(alpha: isDark ? 0.20 : 0.14)
          : (isDark ? AppColors.darkCard : Colors.white),
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: selected
                  ? AppColors.honeyAmber
                  : (isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE8E0D6)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? AppColors.honeyAmber
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pattern.title,
                          style: AppTypography.titleSmall(
                            context,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pattern.need,
                          style: const TextStyle(
                            color: AppColors.honeyAmber,
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pattern.notation,
                        style: const TextStyle(
                          color: AppColors.honeyAmber,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pattern.breathsPerMinute}/min',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pattern.purpose,
                style: AppTypography.bodySmall(context, isDark: isDark).copyWith(
                  color: (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight)
                      .withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _SessionPill(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
            color: isDark ? AppColors.darkCardBorder : const Color(0xFFE8E0D6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.honeyAmber),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(context, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathPattern {
  final String id;

  /// The name the technique is actually known by.
  final String title;

  /// The situation this method is for, phrased as a need.
  final String need;

  /// How the method works and when to reach for it.
  final String purpose;

  final List<_BreathPhase> phases;

  const _BreathPattern({
    required this.id,
    required this.title,
    required this.need,
    required this.purpose,
    required this.phases,
  });

  String get notation => phases.map((phase) => phase.seconds).join('-');

  int get cycleSeconds =>
      phases.fold(0, (total, phase) => total + phase.seconds);

  /// Breaths per minute, rounded — the number that tells you how slow a method
  /// really is.
  int get breathsPerMinute => (60 / cycleSeconds).round().clamp(1, 60);
}

class _BreathPhase {
  final String label;
  final int seconds;
  final double scale;

  /// A concrete instruction for this phase of this method.
  final String guidance;

  const _BreathPhase({
    required this.label,
    required this.seconds,
    required this.scale,
    required this.guidance,
  });
}

/// Horizontal chooser for the looping background sound. Each option states
/// what it is good for, so the pick is informed rather than a guess.
class _SoundPicker extends StatelessWidget {
  const _SoundPicker({
    super.key,
    required this.selected,
    required this.enabled,
    required this.isDark,
    required this.onSelected,
  });

  final AmbientSound selected;
  final bool enabled;
  final bool isDark;
  final ValueChanged<AmbientSound> onSelected;

  IconData _iconFor(String id) => switch (id) {
        'rain' => Icons.water_drop_outlined,
        'ocean' => Icons.waves_rounded,
        'synth' => Icons.graphic_eq_rounded,
        'hum' => Icons.blur_on_rounded,
        _ => Icons.volume_off_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AmbientSounds.all.map((sound) {
            final isSelected = sound.id == selected.id;
            return ChoiceChip(
              key: ValueKey('breathing-sound-${sound.id}'),
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                _iconFor(sound.id),
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
              label: Text(sound.label),
              onSelected: enabled ? (_) => onSelected(sound) : null,
              selectedColor: AppColors.honeyAmber,
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.honeyAmber
                    : (isDark
                        ? AppColors.darkCardBorder
                        : const Color(0xFFE8E0D6)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 9),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Row(
            key: ValueKey('breathing-sound-description-${selected.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.honeyAmber,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  selected.description,
                  style:
                      AppTypography.bodySmall(context, isDark: isDark).copyWith(
                    color: (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)
                        .withValues(alpha: 0.60),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
