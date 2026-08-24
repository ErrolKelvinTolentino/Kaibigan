import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/cozy_action_sheet.dart';
import '../../companion/companion_model.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';
import '../screens/todays_focus_screen.dart';
import '../screens/todays_highlight_screen.dart';
import '../screens/daily_reflection_screen.dart';
import '../../mood_tracking/mood_tracker_screen.dart';
import '../../gratitude_garden/garden_screen.dart';

class ProgressiveRoutineRunner extends StatefulWidget {
  final RoutineType routineType;

  const ProgressiveRoutineRunner({super.key, required this.routineType});

  @override
  State<ProgressiveRoutineRunner> createState() =>
      _ProgressiveRoutineRunnerState();
}

class _ProgressiveRoutineRunnerState extends State<ProgressiveRoutineRunner> {
  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    if (widget.routineType == RoutineType.morning) {
      return TodaysFocusScreen(
        onCompleted: () => _finishRoutine(),
      );
    } else if (widget.routineType == RoutineType.midday) {
      if (_stepIndex == 0) {
        return MoodTrackerScreen(
          onCompleted: () => setState(() => _stepIndex = 1),
        );
      } else if (_stepIndex == 1) {
        return GardenScreen(onEntrySaved: _finishRoutine);
      }
    } else {
      // Night Routine: Mood -> Highlight -> Reflection prompt
      if (_stepIndex == 0) {
        return MoodTrackerScreen(
          onCompleted: () => setState(() => _stepIndex = 1),
        );
      } else if (_stepIndex == 1) {
        return TodaysHighlightScreen(
          onCompleted: () => _promptDailyReflection(context, mascot),
        );
      } else if (_stepIndex == 2) {
        return DailyReflectionScreen(
          onCompleted: () => _finishRoutine(),
        );
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mascot.avatarIcon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Routine Complete! 🐝✨',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptDailyReflection(
    BuildContext sourceContext,
    MascotInfo mascot,
  ) async {
    final shouldReflect = await CozyActionSheet.show(
      sourceContext,
      eyebrow: 'A gentle next step',
      title: 'Close the day with a little clarity',
      message:
          'Write down what mattered, what felt difficult, and what you want to carry forward with ${mascot.name}.',
      primaryLabel: 'Begin reflection',
      secondaryLabel: 'Finish my routine',
      emoji: '🪞',
      detail: 'About 3 minutes · private and saved to your journal',
      isDismissible: false,
    );

    if (!mounted) return;
    if (shouldReflect) {
      setState(() => _stepIndex = 2);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _finishRoutine() async {
    final provider = Provider.of<RoutinesProvider>(context, listen: false);
    final success = await provider.completeRoutine(widget.routineType);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Your routine could not be saved. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
