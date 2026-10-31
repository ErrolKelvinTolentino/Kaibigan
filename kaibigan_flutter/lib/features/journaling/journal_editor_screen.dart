import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/journal_appearance.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/language_helper.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/ai_memory_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/ai_response_feedback_service.dart';
import '../../core/services/journal_draft_service.dart';
import '../../core/services/supabase_service.dart';
import '../companion/companion_model.dart';
import '../settings/journal_appearance_screen.dart';
import '../settings/user_provider.dart';
import '../comfort_corner/akbay_safety_sheet.dart';
import '../insights/wellbeing_context.dart';
import '../mood_tracking/mood_provider.dart';
import '../routines/routines_provider.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../../core/widgets/journal_format_toolbar.dart';
import '../../core/widgets/journal_paper_surface.dart';
import '../../core/widgets/mobile_layout.dart';
import 'journal_provider.dart';
import 'journal_reply_starters.dart';
import 'journal_reply_reveal.dart';
import 'journal_model.dart';
import 'journal_save_reflection_screen.dart';
import 'journal_editor_chrome.dart';

class MarkdownJournalEditingController extends TextEditingController {
  MarkdownJournalEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    if (text.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final children = <InlineSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLast = i == lines.length - 1;
      final lineEnding = isLast ? '' : '\n';

      // Check if line is a markdown heading: e.g. ### Heading or ## Heading or # Heading
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (headingMatch != null) {
        final hashes = headingMatch.group(1)!;
        final title = headingMatch.group(2)!;
        final level = hashes.length;
        final scale = level == 1 ? 1.22 : (level == 2 ? 1.14 : 1.08);

        // Render the hash marker very faintly so it doesn't look like raw broken syntax
        children.add(TextSpan(
          text: '$hashes ',
          style: baseStyle.copyWith(
            color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.22),
            fontSize: (baseStyle.fontSize ?? 16) * 0.85,
            fontWeight: FontWeight.w400,
          ),
        ));
        // Bold, prominent heading text
        children.add(TextSpan(
          text: '$title$lineEnding',
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: (baseStyle.fontSize ?? 16) * scale,
            height: 1.4,
          ),
        ));
        continue;
      }

      // Check inline bold and italics: **bold**, _italic_, *italic*
      final inlineSpans = _parseInlineMarkdown(line, baseStyle);
      children.addAll(inlineSpans);
      if (!isLast) {
        children.add(TextSpan(text: '\n', style: baseStyle));
      }
    }

    return TextSpan(children: children, style: baseStyle);
  }

  static List<InlineSpan> _parseInlineMarkdown(
      String line, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*([^*]+)\*\*)|(_([^_]+)_)|(\*([^*]+)\*)');
    int lastIndex = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: line.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // **bold**
        final content = match.group(2)!;
        spans.add(TextSpan(
          text: '**',
          style: baseStyle.copyWith(
            color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.22),
          ),
        ));
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
        spans.add(TextSpan(
          text: '**',
          style: baseStyle.copyWith(
            color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.22),
          ),
        ));
      } else if (match.group(3) != null) {
        // _italic_
        final content = match.group(4)!;
        spans.add(TextSpan(
          text: '_',
          style: baseStyle.copyWith(
            color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.22),
          ),
        ));
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(
          text: '_',
          style: baseStyle.copyWith(
            color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.22),
          ),
        ));
      } else if (match.group(5) != null) {
        // *italic*
        final content = match.group(6)!;
        spans.add(TextSpan(
          text: '*',
          style: baseStyle.copyWith(
            color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.22),
          ),
        ));
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(
          text: '*',
          style: baseStyle.copyWith(
            color: (baseStyle.color ?? Colors.black).withValues(alpha: 0.22),
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

class JournalTurn {
  final TextEditingController userController;
  final FocusNode focusNode = FocusNode();
  final GlobalKey replyAnchor = GlobalKey();
  String? aiResponse;
  List<String> suggestedReplies;
  String inferredNeed;
  bool isOfflineReply;
  bool animateReply = false;
  int replyRevision = 0;
  CompanionMode mode;
  String? companionId;
  AIReplyFeedback? feedback;
  AIReplyFeedbackReason? feedbackReason;

  JournalTurn({
    required String userText,
    this.aiResponse,
    this.suggestedReplies = const [],
    this.inferredNeed = 'heard',
    this.isOfflineReply = false,
    this.mode = CompanionMode.auto,
    this.companionId,
    this.feedback,
    this.feedbackReason,
  }) : userController = MarkdownJournalEditingController(
          text: cleanLegacyMarkdownHeadings(userText),
        );

  static String cleanLegacyMarkdownHeadings(String text) {
    return text.replaceAllMapped(
      RegExp(r'^\s*#{1,6}\s+(.+)$', multiLine: true),
      (match) {
        final title = match.group(1)!.trim();
        return title.startsWith('**') && title.endsWith('**')
            ? title
            : '**$title**';
      },
    );
  }

  void dispose() {
    userController.dispose();
    focusNode.dispose();
  }
}

class JournalEditorScreen extends StatefulWidget {
  final JournalEntry? initialEntry;
  final JournalEntry? entry;

  const JournalEditorScreen({super.key, this.initialEntry, this.entry});

  JournalEntry? get targetEntry => entry ?? initialEntry;

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen>
    with WidgetsBindingObserver {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _writingChanges = ValueNotifier(0);
  FocusNode get _activeFocusNode => _turns.last.focusNode;
  JournalTurn? _formattingTurn;
  bool _showFormatting = false;

  final List<JournalTurn> _turns = [];
  bool _isGeneratingAi = false;
  JournalTurn? _generatingTurn;
  JournalTurn? _pendingReplyReveal;
  double _readingSpace = 0;
  bool _isSaving = false;
  bool _isExportingPdf = false;
  AIRequestCancellationToken? _aiCancellationToken;
  String? _activeCompanionId;
  int _promptIndex = 0;
  bool _showWritingPrompt = false;
  bool _draftSaved = true;
  Timer? _draftTimer;
  bool _restoringDraft = false;

  String _t(
    String language, {
    required String english,
    required String filipino,
    String? taglish,
  }) =>
      LanguageHelper.pick(
        language,
        english: english,
        filipino: filipino,
        taglish: taglish,
      );

  List<String> _guidingPrompts(String language) {
    if (language == 'filipino') {
      return const [
        'Ano ang pinakamatagal na nananatili sa isip mo ngayon?',
        'Ano ang nagbigay sa iyo ng saya, pasasalamat, o kapanatagan?',
        'Kung walang manghuhusga, ano ang gusto mong sabihin?',
        'Anong damdamin ang iniiwasan mong maramdaman ngayon?',
        'Ano ang sasabihin sa iyo ng pinakamabait mong sarili?',
        'Ano ang isang munting tagumpay mo ngayong linggo?',
      ];
    }
    return const [
      'What is occupying the most space in your head right now?',
      'What made you feel proud, grateful, or at peace recently?',
      'If you could say anything without fear of judgment, what would it be?',
      'What is one emotion you are trying not to feel today?',
      'What would the kindest version of yourself say right now?',
      'What is one small victory you achieved this week?',
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final target = widget.targetEntry;
    if (target != null) {
      _titleController.text = target.hasGeneratedTitle ? '' : target.title;
      _activeCompanionId = target.companionId;
      for (final storedTurn in target.turnsForDisplay) {
        _addTurn(JournalTurn(
          userText: storedTurn.userText,
          aiResponse: storedTurn.aiResponse,
          mode: CompanionMode.auto,
          companionId: storedTurn.companionId ?? target.companionId,
        ));
      }
      if (_turns.isEmpty) _addTurn(JournalTurn(userText: target.content));
      final lastTurn = _turns.last;
      if (lastTurn.aiResponse?.trim().isNotEmpty ?? false) {
        _addTurn(JournalTurn(
          userText: '',
          mode: CompanionMode.auto,
          companionId: lastTurn.companionId ?? target.companionId,
        ));
      }
    } else {
      _addTurn(JournalTurn(userText: ''));
      _restoreDraft();
    }
    _titleController.addListener(() {
      _scheduleDraftSave();
      if (mounted) setState(() {});
    });
    _titleFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  String? get _draftUserId => SupabaseService.isInitialized
      ? SupabaseService.client.auth.currentUser?.id
      : null;

  void _addTurn(JournalTurn turn) {
    var previousText = turn.userController.text;
    turn.userController.addListener(() {
      if (previousText == turn.userController.text) return;
      final wasEmpty = previousText.trim().isEmpty;
      previousText = turn.userController.text;
      _scheduleDraftSave();
      if (mounted && !_restoringDraft) {
        _writingChanges.value++;
        // Only starter visibility needs to rebuild the conversation. Typing
        // updates the footer and word count without reparsing older replies.
        if (wasEmpty != previousText.trim().isEmpty) setState(() {});
      }
    });
    turn.focusNode.addListener(() {
      if (turn.focusNode.hasFocus && mounted) {
        setState(() => _formattingTurn = turn);
      }
    });
    _turns.add(turn);
  }

  Future<void> _restoreDraft() async {
    final userId = _draftUserId;
    if (userId == null) return;
    final draft = await JournalDraftService.read(userId);
    if (!mounted || draft == null) return;
    final turns = draft['turns'] as List<dynamic>?;
    final hasContent = (draft['title'] as String? ?? '').trim().isNotEmpty ||
        (turns?.any((item) =>
                ((item as Map<String, dynamic>)['text'] as String? ?? '')
                    .trim()
                    .isNotEmpty) ??
            false);
    if (!hasContent) return;

    _restoringDraft = true;
    for (final turn in _turns) {
      turn.dispose();
    }
    _turns.clear();
    _formattingTurn = null;
    _titleController.text = draft['title'] as String? ?? '';
    for (final item in turns ?? const []) {
      final map = item as Map<String, dynamic>;
      _addTurn(JournalTurn(
        userText: map['text'] as String? ?? '',
        aiResponse: map['aiResponse'] as String?,
        suggestedReplies: List<String>.from(
          map['suggestedReplies'] as List<dynamic>? ?? const [],
        ),
        inferredNeed: map['inferredNeed'] as String? ?? 'heard',
        isOfflineReply: map['isOfflineReply'] as bool? ?? false,
        mode: CompanionMode.auto,
        companionId: map['companionId'] as String?,
        feedback: map['feedback'] == null
            ? null
            : AIReplyFeedback.values.firstWhere(
                (value) => value.name == map['feedback'],
                orElse: () => AIReplyFeedback.helpful,
              ),
        feedbackReason: map['feedbackReason'] == null
            ? null
            : AIReplyFeedbackReason.values.firstWhere(
                (value) => value.name == map['feedbackReason'],
                orElse: () => AIReplyFeedbackReason.missedThePoint,
              ),
      ));
    }
    if (_turns.isEmpty) _addTurn(JournalTurn(userText: ''));
    _restoringDraft = false;
    setState(() {});
    if (mounted) {
      final language = context.read<UserProvider>().language;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              language,
              english: 'Your unsaved journal draft was restored.',
              filipino: 'Naibalik ang hindi pa na-save na burador.',
            ),
          ),
        ),
      );
    }
  }

  void _scheduleDraftSave() {
    if (_restoringDraft || widget.targetEntry != null) return;
    if (_draftSaved && mounted) setState(() => _draftSaved = false);
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 700), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final userId = _draftUserId;
    if (userId == null || widget.targetEntry != null) return;
    await JournalDraftService.write(userId, {
      'title': _titleController.text,
      'updatedAt': DateTime.now().toIso8601String(),
      'turns': _turns
          .map((turn) => {
                'text': turn.userController.text,
                'aiResponse': turn.aiResponse,
                'suggestedReplies': turn.suggestedReplies,
                'inferredNeed': turn.inferredNeed,
                'isOfflineReply': turn.isOfflineReply,
                'companionId': turn.companionId,
                'feedback': turn.feedback?.name,
                'feedbackReason': turn.feedbackReason?.name,
              })
          .toList(),
    });
    if (mounted) setState(() => _draftSaved = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _aiCancellationToken?.cancel();
    _draftTimer?.cancel();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _scrollController.dispose();
    _writingChanges.dispose();
    for (var turn in _turns) {
      turn.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealReplyStart());
  }

  void _showReplyStart(JournalTurn turn) {
    _pendingReplyReveal = turn;
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealReplyStart());
  }

  void _revealReplyStart() {
    if (!mounted ||
        _pendingReplyReveal == null ||
        !_scrollController.hasClients) {
      return;
    }
    // Wait for the actual keyboard resize, rather than racing timed scrolls.
    if (View.of(context).viewInsets.bottom > 0) return;
    final target =
        _pendingReplyReveal!.replyAnchor.currentContext?.findRenderObject();
    if (target == null || !target.attached) return;
    final offset =
        RenderAbstractViewport.of(target).getOffsetToReveal(target, 0).offset;
    final position = _scrollController.position;
    if (offset > position.maxScrollExtent + 0.5) {
      setState(() => _readingSpace += offset - position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealReplyStart());
      return;
    }
    _pendingReplyReveal = null;
    _scrollController.jumpTo(offset.clamp(0.0, position.maxScrollExtent));
  }

  void _shufflePrompt() {
    setState(() {
      final language = context.read<UserProvider>().language;
      _promptIndex = (_promptIndex + 1) % _guidingPrompts(language).length;
    });
  }

  String _getAllUserContent() {
    return _turns
        .map((t) => t.userController.text.trim())
        .where((txt) => txt.isNotEmpty)
        .join('\n\n');
  }

  String? _getAllAiResponses() {
    final responses = _turns
        .map((t) => t.aiResponse)
        .where((res) => res != null && res.isNotEmpty)
        .join('\n\n---\n\n');
    return responses.isEmpty ? null : responses;
  }

  List<JournalConversationTurn> _getConversationTurns() {
    return _turns
        .where((turn) =>
            turn.userController.text.trim().isNotEmpty ||
            (turn.aiResponse?.trim().isNotEmpty ?? false))
        .map(
          (turn) => JournalConversationTurn(
            userText: turn.userController.text.trim(),
            aiResponse: turn.aiResponse?.trim().isEmpty ?? true
                ? null
                : turn.aiResponse!.trim(),
            companionId: turn.companionId,
          ),
        )
        .toList(growable: false);
  }

  bool _conversationMatches(JournalEntry target) {
    final current = _getConversationTurns();
    final stored = target.turnsForDisplay;
    if (current.length != stored.length) return false;
    for (var index = 0; index < current.length; index++) {
      if (current[index].userText.trim() != stored[index].userText.trim() ||
          (current[index].aiResponse?.trim() ?? '') !=
              (stored[index].aiResponse?.trim() ?? '') ||
          (current[index].companionId ?? target.companionId) !=
              (stored[index].companionId ?? target.companionId)) {
        return false;
      }
    }
    return true;
  }

  List<AIConversationMessage> _conversationHistoryBeforeTurn(int turnIndex) {
    final history = <AIConversationMessage>[];
    for (final turn in _turns.take(turnIndex)) {
      final userText = turn.userController.text.trim();
      if (userText.isNotEmpty) {
        history.add(AIConversationMessage.user(userText));
      }
      final reply = turn.aiResponse?.trim() ?? '';
      if (reply.isNotEmpty) {
        history.add(AIConversationMessage.assistant(reply));
      }
    }
    return history;
  }

  /// The companion's view of how this week has actually gone.
  ///
  /// Aggregates only — counts, averages and the sleep shortfall the insights
  /// screens already display. No other entry's text is included, and the
  /// person can switch this off in AI memory & privacy.
  WellbeingContext _wellbeingContext() {
    if (!WellbeingContextService.isEnabled) return WellbeingContext.none;
    return WellbeingContextService.build(
      now: DateTime.now(),
      moods: context.read<MoodProvider?>()?.logs ?? const [],
      routines: context.read<RoutinesProvider?>()?.logs ?? const [],
      language: context.read<UserProvider>().language,
    );
  }

  Future<void> _triggerAiReflection() async {
    if (_isGeneratingAi || _isSaving) return;
    final lastTurn = _turns.last;
    final textToReflectOn = lastTurn.userController.text.trim();

    if (textToReflectOn.isEmpty) {
      final language = context.read<UserProvider>().language;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              language,
              english:
                  'Write at least one thought before asking for a reflection.',
              filipino:
                  'Magsulat muna ng kahit isang kaisipan bago humingi ng pagninilay.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Unfocus active input so the keyboard does not obscure the loading progress
    FocusScope.of(context).unfocus();

    final cancellationToken = AIRequestCancellationToken();
    _aiCancellationToken?.cancel();
    _aiCancellationToken = cancellationToken;
    setState(() {
      _isGeneratingAi = true;
      _generatingTurn = lastTurn;
      _readingSpace = 0;
    });
    _showReplyStart(lastTurn);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final companionId = _activeCompanionId ?? userProvider.selectedCompanion;
    final language = userProvider.language;
    // Read before the await: the widget may be gone by the time it returns.
    final wellbeing = _wellbeingContext();

    try {
      final aiReply = await AIService.generateCompanionReply(
        userText: textToReflectOn,
        companionId: companionId,
        language: language,
        mode: CompanionMode.auto,
        conversationHistory: _conversationHistoryBeforeTurn(_turns.length - 1),
        cancellationToken: cancellationToken,
        wellbeingContext: wellbeing.promptBlock,
      );

      if (mounted && !cancellationToken.isCancelled) {
        // The companion has already read this entry carefully; reusing what it
        // recognised is more accurate than re-deriving themes from keywords.
        if (!aiReply.isOffline) {
          unawaited(
            AIMemoryService.noteCompanionObservation(
              detectedEmotions: aiReply.detectedEmotions,
              standoutMoments: aiReply.journalMoments
                  .map((moment) => moment.title)
                  .toList(growable: false),
            ),
          );
        }
        setState(() {
          _readingSpace = 0;
          lastTurn.aiResponse = aiReply.text;
          lastTurn.animateReply = aiReply.safetyLevel == 'none';
          lastTurn.replyRevision++;
          lastTurn.suggestedReplies = aiReply.suggestedReplies;
          lastTurn.inferredNeed = aiReply.inferredNeed;
          lastTurn.isOfflineReply = aiReply.isOffline;
          lastTurn.mode = CompanionMode.auto;
          lastTurn.companionId = companionId;

          // Prepare next turn prompt area
          _addTurn(JournalTurn(
            userText: '',
            mode: CompanionMode.auto,
            companionId: companionId,
          ));
        });

        _showReplyStart(lastTurn);
        _scheduleDraftSave();
      }
    } on AIRequestCancelledException {
      // Cancellation is user-directed and does not need an error message.
    } catch (_) {
      if (mounted) {
        final language = context.read<UserProvider>().language;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                language,
                english:
                    'The reflection could not load. Your journal entry is still safe.',
                filipino:
                    'Hindi nag-load ang pagninilay. Ligtas pa rin ang iyong tala.',
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (identical(_aiCancellationToken, cancellationToken)) {
        _aiCancellationToken = null;
        if (mounted) {
          setState(() {
            _isGeneratingAi = false;
            _generatingTurn = null;
          });
        }
      }
    }
  }

  Future<void> _recordHelpfulFeedback(JournalTurn turn) async {
    setState(() {
      turn.feedback = AIReplyFeedback.helpful;
      turn.feedbackReason = null;
    });
    _scheduleDraftSave();
    await AIResponseFeedbackService.record(
      feedback: AIReplyFeedback.helpful,
      companionId: turn.companionId ?? 'kai',
      mode: turn.mode.name,
      wasOffline: turn.isOfflineReply,
    );
  }

  Future<void> _showNotHelpfulReasons(JournalTurn turn) async {
    final language = context.read<UserProvider>().language;
    final reason = await showModalBottomSheet<AIReplyFeedbackReason>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final reasons = <AIReplyFeedbackReason, (String, IconData)>{
          AIReplyFeedbackReason.tooGeneric: (
            _t(language,
                english: 'Too generic', filipino: 'Masyadong pangkalahatan'),
            Icons.blur_on_rounded,
          ),
          AIReplyFeedbackReason.wrongLanguage: (
            _t(language,
                english: 'Wrong language or tone',
                filipino: 'Maling wika o tono'),
            Icons.translate_rounded,
          ),
          AIReplyFeedbackReason.tooMuchAdvice: (
            _t(language,
                english: 'Too much advice',
                filipino: 'Masyadong maraming payo'),
            Icons.format_list_bulleted_rounded,
          ),
          AIReplyFeedbackReason.repetitive: (
            _t(language, english: 'Felt repetitive', filipino: 'Paulit-ulit'),
            Icons.repeat_rounded,
          ),
          AIReplyFeedbackReason.missedThePoint: (
            _t(language,
                english: 'Missed the point',
                filipino: 'Hindi nakuha ang punto'),
            Icons.track_changes_rounded,
          ),
        };
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _t(language,
                        english: 'What could be better?',
                        filipino: 'Ano ang puwedeng pagbutihin?'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(language,
                        english: 'No journal text is saved with this feedback.',
                        filipino:
                            'Walang journal text na sine-save kasama ng feedback na ito.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...reasons.entries.map(
                    (entry) => Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppColors.honeyGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(entry.value.$2,
                              size: 19, color: AppColors.honeyAmber),
                        ),
                        title: Text(entry.value.$1,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(sheetContext, entry.key),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (reason == null || !mounted) return;
    setState(() {
      turn.feedback = AIReplyFeedback.notHelpful;
      turn.feedbackReason = reason;
    });
    _scheduleDraftSave();
    await AIResponseFeedbackService.record(
      feedback: AIReplyFeedback.notHelpful,
      reason: reason,
      companionId: turn.companionId ?? 'kai',
      mode: turn.mode.name,
      wasOffline: turn.isOfflineReply,
    );
  }

  AIResponseAdjustment _adjustmentFor(AIReplyFeedbackReason reason) {
    return switch (reason) {
      AIReplyFeedbackReason.tooGeneric => AIResponseAdjustment.moreSpecific,
      AIReplyFeedbackReason.wrongLanguage => AIResponseAdjustment.matchLanguage,
      AIReplyFeedbackReason.tooMuchAdvice => AIResponseAdjustment.lessAdvice,
      AIReplyFeedbackReason.repetitive => AIResponseAdjustment.lessRepetitive,
      AIReplyFeedbackReason.missedThePoint =>
        AIResponseAdjustment.betterUnderstand,
    };
  }

  Future<void> _regenerateTurn(JournalTurn turn, int turnIndex) async {
    final reason = turn.feedbackReason;
    final text = turn.userController.text.trim();
    if (reason == null || text.isEmpty || _isGeneratingAi) return;

    // Unfocus active input so the keyboard does not obscure the loading progress
    FocusScope.of(context).unfocus();

    final cancellationToken = AIRequestCancellationToken();
    _aiCancellationToken?.cancel();
    _aiCancellationToken = cancellationToken;
    setState(() {
      _isGeneratingAi = true;
      _generatingTurn = turn;
    });
    _showReplyStart(turn);

    final user = context.read<UserProvider>();
    final companionId = turn.companionId ?? user.selectedCompanion;
    final wellbeing = _wellbeingContext();
    try {
      final reply = await AIService.generateCompanionReply(
        userText: text,
        companionId: companionId,
        language: user.language,
        mode: CompanionMode.auto,
        conversationHistory: _conversationHistoryBeforeTurn(turnIndex),
        cancellationToken: cancellationToken,
        adjustment: _adjustmentFor(reason),
        previousResponse: turn.aiResponse,
        wellbeingContext: wellbeing.promptBlock,
      );
      if (!mounted || cancellationToken.isCancelled) return;
      setState(() {
        turn.aiResponse = reply.text;
        turn.animateReply = reply.safetyLevel == 'none';
        turn.replyRevision++;
        turn.suggestedReplies = reply.suggestedReplies;
        turn.inferredNeed = reply.inferredNeed;
        turn.isOfflineReply = reply.isOffline;
        turn.feedback = null;
        turn.feedbackReason = null;
      });
      _showReplyStart(turn);
      _scheduleDraftSave();
    } on AIRequestCancelledException {
      // The user explicitly cancelled this request.
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(
              user.language,
              english: 'A different reflection could not load. Try again soon.',
              filipino:
                  'Hindi nag-load ang ibang pagninilay. Subukan muli mamaya.',
            )),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (identical(_aiCancellationToken, cancellationToken)) {
        _aiCancellationToken = null;
        if (mounted) {
          setState(() {
            _isGeneratingAi = false;
            _generatingTurn = null;
          });
        }
      }
    }
  }

  Widget _buildAiReplyBox(
    BuildContext context,
    MascotInfo mascot,
    JournalTurn turn,
    int turnIndex,
    bool isDark,
  ) {
    final reply = turn.aiResponse ?? '';
    final isOfflineReply = turn.isOfflineReply;
    final language = context.read<UserProvider>().language;
    final isCrisisReply = reply.contains('1553') ||
        reply.contains('Hotline') ||
        reply.contains('Crisis');

    final palette = context.kaibigan;
    final replyFontSize =
        15 * context.watch<UserProvider>().journalTextSize.scale;
    final nameColor = isDark
        ? palette.accentStrong
        : mascot.id == 'ann'
            ? AppColors.annDark
            : AppColors.kaiDark;
    // Replies sit between the writing sheets, so the paper remains for the
    // person's own words and the companion has a clearly separate voice.
    return JournalReplyReveal(
      key: ObjectKey(turn),
      text: reply,
      animate: turn.animateReply && !isCrisisReply,
      revision: turn.replyRevision,
      builder: (context, visibleReply, isRevealing, showFullReply) => Container(
        key: ValueKey('journal-ai-reply-$turnIndex'),
        margin: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                    mascot.primaryColor.withValues(alpha: isDark ? 0.1 : 0.07),
                    palette.surface),
                palette.surface
              ]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color:
                  mascot.primaryColor.withValues(alpha: isDark ? 0.28 : 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(mascot.name,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: nameColor)),
                        const SizedBox(height: 2),
                        Text(
                            isOfflineReply
                                ? _t(language,
                                    english: 'a quiet note',
                                    filipino: 'munting tala')
                                : _t(language,
                                    english: 'Your AI companion',
                                    filipino: 'Kasama mong AI'),
                            style: TextStyle(
                                fontSize: 11.5, color: palette.textSecondary)),
                      ])),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    color: isDark ? Colors.white54 : Colors.black45,
                    tooltip: _t(
                      language,
                      english: 'Copy reflection',
                      filipino: 'Kopyahin ang pagninilay',
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: reply));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _t(
                              language,
                              english: 'Reflection from ${mascot.name} copied.',
                              filipino:
                                  'Nakopya ang pagninilay mula kay ${mascot.name}.',
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Markdown Body
              MarkdownBody(
                data: visibleReply,
                selectable: !isRevealing,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: replyFontSize,
                    height: 1.65,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  em: GoogleFonts.lora(
                    fontStyle: FontStyle.italic,
                    fontSize: replyFontSize,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.honeyGold : AppColors.honeyAmber,
                    height: 1.5,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  blockquote: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: mascot.primaryColor, width: 3),
                    ),
                  ),
                  listBullet: TextStyle(
                    color: mascot.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (isRevealing)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: ValueKey('journal-show-full-reply-$turnIndex'),
                    onPressed: showFullReply,
                    child: Text(_t(language,
                        english: 'Show full reflection',
                        filipino: 'Ipakita ang buong pagninilay')),
                  ),
                ),
              if (!isCrisisReply && !isRevealing) ...[
                const SizedBox(height: 6),
                if (turn.feedback == null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                              width: 48, height: 48),
                          padding: const EdgeInsets.all(12),
                          tooltip: _t(language,
                              english: 'Helpful', filipino: 'Nakatulong'),
                          onPressed: () => _recordHelpfulFeedback(turn),
                          icon: Icon(Icons.thumb_up_alt_outlined,
                              size: 15,
                              color: isDark ? Colors.white38 : Colors.black38),
                        ),
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                              width: 48, height: 48),
                          padding: const EdgeInsets.all(12),
                          tooltip: _t(language,
                              english: 'Not helpful',
                              filipino: 'Hindi nakatulong'),
                          onPressed: () => _showNotHelpfulReasons(turn),
                          icon: Icon(Icons.thumb_down_alt_outlined,
                              size: 15,
                              color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      ],
                    ),
                  )
                else if (turn.feedback == AIReplyFeedback.helpful)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(Icons.check_circle_outline_rounded,
                          size: 17,
                          color: AppColors.sageGreen.withValues(alpha: 0.75)),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _isGeneratingAi
                          ? null
                          : () => _regenerateTurn(turn, turnIndex),
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: Text(_t(language,
                          english: 'Try another reflection',
                          filipino: 'Subukan ang ibang pagninilay')),
                    ),
                  ),
              ],

              // Crisis Hotlines Card
              if (isCrisisReply) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '24/7 Free Crisis Support (Philippines)',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final uri = Uri(scheme: 'tel', path: '911');
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emergency_rounded,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Emergency 911',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final uri = Uri(scheme: 'tel', path: '1553');
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sageGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Call NCMH 1553',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              final uri =
                                  Uri(scheme: 'tel', path: '09178001123');
                              if (await canLaunchUrl(uri)) await launchUrl(uri);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_in_talk,
                                    size: 14, color: Colors.redAccent),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'In Touch 0917-800-1123',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => AkbaySafetySheet.show(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.sageGreen,
                              side:
                                  const BorderSide(color: AppColors.sageGreen),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline,
                                    size: 14, color: AppColors.sageGreen),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'All Safety Lines',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _t(
                        language,
                        english: 'AI reflection · not medical advice',
                        filipino: 'Pagninilay ng AI · hindi medikal na payo',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isRevealing &&
                  _startersToShow(turn, turnIndex).isNotEmpty) ...[
                const SizedBox(height: 14),
                JournalReplyStarters(
                  starters: _startersToShow(turn, turnIndex),
                  isDark: isDark,
                  label: _t(
                    language,
                    english: 'IF IT HELPS TO START',
                    filipino: 'KUNG NAHIHIRAPANG MAGSIMULA',
                  ),
                  onSelected: _useStarter,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> _startersToShow(JournalTurn turn, int turnIndex) {
    return JournalReplyStarters.visibleStarters(
      turn.suggestedReplies,
      // The answering turn is the last one with a reply; a blank turn is
      // always appended after it.
      isAnsweringTurn: turnIndex == _turns.length - 2,
      activeTurnIsEmpty: _turns.last.userController.text.trim().isEmpty,
      isBusy: _isGeneratingAi || _isSaving,
    );
  }

  void _useStarter(String starter) {
    final active = _turns.last.userController;
    final existing = active.text.trim();
    final text = existing.isEmpty ? starter : '$existing $starter';
    active.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
    _activeFocusNode.requestFocus();
    _scheduleDraftSave();
  }

  Widget _buildThinkingIndicator(MascotInfo mascot, bool isDark) {
    final language = context.read<UserProvider>().language;
    return Container(
      key: const ValueKey('journal-thinking-indicator'),
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      decoration: BoxDecoration(
          color: context.kaibigan.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.kaibigan.border)),
      child: Row(
        children: [
          const SizedBox.square(
              dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t(
                language,
                english: '${mascot.name} is reflecting on what you wrote…',
                filipino: 'Pinagninilayan ni ${mascot.name} ang isinulat mo…',
              ),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _aiCancellationToken?.cancel(),
            child: Text(
              _t(
                language,
                english: 'Cancel',
                filipino: 'Kanselahin',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJournal() async {
    if (_isExportingPdf) return;
    final language = context.read<UserProvider>().language;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final content = _getAllUserContent();
    if (content.trim().isEmpty && _titleController.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(_t(language,
              english: 'Write something before exporting a PDF.',
              filipino: 'Sumulat muna bago mag-export ng PDF.'))));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isExportingPdf = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final saved = await PdfService.exportJournalPdf(
        title: _titleController.text.trim().isEmpty
            ? JournalEntry.warmUntitledTitle
            : _titleController.text.trim(),
        content: content,
        aiResponse: _getAllAiResponses(),
        createdAt: widget.targetEntry?.createdAt ?? DateTime.now(),
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(saved
              ? _t(language,
                  english: 'PDF saved.', filipino: 'Na-save ang PDF.')
              : _t(language,
                  english: 'PDF export canceled.',
                  filipino: 'Kinansela ang pag-export ng PDF.'))));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(_t(language,
            english: 'The PDF could not be saved. Please try again.',
            filipino: 'Hindi na-save ang PDF. Pakisubukang muli.')),
      ));
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _deleteCurrentEntry(String language) async {
    final target = widget.targetEntry;
    if (target == null) return;
    final provider = context.read<JournalProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await CozyConfirmSheet.show(
      context,
      title: _t(language,
          english: 'Delete this entry?', filipino: 'Burahin ang talang ito?'),
      message: _t(
        language,
        english:
            'This journal entry and its companion reflection will be removed permanently.',
        filipino:
            'Permanenteng aalisin ang tala at pagninilay ng companion nito.',
      ),
      confirmLabel: _t(language, english: 'Delete', filipino: 'Burahin'),
      cancelLabel: _t(language, english: 'Keep entry', filipino: 'Panatilihin'),
      icon: Icons.edit_note_rounded,
    );
    if (!confirmed) return;
    final deleted = await provider.deleteJournalEntry(target.id);
    if (!mounted) return;
    if (deleted) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(_t(language,
            english: 'Journal entry deleted.',
            filipino: 'Nabura na ang tala.')),
        behavior: SnackBarBehavior.floating,
      ));
    } else if (provider.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  String _draftCaption(String language) {
    if (_titleController.text.trim().isEmpty &&
        _getAllUserContent().trim().isEmpty) {
      return _t(language,
          english: 'No rush. Start anywhere.',
          filipino: 'Dahan-dahan lang. Simula saanman.');
    }
    if (widget.targetEntry != null) {
      return _t(language,
          english: 'Editing your entry', filipino: 'Inaayos ang iyong tala');
    }
    if (_draftUserId == null) {
      return _t(language,
          english: 'Save to keep this moment',
          filipino: 'I-save para maingatan');
    }
    return _draftSaved
        ? _t(language,
            english: 'Draft saved on this device',
            filipino: 'Naka-save ang burador sa device')
        : _t(language,
            english: 'Saving draft…', filipino: 'Sine-save ang burador…');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.kaibigan;
    final user = context.watch<UserProvider>();
    final language = user.language;
    final activeId = _activeCompanionId ?? user.selectedCompanion;
    final mascot = MascotInfo.getById(activeId);
    final paperMinHeight = (MediaQuery.sizeOf(context).height * 0.44)
        .clamp(300.0, 500.0)
        .toDouble();

    return Scaffold(
      key: const ValueKey('ai-journal-editor'),
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: _t(language, english: 'Back', filipino: 'Bumalik'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _isSaving ? null : () => _saveAndPop(),
        ),
        titleSpacing: 0,
        title: Text(_t(language, english: 'AI Journal', filipino: 'AI Journal'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            tooltip: _t(language,
                english: 'More journal actions', filipino: 'Iba pang aksyon'),
            icon: _isExportingPdf
                ? const SizedBox(
                    key: ValueKey('journal-export-progress'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.more_horiz_rounded),
            onSelected: (action) {
              if (action == 'export') _exportJournal();
              if (action == 'delete') _deleteCurrentEntry(language);
              if (action == 'appearance') {
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const JournalAppearanceScreen()));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'appearance',
                  child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.palette_outlined),
                      title: Text(_t(language,
                          english: 'Paper & text style',
                          filipino: 'Papel at estilo ng teksto')))),
              PopupMenuItem(
                  value: 'export',
                  enabled: !_isExportingPdf,
                  child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(_t(language,
                          english: 'Export as PDF',
                          filipino: 'I-export bilang PDF')))),
              if (widget.targetEntry != null)
                PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded,
                            color: palette.danger),
                        title: Text(_t(language,
                            english: 'Delete entry',
                            filipino: 'Burahin ang tala')))),
            ],
          ),
          Tooltip(
            message: _t(language,
                english: 'Save journal', filipino: 'I-save ang talaarawan'),
            child: TextButton(
              key: const ValueKey('journal-save-button'),
              onPressed:
                  _isSaving ? null : () => _saveAndPop(showReflection: true),
              style: TextButton.styleFrom(
                  foregroundColor: palette.botanical,
                  minimumSize: const Size(54, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10)),
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_t(language, english: 'Save', filipino: 'I-save'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('journal-editor-scroll'),
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: MobileContent(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      MobileLayout.horizontalPadding(context),
                      4,
                      MobileLayout.horizontalPadding(context),
                      24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        JournalCompanionHeader(
                            mascot: mascot, language: language),
                        Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.today_outlined,
                                    size: 14, color: palette.textMuted),
                                const SizedBox(width: 6),
                                Flexible(
                                    child: Text(
                                        DateFormatter.formatFullDate(
                                            widget.targetEntry?.createdAt ??
                                                DateTime.now(),
                                            language: language),
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: palette.textSecondary))),
                              ]),
                              TextButton.icon(
                                key: const ValueKey('journal-prompt-toggle'),
                                onPressed: () => setState(() =>
                                    _showWritingPrompt = !_showWritingPrompt),
                                icon: Icon(
                                    _showWritingPrompt
                                        ? Icons.close_rounded
                                        : Icons.lightbulb_outline_rounded,
                                    size: 16),
                                label: Text(_showWritingPrompt
                                    ? _t(language,
                                        english: 'Hide prompt',
                                        filipino: 'Itago ang gabay')
                                    : _t(language,
                                        english: 'Need a starting point?',
                                        filipino: 'Kailangan ng panimula?')),
                                style: TextButton.styleFrom(
                                    foregroundColor: palette.accentStrong,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    textStyle: GoogleFonts.quicksand(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ]),
                        const SizedBox(height: 12),
                        JournalAnimatedSize(
                            child: _showWritingPrompt
                                ? JournalPromptCard(
                                    text:
                                        _guidingPrompts(language)[_promptIndex],
                                    onShuffle: _shufflePrompt,
                                    shuffleLabel: _t(language,
                                        english: 'Another prompt',
                                        filipino: 'Ibang gabay'))
                                : const SizedBox.shrink()),
                        for (var index = 0; index < _turns.length; index++) ...[
                          if (index > 0) ...[
                            Padding(
                                padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                                child: Text(
                                    _t(language,
                                        english: 'YOUR NEXT THOUGHT',
                                        filipino: 'ANG SUSUNOD MONG KAISIPAN'),
                                    style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w800,
                                        color: palette.textMuted))),
                          ],
                          _buildWritingPaper(
                              index, user, activeId, paperMinHeight),
                          if (_turns[index].aiResponse != null ||
                              identical(_turns[index], _generatingTurn))
                            KeyedSubtree(
                              key: _turns[index].replyAnchor,
                              child: Column(children: [
                                if (_turns[index].aiResponse != null)
                                  _buildAiReplyBox(
                                      context,
                                      MascotInfo.getById(
                                          _turns[index].companionId ??
                                              activeId),
                                      _turns[index],
                                      index,
                                      isDark),
                                if (identical(_turns[index], _generatingTurn))
                                  _buildThinkingIndicator(mascot, isDark),
                              ]),
                            ),
                        ],
                        const SizedBox(height: 12),
                        ListenableBuilder(
                          listenable: _writingChanges,
                          builder: (context, _) {
                            final content = _getAllUserContent().trim();
                            final words = content.isEmpty
                                ? 0
                                : content.split(RegExp(r'\s+')).length;
                            return Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  Text(_draftCaption(language),
                                      key: const ValueKey(
                                          'journal-draft-status'),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: palette.textSecondary)),
                                  Text(
                                      words == 0
                                          ? _t(language,
                                              english: 'A fresh page',
                                              filipino: 'Bagong pahina')
                                          : _t(language,
                                              english:
                                                  '$words ${words == 1 ? 'word' : 'words'}',
                                              filipino: '$words salita'),
                                      key: const ValueKey('journal-word-count'),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: palette.textMuted)),
                                ]);
                          },
                        ),
                        SizedBox(height: _readingSpace),
                      ]),
                ),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _writingChanges,
            builder: (_, __) => _buildEditorFooter(user, mascot),
          ),
        ]),
      ),
    );
  }

  Widget _buildWritingPaper(
      int index, UserProvider user, String activeId, double minHeight) {
    final palette = context.kaibigan;
    final turn = _turns[index];
    final first = index == 0;
    final active = index == _turns.length - 1 && turn.aiResponse == null;
    final textSize = user.journalTextSize;
    final fontSize = 16.5 * textSize.scale;
    final textScaler = MediaQuery.textScalerOf(context);
    final lineHeight =
        textScaler.scale(fontSize) * textSize.lineHeight / fontSize;
    final newlineCount = '\n'.allMatches(_titleController.text).length;
    final estimatedWrapLines =
        (_titleController.text.length / 25).ceil().clamp(1, 4);
    final titleLineCount = math.max(newlineCount + 1, estimatedWrapLines);
    final titleHeight = textScaler.scale(21) * 1.4 * titleLineCount;
    final turnMascot = MascotInfo.getById(turn.companionId ?? activeId);
    return JournalPaperSurface(
      key: first
          ? const ValueKey('ai-journal-paper')
          : ValueKey('journal-writing-paper-$index'),
      style: user.journalPaperStyle,
      accentColor: user.journalAccent.color,
      showBinding: first,
      minHeight: active ? minHeight : null,
      lineHeight: lineHeight,
      firstLineOffset: 22 + (first ? titleHeight + 18 : 0) + lineHeight - 3,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (first) ...[
          TextField(
            key: const ValueKey('journal-title-field'),
            controller: _titleController,
            focusNode: _titleFocusNode,
            readOnly: _isSaving,
            minLines: 1,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              if (_turns.isNotEmpty) {
                _turns.first.focusNode.requestFocus();
              }
            },
            style: GoogleFonts.lora(
                fontSize: 21,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary),
            strutStyle: const StrutStyle(
                fontSize: 21, height: 1.4, forceStrutHeight: true),
            decoration: InputDecoration(
                isCollapsed: true,
                hintText: _t(user.language,
                    english: 'Name this moment (optional)',
                    filipino: 'Bigyan ng pamagat (opsyonal)'),
                hintStyle: GoogleFonts.lora(
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero),
          ),
          const SizedBox(height: 18),
        ],
        TextField(
          key: active
              ? const ValueKey('active-journal-writing-field')
              : ValueKey('journal-writing-field-$index'),
          controller: turn.userController,
          focusNode: turn.focusNode,
          readOnly: _isSaving || _isGeneratingAi,
          minLines: active ? 7 : 2,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          scrollPadding: const EdgeInsets.only(bottom: 28),
          style: GoogleFonts.lora(
              fontSize: fontSize,
              height: textSize.lineHeight / fontSize,
              color: palette.textPrimary),
          strutStyle: StrutStyle(
              fontSize: fontSize,
              height: textSize.lineHeight / fontSize,
              forceStrutHeight: true),
          decoration: InputDecoration(
              isCollapsed: true,
              hintText: first
                  ? _t(user.language,
                      english: 'What has been sitting with you?',
                      filipino: 'Ano ang nasa isip mo?')
                  : _t(user.language,
                      english: 'Continue with ${turnMascot.name}…',
                      filipino: 'Magpatuloy kasama si ${turnMascot.name}…'),
              hintStyle: GoogleFonts.lora(
                  fontSize: fontSize,
                  height: textSize.lineHeight / fontSize,
                  color: palette.textMuted),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              filled: false,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero),
        ),
        if (active)
          const SizedBox(
              key: ValueKey('journal-paper-breathing-room'), height: 32),
      ]),
    );
  }

  Widget _buildEditorFooter(UserProvider user, MascotInfo mascot) {
    final palette = context.kaibigan;
    final accent = user.journalAccent.color;
    final target = _titleFocusNode.hasFocus
        ? null
        : (_formattingTurn ?? _turns.last).userController;
    final canShare = !_isGeneratingAi &&
        !_isSaving &&
        _turns.last.userController.text.trim().isNotEmpty;
    return Material(
      key: const ValueKey('journal-editor-controls'),
      color: palette.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.border))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          JournalAnimatedSize(
            child: _showFormatting
                ? JournalFormatToolbar(
                    controller: target,
                    textSize: user.journalTextSize,
                    enabled: !_isGeneratingAi && !_isSaving,
                    onTextSizeChanged: user.setJournalTextSize)
                : const SizedBox.shrink(),
          ),
          MobileContent(
              child: Padding(
            padding: EdgeInsets.fromLTRB(
                MobileLayout.horizontalPadding(context),
                8,
                MobileLayout.horizontalPadding(context),
                8),
            child: Row(children: [
              TextFieldTapRegion(
                  child: IconButton(
                key: const ValueKey('journal-toggle-formatting'),
                tooltip: _t(user.language,
                    english: 'Formatting', filipino: 'Pag-format'),
                isSelected: _showFormatting,
                icon: const Icon(Icons.text_format_rounded, size: 24),
                selectedIcon: Icon(Icons.text_format_rounded,
                    size: 24, color: palette.accentStrong),
                style: IconButton.styleFrom(
                    backgroundColor: _showFormatting
                        ? palette.accentSubtle
                        : palette.surfaceSubtle,
                    minimumSize: const Size(48, 48)),
                onPressed: () =>
                    setState(() => _showFormatting = !_showFormatting),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton.icon(
                key: const ValueKey('journal-share-button'),
                onPressed: canShare ? _triggerAiReflection : null,
                icon: _isGeneratingAi
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(
                        _turns.length > 1
                            ? Icons.send_rounded
                            : Icons.auto_awesome_outlined,
                        size: 18),
                label: Text(
                    _isGeneratingAi
                        ? _t(user.language,
                            english: '${mascot.name} is replying…',
                            filipino: 'Sumasagot si ${mascot.name}…')
                        : _turns.length > 1
                            ? _t(user.language,
                                english: 'Send', filipino: 'Ipadala')
                            : _t(user.language,
                                english: 'Share with ${mascot.name}',
                                filipino: 'Ibahagi kay ${mascot.name}'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.readableOn(accent),
                    disabledBackgroundColor: _isGeneratingAi
                        ? palette.accentSubtle
                        : palette.surfaceSubtle,
                    disabledForegroundColor: palette.textSecondary,
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              )),
            ]),
          )),
        ]),
      ),
    );
  }

  Future<void> _saveAndPop({bool showReflection = false}) async {
    _aiCancellationToken?.cancel();
    final title = _titleController.text.trim();
    final content = _getAllUserContent();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final userProvider = context.read<UserProvider>();
    final activeCompanion =
        _activeCompanionId ?? userProvider.selectedCompanion;
    final warmTitle = _t(
      userProvider.language,
      english: JournalEntry.warmUntitledTitle,
      filipino: 'Isang sandali sa iyong buhay',
    );
    final resolvedTitle = title.isEmpty ? warmTitle : title;
    final target = widget.targetEntry;
    final contentChanged = target == null ||
        content.trim() != target.content.trim() ||
        !_conversationMatches(target);
    final hasChanges = target == null ||
        resolvedTitle != target.title.trim() ||
        contentChanged ||
        activeCompanion != target.companionId;

    // Opening an existing record and tapping save is a no-op. In particular,
    // it must not trigger a fresh AI recap for words that did not change.
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<JournalProvider>();
    final conversationTurns = _getConversationTurns();

    JournalEntry? savedEntry;
    try {
      if (target != null) {
        final updated = target.copyWith(
          title: resolvedTitle,
          content: content,
          aiResponse: _getAllAiResponses(),
          companionId: activeCompanion,
          mood: '',
          reflectionMode: CompanionMode.auto.name,
          conversationTurns: conversationTurns,
          clearSummary: contentChanged,
        );
        final saved = await provider.updateJournalEntry(updated);
        if (saved) savedEntry = updated;
      } else {
        savedEntry = await provider.addJournalEntry(
          title: resolvedTitle,
          content: content,
          aiResponse: _getAllAiResponses(),
          companionId: activeCompanion,
          mood: '',
          reflectionMode: CompanionMode.auto.name,
          conversationTurns: conversationTurns,
        );
      }
    } catch (_) {
      // The provider's user-facing error below remains the single save error.
    }

    if (!mounted) return;
    if (savedEntry == null || provider.errorMessage != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ??
              _t(userProvider.language,
                  english: 'Your journal could not be saved yet.',
                  filipino: 'Hindi pa na-save ang iyong journal.')),
        ),
      );
      return;
    }

    final userId = _draftUserId;
    if (userId != null) await JournalDraftService.clear(userId);
    if (!mounted) return;
    if (showReflection && content.isNotEmpty && contentChanged) {
      // Snapshotted before navigation so the look-back compares this entry
      // with the ones that existed before it.
      final earlier = provider.allEntries
          .where((item) => item.id != savedEntry!.id)
          .toList(growable: false);
      final wellbeing = _wellbeingContext();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => JournalSaveReflectionScreen(
            entry: savedEntry!,
            language: userProvider.language,
            companionId: activeCompanion,
            previousEntries: earlier,
            wellbeingContext: wellbeing.promptBlock,
            // Kept with the record so reopening it later shows the same cards
            // rather than the conversation alone.
            onSummaryReady: (summary) => provider.saveSummary(
                savedEntry!.id, summary,
                expectedContent: savedEntry.content),
          ),
        ),
      );
      return;
    }
    Navigator.pop(context);
  }
}
