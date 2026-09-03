import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_surface.dart';
import '../comfort_corner/akbay_safety_sheet.dart';
import 'learning_ask_kai_service.dart';
import 'learning_model.dart';

class LearningAskKaiSheet extends StatefulWidget {
  const LearningAskKaiSheet({
    super.key,
    required this.lesson,
    required this.currentSection,
    required this.language,
  });

  final LearningLesson lesson;
  final LearningSection currentSection;
  final String language;

  static Future<void> show(
    BuildContext context, {
    required LearningLesson lesson,
    required LearningSection currentSection,
    required String language,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LearningAskKaiSheet(
        lesson: lesson,
        currentSection: currentSection,
        language: language,
      ),
    );
  }

  @override
  State<LearningAskKaiSheet> createState() => _LearningAskKaiSheetState();
}

class _LearningAskKaiSheetState extends State<LearningAskKaiSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _service = const LearningAskKaiService();
  AIRequestCancellationToken? _cancellationToken;
  LearningAskKaiResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _cancellationToken?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> get _suggestions => [
        LanguageHelper.pick(
          widget.language,
          english: 'Explain this in simpler words.',
          filipino: 'Ipaliwanag ito sa mas simpleng salita.',
          taglish: 'Explain this in simpler words.',
        ),
        LanguageHelper.pick(
          widget.language,
          english: 'What could this look like in daily life?',
          filipino: 'Paano ito maaaring makita sa araw-araw?',
          taglish: 'Ano ang itsura nito in daily life?',
        ),
        LanguageHelper.pick(
          widget.language,
          english: 'What is one safe step from this idea?',
          filipino: 'Ano ang isang ligtas na hakbang mula sa ideyang ito?',
          taglish: 'What is one safe step from this idea?',
        ),
      ];

  Future<void> _ask([String? suggestedQuestion]) async {
    if (_loading) return;
    if (suggestedQuestion != null) {
      _controller.text = suggestedQuestion;
    }
    final question = _controller.text.trim();
    if (question.isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    final token = AIRequestCancellationToken();
    _cancellationToken = token;
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final result = await _service.answer(
        question: question,
        lesson: widget.lesson,
        currentSection: widget.currentSection,
        language: widget.language,
        cancellationToken: token,
      );
      if (!mounted || token.isCancelled) return;
      setState(() => _result = result);
    } on AIRequestCancelledException {
      // Closing the sheet intentionally cancels the request.
    } finally {
      if (mounted && identical(_cancellationToken, token)) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Material(
          key: const ValueKey('learning-ask-kai-sheet'),
          color: palette.background,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.honeyAmber,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'K',
                        style: TextStyle(
                          color: AppColors.onHoney,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
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
                              widget.language,
                              english: 'Ask Kai about this idea',
                              filipino:
                                  'Tanungin si Kai tungkol sa ideyang ito',
                              taglish: 'Ask Kai about this idea',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            widget.currentSection.heading
                                .resolve(widget.language),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: LanguageHelper.pick(
                        widget.language,
                        english: 'Close',
                        filipino: 'Isara',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KaibiganSurface(
                        tone: KaibiganSurfaceTone.accent,
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: palette.accentStrong,
                              size: 19,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                LanguageHelper.pick(
                                  widget.language,
                                  english:
                                      'Kai answers questions about this slide, other lessons, and mental health. Questions are not added to your journal or memory, and this cannot diagnose or replace professional care.',
                                  filipino:
                                      'Sumasagot si Kai tungkol sa slide na ito, iba pang aralin, at kalusugang pangkaisipan. Hindi idaragdag sa journal o memory ang tanong, at hindi ito diagnosis o kapalit ng professional care.',
                                  taglish:
                                      'Kai answers about this slide, other lessons, and mental health. Hindi mase-save sa journal or memory ang question, at hindi ito diagnosis or replacement for professional care.',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: palette.textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        LanguageHelper.pick(
                          widget.language,
                          english: 'Try asking',
                          filipino: 'Subukang itanong',
                        ),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestions
                            .map(
                              (suggestion) => ActionChip(
                                key: ValueKey(
                                  'learning-kai-suggestion-${_suggestions.indexOf(suggestion)}',
                                ),
                                avatar: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                ),
                                label: Text(suggestion),
                                onPressed:
                                    _loading ? null : () => _ask(suggestion),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const ValueKey('learning-kai-question-field'),
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !_loading,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: LearningAskKaiService.maxQuestionCharacters,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _ask(),
                        decoration: InputDecoration(
                          hintText: LanguageHelper.pick(
                            widget.language,
                            english: 'What would you like clarified?',
                            filipino: 'Ano ang gusto mong malinawan?',
                            taglish: 'What would you like clarified?',
                          ),
                          prefixIcon: const Icon(Icons.chat_bubble_outline),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey('submit-learning-kai-question'),
                          onPressed: _loading ? null : _ask,
                          icon: _loading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: palette.onAccent,
                                  ),
                                )
                              : const Icon(Icons.arrow_upward_rounded),
                          label: Text(
                            _loading
                                ? LanguageHelper.pick(
                                    widget.language,
                                    english: 'Checking the lesson…',
                                    filipino: 'Sinusuri ang lesson…',
                                  )
                                : LanguageHelper.pick(
                                    widget.language,
                                    english: 'Ask from this lesson',
                                    filipino: 'Magtanong mula sa lesson',
                                  ),
                          ),
                        ),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 16),
                        _LearningKaiAnswer(
                          result: _result!,
                          language: widget.language,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningKaiAnswer extends StatelessWidget {
  const _LearningKaiAnswer({
    required this.result,
    required this.language,
  });

  final LearningAskKaiResult result;
  final String language;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final isRedirect = result.kind != LearningAskKaiResultKind.answer &&
        result.kind != LearningAskKaiResultKind.crisis;
    return Semantics(
      liveRegion: true,
      child: KaibiganSurface(
        key: const ValueKey('learning-kai-answer'),
        tone: result.isSafetyResponse
            ? KaibiganSurfaceTone.botanical
            : isRedirect
                ? KaibiganSurfaceTone.subtle
                : KaibiganSurfaceTone.accent,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isSafetyResponse
                      ? Icons.health_and_safety_outlined
                      : isRedirect
                          ? Icons.turn_left_rounded
                          : Icons.auto_awesome_rounded,
                  color: result.isSafetyResponse
                      ? palette.botanical
                      : palette.accent,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.isSafetyResponse
                        ? LanguageHelper.pick(
                            language,
                            english: 'Safety comes first',
                            filipino: 'Kaligtasan muna',
                          )
                        : isRedirect
                            ? LanguageHelper.pick(
                                language,
                                english: 'Staying with this lesson',
                                filipino: 'Nananatili sa lesson na ito',
                              )
                            : LanguageHelper.pick(
                                language,
                                english: 'Kai, grounded in this lesson',
                                filipino: 'Kai, nakabatay sa lesson na ito',
                              ),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MarkdownBody(
              data: result.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                      height: 1.55,
                    ),
                listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
              ),
            ),
            if (result.isOffline) ...[
              const SizedBox(height: 9),
              Text(
                LanguageHelper.pick(
                  language,
                  english: 'Offline answer copied directly from this idea.',
                  filipino:
                      'Offline na sagot na direktang mula sa ideyang ito.',
                ),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: palette.textMuted),
              ),
            ],
            if (result.isSafetyResponse) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('open-learning-safety-lines'),
                onPressed: () => AkbaySafetySheet.show(context),
                icon: const Icon(Icons.phone_in_talk_outlined),
                label: Text(
                  LanguageHelper.pick(
                    language,
                    english: 'View all safety lines',
                    filipino: 'Tingnan ang safety lines',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
