import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../../../core/widgets/mobile_layout.dart';
import '../../settings/user_provider.dart';
import '../learning_progress_store.dart';
import 'friend_support_completion_screen.dart';
import 'friend_support_model.dart';
import 'friend_support_safety_sheet.dart';

class FriendSupportQuizScreen extends StatefulWidget {
  const FriendSupportQuizScreen({
    super.key,
    required this.lesson,
    this.progressStore,
  });

  final FriendSupportLesson lesson;
  final LearningProgressStore? progressStore;

  @override
  State<FriendSupportQuizScreen> createState() =>
      _FriendSupportQuizScreenState();
}

class _FriendSupportQuizScreenState extends State<FriendSupportQuizScreen> {
  late final LearningProgressStore _progressStore;
  int _currentIndex = 0;
  int? _selectedIndex;
  int _correctCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _progressStore = widget.progressStore ?? LearningProgressStore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  FriendSupportQuestion get _currentQuestion =>
      widget.lesson.questions[_currentIndex];

  bool get _isAnswered => _selectedIndex != null;

  void _onSelectOption(int index) {
    if (_isAnswered) return; // Locked once answered
    setState(() {
      _selectedIndex = index;
      if (index == _currentQuestion.correctIndex) {
        _correctCount++;
      }
    });

    // Auto-scroll down slightly so user clearly sees the feedback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showHint(BuildContext context, String language) {
    final palette = context.kaibigan;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: KaibiganSurface(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.accentSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '💡',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LanguageHelper.pick(
                          language,
                          english: 'Helpful Guidance',
                          filipino: 'Gabay sa Pagsagot',
                        ),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: LanguageHelper.pick(
                        language,
                        english: 'Close',
                        filipino: 'Isara',
                      ),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _currentQuestion.hint.resolve(language),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: palette.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNext(String language) async {
    final isLastQuestion =
        _currentIndex == widget.lesson.questions.length - 1;

    if (isLastQuestion) {
      // Save score and mark completed
      await _progressStore.saveQuizScore(
        widget.lesson.id,
        _correctCount,
        widget.lesson.questions.length,
      );
      await _progressStore.setCompleted(widget.lesson.id, true);

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => FriendSupportCompletionScreen(
            lesson: widget.lesson,
            score: _correctCount,
            total: widget.lesson.questions.length,
            language: language,
            onPracticeAgain: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => FriendSupportQuizScreen(
                    lesson: widget.lesson,
                    progressStore: _progressStore,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserProvider>().language;
    final palette = context.kaibigan;
    final question = _currentQuestion;
    final totalQuestions = widget.lesson.questions.length;
    final isLastQuestion = _currentIndex == totalQuestions - 1;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          LanguageHelper.pick(
            language,
            english: 'Question ${_currentIndex + 1} of $totalQuestions',
            filipino: 'Tanong ${_currentIndex + 1} ng $totalQuestions',
          ),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          // Help Hint Button
          IconButton(
            key: const ValueKey('friend-support-quiz-hint-btn'),
            tooltip: LanguageHelper.pick(
              language,
              english: 'Helpful hint',
              filipino: 'Tulong / Gabay',
            ),
            icon: const Text('💡', style: TextStyle(fontSize: 20)),
            onPressed: () => _showHint(context, language),
          ),
          // Need Help Emergency Hotline Button
          TextButton.icon(
            key: const ValueKey('friend-support-quiz-need-help'),
            onPressed: () => FriendSupportSafetySheet.show(
              context,
              language: language,
            ),
            icon: Icon(
              Icons.health_and_safety_outlined,
              color: palette.danger,
              size: 18,
            ),
            label: Text(
              LanguageHelper.pick(
                language,
                english: 'Need Help?',
                filipino: 'Tulong?',
              ),
              style: TextStyle(
                color: palette.danger,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / totalQuestions,
            backgroundColor: palette.surfaceSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
          ),
        ),
      ),
      body: SafeArea(
        child: MobileContent(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: MobileLayout.horizontalPadding(context),
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Context quote (Friend's statement)
                if (question.contextQuote != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? palette.surfaceElevated
                          : AppColors.pollenGlow.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: palette.accentSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '💬',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageHelper.pick(
                                  language,
                                  english: 'Your friend says:',
                                  filipino: 'Sinabi ng kaibigan mo:',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: palette.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                question.contextQuote!.resolve(language),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                      height: 1.42,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Question Prompt
                Text(
                  question.prompt.resolve(language),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.38,
                      ),
                ),
                const SizedBox(height: 16),

                // Option Cards
                ...List.generate(question.options.length, (optIndex) {
                  final option = question.options[optIndex];
                  final isSelected = _selectedIndex == optIndex;
                  final isCorrect = optIndex == question.correctIndex;

                  Color backgroundColor = palette.surface;
                  Color borderColor = palette.border;
                  Color textColor = palette.textPrimary;
                  Widget? statusIcon;

                  if (_isAnswered) {
                    if (isSelected) {
                      if (isCorrect) {
                        backgroundColor = palette.accentSubtle;
                        borderColor = palette.accent;
                        textColor = palette.accentStrong;
                        statusIcon = Icon(
                          Icons.check_circle_rounded,
                          color: palette.accent,
                          size: 22,
                        );
                      } else {
                        backgroundColor =
                            palette.danger.withValues(alpha: 0.1);
                        borderColor = palette.danger;
                        textColor = palette.danger;
                        statusIcon = Icon(
                          Icons.cancel_rounded,
                          color: palette.danger,
                          size: 22,
                        );
                      }
                    } else if (isCorrect) {
                      // Reveal correct option in soft green
                      backgroundColor = palette.accentSubtle.withValues(alpha: 0.5);
                      borderColor = palette.accent.withValues(alpha: 0.6);
                      statusIcon = Icon(
                        Icons.check_circle_outline_rounded,
                        color: palette.accent,
                        size: 22,
                      );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('quiz-option-${option.id}'),
                        onTap: _isAnswered ? null : () => _onSelectOption(optIndex),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.shadow.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isCorrect
                                          ? palette.accent
                                          : palette.danger)
                                      : palette.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  option.id,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : palette.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option.text.resolve(language),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        height: 1.4,
                                      ),
                                ),
                              ),
                              if (statusIcon != null) ...[
                                const SizedBox(width: 8),
                                statusIcon,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Educational Feedback Panel
                if (_isAnswered) ...[
                  const SizedBox(height: 12),
                  KaibiganSurface(
                    key: const ValueKey('quiz-feedback-panel'),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Result Banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedIndex == question.correctIndex
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF1E3326)
                                    : const Color(0xFFEDF8F1))
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF3B2323)
                                    : const Color(0xFFFFF0F0)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedIndex == question.correctIndex
                                  ? const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.3)
                                  : palette.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedIndex == question.correctIndex
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                color: _selectedIndex == question.correctIndex
                                    ? const Color(0xFF2E7D32)
                                    : palette.danger,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedIndex == question.correctIndex
                                      ? LanguageHelper.pick(
                                          language,
                                          english: 'Correct! Well done.',
                                          filipino: 'Tama! Magaling.',
                                        )
                                      : LanguageHelper.pick(
                                          language,
                                          english:
                                              'Correct Answer: ${question.correctOption.id}',
                                          filipino:
                                              'Tamang Sagot: ${question.correctOption.id}',
                                        ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: _selectedIndex ==
                                                question.correctIndex
                                            ? const Color(0xFF2E7D32)
                                            : palette.danger,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Chosen Option Explanation (if not correct)
                        if (_selectedIndex != question.correctIndex) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LanguageHelper.pick(
                                    language,
                                    english:
                                        'About Option ${question.options[_selectedIndex!].id}:',
                                    filipino:
                                        'Tungkol sa Opsyon ${question.options[_selectedIndex!].id}:',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: palette.danger,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  question.options[_selectedIndex!].explanation
                                      .resolve(language),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: palette.textSecondary,
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Why Correct Option is right
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? const Color(0xFF1E3326).withValues(alpha: 0.5)
                                : const Color(0xFFF1F8F4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      LanguageHelper.pick(
                                        language,
                                        english:
                                            'Why ${question.correctOption.id} is the most supportive:',
                                        filipino:
                                            'Bakit ${question.correctOption.id} ang pinaka-nakakatulong:',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                question.correctExplanation.resolve(language),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: palette.textPrimary,
                                      height: 1.48,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        // Detailed review of all options expandable
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(top: 8),
                            title: Text(
                              LanguageHelper.pick(
                                language,
                                english: 'Review other choices',
                                filipino: 'Suriin ang ibang mga opsyon',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: palette.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            children: question.options.map((opt) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Option ${opt.id}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        opt.explanation.resolve(language),
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Next Question / Complete CTA
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.honeyGold,
                                AppColors.honeyAmber,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.honeyAmber.withValues(alpha: 0.32),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            key: const ValueKey('quiz-next-question-btn'),
                            onPressed: () => _onNext(language),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: AppColors.onHoney,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              isLastQuestion
                                  ? LanguageHelper.pick(
                                      language,
                                      english: 'Complete Lesson →',
                                      filipino: 'Tapusin ang Aralin →',
                                    )
                                  : LanguageHelper.pick(
                                      language,
                                      english: 'Next Question →',
                                      filipino: 'Susunod na Tanong →',
                                    ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
