import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../settings/user_provider.dart';
import '../../companion/companion_model.dart';
import '../routines_provider.dart';
import '../routine_model.dart';

class SleepLogFlowScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const SleepLogFlowScreen({super.key, this.onCompleted});

  @override
  State<SleepLogFlowScreen> createState() => _SleepLogFlowScreenState();
}

class _SleepLogFlowScreenState extends State<SleepLogFlowScreen> {
  int _currentStep = 0; // 0: Quality/Feeling, 1: Hours Spinner, 2: Completed Recap
  SleepFeeling _selectedFeeling = SleepFeeling.moderate;
  int _selectedHoursIndex = 7; // Default to '7' hours

  final List<String> _sleepHoursOptions = [
    'Less than 1',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '10+',
  ];

  late final FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: _selectedHoursIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _saveSleepLog() async {
    final routinesProvider = Provider.of<RoutinesProvider>(context, listen: false);
    final hoursString = _sleepHoursOptions[_selectedHoursIndex];

    await routinesProvider.addLog(
      RoutineLog(
        id: '',
        routineId: 'sleep_${DateTime.now().millisecondsSinceEpoch}',
        routineType: RoutineType.morning,
        sleepFeeling: _selectedFeeling,
        focusOrHighlight: "Slept $hoursString hrs: ${_selectedFeeling.description}",
        completedAt: DateTime.now(),
      ),
    );

    setState(() {
      _currentStep = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () {
            if (_currentStep > 0 && _currentStep < 2) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Sleep Log",
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _buildCurrentStep(context, isDark, mascot),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, bool isDark, MascotInfo mascot) {
    if (_currentStep == 0) {
      return _buildQualityStep(context, isDark);
    } else if (_currentStep == 1) {
      return _buildHoursStep(context, isDark);
    } else {
      return _buildRecapStep(context, isDark, mascot);
    }
  }

  Widget _buildQualityStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Indicator
        _buildProgressBar(1, 2, isDark),
        const SizedBox(height: 24),

        Text(
          "How was your sleep last night?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Pick the bee energy that matches how rested you feel.",
          style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: SleepFeeling.values.length,
            itemBuilder: (context, index) {
              final feeling = SleepFeeling.values[index];
              final isSelected = _selectedFeeling == feeling;

              return GestureDetector(
                onTap: () => setState(() => _selectedFeeling = feeling),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.honeyGold.withValues(alpha: isDark ? 0.25 : 0.15)
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.honeyGold
                          : (isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          feeling.assetPath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(feeling.icon, color: AppColors.honeyAmber, size: 52),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feeling.label,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              feeling.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.honeyGold, size: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Next: Sleep Duration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildHoursStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(2, 2, isDark),
        const SizedBox(height: 24),

        Text(
          "About how many hours did you sleep?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Scroll to select your total hours of sleep.",
          style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),

        const SizedBox(height: 30),

        // Rolling number spinner
        Expanded(
          child: Center(
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  // Center selection indicator box
                  Center(
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.honeyGold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.honeyGold.withValues(alpha: 0.4), width: 1.5),
                      ),
                    ),
                  ),

                  ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 54,
                    perspective: 0.004,
                    diameterRatio: 1.6,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedHoursIndex = index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _sleepHoursOptions.length,
                      builder: (context, index) {
                        final isSelected = index == _selectedHoursIndex;
                        final label = _sleepHoursOptions[index];

                        return Center(
                          child: Text(
                            '$label ${label.contains('than') ? 'hour' : (label == '1' ? 'hour' : 'hours')}',
                            style: TextStyle(
                              fontSize: isSelected ? 22 : 16,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.honeyAmber
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveSleepLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Save Sleep Log", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecapStep(BuildContext context, bool isDark, MascotInfo mascot) {
    final hours = _sleepHoursOptions[_selectedHoursIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            _selectedFeeling.assetPath,
            width: 140,
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.bedtime_rounded, size: 72, color: AppColors.honeyGold),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 24),

        Text(
          "Sleep Recorded!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Text(
                "Logged $hours hours • ${_selectedFeeling.label}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedFeeling.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.honeyGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(mascot.materialIcon, size: 24, color: mascot.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${mascot.name}: Staying mindful of your rest habits builds consistent daily energy. Let's make today gentle!",
                  style: TextStyle(fontSize: 13, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onCompleted != null) {
                widget.onCompleted!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text("Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int current, int total, bool isDark) {
    return Row(
      children: List.generate(total, (index) {
        final isFilled = index < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < total - 1 ? 8 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: isFilled
                  ? AppColors.honeyGold
                  : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
