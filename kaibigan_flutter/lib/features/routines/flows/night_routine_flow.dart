import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../journaling/journal_provider.dart';
import '../../mood_tracking/mood_provider.dart';
import '../../gratitude_garden/gratitude_provider.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class NightRoutineFlow extends StatefulWidget {
  final RoutineConfig config;

  const NightRoutineFlow({super.key, required this.config});

  @override
  State<NightRoutineFlow> createState() => _NightRoutineFlowState();
}

class _NightRoutineFlowState extends State<NightRoutineFlow> {
  final PageController _pageController = PageController();
  int _currentStepIndex = 0;

  // Step 1 State: Today's Highlights (2 Pages inside PageView)
  final PageController _highlightPageController = PageController();
  int _highlightSubPage = 0;
  final TextEditingController _highlightTitleController =
      TextEditingController();
  final TextEditingController _highlightDetailController =
      TextEditingController();

  // Step 2 State: Night Mood Tracker (2 Pages inside PageView)
  final PageController _moodPageController = PageController();
  int _moodSubPage = 0;
  int _selectedMoodScore = 4;
  String _selectedMoodLabel = 'Good';
  final List<String> _selectedFactors = [];
  final TextEditingController _moodNoteController = TextEditingController();

  final List<Map<String, dynamic>> _moodOptions = [
    {
      'score': 1,
      'label': 'Struggling',
      'icon': Icons.sentiment_very_dissatisfied_outlined,
      'color': AppColors.moodAwful
    },
    {
      'score': 2,
      'label': 'Low',
      'icon': Icons.sentiment_dissatisfied_outlined,
      'color': AppColors.moodLow
    },
    {
      'score': 3,
      'label': 'Okay',
      'icon': Icons.sentiment_neutral_outlined,
      'color': AppColors.moodOkay
    },
    {
      'score': 4,
      'label': 'Good',
      'icon': Icons.sentiment_satisfied_outlined,
      'color': AppColors.moodGood
    },
    {
      'score': 5,
      'label': 'Awesome',
      'icon': Icons.sentiment_very_satisfied_outlined,
      'color': AppColors.moodAwesome
    },
  ];

  final List<String> _factorOptions = [
    'Work & School',
    'Family & Friends',
    'Self Care',
    'Sleep & Rest',
    'Health & Exercise',
    'Weather',
    'Hobbies',
    'Quiet Time',
  ];

  // Step 3 State: Gratitude Garden
  final TextEditingController _gratitudeController = TextEditingController();
  String _chosenFlowerType = 'sunflower';
  bool _flowerPlanted = false;

  final List<Map<String, String>> _flowerOptions = [
    {'type': 'sunflower', 'name': 'Sunflower', 'desc': 'Bright & uplifting'},
    {'type': 'sampaguita', 'name': 'Sampaguita', 'desc': 'Pure & fragrant'},
    {'type': 'tulip', 'name': 'Tulip', 'desc': 'Peaceful & gentle'},
    {'type': 'orchid', 'name': 'Orchid', 'desc': 'Resilient & calm'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _highlightPageController.dispose();
    _moodPageController.dispose();
    _highlightTitleController.dispose();
    _highlightDetailController.dispose();
    _moodNoteController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < widget.config.activeStepsCount) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _completeNightRoutine() {
    final journalProvider =
        Provider.of<JournalProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final gratitudeProvider =
        Provider.of<GratitudeProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);

    // 1. Save Night Highlight Journal Entry
    if (_highlightTitleController.text.trim().isNotEmpty ||
        _highlightDetailController.text.trim().isNotEmpty) {
      journalProvider.addJournalEntry(
        title: _highlightTitleController.text.trim().isEmpty
            ? 'Evening Highlight'
            : _highlightTitleController.text.trim(),
        content: _highlightDetailController.text.trim(),
        companionId: userProvider.selectedCompanion,
        mood: 'peaceful',
        tags: ['Night', 'Highlight'],
      );
    }

    // 2. Save Mood Log
    moodProvider.logMood(
      score: _selectedMoodScore,
      label: _selectedMoodLabel,
      note:
          '${_selectedFactors.join(", ")}. ${_moodNoteController.text.trim()}',
    );

    // 3. Plant Flower in Gratitude Garden
    if (_gratitudeController.text.trim().isNotEmpty) {
      gratitudeProvider.addGratitudeEntry(
        _gratitudeController.text.trim(),
        flowerType: _chosenFlowerType,
      );
      setState(() => _flowerPlanted = true);
    }

    // 4. Save Routine Log
    routinesProvider.addLog(
      RoutineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineId: 'night',
        routineType: RoutineType.night,
        completedAt: DateTime.now(),
        focusOrHighlight: _highlightTitleController.text.trim(),
        moodScore: _selectedMoodScore,
        moodNote: _moodNoteController.text.trim(),
        gratitudeContent: _gratitudeController.text.trim(),
      ),
    );

    _nextStep(); // Goes to completion screen
  }

  void _prevStep() {
    if (_currentStepIndex == 0 && _highlightSubPage > 0) {
      _highlightPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    if (_currentStepIndex == 1 && _moodSubPage > 0) {
      _moodPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    if (_currentStepIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    Navigator.pop(context);
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
          'Night Routine',
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
                      color: AppColors.lavenderMist.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _currentStepIndex < activeSteps.length
                      ? 'Step ${_currentStepIndex + 1} of ${activeSteps.length}'
                      : 'Completed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.beePrimary,
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
                      const AlwaysStoppedAnimation<Color>(AppColors.beePrimary),
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
                    if (step.type == StepType.journalHighlight) {
                      return _buildHighlightJournalStep(isDark);
                    } else if (step.type == StepType.moodTracker) {
                      return _buildNightMoodStep(isDark);
                    } else if (step.type == StepType.gratitudeGarden) {
                      return _buildGratitudeGardenStep(isDark);
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

  // STEP 1: HIGHLIGHT JOURNAL (Page 1: Title/Favorite Part, Page 2: Story Detail)
  Widget _buildHighlightJournalStep(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.beePrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_stories_outlined,
                    color: AppColors.beePrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s Highlights',
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                    Text(
                        _highlightSubPage == 0
                            ? 'Page 1: Favorite Part'
                            : 'Page 2: Tell Us More',
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _highlightPageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _highlightSubPage = index;
              });
            },
            children: [
              // Page 1: Favorite part of the day
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s your favorite part of the day?',
                      style: AppTypography.titleMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Name a quiet moment, a funny interaction, or a simple joy.',
                      style: AppTypography.bodyMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : Colors.black.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _highlightTitleController,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Having coffee with a friend, watching the sunset...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
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
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _highlightPageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.beePrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Next: Tell us about it!',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Page 2: Tell us about it
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tell us about it!',
                      style: AppTypography.titleMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Why did this moment stand out? How did it make you feel?',
                      style: AppTypography.bodyMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : Colors.black.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _highlightDetailController,
                        maxLines: 6,
                        style: TextStyle(
                            fontSize: 15,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        decoration: const InputDecoration(
                          hintText:
                              'Pour out your reflections on this moment...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.beePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Continue to Mood Check-In',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: NIGHT MOOD TRACKER (Page 1: How do you feel?, Page 2: What got you feeling this way?)
  Widget _buildNightMoodStep(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.beePrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sentiment_satisfied_alt_outlined,
                    color: AppColors.beePrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Night Mood Tracker',
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                    Text(
                        _moodSubPage == 0
                            ? 'Page 1: How do you feel?'
                            : 'Page 2: What influenced it?',
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _moodPageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _moodSubPage = index;
              });
            },
            children: [
              // Mood Page 1: Select Mood
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How do you feel tonight?',
                      style: AppTypography.titleMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _moodOptions.map((opt) {
                        final isSelected = _selectedMoodScore == opt['score'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMoodScore = opt['score'];
                              _selectedMoodLabel = opt['label'];
                            });
                          },
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (opt['color'] as Color)
                                          .withValues(alpha: 0.2)
                                      : (isDark
                                          ? AppColors.darkCard
                                          : Colors.white),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? (opt['color'] as Color)
                                        : (isDark
                                            ? AppColors.darkCardBorder
                                            : Colors.black
                                                .withValues(alpha: 0.08)),
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                ),
                                child: Icon(
                                  opt['icon'] as IconData,
                                  color: isSelected
                                      ? (opt['color'] as Color)
                                      : (isDark
                                          ? Colors.white60
                                          : Colors.black54),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                opt['label'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (opt['color'] as Color)
                                      : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),
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
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _moodPageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.beePrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Next: Factors & Notes',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Mood Page 2: What got you feeling this way?
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What got you feeling this way?',
                      style: AppTypography.titleMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _factorOptions.map((factor) {
                        final isSelected = _selectedFactors.contains(factor);
                        return FilterChip(
                          label: Text(factor),
                          selected: isSelected,
                          selectedColor:
                              AppColors.beePrimary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.beePrimary,
                          backgroundColor:
                              isDark ? AppColors.darkCard : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: isSelected
                                    ? AppColors.beePrimary
                                    : (isDark
                                        ? AppColors.darkCardBorder
                                        : Colors.black
                                            .withValues(alpha: 0.08))),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFactors.add(factor);
                              } else {
                                _selectedFactors.remove(factor);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : Colors.black.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _moodNoteController,
                        maxLines: 3,
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                        decoration: const InputDecoration(
                          hintText:
                              'Add an optional note about tonight\'s mood...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.beePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Continue to Gratitude Garden',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3: GRATITUDE GARDEN PLANTING
  Widget _buildGratitudeGardenStep(bool isDark) {
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
                child: const Icon(Icons.local_florist_outlined,
                    color: AppColors.sageGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gratitude Garden',
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                    Text('Plant a Gratitude Flower',
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 20),
          Text(
            'What are you grateful for today?',
            style: AppTypography.titleMedium(context, isDark: isDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Expressing gratitude plants a new blooming flower in your personal garden.',
            style: AppTypography.bodyMedium(context, isDark: isDark),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : Colors.black.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _gratitudeController,
              maxLines: 4,
              style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
              decoration: const InputDecoration(
                hintText: 'I am grateful for...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Select Flower Variety:',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight)),
          const SizedBox(height: 10),
          Row(
            children: _flowerOptions.map((flower) {
              final isSelected = _chosenFlowerType == flower['type'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _chosenFlowerType = flower['type']!;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.sageGreen.withValues(alpha: 0.2)
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.sageGreen
                              : (isDark
                                  ? AppColors.darkCardBorder
                                  : Colors.black.withValues(alpha: 0.08)),
                          width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_florist,
                          color: isSelected
                              ? AppColors.sageGreen
                              : (isDark ? Colors.white54 : Colors.black45),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          flower['name']!,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
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
                child: ElevatedButton.icon(
                  onPressed: _completeNightRoutine,
                  icon: const Icon(Icons.local_florist, size: 18),
                  label: const Text('Plant Flower',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.beePrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nights_stay,
                color: AppColors.beePrimary, size: 54),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'Night Routine Completed!',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge(context, isDark: isDark),
          ),
          const SizedBox(height: 12),
          Text(
            _flowerPlanted
                ? 'Your evening highlight and mood are logged, and a new flower has bloomed in your Gratitude Garden. Rest well tonight.'
                : 'Your evening reflections and mood are logged. Have a peaceful night of rest.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge(context, isDark: isDark),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.beePrimary,
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
