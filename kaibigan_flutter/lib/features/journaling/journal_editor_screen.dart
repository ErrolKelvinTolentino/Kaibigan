import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/journal_appearance.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/language_helper.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/ai_memory_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/ai_response_feedback_service.dart';
import '../../core/services/journal_draft_service.dart';
import '../../core/services/supabase_service.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';
import '../comfort_corner/akbay_safety_sheet.dart';
import '../comfort_corner/comfort_corner_screen.dart';
import '../insights/wellbeing_context.dart';
import '../mood_tracking/mood_provider.dart';
import '../routines/routines_provider.dart';
import '../mood_tracking/mood_tracker_screen.dart';
import '../routines/screens/gratitude_planting_screen.dart';
import '../routines/screens/grounding_session_screen.dart';
import '../routines/screens/mindfulness_meditation_screen.dart';
import '../routines/screens/sleep_log_flow_screen.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../../core/widgets/journal_format_toolbar.dart';
import '../../core/widgets/journal_paper_surface.dart';
import 'journal_provider.dart';
import 'journal_reflection_insights.dart';
import 'journal_reply_starters.dart';
import 'journal_model.dart';
import 'journal_save_reflection_screen.dart';

class JournalTurn {
  final TextEditingController userController;
  String? aiResponse;
  List<String> suggestedReplies;
  String inferredNeed;
  bool isOfflineReply;
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
  }) : userController = TextEditingController(text: userText);

  void dispose() {
    userController.dispose();
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

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _activeFocusNode = FocusNode();

  final List<JournalTurn> _turns = [];
  bool _isGeneratingAi = false;
  bool _isSaving = false;
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
    _titleController.addListener(_scheduleDraftSave);
  }

  String? get _draftUserId => SupabaseService.isInitialized
      ? SupabaseService.client.auth.currentUser?.id
      : null;

  void _addTurn(JournalTurn turn) {
    turn.userController.addListener(_scheduleDraftSave);
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
    _aiCancellationToken?.cancel();
    _draftTimer?.cancel();
    _titleController.dispose();
    _scrollController.dispose();
    _activeFocusNode.dispose();
    for (var turn in _turns) {
      turn.dispose();
    }
    super.dispose();
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
    setState(() => _isGeneratingAi = true);

    // Scroll immediately so the thinking indicator is brought into view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });

    // Ensure indicator stays centered/visible after keyboard dismiss animation
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });

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
          lastTurn.aiResponse = aiReply.text;
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

        // Focus first, then scroll after the keyboard has changed the viewport.
        // Scrolling before that resize can leave the new paper area hidden in a
        // cramped strip below a longer AI response.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _activeFocusNode.requestFocus();
          Future.delayed(const Duration(milliseconds: 320), () {
            if (!mounted || !_scrollController.hasClients) return;
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
            );
          });
        });
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
        if (mounted) setState(() => _isGeneratingAi = false);
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
                          style: const TextStyle(fontWeight: FontWeight.w700)),
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
    setState(() => _isGeneratingAi = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });

    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });

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
        turn.suggestedReplies = reply.suggestedReplies;
        turn.inferredNeed = reply.inferredNeed;
        turn.isOfflineReply = reply.isOffline;
        turn.feedback = null;
        turn.feedbackReason = null;
      });
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
        if (mounted) setState(() => _isGeneratingAi = false);
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

    // A translucent wash rather than a solid card: the reply belongs to the
    // page, so the ruled paper stays visible underneath it. A solid white fill
    // here read as a box dropped into the middle of the notebook.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: mascot.primaryColor.withValues(alpha: isDark ? 0.15 : 0.07),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        border: Border.all(
          color: mascot.primaryColor.withValues(alpha: isDark ? 0.34 : 0.24),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 13, 14, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: mascot.primaryColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(mascot.materialIcon,
                            size: 16, color: mascot.primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          mascot.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: mascot.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          isOfflineReply
                              ? _t(
                                  language,
                                  english: 'a quiet note',
                                  filipino: 'munting tala',
                                )
                              : _t(
                                  language,
                                  english: 'with you',
                                  filipino: 'kasama mo',
                                ),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
              data: reply,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                em: GoogleFonts.lora(
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
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

            if (!isCrisisReply) ...[
              const SizedBox(height: 6),
              if (turn.feedback == null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints.tightFor(
                            width: 44, height: 44),
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
                            width: 44, height: 44),
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
                            final uri = Uri(scheme: 'tel', path: '09178001123');
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
                            side: const BorderSide(color: AppColors.sageGreen),
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
                      english:
                          '✦ AI response · for personal reflection, not medical advice',
                      filipino:
                          '✦ Tugon ng AI · para sa pagninilay, hindi medikal na payo',
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            if (_startersToShow(turn, turnIndex).isNotEmpty) ...[
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
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mascot.primaryColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final dot = Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: mascot.primaryColor,
                    shape: BoxShape.circle,
                  ),
                );
                if (MediaQuery.disableAnimationsOf(context)) return dot;
                return dot
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                      delay: Duration(milliseconds: index * 130),
                    )
                    .fade(
                      begin: 0.25,
                      end: 1,
                      duration: 520.ms,
                    )
                    .then()
                    .fade(
                      begin: 1,
                      end: 0.25,
                      duration: 520.ms,
                    );
              }),
            ),
          ),
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
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.04);
  }

  Future<void> _exportJournal() async {
    final content = _getAllUserContent();
    if (content.isEmpty) return;
    await PdfService.exportJournalPdf(
      title: _titleController.text.trim().isEmpty
          ? JournalEntry.warmUntitledTitle
          : _titleController.text.trim(),
      content: content,
      aiResponse: _getAllAiResponses(),
      createdAt: widget.initialEntry?.createdAt ?? DateTime.now(),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final language = userProvider.language;
    final activeId = _activeCompanionId ?? userProvider.selectedCompanion;
    final mascot = MascotInfo.getById(activeId);
    final journalAccent = userProvider.journalAccent.color;
    final textSize = userProvider.journalTextSize;
    // The writing font and the ruled lines are derived from one number so the
    // words sit on the rules instead of drifting between them.
    final bodyFontSize = 16.5 * textSize.scale;
    final ruleHeight = textSize.lineHeight;
    final journalPaperMinHeight = (MediaQuery.sizeOf(context).height * 0.58)
        .clamp(420.0, 620.0)
        .toDouble();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: _isSaving ? null : () => _saveAndPop(),
        ),
        title: Text(
          _t(language, english: 'Journal', filipino: 'Talaarawan'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            tooltip: _t(language,
                english: 'More journal actions', filipino: 'Iba pang aksyon'),
            onSelected: (action) {
              if (action == 'export') _exportJournal();
              if (action == 'delete') _deleteCurrentEntry(language);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined),
                    const SizedBox(width: 12),
                    Text(_t(language,
                        english: 'Export as PDF',
                        filipino: 'I-export bilang PDF')),
                  ],
                ),
              ),
              if (widget.targetEntry != null)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Text(_t(language,
                          english: 'Delete entry',
                          filipino: 'Burahin ang tala')),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded,
                    size: 24, color: AppColors.sageGreen),
            tooltip: _t(
              language,
              english: 'Save journal',
              filipino: 'I-save ang talaarawan',
            ),
            onPressed:
                _isSaving ? null : () => _saveAndPop(showReflection: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    mascot.primaryColor.withValues(alpha: 0.20),
                                    AppColors.darkCard,
                                  ]
                                : [
                                    mascot.lightBgColor,
                                    AppColors.honeyLight,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: mascot.primaryColor
                                .withValues(alpha: isDark ? 0.28 : 0.14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    mascot.primaryColor.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                mascot.materialIcon,
                                color: mascot.primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _t(
                                      language,
                                      english: 'Write it as it comes',
                                      filipino: 'Isulat nang malaya',
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _t(
                                      language,
                                      english:
                                          '${mascot.name} will follow your lead and respond in your language.',
                                      filipino:
                                          'Susundan ni ${mascot.name} ang tono at wikang ginagamit mo.',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.04),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          DateFormatter.formatFullDate(
                            widget.initialEntry?.createdAt ?? DateTime.now(),
                            language: language,
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => _showWritingPrompt = !_showWritingPrompt,
                          ),
                          icon: Icon(
                            _showWritingPrompt
                                ? Icons.close_rounded
                                : Icons.lightbulb_outline_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _showWritingPrompt
                                ? _t(
                                    language,
                                    english: 'Hide prompt',
                                    filipino: 'Itago ang gabay',
                                  )
                                : _t(
                                    language,
                                    english: 'Need a starting point?',
                                    filipino: 'Kailangan ng panimula?',
                                  ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: mascot.primaryColor,
                            textStyle: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: _showWritingPrompt
                          ? Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
                              decoration: BoxDecoration(
                                color: AppColors.honeyGold.withValues(
                                  alpha: isDark ? 0.12 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.honeyGold
                                      .withValues(alpha: 0.20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _guidingPrompts(language)[_promptIndex],
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: AppColors.honeyAmber,
                                      size: 19,
                                    ),
                                    tooltip: _t(
                                      language,
                                      english: 'Another prompt',
                                      filipino: 'Ibang gabay',
                                    ),
                                    onPressed: _shufflePrompt,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 180.ms)
                          : const SizedBox.shrink(),
                    ),
                    JournalPaperSurface(
                      key: const ValueKey('ai-journal-paper'),
                      style: userProvider.journalPaperStyle,
                      accentColor: journalAccent,
                      minHeight: journalPaperMinHeight,
                      lineHeight: ruleHeight,
                      // Clears the title field so the first rule lands under
                      // the first line of the entry itself.
                      firstLineOffset: 26 + 34 * textSize.scale + ruleHeight,
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            style: GoogleFonts.lora(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              hintText: _t(
                                language,
                                english: 'Name this moment (optional)',
                                filipino: 'Bigyan ng pamagat (opsyonal)',
                              ),
                              hintStyle: GoogleFonts.lora(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Conversation / Entry Turns List
                          ..._turns.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final turn = entry.value;
                            final isLastTurn = idx == _turns.length - 1;
                            final isActiveWritingTurn =
                                isLastTurn && turn.aiResponse == null;
                            final turnMascot = MascotInfo.getById(
                                turn.companionId ?? activeId);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  margin: EdgeInsets.only(
                                    top: idx == 0 ? 0 : 8,
                                    bottom: turn.aiResponse == null ? 12 : 0,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  decoration: const BoxDecoration(
                                      color: Colors.transparent),
                                  child: TextField(
                                    key: isActiveWritingTurn
                                        ? const ValueKey(
                                            'active-journal-writing-field')
                                        : null,
                                    controller: turn.userController,
                                    focusNode:
                                        isLastTurn ? _activeFocusNode : null,
                                    minLines: isActiveWritingTurn ? 7 : 2,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    onChanged: (_) => setState(() {}),
                                    style: GoogleFonts.lora(
                                      fontSize: bodyFontSize,
                                      height: ruleHeight / bodyFontSize,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: idx == 0
                                          ? _t(
                                              language,
                                              english:
                                                  'What has been sitting with you?',
                                              filipino: 'Ano ang nasa isip mo?',
                                            )
                                          : _t(
                                              language,
                                              english:
                                                  'Continue with ${turnMascot.name}…',
                                              filipino:
                                                  'Magpatuloy kasama si ${turnMascot.name}…',
                                            ),
                                      hintStyle: GoogleFonts.lora(
                                        fontSize: bodyFontSize - 1,
                                        height: ruleHeight / bodyFontSize,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26,
                                      ),
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      filled: false,
                                      fillColor: Colors.transparent,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8),
                                    ),
                                  ),
                                ),
                                if (turn.aiResponse != null)
                                  _buildAiReplyBox(
                                    context,
                                    turnMascot,
                                    turn,
                                    idx,
                                    isDark,
                                  ),
                              ],
                            ).animate().fadeIn(duration: 260.ms);
                          }),
                          const SizedBox(
                            key: ValueKey('journal-paper-breathing-room'),
                            height: 84,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.025),
                    if (_isGeneratingAi)
                      _buildThinkingIndicator(mascot, isDark),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
            JournalFormatToolbar(
              controller: _turns.isEmpty ? null : _turns.last.userController,
              textSize: textSize,
              enabled: !_isGeneratingAi && !_isSaving,
              onTextSizeChanged: userProvider.setJournalTextSize,
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Tooltip(
                    message: _draftSaved
                        ? _t(
                            language,
                            english: 'Draft saved',
                            filipino: 'Ligtas ang burador',
                          )
                        : _t(
                            language,
                            english: 'Saving draft…',
                            filipino: 'Sine-save ang burador…',
                          ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        _draftSaved
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_upload_outlined,
                        key: ValueKey(_draftSaved),
                        size: 18,
                        color: _draftSaved
                            ? AppColors.sageGreen
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: FilledButton.icon(
                        key: ValueKey(_isGeneratingAi),
                        onPressed: _isGeneratingAi || _isSaving
                            ? null
                            : _triggerAiReflection,
                        icon: _isGeneratingAi
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.readableOn(journalAccent),
                                  ),
                                ),
                              )
                            : Icon(
                                _turns.length > 1
                                    ? Icons.send_rounded
                                    : Icons.forum_outlined,
                                size: 16,
                              ),
                        label: Text(
                          _isGeneratingAi
                              ? _t(
                                  language,
                                  english: '${mascot.name} is replying…',
                                  filipino: 'Sumasagot si ${mascot.name}…',
                                )
                              : (_turns.length > 1
                                  ? _t(
                                      language,
                                      english: 'Send',
                                      filipino: 'Ipadala',
                                    )
                                  : _t(
                                      language,
                                      english: 'Share with ${mascot.name}',
                                      filipino: 'Ibahagi kay ${mascot.name}',
                                    )),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: journalAccent,
                          foregroundColor: AppColors.readableOn(journalAccent),
                          disabledBackgroundColor: _isGeneratingAi
                              ? journalAccent.withValues(alpha: 0.72)
                              : journalAccent.withValues(alpha: 0.28),
                          disabledForegroundColor: _isGeneratingAi
                              ? AppColors.readableOn(journalAccent)
                              : null,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            onFollowUp: _openFollowUp,
            wellbeingContext: wellbeing.promptBlock,
            // Kept with the record so reopening it later shows the same cards
            // rather than the conversation alone.
            onSummaryReady: (summary) => provider.updateJournalEntry(
              savedEntry!.copyWith(summary: summary),
            ),
          ),
        ),
      );
      return;
    }
    Navigator.pop(context);
  }

  /// Opens the practice a reflection card suggested.
  ///
  /// Pushed on top of the reflection page rather than replacing it, so
  /// declining the practice returns the person to their own words.
  void _openFollowUp(JournalFollowUpKind kind) {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => switch (kind) {
          JournalFollowUpKind.breathing => const MindfulnessMeditationScreen(),
          JournalFollowUpKind.grounding => const GroundingSessionScreen(),
          JournalFollowUpKind.gratitude => const GratitudePlantingScreen(),
          JournalFollowUpKind.moodCheckIn => const MoodTrackerScreen(),
          JournalFollowUpKind.sleepLog => const SleepLogFlowScreen(),
          JournalFollowUpKind.comfortCorner => const ComfortCornerScreen(),
        },
      ),
    );
  }
}
