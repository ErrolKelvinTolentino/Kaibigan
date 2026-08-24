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

class TodaysHighlightScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final RoutineLog? existingHighlight;

  const TodaysHighlightScreen({
    super.key,
    this.onCompleted,
    this.existingHighlight,
  });

  @override
  State<TodaysHighlightScreen> createState() => _TodaysHighlightScreenState();
}

class _TodaysHighlightScreenState extends State<TodaysHighlightScreen> {
  final TextEditingController _controller = TextEditingController();
  static const int _maxChars = 60;
  bool _isSaved = false;
  bool _isSaving = false;

  bool get _isEditing => widget.existingHighlight != null;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.existingHighlight?.focusOrHighlight ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveHighlight() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    final routinesProvider =
        Provider.of<RoutinesProvider>(context, listen: false);
    final success = _isEditing
        ? await routinesProvider.updateLog(
            widget.existingHighlight!.copyWith(focusOrHighlight: text),
          )
        : await routinesProvider.addLog(
            RoutineLog(
              id: '',
              routineId: 'highlight_${DateTime.now().millisecondsSinceEpoch}',
              routineType: RoutineType.night,
              focusOrHighlight: text,
              completedAt: DateTime.now(),
            ),
          );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isSaved = success;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            routinesProvider.errorMessage ??
                'Your highlight could not be saved. Please try again.',
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

    final currentLength = _controller.text.length;
    final remainingChars = _maxChars - currentLength;

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
          "Today's Highlight",
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete highlight',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              onPressed: _isSaving ? null : _deleteHighlight,
            ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _isSaved
              ? _buildSuccessView(context, isDark, mascot)
              : _buildInputView(context, isDark, mascot, remainingChars),
        ),
      ),
    );
  }

  Widget _buildInputView(BuildContext context, bool isDark, MascotInfo mascot,
      int remainingChars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              FeatureIconHelper.todaysHighlight,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('✨', style: TextStyle(fontSize: 56)),
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 20),
        Text(
          "What is the highlight of your day?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Keep it light, sweet, and memorable (up to 60 characters).",
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _controller,
                maxLength: _maxChars,
                maxLines: 2,
                autofocus: true,
                onChanged: (v) => setState(() {}),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. Sipped warm coffee under morning sun...",
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                        : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: remainingChars < 10
                      ? AppColors.softRose.withValues(alpha: 0.2)
                      : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_controller.text.length} / $_maxChars',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: remainingChars < 10
                        ? AppColors.softRose
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _controller.text.trim().isNotEmpty && !_isSaving
                ? _saveHighlight
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              disabledBackgroundColor: isDark ? Colors.white10 : Colors.black12,
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
                : Text(
                    _isEditing ? 'Update Highlight' : 'Save Highlight',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(
      BuildContext context, bool isDark, MascotInfo mascot) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            FeatureIconHelper.todaysHighlight,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.wb_sunny_rounded,
                size: 60,
                color: AppColors.honeyGold),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          "Highlight Captured!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '"${_controller.text.trim()}"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: AppColors.honeyAmber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Little moments like this bring so much sweetness to life. 🐝",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text("Done",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteHighlight() async {
    final log = widget.existingHighlight;
    if (log == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove today\'s highlight?'),
        content: const Text(
          'This permanently removes the moment from your saved routine history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<RoutinesProvider>(context, listen: false);
    final success = await provider.deleteLog(log.id);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'The highlight was not removed.',
          ),
        ),
      );
    }
  }
}
