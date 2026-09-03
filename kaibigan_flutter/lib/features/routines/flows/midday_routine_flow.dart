import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../mood_tracking/mood_model.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class MiddayRoutineFlow extends StatefulWidget {
  final RoutineConfig config;

  const MiddayRoutineFlow({super.key, required this.config});

  @override
  State<MiddayRoutineFlow> createState() => _MiddayRoutineFlowState();
}

class _MiddayRoutineFlowState extends State<MiddayRoutineFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStepIndex = 0;

  // Step 1 Grounding State: 5-4-3-2-1
  int _groundingSubStep = 0;
  final List<Map<String, dynamic>> _groundingSteps = [
    {
      'count': 5,
      'title': 'Things you see',
      'prompt': 'Look around and notice 5 distinct objects in your room.',
      'icon': Icons.visibility_outlined
    },
    {
      'count': 4,
      'title': 'Things you feel',
      'prompt':
          'Notice 4 textures or physical sensations (e.g., feet on the floor, soft shirt).',
      'icon': Icons.touch_app_outlined
    },
    {
      'count': 3,
      'title': 'Things you hear',
      'prompt': 'Listen closely for 3 background sounds around you.',
      'icon': Icons.hearing_outlined
    },
    {
      'count': 2,
      'title': 'Things you smell',
      'prompt': 'Identify 2 scents or take 2 gentle deep breaths.',
      'icon': Icons.air_outlined
    },
    {
      'count': 1,
      'title': 'Thing you taste',
      'prompt': 'Notice 1 taste in your mouth or feel your tongue rest gently.',
      'icon': Icons.sentiment_satisfied_outlined
    },
  ];

  // Step 2 Breathing Timer State
  late AnimationController _breathingController;
  Timer? _timer;
  int _secondsLeft = 60;
  bool _isBreathingActive = false;
  String _breathInstruction = 'Inhale deeply...';

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _breathInstruction = 'Hold breath gently...');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isBreathingActive) {
            setState(() => _breathInstruction = 'Exhale slowly...');
            _breathingController.reverse();
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _breathInstruction = 'Hold empty...');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isBreathingActive) {
            setState(() => _breathInstruction = 'Inhale deeply...');
            _breathingController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _breathingController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startBreathingTimer() {
    setState(() {
      _isBreathingActive = true;
    });
    _breathingController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        _breathingController.stop();
        setState(() {
          _secondsLeft = 0;
          _isBreathingActive = false;
          _breathInstruction = 'Mindfulness Pause Complete';
        });
      }
    });
  }

  void _nextPage() {
    if (_currentStepIndex < widget.config.activeStepsCount) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _completeRoutine() {
    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);
    routinesProvider.addLog(
      RoutineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineId: 'midday',
        routineType: RoutineType.midday,
        completedAt: DateTime.now(),
      ),
    );
    _nextPage();
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSteps = widget.config.steps.where((s) => s.isEnabled).toList();
    final totalPages = activeSteps.length + 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: _prevStep,
        ),
        title: Text(
          'Mid-Day Routine',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkCard : Colors.white)
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.softRose.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _currentStepIndex < activeSteps.length
                      ? 'Step ${_currentStepIndex + 1} of ${activeSteps.length}'
                      : 'Completed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.softRose,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStepIndex + 1) / totalPages,
                  minHeight: 4,
                  backgroundColor:
                      isDark ? AppColors.darkCardBorder : Colors.black12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.softRose),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStepIndex = index;
                  });
                },
                children: [
                  ...activeSteps.map((step) {
                    if (step.type == StepType.grounding) {
                      return _buildGroundingStep(isDark);
                    } else if (step.type == StepType.meditation) {
                      return _buildMeditationStep(isDark);
                    }
                    return const SizedBox.shrink();
                  }),
                  _buildCompletionStep(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroundingStep(bool isDark) {
    final currentItem = _groundingSteps[_groundingSubStep];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softRose.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa_outlined,
                    color: AppColors.softRose, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grounding Session',
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                    Text('5-4-3-2-1 Sensory Reset',
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          // Sub-step indicator pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_groundingSteps.length, (index) {
              final isCurrent = index == _groundingSubStep;
              final isDone = index < _groundingSubStep;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isCurrent ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.softRose
                      : (isDone
                          ? AppColors.softRose.withValues(alpha: 0.4)
                          : (isDark ? Colors.white10 : Colors.black12)),
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : Colors.black.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.softRose.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${currentItem['count']}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.softRose,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentItem['title'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentItem['prompt'],
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge(context, isDark: isDark),
                  ),
                ],
              ),
            ),
          ).animate(key: ValueKey(_groundingSubStep)).fadeIn().scale(),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (_groundingSubStep > 0) {
                      setState(() {
                        _groundingSubStep--;
                      });
                    } else {
                      _prevStep();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Back',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_groundingSubStep < _groundingSteps.length - 1) {
                      setState(() {
                        _groundingSubStep++;
                      });
                    } else {
                      _nextPage();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: Text(
                    _groundingSubStep < _groundingSteps.length - 1
                        ? 'Next Sensory Item'
                        : 'Continue to Breathing',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softRose.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.air, color: AppColors.softRose, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mindfulness Pause',
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                    Text('1-Minute Box Breathing',
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _breathingController,
                  builder: (context, child) {
                    final scale = 1.0 + (_breathingController.value * 0.35);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.softRose.withValues(alpha: 0.15),
                          border: Border.all(
                              color: AppColors.softRose.withValues(alpha: 0.6),
                              width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.softRose.withValues(alpha: 0.2),
                              blurRadius: 20 * scale,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$_secondsLeft s',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.softRose,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  _breathInstruction,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Follow the pulsing circle for box breathing',
                  style: AppTypography.bodyMedium(context, isDark: isDark),
                ),
                const SizedBox(height: 28),
                if (!_isBreathingActive && _secondsLeft > 0)
                  ElevatedButton.icon(
                    onPressed: _startBreathingTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start 1-Min Breath'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softRose,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Back',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _completeRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: const Text('Complete Routine',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.softRose.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppColors.softRose
                      .withValues(alpha: isDark ? 0.18 : 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                FeatureIconHelper.midDayRoutine,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.spa_rounded,
                  color: AppColors.softRose,
                  size: 74,
                ),
              ),
            ),
          ).animate().scale(duration: 380.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'Mid-Day Reset Complete!',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge(context, isDark: isDark),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ve grounded your mind and centered your breathing. Enjoy the remainder of your afternoon.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge(context, isDark: isDark),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: const Text('Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
