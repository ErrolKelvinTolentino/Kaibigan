import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/cozy_confirm_sheet.dart';
import '../../../core/widgets/cozy_feature_banner.dart';
import '../../mood_tracking/mood_model.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class MindfulnessMeditationScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool routineMode;

  const MindfulnessMeditationScreen({
    super.key,
    this.onCompleted,
    this.routineMode = false,
  });

  @override
  State<MindfulnessMeditationScreen> createState() =>
      _MindfulnessMeditationScreenState();
}

class _MindfulnessMeditationScreenState
    extends State<MindfulnessMeditationScreen>
    with SingleTickerProviderStateMixin {
  static const _patterns = [
    _BreathPattern(
      id: 'calm',
      title: 'Calm exhale',
      subtitle: 'A longer exhale for settling down',
      phases: [
        _BreathPhase('Inhale', 4, 1.13),
        _BreathPhase('Exhale', 6, 0.78),
      ],
    ),
    _BreathPattern(
      id: 'box',
      title: 'Box breathing',
      subtitle: 'Even timing for focus and steadiness',
      phases: [
        _BreathPhase('Inhale', 4, 1.13),
        _BreathPhase('Hold', 4, 1.13),
        _BreathPhase('Exhale', 4, 0.78),
        _BreathPhase('Rest', 4, 0.78),
      ],
    ),
    _BreathPattern(
      id: 'reset',
      title: 'Gentle reset',
      subtitle: 'A small pause before a slow release',
      phases: [
        _BreathPhase('Inhale', 4, 1.13),
        _BreathPhase('Hold softly', 2, 1.13),
        _BreathPhase('Exhale', 6, 0.78),
      ],
    ),
  ];

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

  _BreathPhase get _phase => _pattern.phases[_phaseIndex];
  int get _targetSeconds => widget.routineMode ? 30 : _durationMinutes * 60;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
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
    } else {
      _timer?.cancel();
      _breathController.stop();
    }
  }

  Future<void> _complete() async {
    _timer?.cancel();
    _breathController.stop();
    if (mounted) {
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
            subtitle: 'Choose a pace. The guide will do the counting.',
            assetPath: FeatureIconHelper.breathing,
            placeholderLabel: 'breathing-landscape',
            placeholderIcon: Icons.air_rounded,
            accent: AppColors.honeyAmber,
            height: 170,
          ),
          const SizedBox(height: 24),
          Text('Choose your rhythm',
              style: AppTypography.titleMedium(context, isDark: isDark)),
          const SizedBox(height: 7),
          Text(
            'Each pattern has a different job. Pick the one that matches this moment.',
            style: AppTypography.bodyMedium(context, isDark: isDark),
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
          const SizedBox(height: 16),
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
                'Three calm breaths with a longer exhale. The routine will continue automatically when you finish.',
                style: AppTypography.bodyMedium(context, isDark: isDark)
                    .copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '30 SEC  •  CALM EXHALE',
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
    final phaseProgress = (_phaseSecondsLeft / _phase.seconds).clamp(0.0, 1.0);
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
            duration: const Duration(milliseconds: 850),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
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
                TweenAnimationBuilder<double>(
                  tween: Tween(end: phaseProgress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                  builder: (context, value, child) => SizedBox.square(
                    dimension: 220,
                    child: CircularProgressIndicator(
                      value: value,
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
                            duration: const Duration(milliseconds: 650),
                            switchInCurve: Curves.easeInOutCubic,
                            switchOutCurve: Curves.easeInOutCubic,
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
            duration: const Duration(milliseconds: 900),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
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
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? AppColors.honeyAmber
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pattern.title,
                        style:
                            AppTypography.titleSmall(context, isDark: isDark)),
                    const SizedBox(height: 2),
                    Text(pattern.subtitle,
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                  ],
                ),
              ),
              Text(
                pattern.notation,
                style: const TextStyle(
                  color: AppColors.honeyAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
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
  final String title;
  final String subtitle;
  final List<_BreathPhase> phases;

  const _BreathPattern({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.phases,
  });

  String get notation => phases.map((phase) => phase.seconds).join('–');
}

class _BreathPhase {
  final String label;
  final int seconds;
  final double scale;

  const _BreathPhase(this.label, this.seconds, this.scale);

  String get guidance => switch (label) {
        'Inhale' => 'Let the breath arrive without pulling.',
        'Exhale' => 'Release slowly. Let your shoulders follow.',
        'Hold' || 'Hold softly' => 'Stay easy. There is nothing to force.',
        _ => 'Rest here before the next breath.',
      };
}
