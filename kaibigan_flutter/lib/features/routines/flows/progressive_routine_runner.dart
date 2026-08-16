import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../companion/companion_model.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../screens/todays_focus_screen.dart';
import '../screens/todays_highlight_screen.dart';
import '../screens/daily_reflection_screen.dart';
import '../../mood_tracking/mood_tracker_screen.dart';
import '../../gratitude_garden/garden_screen.dart';

class ProgressiveRoutineRunner extends StatefulWidget {
  final RoutineType routineType;

  const ProgressiveRoutineRunner({super.key, required this.routineType});

  @override
  State<ProgressiveRoutineRunner> createState() => _ProgressiveRoutineRunnerState();
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
        onCompleted: () => Navigator.of(context).pop(),
      );
    } else if (widget.routineType == RoutineType.midday) {
      if (_stepIndex == 0) {
        return MoodTrackerScreen(
          onCompleted: () => setState(() => _stepIndex = 1),
        );
      } else if (_stepIndex == 1) {
        return const GardenScreen();
      }
    } else {
      // Night Routine: Mood -> Highlight -> Reflection prompt
      if (_stepIndex == 0) {
        return MoodTrackerScreen(
          onCompleted: () => setState(() => _stepIndex = 1),
        );
      } else if (_stepIndex == 1) {
        return TodaysHighlightScreen(
          onCompleted: () => _promptDailyReflection(context, isDark, mascot),
        );
      } else if (_stepIndex == 2) {
        return DailyReflectionScreen(
          onCompleted: () => Navigator.of(context).pop(),
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
            const Text('Routine Complete! 🐝✨', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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

  void _promptDailyReflection(BuildContext context, bool isDark, MascotInfo mascot) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.honeyGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('🪞', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 16),
            Text(
              'Want to start writing your Daily Reflection?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a few unhurried minutes to unpack your day with ${mascot.name}, or complete your routine now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop(); // Close routine
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Skip for Now', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() => _stepIndex = 2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.honeyGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Start Reflection ✨', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
