import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class GroundingSessionScreen extends StatefulWidget {
  const GroundingSessionScreen({super.key});

  @override
  State<GroundingSessionScreen> createState() => _GroundingSessionScreenState();
}

class _GroundingSessionScreenState extends State<GroundingSessionScreen> {
  int _currentStepIndex = 0;
  final Map<int, TextEditingController> _notesControllers = {
    0: TextEditingController(),
    1: TextEditingController(),
    2: TextEditingController(),
    3: TextEditingController(),
    4: TextEditingController(),
  };

  final List<Map<String, dynamic>> _steps = [
    {'count': 5, 'title': 'Things you see', 'prompt': 'Look around and identify 5 distinct physical items in your space.', 'icon': Icons.visibility_outlined},
    {'count': 4, 'title': 'Things you feel', 'prompt': 'Notice 4 physical touch sensations (e.g. feet on floor, cloth on skin).', 'icon': Icons.touch_app_outlined},
    {'count': 3, 'title': 'Things you hear', 'prompt': 'Close your eyes for a second and listen for 3 ambient sounds.', 'icon': Icons.hearing_outlined},
    {'count': 2, 'title': 'Things you smell', 'prompt': 'Breathe deeply and identify 2 scents or take 2 calming breaths.', 'icon': Icons.air_outlined},
    {'count': 1, 'title': 'Thing you taste', 'prompt': 'Notice 1 taste in your mouth or feel your tongue rest softly.', 'icon': Icons.sentiment_satisfied_outlined},
  ];

  @override
  void dispose() {
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _finishSession() {
    final routinesProvider = Provider.of<RoutinesProvider>(context, listen: false);
    routinesProvider.addLog(
      RoutineLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        routineId: 'midday',
        routineType: RoutineType.midday,
        completedAt: DateTime.now(),
        focusOrHighlight: 'Completed 5-4-3-2-1 Sensory Grounding Session.',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grounding Session complete! You are present and centered.'),
        backgroundColor: AppColors.softRose,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = _steps[_currentStepIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '5-4-3-2-1 Grounding',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final isCurrent = index == _currentStepIndex;
                  final isDone = index < _currentStepIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 32 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.softRose
                          : (isDone ? AppColors.softRose.withValues(alpha: 0.4) : (isDark ? Colors.white10 : Colors.black12)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Hero Step Card
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.softRose.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.softRose.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${step['count']}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppColors.softRose,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        step['title'],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step['prompt'],
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge(context, isDark: isDark),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.warmCream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _notesControllers[_currentStepIndex],
                          style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          decoration: const InputDecoration(
                            hintText: 'Optional: Note down what you observed...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(key: ValueKey(_currentStepIndex)).fadeIn().scale(),
              const SizedBox(height: 36),

              // Navigation buttons
              Row(
                children: [
                  if (_currentStepIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStepIndex--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStepIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStepIndex < _steps.length - 1) {
                          setState(() {
                            _currentStepIndex++;
                          });
                        } else {
                          _finishSession();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentStepIndex < _steps.length - 1 ? 'Next Sensory Item' : 'Complete Session',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
