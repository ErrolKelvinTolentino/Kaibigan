import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_typography.dart';
import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../../../core/widgets/mobile_layout.dart';
import '../../companion/companion_model.dart';
import '../../../core/services/ui_sound_service.dart';
import '../../../core/widgets/kaibigan_sound_scope.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';
import '../sleep_insights.dart';
import 'sleep_energy_curve.dart';
import 'sleep_feedback_card.dart';
import 'sleep_status_card.dart';

class SleepLogFlowScreen extends StatefulWidget {
  const SleepLogFlowScreen({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  State<SleepLogFlowScreen> createState() => _SleepLogFlowScreenState();
}

class _SleepLogFlowScreenState extends State<SleepLogFlowScreen> {
  static const feelings = [
    SleepFeeling.energized,
    SleepFeeling.wellRested,
    SleepFeeling.moderate,
    SleepFeeling.groggy,
    SleepFeeling.restless,
  ];
  static const quickDurations = [6.0, 7.0, 8.0, 9.0];

  int _step = 0;
  SleepFeeling _feeling = SleepFeeling.moderate;
  double _hours = 7;
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);

  /// Clock times are the default because they unlock the cycle calculator and
  /// the energy forecast. The slider stays for nights nobody can reconstruct.
  bool _useClockTimes = true;
  bool _isSaving = false;
  SleepInsights? _insights;

  double get _effectiveHours => _useClockTimes
      ? SleepCycleCalculator.hoursBetween(_bedtime, _wakeTime)
      : _hours;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final provider = context.read<RoutinesProvider>();
    final duration = _storageDuration(_effectiveHours);
    await provider.addLog(
      RoutineLog(
        id: '',
        routineId: 'sleep_${DateTime.now().millisecondsSinceEpoch}',
        routineType: RoutineType.morning,
        sleepFeeling: _feeling,
        focusOrHighlight: SleepLogCodec.encode(
          durationLabel: duration,
          feeling: _feeling,
          bedtime: _useClockTimes ? _bedtime : null,
          wakeTime: _useClockTimes ? _wakeTime : null,
        ),
        completedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    if (provider.errorMessage != null) {
      KaibiganSoundScope.play(context, UiSound.gentle);
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('We could not save this sleep log. Try again.'),
          action: SnackBarAction(label: 'Retry', onPressed: _save),
        ),
      );
      return;
    }
    KaibiganSoundScope.play(context, UiSound.success);
    setState(() {
      _isSaving = false;
      _step = 2;
      _insights = SleepInsights.build(
        provider.logs,
        language: context.read<UserProvider>().language,
      );
    });
  }

  String _storageDuration(double value) {
    if (value < 1) return 'Less than 1';
    if (value >= 10) return '10+';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  String _durationLabel(double value) {
    if (value < 1) return 'Under 1 hour';
    if (value >= 10) return '10+ hours';
    final number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$number ${value == 1 ? 'hour' : 'hours'}';
  }

  void _close() {
    if (widget.onCompleted != null && _step == 2) {
      widget.onCompleted!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final mascot = MascotInfo.getById(
      context.watch<UserProvider>().selectedCompanion,
    );
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: _step == 1 ? 'Back to sleep quality' : 'Close',
          onPressed: _step == 1 ? () => setState(() => _step = 0) : _close,
          icon: Icon(
            _step == 1 ? Icons.arrow_back_ios_new_rounded : Icons.close_rounded,
          ),
        ),
        title: Text(
          _step == 2 ? 'Sleep saved' : 'Sleep log',
          style: AppTypography.heading3(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: MobileContent(
          child: AnimatedSwitcher(
            duration: KaibiganMotion.standard,
            switchInCurve: KaibiganMotion.enter,
            switchOutCurve: KaibiganMotion.exit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.025, 0.015),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: switch (_step) {
              0 => _QualityStep(
                  key: const ValueKey('sleep-quality-step'),
                  selected: _feeling,
                  onSelected: (value) => setState(() => _feeling = value),
                  onContinue: () => setState(() => _step = 1),
                ),
              1 => _ScheduleStep(
                  key: const ValueKey('sleep-duration-step'),
                  bedtime: _bedtime,
                  wakeTime: _wakeTime,
                  useClockTimes: _useClockTimes,
                  hours: _effectiveHours,
                  feeling: _feeling,
                  saving: _isSaving,
                  durationLabel: _durationLabel(_effectiveHours),
                  onBedtimeChanged: (value) =>
                      setState(() => _bedtime = value),
                  onWakeTimeChanged: (value) =>
                      setState(() => _wakeTime = value),
                  onUseClockTimesChanged: (value) => setState(() {
                    if (!value) _hours = _effectiveHours.clamp(0.5, 10);
                    _useClockTimes = value;
                  }),
                  onHoursChanged: (value) => setState(() => _hours = value),
                  onSave: _save,
                ),
              _ => _SuccessStep(
                  key: const ValueKey('sleep-success-step'),
                  mascot: mascot,
                  feeling: _feeling,
                  durationLabel: _durationLabel(_effectiveHours),
                  insights: _insights,
                  onDone: _close,
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _QualityStep extends StatelessWidget {
  const _QualityStep({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onContinue,
  });

  final SleepFeeling selected;
  final ValueChanged<SleepFeeling> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: MobileLayout.pageInsets(context, top: 10, bottom: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepHeader(current: 1),
              const SizedBox(height: 24),
              const _NightHeader(
                eyebrow: 'LAST NIGHT',
                title: 'How was your sleep last night?',
                subtitle:
                    'Choose the feeling closest to how your body feels now.',
                icon: Icons.nightlight_round,
              ),
              const SizedBox(height: 24),
              Semantics(
                label: 'Choose sleep quality',
                child: LayoutBuilder(
                  builder: (context, grid) {
                    const gap = 10.0;
                    final width = (grid.maxWidth - gap * 2) / 3;
                    Widget tile(SleepFeeling feeling) => SizedBox(
                          width: width,
                          child: _FeelingTile(
                            feeling: feeling,
                            selected: selected == feeling,
                            onTap: () => onSelected(feeling),
                          ),
                        );
                    return Column(
                      children: [
                        Row(
                          children: [
                            tile(_SleepLogFlowScreenState.feelings[0]),
                            const SizedBox(width: gap),
                            tile(_SleepLogFlowScreenState.feelings[1]),
                            const SizedBox(width: gap),
                            tile(_SleepLogFlowScreenState.feelings[2]),
                          ],
                        ),
                        const SizedBox(height: gap),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            tile(_SleepLogFlowScreenState.feelings[3]),
                            const SizedBox(width: gap),
                            tile(_SleepLogFlowScreenState.feelings[4]),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              KaibiganSurface(
                tone: KaibiganSurfaceTone.botanical,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(selected.icon, color: palette.botanical),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(selected.label, style: text.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            selected.description,
                            style: text.bodySmall?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'A quick check-in—not a test.',
                  style: text.bodySmall?.copyWith(color: palette.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeelingTile extends StatelessWidget {
  const _FeelingTile({
    required this.feeling,
    required this.selected,
    required this.onTap,
  });

  final SleepFeeling feeling;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return Semantics(
      button: true,
      selected: selected,
      label: '${feeling.label}. ${feeling.description}',
      child: AnimatedContainer(
        duration: KaibiganMotion.quick,
        decoration: BoxDecoration(
          color: selected ? palette.accentSubtle : palette.surfaceElevated,
          borderRadius: BorderRadius.circular(KaibiganRadius.card),
          border: Border.all(
            color: selected ? palette.accent : palette.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(KaibiganRadius.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 11),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        feeling.assetPath,
                        width: 66,
                        height: 66,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          feeling.icon,
                          size: 48,
                          color: palette.accent,
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: -2,
                          top: -1,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: palette.accent,
                            size: 21,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    feeling.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected
                              ? palette.accentStrong
                              : palette.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleStep extends StatelessWidget {
  const _ScheduleStep({
    super.key,
    required this.bedtime,
    required this.wakeTime,
    required this.useClockTimes,
    required this.hours,
    required this.feeling,
    required this.saving,
    required this.durationLabel,
    required this.onBedtimeChanged,
    required this.onWakeTimeChanged,
    required this.onUseClockTimesChanged,
    required this.onHoursChanged,
    required this.onSave,
  });

  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;
  final bool useClockTimes;
  final double hours;
  final SleepFeeling feeling;
  final bool saving;
  final String durationLabel;
  final ValueChanged<TimeOfDay> onBedtimeChanged;
  final ValueChanged<TimeOfDay> onWakeTimeChanged;
  final ValueChanged<bool> onUseClockTimesChanged;
  final ValueChanged<double> onHoursChanged;
  final VoidCallback onSave;

  Future<void> _pick(
    BuildContext context, {
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
    required String helpText,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: helpText,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final cycles = SleepCycleCalculator.bedtimesFor(wakeTime);
    // Whole cycles completed, which is what makes waking easy or groggy.
    final completedCycles = useClockTimes ? (hours * 60 / 90) : null;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: MobileLayout.pageInsets(context, top: 10, bottom: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepHeader(current: 2),
              const SizedBox(height: 24),
              const _NightHeader(
                eyebrow: 'YOUR NIGHT',
                title: 'When did you sleep?',
                subtitle:
                    'Clock times let Kaibigan work out your sleep cycles and '
                    'how today is likely to run. Estimates are fine.',
                icon: Icons.bedtime_outlined,
              ),
              const SizedBox(height: 22),
              KaibiganSurface(
                tone: KaibiganSurfaceTone.elevated,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                showShadow: true,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            key: const ValueKey('sleep-bedtime-field'),
                            label: 'WENT TO BED',
                            icon: Icons.nightlight_round,
                            time: bedtime,
                            enabled: useClockTimes && !saving,
                            onTap: () => _pick(
                              context,
                              initial: bedtime,
                              onPicked: onBedtimeChanged,
                              helpText: 'What time did you go to bed?',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeField(
                            key: const ValueKey('sleep-waketime-field'),
                            label: 'WOKE UP',
                            icon: Icons.wb_twilight_rounded,
                            time: wakeTime,
                            enabled: useClockTimes && !saving,
                            onTap: () => _pick(
                              context,
                              initial: wakeTime,
                              onPicked: onWakeTimeChanged,
                              helpText: 'What time did you wake up?',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: palette.accentSubtle,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            durationLabel,
                            key: const ValueKey('selected-sleep-duration'),
                            textAlign: TextAlign.center,
                            style: text.headlineSmall?.copyWith(
                              color: palette.accentStrong,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (completedCycles != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${completedCycles.floor()} full sleep '
                              '${completedCycles.floor() == 1 ? 'cycle' : 'cycles'}'
                              '${_partialCycleNote(completedCycles)}',
                              key: const ValueKey('sleep-cycle-readout'),
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('sleep-estimate-toggle'),
                        onPressed: saving
                            ? null
                            : () => onUseClockTimesChanged(!useClockTimes),
                        icon: Icon(
                          useClockTimes
                              ? Icons.tune_rounded
                              : Icons.schedule_rounded,
                          size: 17,
                        ),
                        label: Text(
                          useClockTimes
                              ? 'Not sure of the times? Estimate instead'
                              : 'Use bed and wake times',
                        ),
                      ),
                    ),
                    if (!useClockTimes) ...[
                      Semantics(
                        label: 'Sleep duration, $durationLabel',
                        slider: true,
                        child: Slider(
                          value: hours,
                          min: .5,
                          max: 10,
                          divisions: 19,
                          label: durationLabel,
                          onChanged: saving ? null : onHoursChanged,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Under 1h', style: text.bodySmall),
                            Text('10h+', style: text.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: _SleepLogFlowScreenState.quickDurations
                            .map(
                              (value) => ChoiceChip(
                                label: Text('${value.toInt()} h'),
                                selected: hours == value,
                                onSelected: saving
                                    ? null
                                    : (_) => onHoursChanged(value),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (useClockTimes) ...[
                const SizedBox(height: 16),
                KaibiganSurface(
                  key: const ValueKey('sleep-cycle-calculator'),
                  tone: KaibiganSurfaceTone.botanical,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            size: 18,
                            color: palette.botanical,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To wake at '
                              '${SleepInsights.formatTime(wakeTime)}, '
                              'go to bed by',
                              style: text.labelLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cycles
                            .map(
                              (option) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: palette.border),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      SleepInsights.formatTime(option.bedtime),
                                      style: text.titleSmall,
                                    ),
                                    Text(
                                      '${option.cycles} cycles · '
                                      '${SleepInsights.formatHours(option.hours)}',
                                      style: text.bodySmall?.copyWith(
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Each cycle runs about 90 minutes, plus 15 minutes to '
                        'fall asleep. Waking between cycles is easier than '
                        'waking in the middle of one.',
                        style: text.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              KaibiganSurface(
                tone: KaibiganSurfaceTone.botanical,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Image.asset(
                      feeling.assetPath,
                      width: 48,
                      height: 48,
                      errorBuilder: (_, __, ___) => Icon(
                        feeling.icon,
                        color: palette.botanical,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your check-in', style: text.labelMedium),
                          const SizedBox(height: 2),
                          Text(
                            '${feeling.label}  •  $durationLabel',
                            style: text.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_rounded, color: palette.botanical),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.onAccent,
                          ),
                        )
                      : const Icon(Icons.nightlight_round),
                  label: Text(saving ? 'Saving…' : 'Save sleep log'),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'You can remove this entry later from History.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: palette.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _partialCycleNote(double cycles) {
    final leftover = ((cycles - cycles.floor()) * 90).round();
    if (leftover < 8) return '';
    return ' + ${leftover}m';
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    super.key,
    required this.label,
    required this.icon,
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final TimeOfDay time;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label, ${SleepInsights.formatTime(time)}',
      child: Material(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(KaibiganRadius.card),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(KaibiganRadius.card),
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KaibiganRadius.card),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: enabled ? palette.accent : palette.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          color: palette.textMuted,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  SleepInsights.formatTime(time),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: enabled ? palette.textPrimary : palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    super.key,
    required this.mascot,
    required this.feeling,
    required this.durationLabel,
    required this.insights,
    required this.onDone,
  });

  final MascotInfo mascot;
  final SleepFeeling feeling;
  final String durationLabel;
  final SleepInsights? insights;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final language = context.watch<UserProvider>().language;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: MobileLayout.pageInsets(context, top: 16, bottom: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.accentSubtle,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  feeling.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    feeling.icon,
                    size: 90,
                    color: palette.accent,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sleep recorded',
                style:
                    text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                insights?.headline ??
                    'One gentle check-in at a time builds a clearer picture '
                        'of your rest.',
                key: const ValueKey('sleep-headline'),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              KaibiganSurface(
                tone: KaibiganSurfaceTone.elevated,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    _SuccessMetric(label: 'QUALITY', value: feeling.label),
                    Container(width: 1, height: 44, color: palette.border),
                    _SuccessMetric(label: 'DURATION', value: durationLabel),
                  ],
                ),
              ),
              if (insights != null) ...[
                const SizedBox(height: 12),
                SleepStatusCard(insights: insights!, language: language),
                const SizedBox(height: 12),
                SleepMetricsRow(insights: insights!, language: language),
                const SizedBox(height: 12),
                SleepTipsCard(insights: insights!, language: language),
                const SizedBox(height: 12),
                SleepEnergyCurveCard(insights: insights!),
                const SizedBox(height: 12),
                SleepFeedbackCard(insights: insights!, language: language),
              ],
              const SizedBox(height: 14),
              KaibiganSurface(
                tone: KaibiganSurfaceTone.botanical,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        mascot.materialIcon,
                        color: mascot.primaryColor,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${mascot.name}: Let this guide your pace today. Rest is information, never a score.',
                        style: text.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessMetric extends StatelessWidget {
  const _SuccessMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: palette.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return Semantics(
      label: 'Step $current of 2',
      child: Row(
        children: [
          Text(
            'STEP $current OF 2',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textMuted,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 12),
          for (var index = 1; index <= 2; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: KaibiganMotion.quick,
                height: 5,
                decoration: BoxDecoration(
                  color: index <= current ? palette.accent : palette.border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            if (index == 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _NightHeader extends StatelessWidget {
  const _NightHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: palette.accentSubtle,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: palette.accentStrong),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: text.labelSmall?.copyWith(
                  color: palette.accentStrong,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(title, style: text.headlineSmall),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: text.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
