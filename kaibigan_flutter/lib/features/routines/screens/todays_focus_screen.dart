import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../settings/user_provider.dart';
import '../../companion/companion_model.dart';
import '../../mood_tracking/mood_model.dart';
import '../routines_provider.dart';
import '../routine_model.dart';

class TodaysFocusScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const TodaysFocusScreen({super.key, this.onCompleted});

  @override
  State<TodaysFocusScreen> createState() => _TodaysFocusScreenState();
}

class _TodaysFocusScreenState extends State<TodaysFocusScreen> {
  final TextEditingController _focusController = TextEditingController();
  int _promptIndex = 0;
  bool _isSubmitted = false;
  bool _isSaving = false;
  bool _showPrompt = false;

  final List<String> _guidingPrompts = [
    "What is the single most important thing you want to accomplish today?",
    "What gentle boundary can you set today to protect your peace of mind?",
    "If today could go smoothly in just one area, which one would you choose?",
    "How do you want to feel when you look back at today this evening?",
  ];

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  void _shufflePrompt() {
    setState(() {
      _promptIndex = (_promptIndex + 1) % _guidingPrompts.length;
    });
  }

  void _submitFocus() async {
    final text = _focusController.text.trim();
    if (text.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);
    final success = await routinesProvider.addLog(
      RoutineLog(
        id: '',
        routineId: 'focus_${DateTime.now().millisecondsSinceEpoch}',
        routineType: RoutineType.morning,
        focusOrHighlight: text,
        completedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isSubmitted = success;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            routinesProvider.errorMessage ??
                'Your focus could not be saved. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          icon: Icon(Icons.close_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Today's Focus",
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: _isSubmitted
              ? _buildAiInsightView(context, isDark, mascot)
              : _buildGuidedInputView(context, isDark),
        ),
      ),
    );
  }

  Widget _buildGuidedInputView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              FeatureIconHelper.todaysFocus,
              width: 88,
              height: 88,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('🎯', style: TextStyle(fontSize: 56)),
            ),
          ),
        ).animate().scale(duration: 320.ms, curve: Curves.easeOutCubic),
        const SizedBox(height: 14),
        Text(
          "What deserves your attention today?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'One sentence is enough. This is an intention, not a task list.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.darkCardBorder
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: _focusController,
            minLines: 2,
            maxLines: 3,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: "Today, I want to give my attention to…",
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                    : AppColors.textSecondaryLight.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_showPrompt)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(15, 12, 8, 12),
            decoration: BoxDecoration(
              color: AppColors.honeyGold.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _guidingPrompts[_promptIndex],
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
                IconButton(
                  tooltip: 'Another prompt',
                  onPressed: _shufflePrompt,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                ),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showPrompt = true),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
              label: const Text('Need a gentle prompt?'),
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submitFocus,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "Keep this focus",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsightView(
      BuildContext context, bool isDark, MascotInfo mascot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: mascot.primaryColor.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(
            mascot.materialIcon,
            size: 48,
            color: mascot.primaryColor,
          ),
        ).animate().scale(duration: 320.ms, curve: Curves.easeOutCubic),
        const SizedBox(height: 20),
        Text(
          "Your focus is set",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '"${_focusController.text.trim()}"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: mascot.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'One thing is enough. ${mascot.name} will keep this intention close without turning it into another list.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ).animate().fadeIn(delay: 160.ms),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text("Return to my day",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
