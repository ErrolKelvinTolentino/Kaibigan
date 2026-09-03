import '../gratitude_garden/gratitude_model.dart';
import '../journaling/journal_model.dart';
import '../mood_tracking/mood_model.dart';
import '../routines/routine_model.dart';

class WeeklyReflectionNarrative {
  final String evidence;
  final String pattern;
  final String experiment;

  const WeeklyReflectionNarrative({
    required this.evidence,
    required this.pattern,
    required this.experiment,
  });

  String toMarkdown() => '''
**Evidence**

$evidence

**Pattern**

$pattern

**One experiment**

$experiment
''';

  static WeeklyReflectionNarrative? tryParse(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    final headings = <String, RegExpMatch?>{
      'evidence': _heading('Evidence').firstMatch(normalized),
      'pattern': _heading('Pattern').firstMatch(normalized),
      'experiment': _heading('One experiment').firstMatch(normalized),
    };
    final evidenceHeading = headings['evidence'];
    final patternHeading = headings['pattern'];
    final experimentHeading = headings['experiment'];
    if (evidenceHeading == null ||
        patternHeading == null ||
        experimentHeading == null ||
        evidenceHeading.start >= patternHeading.start ||
        patternHeading.start >= experimentHeading.start) {
      return null;
    }

    final evidence =
        normalized.substring(evidenceHeading.end, patternHeading.start).trim();
    final pattern = normalized
        .substring(patternHeading.end, experimentHeading.start)
        .trim();
    final experiment = normalized.substring(experimentHeading.end).trim();
    if (evidence.isEmpty || pattern.isEmpty || experiment.isEmpty) return null;

    return WeeklyReflectionNarrative(
      evidence: evidence,
      pattern: pattern,
      experiment: experiment,
    );
  }

  static RegExp _heading(String label) => RegExp(
        '^\\s*(?:#{1,6}\\s*)?(?:\\*\\*)?${RegExp.escape(label)}(?:\\*\\*)?\\s*:?\\s*\$',
        caseSensitive: false,
        multiLine: true,
      );
}

class WeeklyReflectionSnapshot {
  final DateTime start;
  final DateTime endExclusive;
  final int moodCheckIns;
  final int journalEntries;
  final int gratitudeEntries;
  final int completedRoutines;
  final int activeDays;
  final double? averageMood;
  final double? averageEnergy;
  final double? averageStress;
  final double? averageSleep;
  final double? moodTrend;
  final double? routineMoodDelta;
  final int pairedRoutineMoodDays;
  final double? sleepMoodDelta;
  final int pairedSleepMoodDays;
  final List<String> journalExcerpts;
  final List<String> gratitudeExcerpts;

  const WeeklyReflectionSnapshot({
    required this.start,
    required this.endExclusive,
    required this.moodCheckIns,
    required this.journalEntries,
    required this.gratitudeEntries,
    required this.completedRoutines,
    required this.activeDays,
    required this.averageMood,
    required this.averageEnergy,
    required this.averageStress,
    required this.averageSleep,
    required this.moodTrend,
    required this.routineMoodDelta,
    required this.pairedRoutineMoodDays,
    required this.sleepMoodDelta,
    required this.pairedSleepMoodDays,
    required this.journalExcerpts,
    required this.gratitudeExcerpts,
  });

  bool get hasData => activeDays > 0;

  /// Identifies the aggregate data behind a saved reflection without storing
  /// any raw journal, gratitude, or routine content.
  String get dataSignature => [
        start.toIso8601String(),
        moodCheckIns,
        journalEntries,
        gratitudeEntries,
        completedRoutines,
        activeDays,
        _signatureValue(averageMood),
        _signatureValue(averageEnergy),
        _signatureValue(averageStress),
        _signatureValue(averageSleep),
        _signatureValue(moodTrend),
        _signatureValue(routineMoodDelta),
        pairedRoutineMoodDays,
        _signatureValue(sleepMoodDelta),
        pairedSleepMoodDays,
        _contentSignature(journalExcerpts),
        _contentSignature(gratitudeExcerpts),
      ].join('|');

  static String _signatureValue(double? value) =>
      value == null ? '-' : value.toStringAsFixed(4);

  static int _contentSignature(Iterable<String> values) {
    var hash = 17;
    for (final unit in values.join('\u241e').codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash;
  }

  String toCompactPrompt({required String language}) {
    String average(double? value) =>
        value == null ? 'not logged' : '${value.toStringAsFixed(1)}/5';
    String difference(double? value) => value == null
        ? 'not enough comparable data'
        : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} points';
    final scores = 'mood ${average(averageMood)}, '
        'energy ${average(averageEnergy)}, stress ${average(averageStress)}, '
        'sleep ${average(averageSleep)}';
    final comparisons = 'later-minus-earlier mood '
        '${difference(moodTrend)}; routine-minus-non-routine mood '
        '${difference(routineMoodDelta)} across $pairedRoutineMoodDays mood '
        'days; better-sleep-minus-lower-sleep mood '
        '${difference(sleepMoodDelta)} across $pairedSleepMoodDays mood days';
    final counts = '$activeDays of 7 active days, $moodCheckIns mood '
        'check-ins, $journalEntries journal entries, $gratitudeEntries '
        'gratitude notes, and $completedRoutines completed routines';
    String context(String label, List<String> excerpts) => excerpts.isEmpty
        ? '$label: none.'
        : '$label:\n${excerpts.map((text) => '- $text').join('\n')}';
    final journalContext = context(
      language == 'filipino'
          ? 'Mga isinulat ng user sa journal ngayong linggo'
          : 'User-authored journal entries from this week',
      journalExcerpts,
    );
    final gratitudeContext = context(
      language == 'filipino'
          ? 'Mga isinulat na pasasalamat ngayong linggo'
          : 'User-authored gratitude notes from this week',
      gratitudeExcerpts,
    );
    final intro = language == 'filipino'
        ? 'Gumawa ng malinaw at makataong pagninilay sa huling pitong araw. '
            'Gawing pangunahing konteksto ang sariling mga salita ng user; '
            'suporta lamang ang check-in data.'
        : 'Create a clear, human weekly reflection. Treat the user\'s own '
            'words as the primary context; use check-in data only as support.';
    return '$intro\n\n$journalContext\n\n$gratitudeContext\n\n'
        'Check-in context: $counts. Average scores on five-point scales: '
        '$scores. Comparisons: $comparisons.';
  }
}

class WeeklyReflectionService {
  static WeeklyReflectionNarrative buildLocalNarrative(
    WeeklyReflectionSnapshot snapshot, {
    required String language,
  }) {
    final filipino = language == 'filipino';
    String checkInSummary() {
      if (snapshot.moodCheckIns == 0) {
        return filipino
            ? 'Walang mood check-in ngayong linggo.'
            : 'There were no mood check-ins this week.';
      }
      String level(double? value, {required bool highIsHard}) {
        if (value == null) return filipino ? 'hindi na-log' : 'not logged';
        final descriptor = switch (value) {
          >= 4.5 => highIsHard
              ? (filipino ? 'napakataas' : 'very high')
              : (filipino ? 'napakaganda' : 'very positive'),
          >= 3.5 => highIsHard
              ? (filipino ? 'mataas' : 'high')
              : (filipino ? 'maganda' : 'positive'),
          >= 2.5 => filipino ? 'nasa gitna' : 'around the middle',
          >= 1.5 => highIsHard
              ? (filipino ? 'mababa' : 'low')
              : (filipino ? 'mababa' : 'low'),
          _ => highIsHard
              ? (filipino ? 'napakababa' : 'very low')
              : (filipino ? 'napakababa' : 'very low'),
        };
        return descriptor;
      }

      return filipino
          ? 'Sa ${snapshot.moodCheckIns} mood check-in, ang mood ay '
              '${level(snapshot.averageMood, highIsHard: false)}, ang energy ay '
              '${level(snapshot.averageEnergy, highIsHard: false)}, at ang stress ay '
              '${level(snapshot.averageStress, highIsHard: true)}.'
          : 'Across ${snapshot.moodCheckIns} mood check-in${snapshot.moodCheckIns == 1 ? '' : 's'}, '
              'mood felt ${level(snapshot.averageMood, highIsHard: false)}, energy was '
              '${level(snapshot.averageEnergy, highIsHard: false)}, and stress was '
              '${level(snapshot.averageStress, highIsHard: true)}.';
    }

    final journalEvidence = snapshot.journalExcerpts.take(2).toList();
    final ownWords = journalEvidence.isEmpty
        ? (filipino
            ? 'Walang journal entry na pagbabatayan ngayong linggo.'
            : 'There was no journal entry to reflect on this week.')
        : journalEvidence.length == 1
            ? (filipino
                ? 'Sa journal mo, isinulat mo: “${journalEvidence.first}”'
                : 'In your journal, you wrote: “${journalEvidence.first}”')
            : (filipino
                ? 'Sa journal mo, isinulat mo ang “${journalEvidence[0]}” at “${journalEvidence[1]}”.'
                : 'Your journal included “${journalEvidence[0]}” and “${journalEvidence[1]}”.');

    final evidence = filipino
        ? '$ownWords ${checkInSummary()}'
        : '$ownWords ${checkInSummary()}';

    String pattern;
    String experiment;
    if (snapshot.activeDays < 3) {
      final anchor = journalEvidence.isEmpty ? null : journalEvidence.last;
      pattern = anchor == null
          ? (filipino
              ? 'Hindi pa sapat ang ilang active days para sabihing may repeated pattern. Mas tapat na ituring itong starting point kaysa conclusion.'
              : 'There are not yet enough active days to claim a repeated pattern. It is more honest to treat this as a starting point than a conclusion.')
          : (filipino
              ? 'Mahalaga ang sandaling isinulat mo, pero hindi pa sapat ang ilang active days para sabihing paulit-ulit itong pattern. Panimulang konteksto ito, hindi konklusyon.'
              : 'The moment you wrote about matters, but there are not yet enough active days to call it a repeated pattern. Treat it as meaningful context, not a conclusion.');
      experiment = anchor == null
          ? (filipino
              ? 'Mag-check in sa parehong oras sa tatlong araw sa susunod na linggo. Isama ang mood, energy, stress, at sleep para magkaroon ng mas malinaw na comparison.'
              : 'Check in at roughly the same time on three days next week. Include mood, energy, stress, and sleep so the comparison becomes clearer.')
          : (filipino
              ? 'Balikan ang sandaling “$anchor” at tapusin ang isang pangungusap: “Ang kailangan ko noon ay…”'
              : 'Return to “$anchor” and finish one sentence: “What I needed then was…”');
    } else if (snapshot.sleepMoodDelta != null &&
        snapshot.sleepMoodDelta!.abs() >= 0.5) {
      pattern = filipino
          ? 'Sa mga araw na may sleep data, ang mood difference sa better-sleep at lower-sleep days ay ${snapshot.sleepMoodDelta!.toStringAsFixed(1)} points. Association ito, hindi patunay na sleep lang ang sanhi.'
          : 'Across days with sleep data, the mood difference between better-sleep and lower-sleep days was ${snapshot.sleepMoodDelta!.toStringAsFixed(1)} points. This is an association, not proof that sleep was the cause.';
      experiment = filipino
          ? 'Pumili ng isang realistic na sleep anchor—halimbawa, parehong wake time—at mag-log bago at pagkatapos nito sa tatlong araw.'
          : 'Choose one realistic sleep anchor, such as a consistent wake time, and log before and after it on three days.';
    } else if (snapshot.routineMoodDelta != null &&
        snapshot.routineMoodDelta!.abs() >= 0.5) {
      pattern = filipino
          ? 'Nagkaiba ng ${snapshot.routineMoodDelta!.toStringAsFixed(1)} points ang mood sa routine at non-routine days. Posibleng signal ito, pero maaari ring may ibang dahilan.'
          : 'Mood differed by ${snapshot.routineMoodDelta!.toStringAsFixed(1)} points between routine and non-routine days. That may be a useful signal, though other factors could explain it.';
      experiment = filipino
          ? 'Ulitin ang isang maikling routine sa tatlong comparable days at mag-check in bago at pagkatapos para masubukan ang pattern.'
          : 'Repeat one short routine on three comparable days and check in before and after it to test the pattern.';
    } else {
      pattern = journalEvidence.isNotEmpty
          ? (filipino
              ? 'Mas malinaw ang linggo sa mga salitang isinulat mo kaysa sa mga score lamang. Ipinapakita ng mga sandaling ito kung ano ang bumabalik sa isip mo, pero kailangan pa rin ng sariling pagtingin mo para malaman kung ano ang pinakamahalaga.'
              : 'Your own words give this week more meaning than the scores alone. These moments show what returned to your mind, while leaving you room to decide what mattered most.')
          : (filipino
              ? 'May activity ngayong linggo, pero walang journal text na nagbibigay ng sapat na konteksto para sa makabuluhang pattern.'
              : 'There was activity this week, but no journal text to give it enough context for a meaningful pattern.');
      final anchor = journalEvidence.isEmpty ? null : journalEvidence.last;
      experiment = anchor == null
          ? (filipino
              ? 'Sa susunod na check-in, magsulat ng isang pangungusap tungkol sa nangyari at isang pangungusap tungkol sa kailangan mo.'
              : 'At your next check-in, write one sentence about what happened and one sentence about what you needed.')
          : (filipino
              ? 'Balikan ang sandaling “$anchor” at tapusin ang isang pangungusap: “Ang kailangan ko noon ay…”'
              : 'Return to “$anchor” and finish one sentence: “What I needed then was…”');
    }

    return WeeklyReflectionNarrative(
      evidence: evidence,
      pattern: pattern,
      experiment: experiment,
    );
  }

  static WeeklyReflectionSnapshot build({
    required DateTime now,
    Iterable<MoodLog> moods = const [],
    Iterable<JournalEntry> journals = const [],
    Iterable<GratitudeEntry> gratitudes = const [],
    Iterable<RoutineLog> routines = const [],
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final end = today.add(const Duration(days: 1));
    bool isRecent(DateTime date) => !date.isBefore(start) && date.isBefore(end);
    String dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

    final recentMoods = moods.where((item) => isRecent(item.createdAt)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recentJournals = journals
        .where((item) => isRecent(item.createdAt))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recentGratitudes = gratitudes
        .where((item) => isRecent(item.createdAt))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recentRoutines =
        routines.where((item) => isRecent(item.completedAt)).toList();

    final active = <String>{
      ...recentMoods.map((item) => dayKey(item.createdAt)),
      ...recentJournals.map((item) => dayKey(item.createdAt)),
      ...recentGratitudes.map((item) => dayKey(item.createdAt)),
      ...recentRoutines.map((item) => dayKey(item.completedAt)),
    };

    final moodByDay = <String, List<int>>{};
    final sleepByDay = <String, List<int>>{};
    for (final mood in recentMoods) {
      moodByDay
          .putIfAbsent(dayKey(mood.createdAt), () => [])
          .add(mood.moodScore);
      sleepByDay
          .putIfAbsent(dayKey(mood.createdAt), () => [])
          .add(mood.sleepQuality);
    }
    final routineDays = <String>{};
    for (final routine in recentRoutines) {
      final key = dayKey(routine.completedAt);
      routineDays.add(key);
      if (routine.sleepFeeling != null) {
        // An explicit sleep log is a stronger signal than the generic mood
        // check-in default, so it replaces that day's other sleep values.
        sleepByDay[key] = [routine.sleepFeeling!.score];
      }
    }

    final dailyMood =
        moodByDay.map((key, values) => MapEntry(key, _averageInts(values)));
    final dailySleep =
        sleepByDay.map((key, values) => MapEntry(key, _averageInts(values)));
    final routineMood = <double>[];
    final nonRoutineMood = <double>[];
    for (final entry in dailyMood.entries) {
      (routineDays.contains(entry.key) ? routineMood : nonRoutineMood)
          .add(entry.value);
    }
    final betterSleepMood = <double>[];
    final lowerSleepMood = <double>[];
    for (final entry in dailyMood.entries) {
      final sleep = dailySleep[entry.key];
      if (sleep == null) continue;
      (sleep >= 4 ? betterSleepMood : lowerSleepMood).add(entry.value);
    }

    double? averageField(int Function(MoodLog item) field) => recentMoods
            .isEmpty
        ? null
        : recentMoods.map(field).reduce((a, b) => a + b) / recentMoods.length;
    final chronologicalMood = dailyMood.values.toList();
    double? moodTrend;
    if (chronologicalMood.length >= 4) {
      final midpoint = chronologicalMood.length ~/ 2;
      moodTrend = _average(chronologicalMood.sublist(midpoint)) -
          _average(chronologicalMood.sublist(0, midpoint));
    }

    return WeeklyReflectionSnapshot(
      start: start,
      endExclusive: end,
      moodCheckIns: recentMoods.length,
      journalEntries: recentJournals.length,
      gratitudeEntries: recentGratitudes.length,
      completedRoutines: recentRoutines.length,
      activeDays: active.length,
      averageMood: averageField((item) => item.moodScore),
      averageEnergy: averageField((item) => item.energyLevel),
      averageStress: averageField((item) => item.stressLevel),
      averageSleep: dailySleep.isEmpty ? null : _average(dailySleep.values),
      moodTrend: moodTrend,
      routineMoodDelta: routineMood.isNotEmpty && nonRoutineMood.isNotEmpty
          ? _average(routineMood) - _average(nonRoutineMood)
          : null,
      pairedRoutineMoodDays: routineMood.length + nonRoutineMood.length,
      sleepMoodDelta: betterSleepMood.isNotEmpty && lowerSleepMood.isNotEmpty
          ? _average(betterSleepMood) - _average(lowerSleepMood)
          : null,
      pairedSleepMoodDays: betterSleepMood.length + lowerSleepMood.length,
      journalExcerpts: recentJournals
          .map((entry) => _excerpt(entry.content))
          .where((text) => text.isNotEmpty)
          .take(5)
          .toList(growable: false),
      gratitudeExcerpts: recentGratitudes
          .map((entry) => _excerpt(entry.content, maxLength: 180))
          .where((text) => text.isNotEmpty)
          .take(7)
          .toList(growable: false),
    );
  }

  static String _excerpt(String value, {int maxLength = 320}) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= maxLength) return clean;
    final shortened = clean.substring(0, maxLength);
    final lastSpace = shortened.lastIndexOf(' ');
    return '${shortened.substring(0, lastSpace > 80 ? lastSpace : maxLength).trim()}…';
  }

  static double _averageInts(Iterable<int> values) =>
      values.reduce((a, b) => a + b) / values.length;
  static double _average(Iterable<double> values) =>
      values.reduce((a, b) => a + b) / values.length;
}
