class LanguageHelper {
  static const Set<String> _filipinoSignals = {
    'ako',
    'akin',
    'ang',
    'ano',
    'anong',
    'ay',
    'bakit',
    'dahil',
    'gusto',
    'hindi',
    'ikaw',
    'iyong',
    'ka',
    'kami',
    'kasi',
    'ko',
    'kung',
    'lang',
    'malungkot',
    'masaya',
    'mga',
    'mo',
    'naman',
    'nang',
    'ng',
    'ngayon',
    'pagod',
    'para',
    'parang',
    'pero',
    'po',
    'pwede',
    'puwede',
    'sa',
    'salamat',
    'siya',
    'sobra',
    'sobrang',
    'tayo',
    'talaga',
    'yung',
  };

  static const Set<String> _englishSignals = {
    'and',
    'anxious',
    'are',
    'because',
    'but',
    'feel',
    'felt',
    'finished',
    'first',
    'frustrated',
    'groupmate',
    'happy',
    'hard',
    'how',
    'i',
    'im',
    'is',
    'me',
    'my',
    'need',
    'overwhelmed',
    'presentation',
    'project',
    'relieved',
    'sad',
    'school',
    'start',
    'stressed',
    'task',
    'that',
    'the',
    'this',
    'tired',
    'today',
    'want',
    'was',
    'were',
    'what',
    'work',
    'why',
    'you',
    'your',
  };

  /// Detects how the latest message is actually written. The saved app
  /// preference is used only for very short or language-neutral messages.
  static String detectContentLanguage(
    String text, {
    String fallback = 'english',
  }) {
    return detectContentLanguageOrNull(text) ?? normalize(fallback);
  }

  /// Returns null when the text is too language-neutral to make a reliable
  /// choice. Callers can then preserve the language established by recent
  /// conversation instead of switching because of replies such as "okay".
  static String? detectContentLanguageOrNull(String text) {
    final tokens = _tokens(text);
    final filipino = tokens.where(_filipinoSignals.contains).length;
    final english = tokens.where(_englishSignals.contains).length;

    if (filipino > 0 && english > 0) return 'taglish';
    if (filipino > 0) return 'filipino';
    if (english > 0) return 'english';
    return null;
  }

  /// Uses a higher evidence threshold than normal language detection. This is
  /// suitable for rejecting model drift without penalizing a borrowed term or
  /// a short quote from the user's entry.
  static bool isStrongMismatch(String text, String expectedLanguage) {
    final tokens = _tokens(text);
    final filipino = tokens.where(_filipinoSignals.contains).length;
    final english = tokens.where(_englishSignals.contains).length;
    final expected = normalize(expectedLanguage);
    if (expected == 'taglish') return false;
    if (expected == 'english') {
      return filipino >= 3 && filipino > english * 2;
    }
    return english >= 3 && english > filipino * 2;
  }

  static List<String> _tokens(String text) {
    return RegExp(r"[a-zA-ZÀ-ÿ']+")
        .allMatches(text.toLowerCase())
        .map((match) => (match.group(0) ?? '').replaceAll("'", ''))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  static String normalize(String language) {
    if (language == 'filipino' || language == 'taglish') return language;
    return 'english';
  }

  static String pick(
    String language, {
    required String english,
    required String filipino,
    String? taglish,
  }) {
    switch (normalize(language)) {
      case 'filipino':
        return filipino;
      case 'taglish':
        return taglish ?? english;
      default:
        return english;
    }
  }
}
