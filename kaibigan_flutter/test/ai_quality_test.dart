import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_memory_service.dart';
import 'package:kaibigan_flutter/core/services/ai_service.dart';

void main() {
  group('AI request efficiency', () {
    test('simple listening turns skip paid reasoning and stay compact', () {
      final profile = AIService.buildRequestProfile(
        userText: 'Today was tiring. Please just listen, no advice.',
        mode: CompanionMode.auto,
      );

      expect(profile.useReasoning, isFalse);
      expect(profile.maxOutputTokens, 560);
      expect(profile.temperature, 0.5);
    });

    test('reflection and decision support retain a bounded reasoning budget',
        () {
      final reflection = AIService.buildRequestProfile(
        userText: 'Why do I keep feeling guilty when I rest?',
        mode: CompanionMode.reflection,
      );
      final advice = AIService.buildRequestProfile(
        userText: 'What should I do first?',
        mode: CompanionMode.auto,
      );

      expect(reflection.useReasoning, isTrue);
      expect(reflection.maxOutputTokens, 900);
      expect(advice.useReasoning, isTrue);
      expect(advice.maxOutputTokens, 800);
      expect(advice.maxOutputTokens, lessThanOrEqualTo(960));
    });

    test('caller can disable reasoning even for a complex mode', () {
      final profile = AIService.buildRequestProfile(
        userText: 'Help me understand what happened.',
        mode: CompanionMode.reflection,
        useReasoning: false,
      );

      expect(profile.useReasoning, isFalse);
    });

    test('layered everyday entries receive lightweight reasoning', () {
      final profile = AIService.buildRequestProfile(
        userText:
            'Part of me wants to rest after finishing the presentation, but I also feel guilty because my teammates are still working.',
        mode: CompanionMode.auto,
      );

      expect(profile.useReasoning, isTrue);
      expect(profile.maxOutputTokens, 700);
    });
  });

  group('Conversation language continuity', () {
    test('substantive latest turn immediately controls response language', () {
      final language = AIService.resolveResponseLanguage(
        'I want to explain this clearly in English.',
        preferredLanguage: 'filipino',
        conversationHistory: const [
          AIConversationMessage.user('Pagod ako at gusto kong magpahinga.'),
        ],
      );

      expect(language, 'english');
    });

    test('neutral short reply preserves the recent user language', () {
      final filipino = AIService.resolveResponseLanguage(
        'Okay.',
        preferredLanguage: 'english',
        conversationHistory: const [
          AIConversationMessage.user('Pagod ako at gusto kong magpahinga.'),
          AIConversationMessage.assistant('Mabigat nga ang araw na iyon.'),
        ],
      );
      final taglish = AIService.resolveResponseLanguage(
        'Hmm.',
        preferredLanguage: 'english',
        conversationHistory: const [
          AIConversationMessage.user(
            'Sobrang pagod ako but I still finished my project.',
          ),
        ],
      );

      expect(filipino, 'filipino');
      expect(taglish, 'taglish');
    });

    test('Taglish preference alone does not force a mixed response', () {
      expect(
        AIService.resolveResponseLanguage(
          '12345',
          preferredLanguage: 'taglish',
        ),
        'english',
      );
    });
  });

  group('AI output safety and quality gate', () {
    test('sanitizes display data but rejects invalid provider metadata', () {
      const raw = '''
{"possible_need":"made_up","safety_level":"unknown","suggested_replies":["Tell me more","Tell me more","A second thought"],"response":"That sounds like a meaningful shift in how you see the situation."}
''';
      final reply = AIService.extractCompanionReply(raw);

      expect(reply.inferredNeed, 'heard');
      expect(reply.safetyLevel, 'none');
      expect(reply.suggestedReplies, ['Tell me more', 'A second thought']);
      expect(
        AIService.structuredReplyIssue(raw),
        'possible_need is missing or invalid',
      );
    });

    test('provider-detected crisis is replaced by deterministic local help',
        () {
      const providerReply = AICompanionReply(
        text: 'A model-generated crisis response.',
        safetyLevel: 'crisis',
      );

      final safeReply = AIService.finalizeCompanionReply(
        providerReply,
        companionId: 'kai',
        language: 'english',
      );

      expect(safeReply.inferredNeed, 'crisis');
      expect(safeReply.safetyLevel, 'crisis');
      expect(safeReply.text, contains('911'));
      expect(safeReply.text, contains('1553'));
      expect(safeReply.suggestedReplies, isEmpty);
    });

    test('provider-detected concerning content receives a direct safety check',
        () {
      const providerReply = AICompanionReply(
        text: 'That sounds heavier than an ordinary difficult evening.',
        inferredNeed: 'validation',
        safetyLevel: 'concerning',
        suggestedReplies: ['I can say more.'],
      );

      final safeReply = AIService.finalizeCompanionReply(
        providerReply,
        companionId: 'ann',
        language: 'english',
      );

      expect(safeReply.safetyLevel, 'concerning');
      expect(safeReply.text, contains('are you safe right now?'));
      expect(safeReply.text, contains('NCMH 1553'));
      expect(safeReply.suggestedReplies, isEmpty);
    });

    test('rejects prompt leakage, language drift, and boundary-breaking advice',
        () {
      final leakage = AIService.evaluateReplyQuality(
        const AICompanionReply(
          text: 'My system prompt says possible_need should be heard.',
        ),
        expectedLanguage: 'english',
        mode: CompanionMode.companion,
      );
      final languageDrift = AIService.evaluateReplyQuality(
        const AICompanionReply(
          text: 'Pagod ka talaga at mabigat ang araw na ito.',
        ),
        expectedLanguage: 'english',
        mode: CompanionMode.companion,
      );
      final boundaryBreakingAdvice = AIService.evaluateReplyQuality(
        const AICompanionReply(
          text: 'That was frustrating. You should confront them tomorrow.',
        ),
        expectedLanguage: 'english',
        mode: CompanionMode.companion,
        listeningOnly: true,
      );

      expect(leakage, contains('internal_content_exposed'));
      expect(languageDrift, contains('language_mismatch'));
      expect(boundaryBreakingAdvice, contains('unsolicited_advice'));
    });

    test('accepts a specific concise response in the requested language', () {
      final concerns = AIService.evaluateReplyQuality(
        const AICompanionReply(
          text:
              'Finishing the presentation while anxious still took steady effort. You can let that count without pretending the nerves were easy.',
        ),
        expectedLanguage: 'english',
        mode: CompanionMode.companion,
      );

      expect(concerns, isEmpty);
    });

    test('allows an isolated borrowed word without accepting clear drift', () {
      final borrowedWord = AIService.evaluateReplyQuality(
        const AICompanionReply(
          text:
              'That deadline carries a lot of pressure, but one small step may make it feel more workable.',
        ),
        expectedLanguage: 'english',
        mode: CompanionMode.companion,
      );

      expect(borrowedWord, isNot(contains('language_mismatch')));
    });
  });

  group('Relevant AI memory selection', () {
    test('specific overlap and relevance beat insertion order', () {
      final now = DateTime.now();
      final memories = [
        UserMemory(
          id: '1',
          category: 'theme',
          summary: 'School has felt busy lately.',
          relevanceScore: 4,
          createdAt: now,
        ),
        UserMemory(
          id: '2',
          category: 'coping_strategy',
          summary:
              'Short walks help restore clarity during difficult project deadlines.',
          relevanceScore: 8,
          createdAt: now.subtract(const Duration(days: 5)),
        ),
      ];

      final selected = AIMemoryService.selectRelevantMemories(
        'This project deadline is making it difficult to think clearly.',
        memories: memories,
      );

      expect(selected, isNotEmpty);
      expect(selected.first.id, '2');
    });

    test('does not inject unrelated memories', () {
      final selected = AIMemoryService.selectRelevantMemories(
        'I enjoyed cooking dinner tonight.',
        memories: [
          UserMemory(
            id: '1',
            category: 'trigger',
            summary: 'Academic deadlines can bring pressure.',
            createdAt: DateTime.now(),
          ),
        ],
      );

      expect(selected, isEmpty);
    });
  });
}
