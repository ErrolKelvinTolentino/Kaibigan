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
      ].join('|');

  static String _signatureValue(double? value) =>
      value == null ? '-' : value.toStringAsFixed(4);

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
    if (language == 'filipino') {
      return 'Pinagsama-samang datos lamang sa huling pitong araw. Coverage '
          'at bilang: $counts. Mga average: $scores. Mga paghahambing: '
          '$comparisons.';
    }
    if (language == 'taglish') {
      return 'Seven-day aggregates only. Coverage and counts: $counts. '
          'Average scores: $scores. Within-week comparisons: $comparisons.';
    }
    return 'Seven-day aggregates only. Coverage and counts: $counts. '
        'Average scores: $scores. Within-week comparisons: $comparisons.';
  }
}

class WeeklyReflectionService {
  static WeeklyReflectionNarrative buildLocalNarrative(
    WeeklyReflectionSnapshot snapshot, {
    required String language,
  }) {
    final filipino = language == 'filipino';
    String score(double? value) => value == null
        ? (filipino ? 'hindi pa sapat ang data' : 'not enough data yet')
        : '${value.toStringAsFixed(1)}/5';

    final evidence = filipino
        ? 'May ${snapshot.activeDays} sa 7 active days, '
            '${snapshot.moodCheckIns} mood check-ins, '
            '${snapshot.journalEntries} journal entries, '
            '${snapshot.gratitudeEntries} gratitude notes, at '
            '${snapshot.completedRoutines} completed routines. '
            'Average mood: ${score(snapshot.averageMood)}; energy: '
            '${score(snapshot.averageEnergy)}; stress: '
            '${score(snapshot.averageStress)}; sleep: '
            '${score(snapshot.averageSleep)}.'
        : 'You had ${snapshot.activeDays} of 7 active days, '
            '${snapshot.moodCheckIns} mood check-ins, '
            '${snapshot.journalEntries} journal entries, '
            '${snapshot.gratitudeEntries} gratitude notes, and '
            '${snapshot.completedRoutines} completed routines. '
            'Average mood was ${score(snapshot.averageMood)}; energy '
            '${score(snapshot.averageEnergy)}; stress '
            '${score(snapshot.averageStress)}; and sleep '
            '${score(snapshot.averageSleep)}.';

    String pattern;
    String experiment;
    if (snapshot.activeDays < 3) {
      pattern = filipino
          ? 'Hindi pa sapat ang ilang active days para sabihing may repeated pattern. Mas tapat na ituring itong starting point kaysa conclusion.'
          : 'There are not yet enough active days to claim a repeated pattern. It is more honest to treat this as a starting point than a conclusion.';
      experiment = filipino
          ? 'Mag-check in sa parehong oras sa tatlong araw sa susunod na linggo. Isama ang mood, energy, stress, at sleep para magkaroon ng mas malinaw na comparison.'
          : 'Check in at roughly the same time on three days next week. Include mood, energy, stress, and sleep so the comparison becomes clearer.';
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
      pattern = filipino
          ? 'May sapat na activity para mapansin ang linggo, pero wala pang isang malakas na relationship sa routine, sleep, at mood. Hindi ibig sabihin na walang pattern—kailangan lang ng mas consistent na comparison.'
          : 'There is enough activity to notice the week, but no strong relationship between routine, sleep, and mood stands out yet. That does not mean there is no pattern—only that a more consistent comparison is needed.';
      experiment = filipino
          ? 'Pumili ng isang busy period at mag-check in bago at pagkatapos nito sa tatlong araw. Panatilihing maikli para madaling ulitin.'
          : 'Choose one busy period and check in before and after it on three days. Keep the check-in brief enough to repeat.';
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
    final recentJournals =
        journals.where((item) => isRecent(item.createdAt)).toList();
    final recentGratitudes =
        gratitudes.where((item) => isRecent(item.createdAt)).toList();
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
    );
  }

  static double _averageInts(Iterable<int> values) =>
      values.reduce((a, b) => a + b) / values.length;
  static double _average(Iterable<double> values) =>
      values.reduce((a, b) => a + b) / values.length;
}
