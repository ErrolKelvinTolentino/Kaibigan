import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../routine_model.dart';
import '../routines_provider.dart';

class AddActionSheet extends StatefulWidget {
  final String routineId;

  const AddActionSheet({super.key, required this.routineId});

  @override
  State<AddActionSheet> createState() => _AddActionSheetState();
}

class _AddActionSheetState extends State<AddActionSheet> {
  bool _isCreatingCustom = false;
  bool _isSaving = false;
  bool _hasPendingAction = false;
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _customSubtitleController =
      TextEditingController();
  final TextEditingController _customPromptController = TextEditingController();
  int _estimatedMinutes = 2;

  final List<RoutineStep> _presetSteps = [
    RoutineStep(
        id: 'preset-sleep',
        title: 'Sleep Feeling Check',
        subtitle: 'Log morning sleep restoration',
        icon: Icons.wb_twilight,
        type: StepType.sleepTracker,
        estimatedMinutes: 1),
    RoutineStep(
        id: 'preset-focus',
        title: 'Morning Focus Journal',
        subtitle: 'Set intention & priority for today',
        icon: Icons.lightbulb_outline,
        type: StepType.journalFocus,
        estimatedMinutes: 2),
    RoutineStep(
        id: 'preset-grounding',
        title: 'Quick 3-2-1 Grounding',
        subtitle: 'About 30 seconds of sensory anchoring',
        icon: Icons.spa_outlined,
        type: StepType.grounding,
        estimatedMinutes: 1),
    RoutineStep(
        id: 'preset-breath',
        title: '30-second Breathing Reset',
        subtitle: 'Three guided calming breaths',
        icon: Icons.air,
        type: StepType.meditation,
        estimatedMinutes: 1),
    RoutineStep(
        id: 'preset-highlight',
        title: 'Night Highlight Journal',
        subtitle: 'Reflect on top moment today',
        icon: Icons.auto_stories_outlined,
        type: StepType.journalHighlight,
        estimatedMinutes: 3),
    RoutineStep(
        id: 'preset-mood',
        title: 'Night Mood Check-In',
        subtitle: 'Track emotional state & factors',
        icon: Icons.sentiment_satisfied_alt_outlined,
        type: StepType.moodTracker,
        estimatedMinutes: 2),
    RoutineStep(
        id: 'preset-gratitude',
        title: 'Gratitude Garden Planting',
        subtitle: 'Plant a gratitude flower',
        icon: Icons.local_florist_outlined,
        type: StepType.gratitudeGarden,
        estimatedMinutes: 2),
  ];

  @override
  void dispose() {
    _customTitleController.dispose();
    _customSubtitleController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _addPresetAction(RoutineStep step) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);
    if (_hasPendingAction) {
      await routinesProvider.saveConfigurations();
      await _finishSave(routinesProvider);
      return;
    }
    final newStep = step.copyWith(
      id: 'step_${DateTime.now().millisecondsSinceEpoch}',
      isEnabled: true,
    );
    routinesProvider.addStepToRoutine(widget.routineId, newStep);
    _hasPendingAction = true;
    await _finishSave(routinesProvider);
  }

  Future<void> _saveCustomAction() async {
    if (_isSaving || _customTitleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);
    if (_hasPendingAction) {
      await routinesProvider.saveConfigurations();
      await _finishSave(routinesProvider);
      return;
    }
    final newStep = RoutineStep(
      id: 'custom_step_${DateTime.now().millisecondsSinceEpoch}',
      title: _customTitleController.text.trim(),
      subtitle: _customSubtitleController.text.trim().isEmpty
          ? 'Custom Action Step'
          : _customSubtitleController.text.trim(),
      icon: Icons.star_outline,
      type: StepType.custom,
      estimatedMinutes: _estimatedMinutes,
      customPrompt: _customPromptController.text.trim(),
      isEnabled: true,
    );

    routinesProvider.addStepToRoutine(widget.routineId, newStep);
    _hasPendingAction = true;
    await _finishSave(routinesProvider);
  }

  Future<void> _finishSave(RoutinesProvider routinesProvider) async {
    await routinesProvider.flushConfigurationWrites();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (routinesProvider.configurationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(routinesProvider.configurationError!)),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
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
                Expanded(
                    child: Text(
                  _isCreatingCustom
                      ? 'Create Custom Action'
                      : 'Add Action to Routine',
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
            if (!_isCreatingCustom) ...[
              ElevatedButton.icon(
                onPressed: () => setState(() => _isCreatingCustom = true),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Create New Custom Action'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Or Pick Preset Action:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 10),
              ..._presetSteps.map((step) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color:
                        isDark ? AppColors.darkBackground : AppColors.warmCream,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(step.icon,
                            color: AppColors.sageGreen, size: 20),
                      ),
                      title: Text(step.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(step.subtitle,
                          style: const TextStyle(fontSize: 12)),
                      trailing:
                          const Icon(Icons.add, color: AppColors.sageGreen),
                      onTap: _isSaving ? null : () => _addPresetAction(step),
                    ),
                  ),
                );
              }),
            ] else ...[
              TextField(
                controller: _customTitleController,
                onChanged: (_) => setState(() {}),
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: 'Action Title',
                  hintText: 'e.g. 5-Min Warm Tea Stretch',
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
                controller: _customSubtitleController,
                decoration: InputDecoration(
                  labelText: 'Subtitle',
                  hintText: 'e.g. Sip tea slowly and stretch',
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
                controller: _customPromptController,
                decoration: InputDecoration(
                  labelText: 'Custom Prompt (Optional)',
                  hintText:
                      'e.g. What warm thoughts are you savoring right now?',
                  filled: true,
                  fillColor:
                      isDark ? AppColors.darkBackground : AppColors.warmCream,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Duration:',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  DropdownButton<int>(
                    value: _estimatedMinutes,
                    items: [1, 2, 3, 5, 10, 15].map((m) {
                      return DropdownMenuItem(value: m, child: Text('$m mins'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _estimatedMinutes = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _isCreatingCustom = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Back to Presets'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ||
                              _customTitleController.text.trim().isEmpty
                          ? null
                          : _saveCustomAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(_isSaving ? 'Saving…' : 'Save Action',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
