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
  final _scrollController = ScrollController();
  bool _failed = false;
  final _service = const LearningAskKaiService();
  AIRequestCancellationToken? _cancellationToken;
  LearningAskKaiResult? _result;
  bool _loading = false;
  String? _submittedQuestion;

  @override
  void dispose() {
    _cancellationToken?.cancel();
    _controller.dispose();
    _scrollController.dispose();
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
    _controller.clear();
    _focusNode.unfocus();
    final token = AIRequestCancellationToken();
    _cancellationToken = token;
    setState(() {
      _submittedQuestion = question;
      _loading = true;
      _result = null;
      _failed = false;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
              ? Duration.zero
              : KaibiganMotion.standard,
          curve: KaibiganMotion.enter,
        );
      });
    } on AIRequestCancelledException {
      // Closing the sheet intentionally cancels the request.
    } catch (_) {
      if (mounted && !token.isCancelled) {
        setState(() {
          _failed = true;
          _controller.text = question;
        });
      }
    } finally {
      if (mounted && identical(_cancellationToken, token)) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildUserBubble(
    BuildContext context, {
    required KaibiganPalette palette,
    required String text,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.accent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: palette.onAccent,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildKaiBubble(
    BuildContext context, {
    required KaibiganPalette palette,
    required Widget child,
    bool isAnswer = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.honeyAmber,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: AppColors.honeyAmber.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '🐝',
            style: TextStyle(fontSize: 17),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: isAnswer
              ? child
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: palette.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.shadow.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: child,
                ),
        ),
      ],
    );
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
              // Drag Handle
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Chat Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.honeyGold, AppColors.honeyAmber],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.honeyAmber.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '🐝',
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  LanguageHelper.pick(
                                    widget.language,
                                    english: 'Ask Kai about this idea',
                                    filipino:
                                        'Tanungin si Kai tungkol sa ideyang ito',
                                    taglish: 'Ask Kai about this idea',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.accentSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: palette.accentStrong,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.currentSection.heading
                                .resolve(widget.language),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: palette.textSecondary,
                                      fontSize: 12,
                                    ),
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

              // Chat Message Stream
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: [
                    // Safety/Grounding Banner Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: palette.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: palette.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: palette.accentStrong,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              LanguageHelper.pick(
                                widget.language,
                                english:
                                    'Ask about this idea, other lessons, and mental health. Kai is an AI guide, not a clinician. Your questions are not added to your journal or memory.',
                                filipino:
                                    'Magtanong tungkol sa ideyang ito, iba pang aralin, at kalusugang pangkaisipan. AI na gabay si Kai, hindi propesyonal na tagapangalaga. Hindi itinatabi sa talaarawan o memorya ang mga tanong mo.',
                                taglish:
                                    'Ask about this idea, other lessons, and mental health. AI guide si Kai, hindi clinician. Hindi idinadagdag sa journal or memory ang questions mo.',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: palette.textSecondary,
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Kai Initial Greeting Message
                    _buildKaiBubble(
                      context,
                      palette: palette,
                      child: Text(
                        LanguageHelper.pick(
                          widget.language,
                          english:
                              'Hello! I\'m Kai, your learning companion. Ask me anything to clarify this concept, or explore how to apply it in your life.',
                          filipino:
                              'Kumusta! Ako si Kai, ang kasama mo sa pag-aaral. Magtanong ng kahit ano upang mas luminao ang ideyang ito o kung paano ito maisasabuhay.',
                          taglish:
                              'Hello! I\'m Kai, your learning companion. Ask me anything to clarify this concept, or explore how to apply it in your life.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.textPrimary,
                              height: 1.45,
                            ),
                      ),
                    ),

                    // User Submitted Question
                    if (_submittedQuestion != null) ...[
                      const SizedBox(height: 16),
                      _buildUserBubble(
                        context,
                        palette: palette,
                        text: _submittedQuestion!,
                      ),
                    ],

                    // Loading Indicator Bubble
                    if (_loading) ...[
                      const SizedBox(height: 16),
                      _buildKaiBubble(
                        context,
                        palette: palette,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              LanguageHelper.pick(
                                widget.language,
                                english: 'Finding a helpful explanation…',
                                filipino: 'Naghahanap ng malinaw na paliwanag…',
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Failed Error Notice
                    if (_failed) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: palette.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: palette.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                LanguageHelper.pick(
                                  widget.language,
                                  english:
                                      'That answer could not load. Tap Ask Kai to try again.',
                                  filipino:
                                      'Hindi mabuksan ang sagot. Pindutin ang Tanungin si Kai para subukan muli.',
                                ),
                                style: TextStyle(
                                  color: palette.danger,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Kai Answer Bubble
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      _buildKaiBubble(
                        context,
                        palette: palette,
                        isAnswer: true,
                        child: _LearningKaiAnswer(
                          result: _result!,
                          language: widget.language,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Suggestions Strip
              if (!_loading) ...[
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ActionChip(
                        key: ValueKey('learning-kai-suggestion-$index'),
                        label: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        avatar: Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: palette.accent,
                        ),
                        backgroundColor: palette.surfaceSubtle,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: palette.border.withValues(alpha: 0.6),
                          ),
                        ),
                        onPressed: () => _ask(suggestion),
                      );
                    },
                  ),
                ),
              ],

              // Sticky Bottom Chat Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 12, 12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border(
                    top: BorderSide(
                      color: palette.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('learning-kai-question-field'),
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !_loading,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: LearningAskKaiService.maxQuestionCharacters,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _ask(),
                        decoration: InputDecoration(
                          hintText: LanguageHelper.pick(
                            widget.language,
                            english: 'Ask a question about this idea…',
                            filipino: 'Magtanong tungkol sa ideyang ito…',
                            taglish: 'Ask a question about this idea…',
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: palette.surfaceSubtle,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: palette.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.honeyGold, AppColors.honeyAmber],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.honeyAmber.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        key: const ValueKey('submit-learning-kai-question'),
                        onPressed: _loading ? null : () => _ask(),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onHoney,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                color: AppColors.onHoney,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
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
                                filipino: 'Tungkol sa araling ito',
                              )
                            : LanguageHelper.pick(
                                language,
                                english: 'Kai, grounded in this lesson',
                                filipino: 'Kai, batay sa araling ito',
                              ),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                    filipino: 'Tingnan ang mga matatawagan',
                  ),
                ),
              ),
            ],
            // Subtle AI Disclaimer
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 11,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    LanguageHelper.pick(
                      language,
                      english:
                          '✦ AI-generated response. For guidance only, not professional medical advice.',
                      filipino:
                          '✦ Binuo ng AI. Para sa gabay lamang, hindi medikal na payo.',
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
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
