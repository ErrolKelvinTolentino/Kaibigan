import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../journaling/journal_provider.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class MorningRoutineFlow extends StatefulWidget {
  final RoutineConfig config;

  const MorningRoutineFlow({super.key, required this.config});

  @override
  State<MorningRoutineFlow> createState() => _MorningRoutineFlowState();
}

class _MorningRoutineFlowState extends State<MorningRoutineFlow> {
  final PageController _pageController = PageController();
  int _currentStepIndex = 0;

  // Step 1 State: Sleep Feeling
  SleepFeeling? _selectedSleepFeeling = SleepFeeling.wellRested;

  // Step 2 State: Focus Journal
  final TextEditingController _focusController = TextEditingController();
  String _selectedPrompt =
      'What is your single most important intention for today?';

  final List<String> _promptSuggestions = [
    'What is your single most important intention for today?',
    'What would make today feel gentle and fulfilling?',
    'What mindset or energy do you want to cultivate today?',
    'What is one small win you want to achieve before sunset?',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _focusController.dispose();
    super.dispose();
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
    final journalProvider =
        Provider.of<JournalProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);

    // Save Journal Focus Entry if text entered
    if (_focusController.text.trim().isNotEmpty) {
      journalProvider.addJournalEntry(
        title:
            'Morning Focus: ${_selectedSleepFeeling?.label ?? "Restful Morning"}',
        content: _focusController.text.trim(),
        companionId: userProvider.selectedCompanion,
        mood: 'calm',
        tags: ['Morning', 'Focus'],
      );
    }

    // Save Routine Log
    routinesProvider.addLog(
      RoutineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineId: 'morning',
        routineType: RoutineType.morning,
        completedAt: DateTime.now(),
        sleepFeeling: _selectedSleepFeeling,
        focusOrHighlight: _focusController.text.trim(),
      ),
    );

    _nextPage(); // Navigates to completion slide
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
    final totalPages = activeSteps.length + 1; // +1 for completion slide

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
          'Morning Routine',
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
                      color: AppColors.sageGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _currentStepIndex < activeSteps.length
                      ? 'Step ${_currentStepIndex + 1} of ${activeSteps.length}'
                      : 'Completed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sageGreen,
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
            // Minimalist Progress Bar
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
                      const AlwaysStoppedAnimation<Color>(AppColors.sageGreen),
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
                    if (step.type == StepType.sleepTracker) {
                      return _buildSleepStep(isDark);
                    } else if (step.type == StepType.journalFocus) {
                      return _buildFocusJournalStep(isDark);
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

  Widget _buildSleepStep(bool isDark) {
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
                child: const Icon(Icons.wb_sunny_outlined,
                    color: AppColors.sageGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good Morning',
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                    Text('How did your sleep feel?',
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.1),
          const SizedBox(width: 0, height: 24),
          Text(
            'Select the option that best describes your rest quality today:',
            style: AppTypography.bodyMedium(context, isDark: isDark),
          ),
          const SizedBox(height: 20),
          ...SleepFeeling.values.map((feeling) {
            final isSelected = _selectedSleepFeeling == feeling;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSleepFeeling = feeling;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.sageGreen
                          .withValues(alpha: isDark ? 0.25 : 0.12)
                      : (isDark ? AppColors.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.sageGreen
                        : (isDark
                            ? AppColors.darkCardBorder
                            : Colors.black.withValues(alpha: 0.06)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.sageGreen.withValues(alpha: 0.2)
                            : (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.04)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feeling.icon,
                        color: isSelected
                            ? AppColors.sageGreen
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feeling.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            feeling.description,
                            style: AppTypography.bodyMedium(context,
                                isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: AppColors.sageGreen, size: 22),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
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
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: const Text('Continue to Focus',
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

  Widget _buildFocusJournalStep(bool isDark) {
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
                child: const Icon(Icons.lightbulb_outline,
                    color: AppColors.sageGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Morning Focus',
                        style:
                            AppTypography.bodySmall(context, isDark: isDark)),
                    Text('Set Your Intention',
                        style:
                            AppTypography.titleLarge(context, isDark: isDark)),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.1),
          const SizedBox(height: 20),
          Text(
            'Choose a guiding prompt or write your own focus for today:',
            style: AppTypography.bodyMedium(context, isDark: isDark),
          ),
          const SizedBox(height: 14),
          // Prompt suggestions chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _promptSuggestions.map((prompt) {
              final isPromptSelected = _selectedPrompt == prompt;
              return ChoiceChip(
                label: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isPromptSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isPromptSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  ),
                ),
                selected: isPromptSelected,
                selectedColor: AppColors.sageGreen,
                backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isPromptSelected
                        ? AppColors.sageGreen
                        : (isDark
                            ? AppColors.darkCardBorder
                            : Colors.black.withValues(alpha: 0.08)),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPrompt = prompt;
                    });
                  }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPrompt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: AppColors.sageGreen,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _focusController,
                  maxLines: 5,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                        'Write your thoughts, focus, or gentle intention here...',
                    border: InputBorder.none,
                  ),
                ),
              ],
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
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _completeRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.sageGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny,
                color: AppColors.sageGreen, size: 54),
          ).animate().scale(duration: 340.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 24),
          Text(
            'Morning Routine Complete!',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge(context, isDark: isDark),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ve set your intention and listened to your body. Carry this calm clarity into your day.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge(context, isDark: isDark),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
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
