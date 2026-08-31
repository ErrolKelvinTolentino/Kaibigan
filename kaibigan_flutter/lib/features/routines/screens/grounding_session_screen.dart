import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/cozy_feature_banner.dart';
import '../../mood_tracking/mood_model.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class GroundingSessionScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final bool routineMode;

  const GroundingSessionScreen({
    super.key,
    this.onCompleted,
    this.routineMode = false,
  });

  @override
  State<GroundingSessionScreen> createState() => _GroundingSessionScreenState();
}

class _GroundingSessionScreenState extends State<GroundingSessionScreen> {
  static const _steps = [
    _GroundingStep(
      count: 5,
      sense: 'See',
      title: 'Find five things you can see',
      prompt:
          'Let your eyes move slowly. Notice shape, color, light, and distance.',
      hint: 'A window, a shadow, something blue…',
      icon: Icons.visibility_outlined,
      color: Color(0xFF6F9775),
    ),
    _GroundingStep(
      count: 4,
      sense: 'Feel',
      title: 'Notice four things you can feel',
      prompt:
          'Bring attention to contact: feet, fabric, temperature, or support.',
      hint: 'My feet on the floor…',
      icon: Icons.touch_app_outlined,
      color: Color(0xFFD09355),
    ),
    _GroundingStep(
      count: 3,
      sense: 'Hear',
      title: 'Listen for three sounds',
      prompt:
          'Near or far, pleasant or ordinary. Let each sound arrive on its own.',
      hint: 'A fan, traffic, my breathing…',
      icon: Icons.hearing_outlined,
      color: Color(0xFF7896B1),
    ),
    _GroundingStep(
      count: 2,
      sense: 'Smell',
      title: 'Find two things you can smell',
      prompt:
          'Take an easy breath. If no scent stands out, notice the air itself.',
      hint: 'Coffee, soap, fresh air…',
      icon: Icons.air_rounded,
      color: Color(0xFF9A86AE),
    ),
    _GroundingStep(
      count: 1,
      sense: 'Taste',
      title: 'Notice one thing you can taste',
      prompt:
          'Notice a lingering flavor, a sip of water, or simply your mouth at rest.',
      hint: 'Water, mint, something subtle…',
      icon: Icons.water_drop_outlined,
      color: Color(0xFFB7776F),
    ),
  ];

  static const _routineSteps = [
    _GroundingStep(
      count: 3,
      sense: 'See',
      title: 'Notice three things you can see',
      prompt:
          'Let your eyes land on three colors, shapes, or sources of light.',
      hint: '',
      icon: Icons.visibility_outlined,
      color: Color(0xFF6F9775),
    ),
    _GroundingStep(
      count: 2,
      sense: 'Feel',
      title: 'Notice two points of contact',
      prompt:
          'Feel the support beneath you and one texture touching your body.',
      hint: '',
      icon: Icons.touch_app_outlined,
      color: Color(0xFFD09355),
    ),
    _GroundingStep(
      count: 1,
      sense: 'Hear',
      title: 'Notice one sound',
      prompt: 'Let one nearby or distant sound arrive without judging it.',
      hint: '',
      icon: Icons.hearing_outlined,
      color: Color(0xFF7896B1),
    ),
  ];

  final _notes = List.generate(5, (_) => TextEditingController());
  final _noticed = List.filled(5, 0);
  int _page = 0;
  bool _recorded = false;

  List<_GroundingStep> get _activeSteps =>
      widget.routineMode ? _routineSteps : _steps;
  int get _completePage => _activeSteps.length + 1;

  @override
  void initState() {
    super.initState();
    if (widget.routineMode) _page = 1;
  }

  @override
  void dispose() {
    for (final controller in _notes) {
      controller.dispose();
    }
    super.dispose();
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_page == 0 || (widget.routineMode && _page == 1)) {
      Navigator.maybePop(context);
    } else {
      setState(() => _page--);
    }
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (_page < _activeSteps.length) {
      setState(() => _page++);
      return;
    }
    if (!_recorded) {
      _recorded = true;
      final observations = _notes
          .where((controller) => controller.text.trim().isNotEmpty)
          .length;
      await context.read<RoutinesProvider>().addLog(
            RoutineLog(
              id: '',
              routineId: 'grounding_${DateTime.now().millisecondsSinceEpoch}',
              routineType: RoutineType.midday,
              completedAt: DateTime.now(),
              focusOrHighlight: widget.routineMode
                  ? 'Completed a quick 3-2-1 sensory grounding reset.'
                  : 'Completed 5-4-3-2-1 grounding with $observations saved observations.',
            ),
          );
      if (!mounted) return;
    }
    if (widget.routineMode) {
      _finish();
    } else {
      setState(() => _page = _completePage);
    }
  }

  void _finish() {
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
            _GroundingHeader(
              page: _page,
              routineMode: widget.routineMode,
              stepCount: _activeSteps.length,
              isDark: isDark,
              onBack: _goBack,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.035, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildPage(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(bool isDark) {
    if (_page == 0) {
      return _GroundingIntro(
        key: const ValueKey('grounding-intro'),
        isDark: isDark,
        onBegin: () => setState(() => _page = 1),
      );
    }
    if (_page == _completePage) {
      return _GroundingComplete(
        key: const ValueKey('grounding-complete'),
        isDark: isDark,
        onDone: _finish,
      );
    }
    final index = _page - 1;
    final step = _activeSteps[index];
    return _GroundingSensePage(
      key: ValueKey('grounding-step-${step.count}'),
      step: step,
      isDark: isDark,
      controller: _notes[index],
      noticed: _noticed[index],
      onNotice: () {
        if (_noticed[index] < step.count) {
          setState(() => _noticed[index]++);
        }
      },
      onUndo: () {
        if (_noticed[index] > 0) {
          setState(() => _noticed[index]--);
        }
      },
      onContinue: _continue,
      compact: widget.routineMode,
      isLast: index == _activeSteps.length - 1,
    );
  }
}

class _GroundingHeader extends StatelessWidget {
  final int page;
  final bool routineMode;
  final int stepCount;
  final bool isDark;
  final VoidCallback onBack;

  const _GroundingHeader({
    required this.page,
    required this.routineMode,
    required this.stepCount,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: page == 0 || (routineMode && page == 1) ? 'Close' : 'Back',
            onPressed: onBack,
            icon: Icon(page == 0 || (routineMode && page == 1)
                ? Icons.close_rounded
                : Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routineMode ? 'Quick 3–2–1 grounding' : '5–4–3–2–1 grounding',
                  style: TextStyle(
                    color: AppColors.honeyAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: List.generate(stepCount, (index) {
                    final active = page > index || page == stepCount + 1;
                    return Expanded(
                      child: AnimatedContainer(
                        key: ValueKey('grounding-progress-$index'),
                        duration: const Duration(milliseconds: 240),
                        height: 4,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.honeyAmber
                              : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE7E0D5)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            page == 0
                ? (routineMode ? '~30 sec' : '3–5 min')
                : page == stepCount + 1
                    ? 'Done'
                    : '$page of $stepCount',
            style: AppTypography.bodySmall(context, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _GroundingIntro extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBegin;

  const _GroundingIntro(
      {super.key, required this.isDark, required this.onBegin});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CozyFeatureBanner(
            eyebrow: 'Return to the room',
            title: 'Find the present',
            subtitle: 'Five senses. One steady step at a time.',
            assetPath: FeatureIconHelper.grounding,
            placeholderLabel: 'grounding-landscape',
            placeholderIcon: Icons.spa_outlined,
            accent: AppColors.honeyAmber,
            height: 196,
          ),
          const SizedBox(height: 24),
          Text(
            'Come back through your senses.',
            style: AppTypography.titleLarge(context, isDark: isDark),
          ),
          const SizedBox(height: 8),
          Text(
            'We will move through one sense at a time. Notice what is already around you; you never need to force an answer.',
            style: AppTypography.bodyMedium(context, isDark: isDark)
                .copyWith(height: 1.55),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard
                  : AppColors.honeyAmber.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.honeyAmber,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Move at your pace. This is noticing, not a test.',
                    style: AppTypography.bodySmall(context, isDark: isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('begin-grounding-button'),
            onPressed: onBegin,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.honeyAmber,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19)),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Begin grounding',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _GroundingSensePage extends StatelessWidget {
  final _GroundingStep step;
  final bool isDark;
  final TextEditingController controller;
  final int noticed;
  final VoidCallback onNotice;
  final VoidCallback onUndo;
  final VoidCallback onContinue;
  final bool isLast;
  final bool compact;

  const _GroundingSensePage({
    super.key,
    required this.step,
    required this.isDark,
    required this.controller,
    required this.noticed,
    required this.onNotice,
    required this.onUndo,
    required this.onContinue,
    required this.isLast,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    '${step.count}',
                    style: TextStyle(
                      color: step.color,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(step.icon, color: step.color, size: 18),
                        const SizedBox(width: 7),
                        Text(
                          step.sense,
                          style: TextStyle(
                            color: step.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.title,
                      style: AppTypography.titleMedium(context, isDark: isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            step.prompt,
            style: AppTypography.bodyLarge(context, isDark: isDark),
          ),
          const SizedBox(height: 24),
          if (!compact)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : step.color.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: step.color.withValues(
                            alpha: isDark ? 0.2 : 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$noticed',
                          style: TextStyle(
                            color: step.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          noticed == step.count
                              ? 'You found all ${step.count}.'
                              : '$noticed of ${step.count} noticed',
                          style:
                              AppTypography.titleSmall(context, isDark: isDark),
                        ),
                      ),
                      if (noticed > 0)
                        TextButton.icon(
                          onPressed: onUndo,
                          icon: const Icon(Icons.undo_rounded, size: 17),
                          label: const Text('Undo'),
                          style: TextButton.styleFrom(
                            foregroundColor: step.color,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(step.count, (index) {
                      final found = index < noticed;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 28,
                        height: 28,
                        margin: EdgeInsets.only(
                          right: index == step.count - 1 ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: found
                              ? step.color
                              : step.color.withValues(alpha: 0.09),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: step.color.withValues(
                              alpha: found ? 1 : 0.28,
                            ),
                          ),
                        ),
                        child: found
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 17),
                  FilledButton.icon(
                    key: ValueKey('notice-${step.count}'),
                    onPressed: noticed < step.count ? onNotice : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppColors.honeyAmber,
                      foregroundColor: AppColors.onHoney,
                      disabledBackgroundColor: step.color.withValues(
                        alpha: isDark ? 0.18 : 0.10,
                      ),
                      disabledForegroundColor: step.color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(noticed == step.count
                        ? Icons.check_rounded
                        : Icons.add_rounded),
                    label:
                        Text(noticed == step.count ? 'Noticed' : 'I found one'),
                  ),
                ],
              ),
            ),
          if (compact)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: step.color.withValues(alpha: isDark ? 0.16 : 0.09),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: step.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A brief pause is enough—continue when you notice something.',
                      style: AppTypography.bodySmall(context, isDark: isDark),
                    ),
                  ),
                ],
              ),
            ),
          if (!compact) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE8E0D6),
                ),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  leading: Icon(Icons.edit_note_rounded, color: step.color),
                  title: const Text(
                    'Add a private note',
                    style:
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Optional and kept private'),
                  children: [
                    TextField(
                      controller: controller,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: step.hint,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.honeyLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const ValueKey('grounding-continue-button'),
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.honeyAmber,
              foregroundColor: AppColors.onHoney,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19)),
            ),
            icon: Icon(
                isLast ? Icons.check_rounded : Icons.arrow_forward_rounded),
            label: Text(
              isLast
                  ? (compact ? 'Finish quick reset' : 'Complete grounding')
                  : 'Next sense',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (!compact && noticed < step.count) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'You can continue without counting every item.',
                style: AppTypography.bodySmall(context, isDark: isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroundingComplete extends StatelessWidget {
  final bool isDark;
  final VoidCallback onDone;

  const _GroundingComplete(
      {super.key, required this.isDark, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.honeyAmber.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.honeyAmber,
                size: 44,
              ),
            ).animate().scale(duration: 320.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 24),
            Text('You are here.',
                style: AppTypography.titleLarge(context, isDark: isDark)),
            const SizedBox(height: 9),
            Text(
              'The room did not need to change. You simply found your way back into it.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(context, isDark: isDark)
                  .copyWith(height: 1.55),
            ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: AppColors.honeyAmber,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19)),
              ),
              child: const Text('Return feeling steadier',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroundingStep {
  final int count;
  final String sense;
  final String title;
  final String prompt;
  final String hint;
  final IconData icon;
  final Color color;

  const _GroundingStep({
    required this.count,
    required this.sense,
    required this.title,
    required this.prompt,
    required this.hint,
    required this.icon,
    required this.color,
  });
}
