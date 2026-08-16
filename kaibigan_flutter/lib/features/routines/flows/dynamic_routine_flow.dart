import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../settings/user_provider.dart';
import '../../gratitude_garden/gratitude_provider.dart';
import '../../mood_tracking/mood_provider.dart';
import '../../journaling/journal_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class DynamicRoutineFlow extends StatefulWidget {
  final RoutineConfig config;

  const DynamicRoutineFlow({super.key, required this.config});

  @override
  State<DynamicRoutineFlow> createState() => _DynamicRoutineFlowState();
}

class _DynamicRoutineFlowState extends State<DynamicRoutineFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentStepIndex = 0;

  // Gratitude Step State
  final TextEditingController _gratitudeController = TextEditingController();
  String _selectedFlowerType = 'sunflower';

  // Focus Step State
  final TextEditingController _focusController = TextEditingController();

  // Highlight Step State
  final TextEditingController _highlightController = TextEditingController();

  // Mood Tracker Step State
  int _selectedMoodScore = 4;
  final List<String> _selectedMoodTags = [];
  final TextEditingController _moodNoteController = TextEditingController();

  // Grounding Step State
  int _groundingSubStep = 0;
  final List<Map<String, dynamic>> _groundingSteps = [
    {
      'count': 5,
      'title': 'Things you see',
      'prompt': 'Look around and notice 5 distinct objects around you.',
      'icon': Icons.visibility_outlined
    },
    {
      'count': 4,
      'title': 'Things you touch',
      'prompt':
          'Feel 4 physical sensations (e.g. feet on floor, soft chair, your phone).',
      'icon': Icons.touch_app_outlined
    },
    {
      'count': 3,
      'title': 'Things you hear',
      'prompt': 'Listen closely for 3 distinct background sounds.',
      'icon': Icons.hearing_outlined
    },
    {
      'count': 2,
      'title': 'Things you smell',
      'prompt': 'Identify 2 scents or take 2 slow deep breaths.',
      'icon': Icons.air_outlined
    },
    {
      'count': 1,
      'title': 'Thing you taste',
      'prompt': 'Notice 1 taste in your mouth or feel your tongue rest gently.',
      'icon': Icons.sentiment_satisfied_outlined
    },
  ];

  // Breathing Step State
  late AnimationController _breathingController;
  Timer? _breathingTimer;
  int _secondsLeft = 60;
  bool _isBreathingActive = false;
  String _breathPhaseText = 'Inhale deeply...';

  // Sleep Step State
  SleepFeeling? _selectedSleepFeeling = SleepFeeling.wellRested;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && _isBreathingActive) {
          setState(() => _breathPhaseText = 'Hold breath gently...');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _isBreathingActive) {
              setState(() => _breathPhaseText = 'Exhale slowly...');
              _breathingController.reverse();
            }
          });
        }
      } else if (status == AnimationStatus.dismissed) {
        if (mounted && _isBreathingActive) {
          setState(() => _breathPhaseText = 'Hold empty...');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _isBreathingActive) {
              setState(() => _breathPhaseText = 'Inhale deeply...');
              _breathingController.forward();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _gratitudeController.dispose();
    _focusController.dispose();
    _highlightController.dispose();
    _moodNoteController.dispose();
    _breathingController.dispose();
    _breathingTimer?.cancel();
    super.dispose();
  }

  List<RoutineStep> get _activeSteps =>
      widget.config.steps.where((s) => s.isEnabled).toList();

  void _nextPage() {
    if (_currentStepIndex < _activeSteps.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentStepIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _completeCurrentStep(RoutineStep step) {
    final gratitudeProvider =
        Provider.of<GratitudeProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final journalProvider =
        Provider.of<JournalProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    switch (step.type) {
      case StepType.gratitudeGarden:
        if (_gratitudeController.text.trim().isNotEmpty) {
          gratitudeProvider.addGratitudeEntry(
            _gratitudeController.text.trim(),
            flowerType: _selectedFlowerType,
          );
        }
        break;

      case StepType.journalFocus:
        if (_focusController.text.trim().isNotEmpty) {
          journalProvider.addJournalEntry(
            title: 'Daily Focus (${widget.config.title})',
            content: _focusController.text.trim(),
            companionId: userProvider.selectedCompanion,
            mood: 'focused',
            tags: ['Focus', widget.config.title],
          );
        }
        break;

      case StepType.journalHighlight:
        if (_highlightController.text.trim().isNotEmpty) {
          journalProvider.addJournalEntry(
            title: 'Daily Highlight',
            content: _highlightController.text.trim(),
            companionId: userProvider.selectedCompanion,
            mood: 'happy',
            tags: ['Highlight', widget.config.title],
          );
        }
        break;

      case StepType.moodTracker:
        final moodLabels = ['Heavy', 'Low', 'Calm', 'Good', 'Radiant'];
        final label = _selectedMoodScore >= 1 && _selectedMoodScore <= 5
            ? moodLabels[_selectedMoodScore - 1]
            : 'Good';
        moodProvider.logMood(
          score: _selectedMoodScore,
          label: label,
          note: _moodNoteController.text.trim().isEmpty
              ? null
              : _moodNoteController.text.trim(),
        );
        break;

      default:
        break;
    }

    _nextPage();
  }

  void _finishRoutine() {
    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);
    routinesProvider.addLog(
      RoutineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineId: widget.config.id,
        routineType: widget.config.type,
        completedAt: DateTime.now(),
        sleepFeeling: _selectedSleepFeeling,
        focusOrHighlight: _focusController.text.trim().isNotEmpty
            ? _focusController.text.trim()
            : _highlightController.text.trim(),
        moodScore: _selectedMoodScore,
        gratitudeContent: _gratitudeController.text.trim(),
      ),
    );

    _nextPage(); // Navigates to completion slide
  }

  void _startBreathingTimer() {
    setState(() => _isBreathingActive = true);
    _breathingController.forward();
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _breathingTimer?.cancel();
        _breathingController.stop();
        setState(() {
          _secondsLeft = 0;
          _isBreathingActive = false;
          _breathPhaseText = 'Mindfulness Pause Complete ✨';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSteps = _activeSteps;
    final totalPages = activeSteps.length + 1; // steps + completion slide

    if (activeSteps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.config.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline,
                    size: 48, color: AppColors.sageGreen),
                const SizedBox(height: 16),
                Text(
                  'No active activities in this routine.',
                  style: AppTypography.titleLarge(context, isDark: isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You can customize this routine to add activities anytime.',
                  style: AppTypography.bodyMedium(context, isDark: isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Routines'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header with Progress Line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _prevPage,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.config.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(totalPages, (index) {
                            final isActive = index == _currentStepIndex;
                            final isPassed = index < _currentStepIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 4,
                              width: isActive ? 24 : 12,
                              decoration: BoxDecoration(
                                color: isPassed || isActive
                                    ? widget.config.primaryColor
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.black12),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Main Dynamic PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) =>
                    setState(() => _currentStepIndex = index),
                itemCount: totalPages,
                itemBuilder: (context, index) {
                  if (index < activeSteps.length) {
                    final step = activeSteps[index];
                    return _buildStepWidget(
                        step, index, activeSteps.length, isDark);
                  } else {
                    return _buildCompletionSlide(isDark);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepWidget(
      RoutineStep step, int index, int totalSteps, bool isDark) {
    switch (step.type) {
      case StepType.gratitudeGarden:
        return _buildGratitudeStep(step, index, totalSteps, isDark);
      case StepType.journalFocus:
        return _buildFocusStep(step, index, totalSteps, isDark);
      case StepType.journalHighlight:
        return _buildHighlightStep(step, index, totalSteps, isDark);
      case StepType.moodTracker:
        return _buildMoodStep(step, index, totalSteps, isDark);
      case StepType.grounding:
        return _buildGroundingStep(step, index, totalSteps, isDark);
      case StepType.meditation:
        return _buildBreathingStep(step, index, totalSteps, isDark);
      case StepType.sleepTracker:
        return _buildSleepStep(step, index, totalSteps, isDark);
      case StepType.custom:
        return _buildCustomStep(step, index, totalSteps, isDark);
    }
  }

  // 1. Gratitude Garden Activity
  Widget _buildGratitudeStep(
      RoutineStep step, int index, int totalSteps, bool isDark) {
    final flowers = [
      {
        'type': 'sunflower',
        'icon': '🌻',
        'name': 'Sunflower',
        'desc': 'Joy & Warmth'
      },
      {
        'type': 'sampaguita',
        'icon': '🌼',
        'name': 'Sampaguita',
        'desc': 'Simplicity & Purity'
      },
      {
        'type': 'tulip',
        'icon': '🌷',
        'name': 'Tulip',
        'desc': 'Peaceful Heart'
      },
      {
        'type': 'orchid',
        'icon': '🪻',
        'name': 'Orchid',
        'desc': 'Quiet Reflection'
      },
      {'type': 'rose', 'icon': '🌹', 'name': 'Rose', 'desc': 'Deep Gratitude'},
    ];

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
                  color: AppColors.sageGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌸', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                    Text(step.subtitle,
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('What are you grateful for right now?',
              style: AppTypography.titleMedium(context, isDark: isDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _gratitudeController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'e.g., A warm cup of coffee, a kind text from a friend, or quiet morning air...',
              filled: true,
              fillColor: isDark ? AppColors.darkCard : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          Text('Choose a flower to plant in your garden:',
              style: AppTypography.titleMedium(context, isDark: isDark)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: flowers.length,
              itemBuilder: (context, fIndex) {
                final flower = flowers[fIndex];
                final isSelected = _selectedFlowerType == flower['type'];
                return GestureDetector(
                  onTap: () => setState(
                      () => _selectedFlowerType = flower['type'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.sageGreen.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.sageGreen
                            : (isDark
                                ? AppColors.darkCardBorder
                                : Colors.transparent),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(flower['icon'] as String,
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(
                          flower['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.sageGreen
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _completeCurrentStep(step),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                index == totalSteps - 1
                    ? 'Plant Flower & Complete Routine'
                    : 'Plant Flower & Continue',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Today's Focus Activity
  Widget _buildFocusStep(
      RoutineStep step, int index, int totalSteps, bool isDark) {
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
                  color: AppColors.softRose.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline,
                    color: AppColors.softRose, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                    Text(step.subtitle,
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.spa, color: AppColors.sageGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Keep it simple. Pick 1 or 2 meaningful things that matter most today.',
                    style: AppTypography.bodyMedium(context, isDark: isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _focusController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'What is your single most important priority or gentle focus for today?',
              filled: true,
              fillColor: isDark ? AppColors.darkCard : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _completeCurrentStep(step),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                index == totalSteps - 1
                    ? 'Save Focus & Complete Routine'
                    : 'Save Focus & Continue',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Today's Highlight Activity
  Widget _buildHighlightStep(
      RoutineStep step, int index, int totalSteps, bool isDark) {
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
                  color: AppColors.beePrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_stories_outlined,
                    color: AppColors.beePrimary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                    Text(step.subtitle,
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '"I had a nice conversation with my friend." It doesn\'t need to be a major accomplishment—just a moment that brought a smile.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _highlightController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Share one positive or memorable highlight from your day...',
              filled: true,
              fillColor: isDark ? AppColors.darkCard : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _completeCurrentStep(step),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                index == totalSteps - 1
                    ? 'Save Highlight & Complete Routine'
                    : 'Save Highlight & Continue',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Mood Tracker Activity
  Widget _buildMoodStep(
      RoutineStep step, int index, int totalSteps, bool isDark) {
    final moodOptions = [
      {'score': 1, 'emoji': '😔', 'label': 'Heavy'},
      {'score': 2, 'emoji': '😟', 'label': 'Low'},
      {'score': 3, 'emoji': '😐', 'label': 'Calm'},
      {'score': 4, 'emoji': '🙂', 'label': 'Good'},
      {'score': 5, 'emoji': '😊', 'label': 'Radiant'},
    ];

    final availableChips = [
      'Peaceful',
      'Tired',
      'Anxious',
      'Grateful',
      'Focused',
      'Overwhelmed',
      'Hopeful'
    ];

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
                  color: AppColors.sageGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sentiment_satisfied_alt_outlined,
                    color: AppColors.sageGreen, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                    Text(step.subtitle,
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('How are you feeling right now?',
              style: AppTypography.titleMedium(context, isDark: isDark)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moodOptions.map((opt) {
              final isSelected = _selectedMoodScore == opt['score'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedMoodScore = opt['score'] as int),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.sageGreen.withValues(alpha: 0.2)
                        : (isDark ? AppColors.darkCard : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? AppColors.sageGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(opt['emoji'] as String,
                      style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('What emotions resonate most?',
              style: AppTypography.titleSmall(context, isDark: isDark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableChips.map((chip) {
              final isSelected = _selectedMoodTags.contains(chip);
              return FilterChip(
                label: Text(chip),
                selected: isSelected,
                selectedColor: AppColors.sageGreen.withValues(alpha: 0.25),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedMoodTags.add(chip);
                    } else {
                      _selectedMoodTags.remove(chip);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _moodNoteController,
            decoration: InputDecoration(
              hintText: 'Optional quick note on your feelings...',
              filled: true,
              fillColor: isDark ? AppColors.darkCard : Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _completeCurrentStep(step),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                index == totalSteps - 1
                    ? 'Record Mood & Complete Routine'
                    : 'Record Mood & Continue',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. 5-4-3-2-1 Grounding Activity
  Widget _buildGroundingStep(
      RoutineStep step, int index, int totalSteps, bool isDark) {
    final gStep = _groundingSteps[_groundingSubStep];

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
                  color: AppColors.softRose.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa_outlined,
                    color: AppColors.softRose, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title,
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                    Text(step.subtitle,
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Grounding Sub-step Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.softRose.withValues(alpha: 0.2),
                  child: Text(
                    '${gStep['count']}',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.softRose),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  gStep['title'] as String,
                  style: AppTypography.titleLarge(context, isDark: isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  gStep['prompt'] as String,
                  style: AppTypography.bodyMedium(context, isDark: isDark),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              if (_groundingSubStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _groundingSubStep--),
                    child: const Text('Previous Sensing'),
                  ),
                ),
              if (_groundingSubStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_groundingSubStep < _groundingSteps.length - 1) {
                      setState(() => _groundingSubStep++);
                    } else {
                      _completeCurrentStep(step);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _groundingSubStep < _groundingSteps.length - 1
                        ? 'Next Sense (${_groundingSubStep + 1}/5)'
                        : 'Finish Grounding',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Quick Breathing Exercise Activity
  Widget _buildBreathingStep(
      RoutineStep step, int index, int totalSteps, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(step.title,
              style: AppTypography.titleLarge(context, isDark: isDark)),
          const SizedBox(height: 4),
          Text(step.subtitle,
              style: AppTypography.bodySmall(context, isDark: isDark)),
          const SizedBox(height: 32),

          // Breathing Animated Circle
          ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.25)
                .animate(_breathingController),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sageGreen.withValues(alpha: 0.6),
                    AppColors.sageGreen.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sageGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  '${_secondsLeft}s',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.sageGreen),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            _breathPhaseText,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.sageGreen),
          ),
          const SizedBox(height: 32),

          if (!_isBreathingActive && _secondsLeft == 60)
            ElevatedButton.icon(
              onPressed: _startBreathingTimer,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Breathing Timer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _completeCurrentStep(step),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                index == totalSteps - 1
                    ? 'Finish Breathing & Complete Routine'
                    : 'Continue',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Sleep Feel Step Activity
  Widget _buildSleepStep(
      RoutineStep step, int index, int totalSteps, bool isDark) {
    final feelings = SleepFeeling.values;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.title,
              style: AppTypography.titleLarge(context, isDark: isDark)),
          const SizedBox(height: 4),
          Text(step.subtitle,
              style: AppTypography.bodySmall(context, isDark: isDark)),
          const SizedBox(height: 24),
          Column(
            children: feelings.map((f) {
              final isSelected = _selectedSleepFeeling == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedSleepFeeling = f),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.sageGreen.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.sageGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(f.icon,
                          color:
                              isSelected ? AppColors.sageGreen : Colors.grey),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(f.description,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _completeCurrentStep(step),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save & Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // 8. Custom Step Fallback
  Widget _buildCustomStep(
      RoutineStep step, int index, int totalSteps, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(step.icon, size: 48, color: AppColors.sageGreen),
          const SizedBox(height: 16),
          Text(step.title,
              style: AppTypography.titleLarge(context, isDark: isDark)),
          const SizedBox(height: 8),
          Text(step.subtitle,
              style: AppTypography.bodyMedium(context, isDark: isDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _completeCurrentStep(step),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Complete Step'),
          ),
        ],
      ),
    );
  }

  // 9. Routine Completion Slide
  Widget _buildCompletionSlide(bool isDark) {
    final userProvider = Provider.of<UserProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars_rounded, size: 72, color: Color(0xFFFFD54F))
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'Routine Completed! ✨',
            style: AppTypography.heroHeader(context, isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Maraming salamat sa pag-pause ngayong araw, ${userProvider.displayName}. Great job taking a gentle moment for your well-being!',
            style: AppTypography.bodyMedium(context, isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                _finishRoutine();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Finish & Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
