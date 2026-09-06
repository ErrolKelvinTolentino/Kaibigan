import '../../core/services/ai_service.dart';
import '../../core/utils/language_helper.dart';
import 'learning_catalog.dart';
import 'learning_model.dart';

enum LearningAskKaiResultKind {
  answer,
  offTopic,
  blocked,
  clinicalBoundary,
  crisis,
}

class LearningAskKaiResult {
  const LearningAskKaiResult({
    required this.kind,
    required this.text,
    this.isOffline = false,
    this.safetyLevel = 'none',
  });

  final LearningAskKaiResultKind kind;
  final String text;
  final bool isOffline;
  final String safetyLevel;

  bool get isSafetyResponse =>
      kind == LearningAskKaiResultKind.crisis || safetyLevel != 'none';
}

/// A narrow educational route for Kai. Questions are screened locally before
/// any provider request, and the model receives only bounded lesson content.
class LearningAskKaiService {
  const LearningAskKaiService();

  static const int maxQuestionCharacters = 500;
  static const int _maxContextCharacters = 9000;

  Future<LearningAskKaiResult> answer({
    required String question,
    required LearningLesson lesson,
    required LearningSection currentSection,
    required String language,
    AIRequestCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final prepared = AIService.prepareJournalText(question);
    if (prepared.isEmpty) {
      return LearningAskKaiResult(
        kind: LearningAskKaiResultKind.offTopic,
        text: _pick(
          language,
          english: 'Ask one question about this idea first.',
          filipino: 'Magtanong muna tungkol sa ideyang ito.',
          taglish: 'Ask one question muna about this idea.',
        ),
      );
    }

    if (AIService.isCrisisMessage(prepared)) {
      return LearningAskKaiResult(
        kind: LearningAskKaiResultKind.crisis,
        text: AIService.getCrisisResponse('kai', language),
        safetyLevel: 'crisis',
      );
    }

    if (looksLikePromptInjection(prepared)) {
      return LearningAskKaiResult(
        kind: LearningAskKaiResultKind.blocked,
        text: _pick(
          language,
          english:
              'I can only help explain this lesson. Try asking what this idea means, how it may appear in daily life, or what safe step the lesson suggests.',
          filipino:
              'Ang lesson na ito lang ang maipapaliwanag ko. Maaari mong itanong kung ano ang ibig sabihin ng idea, paano ito makikita sa araw-araw, o anong ligtas na hakbang ang mungkahi ng lesson.',
          taglish:
              'This lesson lang ang puwede kong ipaliwanag. Ask what the idea means, how it may show up day to day, or what safe step the lesson suggests.',
        ),
      );
    }

    if (requestsDiagnosisOrMedication(prepared)) {
      return LearningAskKaiResult(
        kind: LearningAskKaiResultKind.clinicalBoundary,
        text: _pick(
          language,
          english:
              'This lesson cannot tell whether you have a condition or advise starting, stopping, or changing medication. A qualified clinician can assess your situation, and a prescriber or pharmacist can answer medication questions safely. I can still explain what this lesson says about signs, support, or seeking help.',
          filipino:
              'Hindi masasabi ng lesson kung mayroon kang kondisyon, at hindi ito makapagpapayo na magsimula, huminto, o magpalit ng gamot. Makakatulong ang qualified clinician sa assessment at prescriber o pharmacist sa ligtas na tanong tungkol sa gamot. Maaari kong ipaliwanag ang sinasabi ng lesson tungkol sa signs, suporta, o paghingi ng tulong.',
          taglish:
              'This lesson cannot diagnose you or advise starting, stopping, or changing medication. A qualified clinician can assess your situation, and a prescriber or pharmacist can answer medication questions safely. I can still explain the lesson’s signs, support, or help-seeking guidance.',
        ),
      );
    }

    if (!isRelevantQuestion(
      prepared,
      lesson: lesson,
      currentSection: currentSection,
      language: language,
    )) {
      return LearningAskKaiResult(
        kind: LearningAskKaiResultKind.offTopic,
        text: _pick(
          language,
          english:
              'That is outside mental health and outside this lesson, so I will not guess. Ask me about “${currentSection.heading.resolve(language)},” other slides, any lesson, or mental health topics.',
          filipino:
              'Wala iyon sa sakop ng mental health at outside this lesson, kaya hindi ako manghuhula. Magtanong tungkol sa “${currentSection.heading.resolve(language)},” ibang slides, alinmang aralin, o paksang mental health.',
          taglish:
              'Outside mental health and outside this lesson iyon, so I won’t guess. Ask about “${currentSection.heading.resolve(language)},” other slides, any lesson, or mental health topics.',
        ),
      );
    }

    final boundedQuestion = prepared.length <= maxQuestionCharacters
        ? prepared
        : prepared.substring(0, maxQuestionCharacters);
    final educationalContext = buildEducationalContext(
      lesson: lesson,
      currentSection: currentSection,
      language: language,
      question: prepared,
    );

    try {
      final reply = await AIService.generateCompanionReply(
        userText: boundedQuestion,
        companionId: 'kai',
        language: language,
        mode: CompanionMode.companion,
        useReasoning: false,
        educationalContext: educationalContext,
        cancellationToken: cancellationToken,
      );
      if (reply.safetyLevel == 'crisis') {
        return LearningAskKaiResult(
          kind: LearningAskKaiResultKind.crisis,
          text: reply.text,
          safetyLevel: 'crisis',
        );
      }
      if (reply.isOffline || answerViolatesGuardrails(reply.text)) {
        return LearningAskKaiResult(
          kind: LearningAskKaiResultKind.answer,
          text: _groundedOfflineAnswer(currentSection, language),
          isOffline: true,
        );
      }
      return LearningAskKaiResult(
        kind: LearningAskKaiResultKind.answer,
        text: reply.text,
        safetyLevel: reply.safetyLevel,
      );
    } on AIRequestCancelledException {
      rethrow;
    } catch (_) {
      return LearningAskKaiResult(
        kind: LearningAskKaiResultKind.answer,
        text: _groundedOfflineAnswer(currentSection, language),
        isOffline: true,
      );
    }
  }

  static bool isRelevantQuestion(
    String question, {
    required LearningLesson lesson,
    required LearningSection currentSection,
    required String language,
  }) {
    final lower = question.toLowerCase();

    // 1. Refuse unrelated utility tasks (weather, stocks, sports, code, recipes, etc.)
    if (_looksLikeUnrelatedTask(lower)) return false;

    // 2. Referential phrases referring to this idea, this lesson, other slides, or mental health
    final referential = RegExp(
      r'\b(this|that|this idea|this lesson|the lesson|the idea|the slide|other slides|next slide|previous slide|all lessons|mental health|it|ito|iyon|ideyang ito|lesson na ito|paksang ito|ibang slide|mga slide|kalusugan ng isip)\b',
      caseSensitive: false,
    ).hasMatch(lower);
    if (referential) return true;

    // 3. Mental health, emotional wellness, psychology, coping, therapy, and feelings keywords
    const mentalHealthTopics = [
      'mental health', 'mental illness', 'psychology', 'psychological',
      'therapy', 'therapist', 'counseling', 'counselor', 'wellness', 'wellbeing', 'well-being',
      'anxiety', 'anxious', 'panic', 'stress', 'stressed', 'stressor', 'burnout',
      'depression', 'depressed', 'low mood', 'sadness', 'sad', 'grief', 'loss',
      'trauma', 'ptsd', 'adhd', 'ocd', 'bipolar', 'eating disorder', 'schizophrenia',
      'emotion', 'emotions', 'emotional', 'feeling', 'feelings', 'mood', 'moods',
      'calm', 'calming', 'relax', 'relaxation', 'grounding', 'breathe', 'breathing',
      'mindfulness', 'meditation', 'self-care', 'self care', 'compassion', 'self-compassion',
      'boundaries', 'boundary', 'overthinking', 'rumination', 'ruminating',
      'sleep', 'insomnia', 'fatigue', 'tired', 'exhaustion', 'nervous system',
      'coping', 'coping mechanism', 'trigger', 'triggers', 'attachment',
      'loneliness', 'lonely', 'isolation', 'support', 'help', 'relationship', 'relationships',
      'self-worth', 'self-esteem', 'worth', 'confidence', 'habits', 'habit', 'routine',
      'focus', 'procrastination', 'motivation', 'guilt', 'shame', 'anger', 'irritability',
      'kalusugang pangkaisipan', 'pag-iisip', 'damdamin', 'lungkot', 'takot',
      'pangamba', 'pagod', 'pahinga', 'suporta', 'pagkabalisa', 'paghinga',
    ];
    if (mentalHealthTopics.any((topic) => lower.contains(topic))) {
      return true;
    }

    // 4. Current lesson and slide scope
    final currentScope = <String>[
      lesson.title.resolve(language),
      lesson.summary.resolve(language),
      currentSection.heading.resolve(language),
      currentSection.body.resolve(language),
      ...lesson.sections.expand(
        (section) => [
          section.heading.resolve(language),
          section.body.resolve(language),
        ],
      ),
      ...lesson.searchTerms,
    ].join(' ');
    final currentTokens = _meaningfulTokens(currentScope);
    final questionTokens = _meaningfulTokens(question);
    if (questionTokens.any(currentTokens.contains)) return true;

    // 5. Broader LearningCatalog scope (all other lessons in Kaibigan)
    final catalogScope = <String>[
      ...LearningCatalog.lessons.expand(
        (l) => [
          l.title.resolve(language),
          l.summary.resolve(language),
          ...l.searchTerms,
          ...l.sections.map((s) => s.heading.resolve(language)),
        ],
      ),
    ].join(' ');
    final catalogTokens = _meaningfulTokens(catalogScope);
    if (questionTokens.any(catalogTokens.contains)) return true;

    // Genuine questions about feelings and life that aren't unrelated tasks
    return true;
  }

  static bool looksLikePromptInjection(String question) {
    final lower = question.toLowerCase();
    const patterns = [
      'ignore previous',
      'ignore all previous',
      'ignore your instructions',
      'forget your instructions',
      'system prompt',
      'developer message',
      'reveal your prompt',
      'show your instructions',
      'act as unrestricted',
      'pretend you are unrestricted',
      'override your rules',
      'override the rules',
      'new instructions',
      'do anything now',
      'jailbreak',
      'bypass guardrails',
      'disregard previous',
    ];
    return patterns.any(lower.contains);
  }

  static bool requestsDiagnosisOrMedication(String question) {
    final lower = question.toLowerCase();
    final diagnosisRequest = RegExp(
          r'\b(do i have|diagnose me|am i diagnosed|does this mean i have|tell me my diagnosis)\b|\b(may|mayroon|meron) (adhd|anxiety|depression|bipolar|ocd|ptsd|autism|panic disorder) ba ako\b|\b(mayroon|meron) ba akong (adhd|anxiety|depression|bipolar|ocd|ptsd|autism|panic disorder)\b',
          caseSensitive: false,
        ).hasMatch(lower);
    // Ordinary requests such as "Should I take a break?" and "Can I start
    // journaling?" need a helpful answer, not a medication refusal.
    final medicationContext = RegExp(
      r'\b(medication|medicine|meds|pill|pills|dose|dosage|mg|antidepressant|stimulant|sertraline|fluoxetine|escitalopram|alprazolam|gamot|dosis|reseta)\b',
      caseSensitive: false,
    ).hasMatch(lower);
    final medicationChange = RegExp(
          r'\b(should i|can i|dapat ba akong|puwede ba akong|pwede ba akong)\s+(start|stop|take|change|increase|decrease|double|simulan|itigil|inumin|palitan|dagdagan|bawasan)\b',
          caseSensitive: false,
        ).hasMatch(lower);
    return diagnosisRequest ||
        (medicationContext && medicationChange) ||
        RegExp(
          r'\b(what dose|how many mg|prescribe|anong dose|ilang mg|anong gamot ang dapat)\b',
          caseSensitive: false,
        ).hasMatch(lower);
  }

  static bool answerViolatesGuardrails(String answer) {
    final lower = answer.toLowerCase();
    if (lower.contains('system prompt') ||
        lower.contains('developer message') ||
        lower.contains('lesson_context')) {
      return true;
    }
    return AIService.hasUnsafeClinicalAdvice(answer);
  }

  static String buildEducationalContext({
    required LearningLesson lesson,
    required LearningSection currentSection,
    required String language,
    String? question,
  }) {
    final buffer = StringBuffer()
      ..writeln('REFERENCE ONLY: Explain what is supported below. If a detail is missing, say so; never invent a source, diagnosis, or treatment recommendation.')
      ..writeln('SOURCE LABEL: ${lesson.sourceLabel}')
      ..writeln('CURRENT LESSON: ${lesson.title.resolve(language)}')
      ..writeln('SUMMARY: ${lesson.summary.resolve(language)}')
      ..writeln('CURRENT SLIDE / IDEA: ${currentSection.heading.resolve(language)}')
      ..writeln(currentSection.body.resolve(language))
      ..writeln()
      ..writeln('ALL SLIDES IN THIS LESSON:');
    for (var i = 0; i < lesson.sections.length; i++) {
      final section = lesson.sections[i];
      buffer
        ..writeln('Slide ${i + 1}: ${section.heading.resolve(language)}')
        ..writeln(section.body.resolve(language))
        ..writeln();
    }

    final qLower = (question ?? '').toLowerCase();
    final relatedLessons = LearningCatalog.lessons.where((other) {
      if (other.id == lesson.id) return false;
      if (qLower.isEmpty) return false;
      final title = other.title.resolve(language).toLowerCase();
      final terms = other.searchTerms.map((t) => t.toLowerCase());
      return terms.any((t) => qLower.contains(t)) ||
          title.split(' ').any((w) => w.length > 3 && qLower.contains(w));
    }).take(2);

    if (relatedLessons.isNotEmpty) {
      buffer.writeln('RELEVANT LESSONS FROM KAIBIGAN CURRICULUM:');
      for (final rel in relatedLessons) {
        buffer
          ..writeln('Lesson: ${rel.title.resolve(language)}')
          ..writeln('Summary: ${rel.summary.resolve(language)}');
        for (final s in rel.sections) {
          buffer.writeln('- ${s.heading.resolve(language)}: ${s.body.resolve(language)}');
        }
        buffer.writeln();
      }
    }

    buffer
      ..writeln('BROADER MENTAL HEALTH CURRICULUM OVERVIEW:')
      ..writeln(
        LearningCatalog.lessons
            .map((l) => '• ${l.title.resolve(language)}: ${l.summary.resolve(language)}')
            .join('\n'),
      )
      ..writeln()
      ..writeln('SCOPE & GUIDELINES:')
      ..writeln(
        'Use the supplied lesson content for factual explanations. For broader questions, explain only what this context supports and acknowledge what it does not cover. '
        'Answer the question directly, explain one idea at a time, and use one everyday example when helpful. Do not infer symptoms or history about the learner.',
      )
      ..writeln('SOURCE LABEL: ${lesson.sourceLabel}');

    final context = buffer.toString().trim();
    return context.length <= _maxContextCharacters
        ? context
        : context.substring(0, _maxContextCharacters);
  }

  static bool _looksLikeUnrelatedTask(String lower) {
    return RegExp(
      r'\b(write|generate|compose|make)\b.{0,30}\b(code|program|essay|homework|poem|song|joke|story|recipe|email)\b|\b(weather|stock price|crypto|sports score|capital of|solve this equation|translate this document)\b',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  static Set<String> _meaningfulTokens(String text) {
    const stopWords = {
      'about',
      'after',
      'again',
      'also',
      'ang',
      'ano',
      'are',
      'ako',
      'aking',
      'can',
      'does',
      'from',
      'have',
      'help',
      'how',
      'ito',
      'iyong',
      'lesson',
      'may',
      'mga',
      'na',
      'nang',
      'ng',
      'para',
      'paano',
      'that',
      'the',
      'this',
      'what',
      'when',
      'where',
      'which',
      'why',
      'with',
      'you',
      'your',
    };
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñ\s-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 3 && !stopWords.contains(token))
        .toSet();
  }

  static String _groundedOfflineAnswer(
    LearningSection section,
    String language,
  ) {
    final body = section.body.resolve(language).trim();
    final bounded = body.length <= 700 ? body : '${body.substring(0, 697)}…';
    return _pick(
      language,
      english: 'From this lesson: $bounded\n\nA personal explanation is unavailable right now. This is the saved lesson text; it may not answer every part of your question.',
      filipino: 'Mula sa araling ito: $bounded\n\nHindi available ngayon ang paliwanag ni Kai. Ito ang naka-save na teksto ng aralin; maaaring hindi nito masagot ang lahat ng bahagi ng tanong mo.',
      taglish: 'From this lesson: $bounded\n\nHindi available ang personal na explanation ngayon. Saved lesson text ito, so it may not answer every part of your question.',
    );
  }

  static String _pick(
    String language, {
    required String english,
    required String filipino,
    required String taglish,
  }) =>
      LanguageHelper.pick(
        language,
        english: english,
        filipino: filipino,
        taglish: taglish,
      );
}
