import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class CustomRoutineDialog extends StatefulWidget {
  const CustomRoutineDialog({super.key});

  @override
  State<CustomRoutineDialog> createState() => _CustomRoutineDialogState();
}

class _CustomRoutineDialogState extends State<CustomRoutineDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TimeOfDay _reminderTime = const TimeOfDay(hour: 12, minute: 0);

  final List<RoutineStep> _availableSteps = [
    RoutineStep(
        id: 'cs-sleep',
        title: 'Sleep Feeling Check',
        subtitle: 'Log morning sleep restoration',
        icon: Icons.wb_twilight,
        type: StepType.sleepTracker),
    RoutineStep(
        id: 'cs-focus',
        title: 'Morning Focus Journal',
        subtitle: 'Set intention for the day',
        icon: Icons.lightbulb_outline,
        type: StepType.journalFocus),
    RoutineStep(
        id: 'cs-grounding',
        title: 'Quick 3-2-1 Grounding',
        subtitle: 'About 30 seconds of sensory anchoring',
        icon: Icons.spa_outlined,
        type: StepType.grounding),
    RoutineStep(
        id: 'cs-breath',
        title: '30-second Breathing Reset',
        subtitle: 'Three guided calming breaths',
        icon: Icons.air,
        type: StepType.meditation),
    RoutineStep(
        id: 'cs-highlight',
        title: 'Highlight Journal',
        subtitle: 'Record top moment of the day',
        icon: Icons.auto_stories_outlined,
        type: StepType.journalHighlight),
    RoutineStep(
        id: 'cs-mood',
        title: 'Mood Check-In',
        subtitle: 'Track emotional state & factors',
        icon: Icons.sentiment_satisfied_alt_outlined,
        type: StepType.moodTracker),
    RoutineStep(
        id: 'cs-gratitude',
        title: 'Gratitude Garden',
        subtitle: 'Plant a gratitude flower',
        icon: Icons.local_florist_outlined,
        type: StepType.gratitudeGarden),
  ];

  final List<RoutineStep> _selectedSteps = [];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _saveRoutine() {
    if (_titleController.text.trim().isEmpty || _selectedSteps.isEmpty) return;

    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final newRoutine = RoutineConfig(
      id: id,
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty
          ? 'Personalized Routine'
          : _subtitleController.text.trim(),
      type: RoutineType.custom,
      reminderTime: _reminderTime,
      primaryColor: AppColors.sageGreen,
      steps: List.from(_selectedSteps),
    );

    routinesProvider.addCustomRoutine(newRoutine);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(
                  'Create Custom Routine',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                )),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              maxLength: 60,
              decoration: InputDecoration(
                labelText: 'Routine Title',
                hintText: 'e.g. Afternoon Energy Reset',
                filled: true,
                fillColor:
                    isDark ? AppColors.darkBackground : AppColors.warmCream,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleController,
              decoration: InputDecoration(
                labelText: 'Subtitle / Description',
                hintText: 'e.g. Quick 5-min mental clarity',
                filled: true,
                fillColor:
                    isDark ? AppColors.darkBackground : AppColors.warmCream,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose at least one activity:',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 10),
            ..._availableSteps.map((step) {
              final isSelected = _selectedSteps.any((s) => s.type == step.type);
              return CheckboxListTile(
                title: Text(step.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle:
                    Text(step.subtitle, style: const TextStyle(fontSize: 12)),
                secondary: Icon(step.icon, color: AppColors.sageGreen),
                value: isSelected,
                activeColor: AppColors.sageGreen,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSteps.add(step);
                    } else {
                      _selectedSteps.removeWhere((s) => s.type == step.type);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _titleController.text.trim().isEmpty || _selectedSteps.isEmpty
                    ? null : _saveRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Save Custom Routine',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
