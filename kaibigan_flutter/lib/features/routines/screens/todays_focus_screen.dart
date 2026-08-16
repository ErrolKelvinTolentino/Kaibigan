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
  String _generatedAiInsight = '';

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

  void _submitFocus(UserProvider userProvider, MascotInfo mascot) async {
    final text = _focusController.text.trim();
    if (text.isEmpty) return;

    // Generate localized AI guidance based on user language
    final lang = userProvider.language;
    if (lang == 'filipino') {
      _generatedAiInsight = "Napakagandang layunin nito para sa araw na ito! Tandaan, hindi kailangang magmadali. Mag-focus sa paisa-isang hakbang, at huwag kalimutang huminga kapag medyo mabigat. Kasama mo ako sa bawat sandali. Padayon!";
    } else if (lang == 'taglish') {
      _generatedAiInsight = "Ganda ng focus mo today! Advice ko lang: break it down into small, bite-sized tasks para hindi ka ma-overwhelm. Take mindful breathers in between. Wishing you the best of luck today, kaya mo yan! 🐝✨";
    } else {
      _generatedAiInsight = "What a clear and meaningful intention for today. Remember to approach it one gentle step at a time without rushing. Protect your energy and remember that your peace matters most. Wishing you the very best today!";
    }

    final routinesProvider = Provider.of<RoutinesProvider>(context, listen: false);
    await routinesProvider.addLog(
      RoutineLog(
        id: '',
        routineId: 'focus_${DateTime.now().millisecondsSinceEpoch}',
        routineType: RoutineType.morning,
        focusOrHighlight: text,
        completedAt: DateTime.now(),
      ),
    );

    setState(() {
      _isSubmitted = true;
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
          icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Today's Focus",
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _isSubmitted
              ? _buildAiInsightView(context, isDark, mascot)
              : _buildGuidedInputView(context, isDark, userProvider, mascot),
        ),
      ),
    );
  }

  Widget _buildGuidedInputView(BuildContext context, bool isDark, UserProvider userProvider, MascotInfo mascot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              FeatureIconHelper.todaysFocus,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text('🎯', style: TextStyle(fontSize: 56)),
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 20),

        // Guiding prompt pill with reshuffle button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.honeyGold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.honeyGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _guidingPrompts[_promptIndex],
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.shuffle_rounded, color: AppColors.honeyAmber, size: 20),
                tooltip: 'Shuffle guiding question',
                onPressed: _shufflePrompt,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "What will you focus on?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08),
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
            maxLines: 4,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: "Write your priority or intention for today...",
              hintStyle: TextStyle(
                color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
            ),
          ),
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _submitFocus(userProvider, mascot),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text(
              "Set Focus & Get Insight",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsightView(BuildContext context, bool isDark, MascotInfo mascot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),

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
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 20),

        Text(
          "${mascot.name}'s Insight & Wish",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
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

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            _generatedAiInsight,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),

        const Spacer(),

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
            child: const Text("I'm Ready!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
