import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_memory_service.dart';
import 'package:kaibigan_flutter/core/services/ai_response_feedback_service.dart';
import 'package:kaibigan_flutter/core/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AIResponseFeedbackService.resetCacheForTesting();
  });

  group('safety routing', () {
    test('a first-person statement is still a personal crisis', () {
      for (final text in const [
        'i want to die',
        'gusto ko nang mamatay',
        'I have been thinking about suicide all week',
        'i want to kill myself tonight',
      ]) {
        expect(
          AIService.assessSafety(text),
          SafetyConcern.self,
          reason: '"$text" must reach the personal crisis response',
        );
      }
    });

    test('worry about another person gets help-a-friend guidance', () {
      for (final text in const [
        'my friend said she wants to die and I do not know what to do',
        'my brother has been talking about suicide',
        'someone I know keeps saying they want to end it all',
        'ang kaibigan ko gusto na raw magpakamatay',
      ]) {
        expect(
          AIService.assessSafety(text),
          SafetyConcern.someoneElse,
          reason: '"$text" is about someone else',
        );
      }
    });

    test('a personal statement outranks a mention of someone else', () {
      expect(
        AIService.assessSafety(
          'my friend is going through a lot but honestly i want to die too',
        ),
        SafetyConcern.self,
      );
    });

    test('the help-a-friend response still leads with the hotlines', () {
      for (final language in const ['english', 'filipino', 'taglish']) {
        final text =
            AIService.getSupportingSomeoneCrisisResponse('kai', language);
        expect(text, contains('1553'));
        expect(text, contains('911'));
        // It has to tell them the one thing that actually helps, in whichever
        // language they are reading.
        expect(
          text.toLowerCase(),
          anyOf(contains('directly'), contains('diretso')),
          reason: 'every language must carry the ask-directly guidance',
        );
      }
    });

    test('a clearly negated phrase is not treated as a crisis', () {
      expect(AIService.isCrisisMessage("i don't want to die"), isFalse);
      expect(
        AIService.isCrisisMessage('I no longer want to kill myself'),
        isFalse,
      );
      // The unnegated forms must still trigger.
      expect(AIService.isCrisisMessage('i want to die'), isTrue);
      expect(AIService.isCrisisMessage('i want to kill myself'), isTrue);
    });

    test('educational mentions remain out of scope', () {
      expect(
        AIService.isCrisisMessage('what is suicide prevention awareness'),
        isFalse,
      );
    });
  });

  group('transient failure handling', () {
    test('only genuinely retryable statuses are retried', () {
      for (final status in const [408, 409, 425, 429, 500, 502, 503, 504]) {
        expect(AIService.isRetryableStatus(status), isTrue, reason: '$status');
      }
      for (final status in const [400, 401, 403, 404, 422]) {
        expect(AIService.isRetryableStatus(status), isFalse, reason: '$status');
      }
    });

    test('backoff grows, and honours a sane Retry-After', () {
      expect(
        AIService.retryDelay(2),
        greaterThan(AIService.retryDelay(1)),
      );
      expect(
        AIService.retryDelay(1, retryAfterHeader: '3'),
        const Duration(seconds: 3),
      );
      // An absurd or unparseable header falls back to our own schedule.
      expect(
        AIService.retryDelay(1, retryAfterHeader: '900'),
        AIService.retryDelay(1),
      );
      expect(
        AIService.retryDelay(1, retryAfterHeader: 'Wed, 21 Oct 2026 07:28 GMT'),
        AIService.retryDelay(1),
      );
    });

    test('reasoning requests are given longer before being abandoned', () {
      expect(
        AIService.requestTimeout(useReasoning: true),
        greaterThan(AIService.requestTimeout(useReasoning: false)),
      );
    });
  });

  group('repetition guard', () {
    test('a restated reply is caught', () {
      const first =
          'That sounds like a heavy week, and the deadline seems to be sitting '
          'underneath most of it. What part feels most urgent right now?';
      const restated =
          'That sounds like a heavy week, and the deadline seems to be sitting '
          'under most of it. Which part feels most urgent right now?';
      expect(AIService.isRepetitiveReply(restated, first), isTrue);
    });

    test('two replies on the same topic are not confused for repetition', () {
      const first =
          'That sounds like a heavy week, and the deadline seems to be sitting '
          'underneath most of it.';
      const different =
          'You mentioned your sister called afterwards. I am curious whether '
          'that changed anything about how the evening went.';
      expect(AIService.isRepetitiveReply(different, first), isFalse);
    });

    test('the first reply in a conversation is never repetitive', () {
      expect(AIService.isRepetitiveReply('Anything at all.', null), isFalse);
      expect(AIService.isRepetitiveReply('Anything at all.', '   '), isFalse);
    });

    test('similarity is symmetric and bounded', () {
      const a = 'the deadline is sitting underneath most of this week';
      const b = 'the deadline sits underneath this whole week honestly';
      expect(
        AIService.replySimilarity(a, b),
        closeTo(AIService.replySimilarity(b, a), 0.0001),
      );
      expect(AIService.replySimilarity(a, a), 1.0);
      expect(AIService.replySimilarity(a, ''), 0.0);
    });
  });

  group('learned reply preferences', () {
    Future<void> give(
      AIReplyFeedback feedback, {
      AIReplyFeedbackReason? reason,
      bool offline = false,
    }) =>
        AIResponseFeedbackService.record(
          feedback: feedback,
          reason: reason,
          companionId: 'kai',
          mode: 'auto',
          wasOffline: offline,
        );

    test('a single complaint is treated as noise, not a preference', () async {
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.tooMuchAdvice,
      );
      final profile = await AIResponseFeedbackService.loadProfile();
      expect(profile.hasSignal, isFalse);
      expect(profile.steeringDirectives, isEmpty);
    });

    test('a repeated complaint becomes a standing instruction', () async {
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.tooMuchAdvice,
      );
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.tooMuchAdvice,
      );
      final profile = await AIResponseFeedbackService.loadProfile();

      expect(profile.hasSignal, isTrue);
      expect(profile.learnedReasons, [AIReplyFeedbackReason.tooMuchAdvice]);
      expect(profile.steeringDirectives.single, contains('advice-heavy'));
      expect(profile.userFacingSummary, ['Give less advice']);
    });

    test('the instruction reaches the system prompt', () async {
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.tooGeneric,
      );
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.tooGeneric,
      );
      final profile = await AIResponseFeedbackService.loadProfile();

      final prompt = AIService.getSystemPrompt(
        companionId: 'kai',
        language: 'english',
        learnedPreferences: profile.steeringDirectives,
      );
      expect(prompt, contains('LEARNED PREFERENCES'));
      expect(prompt, contains('too generic'));

      // And stays out of the prompt when nothing has been learned.
      final plain = AIService.getSystemPrompt(
        companionId: 'kai',
        language: 'english',
      );
      expect(plain, isNot(contains('LEARNED PREFERENCES')));
    });

    test('rating an offline fallback teaches nothing about the model',
        () async {
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.tooGeneric,
        offline: true,
      );
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.tooGeneric,
        offline: true,
      );
      final profile = await AIResponseFeedbackService.loadProfile();
      expect(profile.hasSignal, isFalse);
    });

    test('at most two standing corrections are carried at once', () async {
      for (final reason in AIReplyFeedbackReason.values) {
        await give(AIReplyFeedback.notHelpful, reason: reason);
        await give(AIReplyFeedback.notHelpful, reason: reason);
      }
      final profile = await AIResponseFeedbackService.loadProfile();
      expect(profile.learnedReasons.length, lessThanOrEqualTo(2));
    });

    test('feedback older than the learning window stops steering', () async {
      // Thirty newer helpful ratings push the old complaints out of the window.
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.repetitive,
      );
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.repetitive,
      );
      expect(
        (await AIResponseFeedbackService.loadProfile()).hasSignal,
        isTrue,
      );

      for (var i = 0; i < 30; i++) {
        await give(AIReplyFeedback.helpful);
      }
      expect(
        (await AIResponseFeedbackService.loadProfile()).hasSignal,
        isFalse,
      );
    });

    test('resetting clears the learning without touching entries', () async {
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.missedThePoint,
      );
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.missedThePoint,
      );
      expect(
        (await AIResponseFeedbackService.loadProfile()).hasSignal,
        isTrue,
      );

      await AIResponseFeedbackService.clearLearnedPreferences();
      expect(AIResponseFeedbackService.cachedProfile.hasSignal, isFalse);

      AIResponseFeedbackService.resetCacheForTesting();
      expect(
        (await AIResponseFeedbackService.loadProfile()).hasSignal,
        isFalse,
      );
    });

    test('corrupt stored feedback degrades to no learning', () async {
      SharedPreferences.setMockInitialValues({
        'ai_response_feedback_v1': 'not json at all',
      });
      AIResponseFeedbackService.resetCacheForTesting();
      expect(
        (await AIResponseFeedbackService.loadProfile()).hasSignal,
        isFalse,
      );
    });

    test('only quality metadata is stored, never what was written', () async {
      await give(
        AIReplyFeedback.notHelpful,
        reason: AIReplyFeedbackReason.tooGeneric,
      );
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString('ai_response_feedback_v1')!;
      final record = (jsonDecode(raw) as List).first as Map<String, dynamic>;

      expect(
        record.keys.toSet(),
        {'feedback', 'reason', 'companion', 'mode', 'offline', 'createdAt'},
      );
    });
  });

  group('memory', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'ai_memory_enabled': true});
      await AIMemoryService.loadPreference();
      await AIMemoryService.clearMemories();
    });

    test('every theme keyword set is distinct and non-empty', () {
      final ids = <String>{};
      for (final theme in AIMemoryService.observableThemes) {
        expect(theme.keywords, isNotEmpty);
        expect(theme.summary.trim(), isNotEmpty);
        expect(ids.add(theme.id), isTrue, reason: 'duplicate ${theme.id}');
        expect(theme.relevance, inInclusiveRange(1, 10));
      }
    });

    test('a plainly stated theme is remembered', () async {
      await AIMemoryService.extractMemoryFromNote(
        'Rough week',
        'The thesis deadline is next Friday and I have barely started writing.',
      );
      expect(
        AIMemoryService.memories.any(
          (memory) => memory.summary.contains('school deadlines'),
        ),
        isTrue,
      );
    });

    test('a very short note is not mined for themes', () async {
      await AIMemoryService.extractMemoryFromNote('', 'exam');
      expect(AIMemoryService.memories, isEmpty);
    });

    test('seeing the same theme again strengthens it instead of duplicating',
        () async {
      await AIMemoryService.extractMemoryFromNote(
        'Week one',
        'The thesis deadline is next Friday and I have barely started.',
      );
      final first = AIMemoryService.memories
          .firstWhere((memory) => memory.summary.contains('school deadlines'));

      await AIMemoryService.extractMemoryFromNote(
        'Week two',
        'Another exam tomorrow and the thesis deadline has not moved at all.',
      );
      final matching = AIMemoryService.memories
          .where((memory) => memory.summary.contains('school deadlines'))
          .toList();

      expect(matching, hasLength(1));
      expect(matching.single.relevanceScore, greaterThan(first.relevanceScore));
    });

    test('memory stays a short list rather than growing without limit',
        () async {
      for (var i = 0; i < 40; i++) {
        await AIMemoryService.addMemory(
          'A distinct remembered observation number $i about something',
          relevance: 1 + (i % 9),
        );
      }
      expect(
        AIMemoryService.memories.length,
        lessThanOrEqualTo(AIMemoryService.maximumMemories),
      );
    });

    test('rephrasings of one observation are treated as the same note', () {
      expect(
        AIMemoryService.isSameObservation(
          'Carries recurring pressure from school deadlines and requirements.',
          'Carries recurring pressure from school deadlines and requirements',
        ),
        isTrue,
      );
      expect(
        AIMemoryService.isSameObservation(
          'Carries recurring pressure from school deadlines.',
          'Draws meaning and steadiness from close family and friendships.',
        ),
        isFalse,
      );
    });

    test('companion observations are stored below keyword themes', () async {
      await AIMemoryService.noteCompanionObservation(
        detectedEmotions: ['overwhelmed', 'happy', 'lonely'],
        standoutMoments: ['Choosing to stop early'],
      );
      final memories = AIMemoryService.memories;

      // "happy" is not weighty enough to remember; the other two are.
      expect(
        memories.where((m) => m.summary.contains('overwhelmed')),
        hasLength(1),
      );
      expect(memories.any((m) => m.summary.contains('happy')), isFalse);
      expect(
        memories.any((m) => m.summary.contains('Choosing to stop early')),
        isTrue,
      );
      // Soft signals are the first thing dropped when memory fills.
      expect(
        memories
            .firstWhere((m) => m.summary.contains('overwhelmed'))
            .relevanceScore,
        lessThan(6),
      );
    });

    test('nothing is learned while memory is paused', () async {
      await AIMemoryService.setEnabled(false);
      addTearDown(() => AIMemoryService.setEnabled(true));

      await AIMemoryService.extractMemoryFromNote(
        'Rough week',
        'The thesis deadline is next Friday and I have barely started writing.',
      );
      await AIMemoryService.noteCompanionObservation(
        detectedEmotions: ['lonely'],
        standoutMoments: const [],
      );
      expect(AIMemoryService.memories, isEmpty);
    });
  });

  group('quality gating', () {
    AICompanionReply replyOf(String text) => AICompanionReply(text: text);

    test('anything unsafe is always rejected, whatever the alternative', () {
      for (final concern in AIService.hardQualityConcerns) {
        expect(AIService.hasHardQualityConcern([concern]), isTrue);
      }
      expect(
        AIService.hasHardQualityConcern(['generic_cliche', 'too_long']),
        isFalse,
      );
      expect(AIService.hasHardQualityConcern(const []), isFalse);
    });

    test('a boundary the user set is a hard failure, not a cosmetic one', () {
      final concerns = AIService.evaluateReplyQuality(
        replyOf('You should try to sleep earlier and it will help.'),
        expectedLanguage: 'english',
        mode: CompanionMode.auto,
        listeningOnly: true,
      );
      expect(concerns, contains('unsolicited_advice'));
      expect(AIService.hasHardQualityConcern(concerns), isTrue);
    });

    test('leaking internal contract fields is a hard failure', () {
      final concerns = AIService.evaluateReplyQuality(
        replyOf('possible_need: venting. Here is what I noticed today.'),
        expectedLanguage: 'english',
        mode: CompanionMode.auto,
      );
      expect(AIService.hasHardQualityConcern(concerns), isTrue);
    });

    test('a cliche alone is not worth losing a relevant reply over', () {
      final concerns = AIService.evaluateReplyQuality(
        replyOf(
          "I'm sorry you're going through this. The double shift on Tuesday "
          'is the part that seems to have taken the most out of you.',
        ),
        expectedLanguage: 'english',
        mode: CompanionMode.auto,
      );
      expect(concerns, contains('generic_cliche'));
      expect(
        AIService.hasHardQualityConcern(concerns),
        isFalse,
        reason: 'the last provider available should still be able to use it',
      );
    });

    test('a missing reflection heading is cosmetic', () {
      final concerns = AIService.evaluateReplyQuality(
        replyOf('A thoughtful paragraph with no headings in it at all.'),
        expectedLanguage: 'english',
        mode: CompanionMode.reflection,
      );
      expect(concerns, contains('reflection_format_missing'));
      expect(AIService.hasHardQualityConcern(concerns), isFalse);
    });

    test('a clean reply raises nothing', () {
      expect(
        AIService.evaluateReplyQuality(
          replyOf(
            'Two long shifts back to back is a lot, and it makes sense that '
            'getting home felt like the only thing left in you.',
          ),
          expectedLanguage: 'english',
          mode: CompanionMode.auto,
        ),
        isEmpty,
      );
    });
  });
}
