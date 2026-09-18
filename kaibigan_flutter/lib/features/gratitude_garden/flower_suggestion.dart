import 'gratitude_model.dart';

/// A flower recommendation derived from the essence of a gratitude note.
///
/// The match is a pure function of the note's text, so the same note always
/// resolves to the same bloom. That lets a saved entry be re-checked later
/// without storing anything extra alongside it.
class FlowerSuggestion {
  const FlowerSuggestion({
    required this.flowerType,
    required this.theme,
    required this.reason,
    required this.confidence,
  });

  final String flowerType;

  /// Short label for the essence that was recognised, e.g. "a calm moment".
  final String theme;

  /// One sentence explaining the pairing, shown beside the recommendation.
  final String reason;

  /// 0–1. Below [FlowerMatcher.confidentThreshold] this is offered as a gentle
  /// default rather than a reading of the note.
  final double confidence;

  bool get isConfident => confidence >= FlowerMatcher.confidentThreshold;

  String get flowerName => GratitudeEntry.getFlowerName(flowerType);
  String get flowerMeaning => GratitudeEntry.getFlowerMeaning(flowerType);
}

class _FlowerTheme {
  const _FlowerTheme({
    required this.flowerType,
    required this.theme,
    required this.reason,
    required this.strong,
    this.supporting = const [],
  });

  final String flowerType;
  final String theme;
  final String reason;

  /// Words that clearly signal this essence.
  final List<String> strong;

  /// Words that lean this way but also appear in other essences.
  final List<String> supporting;
}

/// Matches the essence of a gratitude note to the flower whose traditional
/// meaning fits it. Keyword sets cover English, Filipino and common Taglish
/// spellings because entries are written in all three.
class FlowerMatcher {
  const FlowerMatcher._();

  static const double confidentThreshold = 0.34;
  static const String neutralFlower = 'sunflower';

  static const _themes = <_FlowerTheme>[
    _FlowerTheme(
      flowerType: 'rose',
      theme: 'deep thankfulness for someone',
      reason:
          'Roses have long carried deep gratitude, so they suit a thank you '
          'you feel in your chest.',
      strong: [
        'thank you',
        'thankful',
        'grateful',
        'gratitude',
        'love',
        'loved',
        'beloved',
        'salamat',
        'nagpapasalamat',
        'pagmamahal',
        'mahal',
        'minamahal',
      ],
      supporting: [
        'partner',
        'husband',
        'wife',
        'girlfriend',
        'boyfriend',
        'anniversary',
        'asawa',
        'kasintahan',
        'nobyo',
        'nobya',
      ],
    ),
    _FlowerTheme(
      flowerType: 'geranium',
      theme: 'being met by someone',
      reason:
          'Geraniums carry comfort and true connection — the feeling of being '
          'met by another person.',
      strong: [
        'comfort',
        'comforted',
        'listened',
        'checked on me',
        'showed up',
        'there for me',
        'stayed with me',
        'hug',
        'hugged',
        'reached out',
        'kasama ko',
        'nandiyan',
        'nandyan',
        'sinamahan',
        'inalo',
        'yakap',
        'niyakap',
        'kinamusta',
        'pinakinggan',
      ],
      supporting: [
        'friend',
        'kaibigan',
        'family',
        'pamilya',
        'nanay',
        'tatay',
        'mother',
        'father',
        'sister',
        'brother',
        'ate',
        'kuya',
        'lola',
        'lolo',
        'together',
      ],
    ),
    _FlowerTheme(
      flowerType: 'chrysanthemum',
      theme: 'joy shared with a friend',
      reason:
          'Chrysanthemums stand for joy and loyal friendship, which is what '
          'this moment sounds like.',
      strong: [
        'laughed',
        'laughing',
        'laughter',
        'funny',
        'joke',
        'jokes',
        'tumawa',
        'natawa',
        'katatawanan',
        'tropa',
        'barkada',
        'kwentuhan',
        'kuwentuhan',
        'hang out',
        'hung out',
        'catch up',
        'caught up',
      ],
      supporting: [
        'friend',
        'friends',
        'kaibigan',
        'best friend',
        'fun',
        'celebrate',
        'celebration',
        'handaan',
      ],
    ),
    _FlowerTheme(
      flowerType: 'lavender',
      theme: 'a calm, quiet stretch',
      reason:
          'Lavender means calm and quiet devotion, a fit for stillness you '
          'chose to notice.',
      strong: [
        'calm',
        'calmer',
        'quiet',
        'peaceful',
        'stillness',
        'silence',
        'rested',
        'rest',
        'slept',
        'sleep',
        'nap',
        'breathe',
        'breathing',
        'tahimik',
        'kalmado',
        'kalma',
        'payapa',
        'pahinga',
        'nagpahinga',
        'idlip',
        'tulog',
        'natulog',
        'huminga',
      ],
      supporting: [
        'tea',
        'coffee',
        'kape',
        'bath',
        'shower',
        'ligo',
        'alone',
        'mag isa',
        'evening',
        'gabi',
      ],
    ),
    _FlowerTheme(
      flowerType: 'sunflower',
      theme: 'plain, easy brightness',
      reason:
          'Sunflowers hold joy, warmth and hope — the easy brightness in what '
          'you wrote.',
      strong: [
        'happy',
        'happiness',
        'joy',
        'joyful',
        'sunshine',
        'sunny',
        'sunlight',
        'good day',
        'great day',
        'smiled',
        'smile',
        'masaya',
        'saya',
        'ligaya',
        'ngiti',
        'ngumiti',
      ],
      supporting: [
        'walk',
        'outside',
        'morning',
        'umaga',
        'lakad',
        'labas',
        'weather',
        'panahon',
        'araw',
      ],
    ),
    _FlowerTheme(
      flowerType: 'anemone',
      theme: 'hope for what is coming',
      reason:
          'Anemones mean hope and gentle anticipation, which matches looking '
          'forward the way you are.',
      strong: [
        'hope',
        'hopeful',
        'looking forward',
        'excited',
        'excitement',
        'anticipating',
        'cant wait',
        "can't wait",
        'tomorrow',
        'next week',
        'plan',
        'plans',
        'pag asa',
        'umaasa',
        'inaabangan',
        'bukas',
        'balak',
      ],
      supporting: [
        'new',
        'bago',
        'start',
        'simula',
        'chance',
        'opportunity',
        'pagkakataon',
        'soon',
      ],
    ),
    _FlowerTheme(
      flowerType: 'lily',
      theme: 'renewal after something hard',
      reason:
          'Lilies stand for renewal and tender hope, the quiet turn after a '
          'hard stretch.',
      strong: [
        'healing',
        'healed',
        'recovered',
        'recovery',
        'got through',
        'made it through',
        'survived',
        'moving on',
        'fresh start',
        'gumaling',
        'humupa',
        'nakaraos',
        'nakayanan',
        'nakabangon',
        'panibago',
        'muli',
      ],
      supporting: [
        'hard',
        'difficult',
        'mahirap',
        'sakit',
        'sick',
        'better',
        'finally',
        'sa wakas',
      ],
    ),
    _FlowerTheme(
      flowerType: 'purple_aster',
      theme: 'patience and something you saw clearly',
      reason:
          'Purple asters carry patience and gentle wisdom, which fits noticing '
          'something slowly.',
      strong: [
        'learned',
        'learning',
        'realized',
        'realised',
        'patience',
        'patient',
        'understood',
        'understanding',
        'perspective',
        'lesson',
        'reminded me',
        'natutunan',
        'natuto',
        'napagtanto',
        'naintindihan',
        'pasensya',
        'pasensiya',
        'aral',
      ],
      supporting: [
        'slowly',
        'dahan dahan',
        'thought',
        'naisip',
        'time',
        'oras',
      ],
    ),
    _FlowerTheme(
      flowerType: 'ranunculus',
      theme: 'someone being kind to you',
      reason:
          'Ranunculus means warmth and radiant appreciation — noticing someone '
          'out loud.',
      strong: [
        'appreciate',
        'appreciated',
        'appreciation',
        'kind',
        'kindness',
        'generous',
        'thoughtful',
        'helped me',
        'helped',
        'supported',
        'gift',
        'treat',
        'surprised me',
        'mabait',
        'kabaitan',
        'tumulong',
        'tinulungan',
        'sinuportahan',
        'regalo',
        'libre',
      ],
      supporting: [
        'coworker',
        'colleague',
        'teacher',
        'stranger',
        'neighbor',
        'neighbour',
        'katrabaho',
        'guro',
        'kapitbahay',
        'help',
        'support',
      ],
    ),
    _FlowerTheme(
      flowerType: 'bluebell',
      theme: 'a small, ordinary good thing',
      reason:
          'Bluebells mean humility and lasting care, a fit for something small '
          'that quietly held you.',
      strong: [
        'small',
        'little',
        'simple',
        'ordinary',
        'everyday',
        'tiny',
        'meal',
        'food',
        'dinner',
        'lunch',
        'breakfast',
        'home cooked',
        'maliit',
        'payak',
        'araw araw',
        'pagkain',
        'kumain',
        'ulam',
        'niluto',
      ],
      supporting: [
        'moment',
        'sandali',
        'bagay',
        'noticed',
        'napansin',
        'enough',
      ],
    ),
  ];

  static const _neutralSuggestion = FlowerSuggestion(
    flowerType: neutralFlower,
    theme: 'a moment worth keeping',
    reason:
        'Sunflowers hold joy, warmth and hope — a good home for any gratitude.',
    confidence: 0,
  );

  static FlowerSuggestion suggestFor(String content) {
    final normalized = _normalize(content);
    if (normalized.trim().isEmpty) return _neutralSuggestion;

    var bestTheme = _themes.first;
    var bestScore = 0.0;
    var runnerUp = 0.0;

    for (final theme in _themes) {
      final score = _scoreFor(normalized, theme);
      if (score > bestScore) {
        runnerUp = bestScore;
        bestScore = score;
        bestTheme = theme;
      } else if (score > runnerUp) {
        runnerUp = score;
      }
    }

    if (bestScore <= 0) return _neutralSuggestion;

    // Confidence rewards a clear winner: a strong signal that also stands
    // apart from the next-best essence.
    final separation = (bestScore - runnerUp) / bestScore;
    final strength = (bestScore / 4).clamp(0.0, 1.0);
    final confidence = (strength * 0.65 + separation * 0.35).clamp(0.0, 1.0);

    return FlowerSuggestion(
      flowerType: bestTheme.flowerType,
      theme: bestTheme.theme,
      reason: bestTheme.reason,
      confidence: confidence,
    );
  }

  /// True when [flowerType] is the bloom this note would have been matched to.
  static bool isSuggestedFor(String content, String flowerType) {
    final suggestion = suggestFor(content);
    return suggestion.isConfident && suggestion.flowerType == flowerType;
  }

  static double _scoreFor(String normalized, _FlowerTheme theme) {
    var score = 0.0;
    for (final keyword in theme.strong) {
      if (_containsPhrase(normalized, keyword)) score += 2.0;
    }
    for (final keyword in theme.supporting) {
      if (_containsPhrase(normalized, keyword)) score += 0.75;
    }
    return score;
  }

  /// Matches on word boundaries so "rest" does not fire inside "restless".
  static bool _containsPhrase(String normalized, String phrase) {
    final needle = _normalize(phrase);
    return needle.trim().isNotEmpty && normalized.contains(needle);
  }

  /// Lowercases, strips punctuation and pads with spaces so every word is
  /// surrounded by separators for boundary matching.
  static String _normalize(String value) {
    final lowered = value.toLowerCase().replaceAll(RegExp('[’]'), "'");
    final cleaned = lowered.replaceAll(RegExp("[^a-z0-9']+"), ' ');
    return ' ${cleaned.trim()} ';
  }
}
