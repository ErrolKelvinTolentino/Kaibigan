import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ai_service.dart';
import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../../../core/widgets/mobile_layout.dart';
import '../../settings/user_provider.dart';
import '../learning_progress_store.dart';
import 'friend_support_practice_model.dart';
import 'friend_support_practice_service.dart';
import 'friend_support_safety_sheet.dart';

enum _PracticeMessageType { friend, user, system }

/// One line in the practice transcript.
class _PracticeMessage {
  _PracticeMessage.friend(this.text)
      : type = _PracticeMessageType.friend,
        feedback = null;

  _PracticeMessage.user(this.text)
      : type = _PracticeMessageType.user,
        feedback = null;

  _PracticeMessage.system(this.text)
      : type = _PracticeMessageType.system,
        feedback = null;

  final String text;
  final _PracticeMessageType type;

  bool get isFriend => type == _PracticeMessageType.friend;
  bool get isUser => type == _PracticeMessageType.user;
  bool get isSystem => type == _PracticeMessageType.system;

  /// Attached once the reply has been graded.
  PracticeTurnResult? feedback;
}

/// A rehearsal space: the app plays a friend who is struggling, the user
/// answers in the chat box, and every reply comes back with feedback.
class FriendSupportPracticeScreen extends StatefulWidget {
  const FriendSupportPracticeScreen({
    super.key,
    required this.scenario,
    this.service = const FriendSupportPracticeService(),
  });

  final PracticeScenario scenario;

  /// Swapped in tests so no network call is made.
  final FriendSupportPracticeService service;

  @override
  State<FriendSupportPracticeScreen> createState() =>
      _FriendSupportPracticeScreenState();
}

class _FriendSupportPracticeScreenState
    extends State<FriendSupportPracticeScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final List<_PracticeMessage> _messages = [];
  final List<AIConversationMessage> _history = [];

  bool _started = false;
  bool _sending = false;
  bool _finished = false;
  int _repliesSent = 0;
  int _strongReplies = 0;
  String? _errorMessage;
  final _progressStore = LearningProgressStore();
  final _cancellation = AIRequestCancellationToken();

  String get _language => context.read<UserProvider>().language;

  String _copy({required String english, required String filipino}) =>
      LanguageHelper.pick(_language, english: english, filipino: filipino);

  @override
  void dispose() {
    _cancellation.cancel();
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    final opener = widget.scenario.opener.resolve(_language);
    setState(() {
      _started = true;
      _errorMessage = null;
      _messages.add(_PracticeMessage.friend(opener));
      _history.add(AIConversationMessage.assistant(opener));
    });
    _focus.requestFocus();
  }

  void _resetPractice() {
    setState(() {
      _messages.clear();
      _history.clear();
      _repliesSent = 0;
      _strongReplies = 0;
      _finished = false;
      _started = false;
      _sending = false;
      _errorMessage = null;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _finished) return;

    setState(() {
      _sending = true;
      _errorMessage = null;
      _messages.add(_PracticeMessage.user(text));
      _controller.clear();
    });
    _scrollToEnd();

    PracticeTurnResult result;
    try {
      result = await widget.service.respond(
        scenario: widget.scenario,
        userReply: text,
        history: List<AIConversationMessage>.of(_history),
        language: _language,
        cancellationToken: _cancellation,
      );
    } on AIRequestCancelledException {
      return;
    } catch (_) {
      try {
        result = LocalPracticeCoach.evaluate(
          scenario: widget.scenario,
          userReply: text,
          language: _language,
          turnIndex: _repliesSent,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _errorMessage = _copy(
            english: 'Could not send message. Please try again.',
            filipino: 'Hindi maipadala ang mensahe. Pakisubukang muli.',
          );
        });
        return;
      }
    }
    if (!mounted) return;

    setState(() {
      _sending = false;
      _repliesSent++;
      if (result.tone == PracticeFeedbackTone.strong) _strongReplies++;
      _messages.last.feedback = result;
      _history.add(AIConversationMessage.user(text));
      if (result.endsPractice) {
        _finished = true;
        _messages.add(_PracticeMessage.friend(result.friendReply));
        if (result.hasSafetyNotice) {
          _messages.add(_PracticeMessage.system(result.safetyNotice!));
        }
      } else {
        _messages.add(_PracticeMessage.friend(result.friendReply));
        _history.add(AIConversationMessage.assistant(result.friendReply));
        if (result.hasSafetyNotice) {
          _messages.add(_PracticeMessage.system(result.safetyNotice!));
        }
      }
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: KaibiganMotion.standard,
        curve: KaibiganMotion.enter,
      );
    });
  }

  Future<void> _finish() async {
    if (_sending || _finished || _repliesSent == 0) return;
    _focus.unfocus();
    setState(() => _finished = true);
    await _progressStore.savePracticeResult(
      lessonId: widget.scenario.lessonId,
      scenarioId: widget.scenario.id,
      replies: _repliesSent,
      supportiveReplies: _strongReplies,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          _copy(
            english: 'Practice replying',
            filipino: 'Praktis sa pagsagot',
          ),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            key: const ValueKey('practice-need-help'),
            onPressed: () => FriendSupportSafetySheet.show(
              context,
              language: _language,
            ),
            icon: Icon(
              Icons.health_and_safety_outlined,
              color: palette.danger,
              size: 18,
            ),
            label: Text(
              _copy(english: 'Need Help?', filipino: 'Tulong?'),
              style: TextStyle(
                color: palette.danger,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _PracticeErrorBoundary(
          language: _language,
          onReset: _resetPractice,
          child: !_started
              ? _briefing(palette)
              : Column(
                  children: [
                    Expanded(child: _transcript(palette)),
                    if (_finished) _summaryBar(palette) else _composer(palette),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _briefing(KaibiganPalette palette) {
    final text = Theme.of(context).textTheme;
    final scenario = widget.scenario;
    return MobileContent(
      child: SingleChildScrollView(
        key: const ValueKey('practice-briefing'),
        padding: MobileLayout.pageInsets(context, top: 14, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KaibiganSurface(
              tone: KaibiganSurfaceTone.elevated,
              padding: const EdgeInsets.all(20),
              showShadow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: palette.accentSubtle,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.forum_rounded,
                          color: palette.accentStrong,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _copy(
                                english:
                                    '${scenario.friendName} needs a friend',
                                filipino:
                                    'May kailangang kaibigan si ${scenario.friendName}',
                              ),
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _copy(
                                english: 'A practice conversation',
                                filipino: 'Isang praktis na usapan',
                              ),
                              style: text.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    scenario.situation.resolve(_language),
                    style: text.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _copy(
                      english: 'WHAT TO PRACTISE',
                      filipino: 'ANO ANG PAPRAKTISIN',
                    ),
                    style: text.labelSmall?.copyWith(
                      color: palette.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...scenario.skillFocus.map(
                    (focus) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: palette.botanical,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              focus.resolve(_language),
                              style: text.bodySmall?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            KaibiganSurface(
              tone: KaibiganSurfaceTone.botanical,
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: palette.botanical,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scenario.isSensitive
                          ? _copy(
                              english:
                                  '${scenario.friendName} is written by the '
                                  'app, not a real person. This scenario '
                                  'touches on hopelessness so you can practise '
                                  'asking directly. If any of it is close to '
                                  'home, the Need Help button is at the top.',
                              filipino:
                                  'Ginawa ng app si ${scenario.friendName}, '
                                  'hindi tunay na tao. Tungkol ito sa kawalan '
                                  'ng pag-asa para mapraktis ang diretsong '
                                  'pagtatanong. Kung malapit ito sa '
                                  'karanasan mo, nasa itaas ang Tulong.',
                            )
                          : _copy(
                              english:
                                  '${scenario.friendName} is written by the '
                                  'app, not a real person. Reply the way you '
                                  'actually would — the feedback is more '
                                  'useful that way.',
                              filipino:
                                  'Ginawa ng app si ${scenario.friendName}, '
                                  'hindi tunay na tao. Sumagot ka kung paano '
                                  'ka talaga sasagot — mas magiging kapaki-'
                                  'pakinabang ang feedback.',
                            ),
                      style: text.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const ValueKey('start-practice-button'),
              onPressed: _start,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                _copy(
                  english: 'Start the conversation',
                  filipino: 'Simulan ang usapan',
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transcript(KaibiganPalette palette) {
    return MobileContent(
      child: ListView.builder(
        key: const ValueKey('practice-transcript'),
        controller: _scroll,
        padding: MobileLayout.pageInsets(context, top: 14, bottom: 16),
        itemCount: _messages.length + (_sending ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _messages.length) {
            return _TypingRow(
              name: widget.scenario.friendName,
              palette: palette,
            );
          }
          final message = _messages[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Bubble(
                message: message,
                friendName: widget.scenario.friendName,
                palette: palette,
                language: _language,
              ),
              if (message.feedback != null) ...[
                const SizedBox(height: 8),
                _FeedbackCard(
                  result: message.feedback!,
                  palette: palette,
                  language: _language,
                ),
              ],
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _composer(KaibiganPalette palette) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: palette.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.danger,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    color: palette.danger,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('practice-reply-field'),
                  controller: _controller,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: FriendSupportPracticeService.maxReplyCharacters,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: _copy(
                      english: 'Reply to ${widget.scenario.friendName}…',
                      filipino: 'Sagutin si ${widget.scenario.friendName}…',
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: palette.surfaceSubtle,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: palette.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.filled(
                key: const ValueKey('practice-send-button'),
                onPressed:
                    _controller.text.trim().isEmpty || _sending ? null : _send,
                icon: const Icon(Icons.send_rounded, size: 19),
                style: IconButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
          if (_repliesSent >= 2)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('practice-finish-button'),
                onPressed: _sending ? null : _finish,
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: Text(
                  _copy(
                    english: 'End practice and see how it went',
                    filipino: 'Tapusin at tingnan ang naging takbo',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryBar(KaibiganPalette palette) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('practice-summary'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _copy(
              english: '$_strongReplies of $_repliesSent replies landed well',
              filipino:
                  '$_strongReplies sa $_repliesSent sagot ang maganda ang dating',
            ),
            style: text.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _copy(
              english:
                  'Practice is where this is supposed to feel awkward. The '
                  'phrases get easier to reach for once you have typed them.',
              filipino:
                  'Sa praktis dapat maramdaman ang pagka-awkward. Mas madaling '
                  'maalala ang mga salita kapag na-type mo na ang mga ito.',
            ),
            style: text.bodySmall?.copyWith(
              color: palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('practice-restart-button'),
                  onPressed: _resetPractice,
                  child: Text(
                    _copy(english: 'Try again', filipino: 'Ulitin'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _copy(english: 'Done', filipino: 'Tapos na'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.friendName,
    required this.palette,
    required this.language,
  });

  final _PracticeMessage message;
  final String friendName;
  final KaibiganPalette palette;
  final String language;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _SystemSafetyCard(
        text: message.text,
        palette: palette,
        language: language,
      );
    }
    final text = Theme.of(context).textTheme;
    final isFriend = message.isFriend;
    return Align(
      alignment: isFriend ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
        decoration: BoxDecoration(
          color: isFriend ? palette.surfaceElevated : palette.accentSubtle,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isFriend ? 4 : 18),
            bottomRight: Radius.circular(isFriend ? 18 : 4),
          ),
          border: Border.all(
            color: isFriend
                ? palette.border
                : palette.accent.withValues(
                    alpha: 0.34,
                  ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFriend ? friendName : 'You',
              style: text.labelSmall?.copyWith(
                color: isFriend ? palette.textMuted : palette.accentStrong,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            MarkdownBody(
              data: message.text,
              selectable: true,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: text.bodyMedium?.copyWith(
                  height: 1.45,
                  color: palette.textPrimary,
                ),
                strong: text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
                em: text.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: palette.textPrimary,
                ),
                listBullet: text.bodyMedium?.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow({required this.name, required this.palette});

  final String name;
  final KaibiganPalette palette;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.accent,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              '$name is typing…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.result,
    required this.palette,
    required this.language,
  });

  final PracticeTurnResult result;
  final KaibiganPalette palette;
  final String language;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (colour, icon) = switch (result.tone) {
      PracticeFeedbackTone.strong => (
          palette.botanical,
          Icons.check_circle_rounded
        ),
      PracticeFeedbackTone.mixed => (palette.accent, Icons.lightbulb_rounded),
      PracticeFeedbackTone.offTrack => (palette.warning, Icons.info_rounded),
      PracticeFeedbackTone.unsafe => (
          palette.danger,
          Icons.health_and_safety_rounded
        ),
    };

    return Container(
      key: const ValueKey('practice-feedback-card'),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colour.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: colour),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.headline,
                  style: text.labelLarge?.copyWith(color: colour),
                ),
              ),
              if (result.isOffline)
                Text(
                  LanguageHelper.pick(
                    language,
                    english: 'offline',
                    filipino: 'offline',
                  ),
                  style: text.labelSmall?.copyWith(color: palette.textMuted),
                ),
            ],
          ),
          ...result.points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    point.isStrength
                        ? Icons.add_circle_outline_rounded
                        : Icons.change_circle_outlined,
                    size: 15,
                    color: point.isStrength
                        ? palette.botanical
                        : palette.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(point.label, style: text.labelMedium),
                        const SizedBox(height: 2),
                        MarkdownBody(
                          data: point.detail,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: text.bodySmall?.copyWith(
                              color: palette.textSecondary,
                              height: 1.4,
                            ),
                            strong: text.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                            em: text.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: palette.textSecondary,
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
          if (result.hasModelPhrase) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageHelper.pick(
                      language,
                      english: 'YOU COULD HAVE SAID',
                      filipino: 'PWEDE MO SANANG SABIHIN',
                    ),
                    style: text.labelSmall?.copyWith(
                      color: palette.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  MarkdownBody(
                    data: '“${result.modelPhrase}”',
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: text.bodySmall?.copyWith(
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: palette.textPrimary,
                      ),
                      strong: text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SystemSafetyCard extends StatelessWidget {
  const _SystemSafetyCard({
    required this.text,
    required this.palette,
    required this.language,
  });

  final String text;
  final KaibiganPalette palette;
  final String language;

  @override
  Widget build(BuildContext context) {
    final themeText = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: palette.danger, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageHelper.pick(
                    language,
                    english: 'Crisis Support & Safety',
                    filipino: 'Suporta at Kaligtasan sa Krisis',
                  ),
                  style: themeText.labelLarge?.copyWith(
                    color: palette.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MarkdownBody(
            data: text,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: themeText.bodySmall?.copyWith(
                height: 1.5,
                color: palette.textPrimary,
              ),
              strong: themeText.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.danger,
              ),
              listBullet: themeText.bodySmall?.copyWith(
                color: palette.danger,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => FriendSupportSafetySheet.show(
                context,
                language: language,
              ),
              icon: Icon(Icons.phone_in_talk_rounded, size: 16, color: palette.danger),
              label: Text(
                LanguageHelper.pick(
                  language,
                  english: 'View Crisis Helplines',
                  filipino: 'Tingnan ang mga Hotline',
                ),
                style: TextStyle(color: palette.danger, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: palette.danger.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeErrorBoundary extends StatefulWidget {
  const _PracticeErrorBoundary({
    required this.child,
    required this.language,
    required this.onReset,
  });

  final Widget child;
  final String language;
  final VoidCallback onReset;

  @override
  State<_PracticeErrorBoundary> createState() => _PracticeErrorBoundaryState();
}

class _PracticeErrorBoundaryState extends State<_PracticeErrorBoundary> {
  ErrorWidgetBuilder? _previousBuilder;

  @override
  void initState() {
    super.initState();
    _previousBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (details) => _PracticeErrorWidget(
          errorDetails: details,
          language: widget.language,
          onReset: widget.onReset,
        );
  }

  @override
  void dispose() {
    if (_previousBuilder != null) {
      ErrorWidget.builder = _previousBuilder!;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _PracticeErrorWidget extends StatelessWidget {
  const _PracticeErrorWidget({
    required this.errorDetails,
    required this.language,
    required this.onReset,
  });

  final FlutterErrorDetails errorDetails;
  final String language;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: KaibiganSurface(
          tone: KaibiganSurfaceTone.elevated,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 44, color: palette.danger),
              const SizedBox(height: 14),
              Text(
                LanguageHelper.pick(
                  language,
                  english: 'Something went wrong displaying this practice',
                  filipino: 'May nagkaproblema sa pagpapakita ng praktis na ito',
                ),
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                LanguageHelper.pick(
                  language,
                  english: 'An unexpected issue occurred. You can restart or head back safely.',
                  filipino: 'Nagkaroon ng problema. Maaari kang mag-restart o bumalik nang ligtas.',
                ),
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(LanguageHelper.pick(
                      language,
                      english: 'Go back',
                      filipino: 'Bumalik',
                    )),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(LanguageHelper.pick(
                      language,
                      english: 'Restart',
                      filipino: 'Ulitin',
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
