import '../gratitude_garden/gratitude_model.dart';
import '../home/activity_feedback_store.dart';
import '../insights/wellness_analytics.dart';
import '../journaling/journal_model.dart';
import '../mood_tracking/mood_model.dart';
import '../routines/routine_model.dart';
import '../../core/services/ai_service.dart';

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
      'evidence': _heading(r'(?:Evidence|Katibayan|Ebidensya|What you shared|Ang ibinahagi mo)').firstMatch(normalized),
      'pattern': _heading(r'(?:Pattern|Patern|Mga pattern|What may connect|Posibleng ugnayan)').firstMatch(normalized),
      'experiment': _heading(r'(?:One\s+experiment|Experiment|Isang\s+eksperimento|Eksperimento|Try this next|Subukan ito)').firstMatch(normalized),
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

  static RegExp _heading(String pattern) => RegExp(
        r'^\s*(?:#{1,6}\s*)?(?:\d+[\.\)]\s*)?(?:\*\*)?(?:' +
            pattern +
            r')(?::?\s*\*\*|\*\*\s*:?|:)?\s*$',
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
  final WellnessSnapshot wellness;

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
    required this.wellness,
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
        _contentSignature([wellness.toPromptContext()]),
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
    return '$intro\n\n<user_writing>\n$journalContext\n\n$gratitudeContext\n</user_writing>\n\n'
        'Check-in context: $counts. Average scores on five-point scales: '
        '$scores. Higher mood, energy and sleep quality mean more positive '
        'ratings; higher stress means more stress. Comparisons: $comparisons. '
        'Within-week comparisons need at least 3 recorded days in each group. '
        'They are descriptive associations, never evidence of cause.\n\n'
        '${wellness.toPromptContext()}';
  }
}

class WeeklyReflectionService {
  static WeeklyReflectionNarrative buildLocalNarrative(
    WeeklyReflectionSnapshot snapshot, {
    required String language,
  }) {
    final filipino = language == 'filipino';

    // 0. Safety Intercept: Detect crisis or self-harm content in weekly writing
    final hasCrisis = snapshot.journalExcerpts.any((e) => AIService.isCrisisMessage(e)) ||
        snapshot.gratitudeExcerpts.any((e) => AIService.isCrisisMessage(e));
    if (hasCrisis) {
      final crisisNarrative = WeeklyReflectionNarrative.tryParse(
        AIService.getWeeklyReflectionCrisisResponse(language),
      );
      if (crisisNarrative != null) return crisisNarrative;
    }

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

    final safeJournalExcerpts = snapshot.journalExcerpts
        .where((e) => !AIService.isCrisisMessage(e))
        .toList();
    final journalEvidence = safeJournalExcerpts.take(2).toList();
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

    final evidence = '$ownWords ${checkInSummary()}';

    // Extract wellness themes from non-crisis user writing
    final allWriting = (safeJournalExcerpts + snapshot.gratitudeExcerpts)
        .join(' ')
        .toLowerCase();

    final hasPerfectionTheme = RegExp(
      r'\b(perfect|perpekto|satisfaction|good enough|sapat|enough|pressure|standard|mistake|failure|fail|hindi kailangan)\b',
      caseSensitive: false,
    ).hasMatch(allWriting);

    final hasFriendTheme = RegExp(
      r'\b(friend|friends|kaibigan|barkada|tropa|kasama|activity with|classmate|roommate)\b',
      caseSensitive: false,
    ).hasMatch(allWriting);

    final hasFatigueTheme = RegExp(
      r'\b(energized|energy|tired|pagod|exhausted|drain|drained|hina|low energy|puyat|sleepy|antok)\b',
      caseSensitive: false,
    ).hasMatch(allWriting);

    final hasGratitudeTheme = snapshot.gratitudeExcerpts.isNotEmpty ||
        RegExp(
          r'\b(grateful|gratitude|appreciate|salamat|pasasalamat|thankful|blessed|smile)\b',
          caseSensitive: false,
        ).hasMatch(allWriting);

    final hasStressTheme = RegExp(
      r'\b(stress|stressed|anxious|anxiety|overwhelm|overwhelmed|kaba|takot|worried|bigat)\b',
      caseSensitive: false,
    ).hasMatch(allWriting);

    String pattern;
    String experiment;

    if (hasPerfectionTheme) {
      pattern = filipino
          ? 'Isang mahalagang hakbang sa self-compassion: Napansin mong hindi kailangang maging perpekto ang araw para makaramdam ng kasiyahan. Ang pagbitiw sa labis na pamantayan ay nagbibigay-daan upang ma-enjoy ang bawat sandali nang walang mabigat na presyur sa sarili.'
          : 'A powerful shift toward self-compassion: You noted that a day does not have to be perfect to bring genuine satisfaction. When you release rigid standards and allow "good enough" to be enough, it creates space to enjoy moments of connection without demanding 100% from yourself.';
      experiment = filipino
          ? 'Subukan ang "sapat na" bukas: Sa isang gawain kung saan nakakaramdam ka ng presyur na magpakaperpekto, huminto sa 80% at sabihin sa sarili: "Sapat na ito para sa araw na ito." Pansinin ang ginhawa sa iyong katawan.'
          : 'Practice "good enough" tomorrow: In one task or moment where you feel internal pressure, pause, stop at 80%, and tell yourself: "This is good enough for today." Notice how your body feels when you let go of the pressure.';
    } else if (hasFriendTheme && hasFatigueTheme) {
      pattern = filipino
          ? 'Koneksyon kasabay ng mababang lakas: Naglaan ka ng oras sa mga kaibigan kahit mababa ang iyong energy. Nakatutulong ang suporta ng iba bilang sandigan, ngunit mahalaga ring pakinggan ang pangangailangan ng iyong katawan na magpahinga.'
          : 'Connection alongside low battery: You spent meaningful time with friends even while navigating drained energy. Social warmth can offer a comforting anchor, but honoring your physical need to recharge is equally vital.';
      experiment = filipino
          ? 'Maglaan ng tahimik na oras ng pahinga: Mag-set ng 20 hanggang 30 minuto bukas para sa payapang pahinga—walang gawain o cellphone—upang muling makapag-recharge ang iyong katawan.'
          : 'Protect a quiet recharge window: Schedule 20 to 30 minutes tomorrow solely for restorative rest—no chores, no screens, just quiet downtime—to let your battery replenish.';
    } else if (hasFriendTheme) {
      pattern = filipino
          ? 'Koneksyon bilang sandigan: Lumitaw sa iyong mga tala ang kahalagahan ng pakikipag-ugnayan sa iba. Ang presensya ng mga taong sumusuporta sa iyo ay naghatid ng ginhawa at pananaw sa iyong linggo.'
          : 'Social connection as a grounding anchor: Your reflections highlighted the value of spending time with others. Being around supportive people provided warmth and helpful perspective during your week.';
      experiment = filipino
          ? 'Magpadala ng maikling pasasalamat: Mag-message o magpadala ng emoji sa isang kaibigang nagpasaya sa iyo ngayong linggo upang ipaalam na pinahahalagahan mo ang inyong pagsasama.'
          : 'Send a zero-pressure note of appreciation: Share a brief text or emoji with a friend whose company you enjoyed, simply letting them know you valued your time together.';
    } else if (hasFatigueTheme) {
      pattern = filipino
          ? 'Pagkilala sa pagod nang may unawa: Hinarap mo ang mga sandaling mababa ang iyong lakas. Ang pag-amin sa pagod nang walang paninisi sa sarili ay mahalaga upang maprotektahan ang iyong kalusugan.'
          : 'Navigating fatigue with gentleness: You experienced moments where your energy felt depleted. Acknowledging physical tiredness without self-blame is key to pacing yourself sustainably.';
      experiment = filipino
          ? 'Magpahinga nang walang pag-aalinlangan: Pahintulutan ang sariling tanggihan ang isang hindi apurahang gawain ngayong linggo upang maipahinga ang katawan at isipan.'
          : 'Take a deliberate low-battery pause: Give yourself permission to say no to one non-essential task this week, and dedicate that time to unhurried rest.';
    } else if (hasGratitudeTheme) {
      pattern = filipino
          ? 'Pagpansin sa maliliit na biyaya: Naitala sa iyong pasasalamat ang magagandang sandali sa gitna ng mga hamon. Ang pagkilala sa kabutihan ay nagpapatibay sa iyong kalooban at nagbibigay ng kapanatagan.'
          : 'Finding anchors in small moments: Your gratitude reflections captured bright spots amidst daily demands. Training your mind to notice safety and appreciation builds quiet emotional resilience.';
      experiment = filipino
          ? 'Damhin ang isang payapang sandali bukas: Maglaan ng dalawang minuto upang damhin ang init ng inumin, sariwang hangin, o liwanag ng umaga nang walang pagmamadali.'
          : 'Savor one sensory detail tomorrow: Spend two quiet minutes savoring one simple moment—a warm drink, fresh air, or quiet morning light—without rushing.';
    } else if (hasStressTheme) {
      pattern = filipino
          ? 'Pagharap sa presyur at bigat: Hinarap mo ang mga sandali ng stress at pag-aalala. Ang pagkilala rito ay tumutulong upang hindi mapuno ang iyong buong araw ng pagod.'
          : 'Carrying mental load and tension: You navigated moments of stress and high pressure. Acknowledging that weight helps create distance from it, keeping stress from defining your entire week.';
      experiment = filipino
          ? 'Subukan ang 3-3-3 grounding exercise: Kapag nakaramdam ng kaba, huminto at magbanggit ng 3 bagay na nakikita, 3 tunog na naririnig, at igalaw ang 3 bahagi ng katawan.'
          : 'Practice the 3-3-3 grounding pause: When pressure rises, pause and name 3 things you see, 3 sounds you hear, and move 3 parts of your body to ground yourself.';
    } else if (snapshot.sleepMoodDelta != null &&
        snapshot.sleepMoodDelta!.abs() >= 0.5) {
      pattern = filipino
          ? 'Sa mga araw na may sleep data, ang mood difference sa better-sleep at lower-sleep days ay ${snapshot.sleepMoodDelta!.toStringAsFixed(1)} points. Malaki ang maitutulong ng maayos na tulog sa iyong katatagan.'
          : 'Across days with sleep data, the mood difference between better-sleep and lower-sleep days was ${snapshot.sleepMoodDelta!.toStringAsFixed(1)} points. Rest directly supported your emotional bandwidth.';
      experiment = filipino
          ? 'Sa susunod na tala ng tulog, isama ang haba ng tulog at pakiramdam pagkagising. Pansinin kung paano mo nararamdaman ang araw nang walang pagmamadali.'
          : 'At your next sleep log, note both the hours and how rested you feel. Notice how the day feels, without needing to prove an effect.';
    } else if (snapshot.routineMoodDelta != null &&
        snapshot.routineMoodDelta!.abs() >= 0.5) {
      pattern = filipino
          ? 'Nagkaiba ng ${snapshot.routineMoodDelta!.toStringAsFixed(1)} points ang mood sa routine at non-routine days. Posibleng senyales ito na nakapagpapanatag ang iyong mga gawi.'
          : 'Mood differed by ${snapshot.routineMoodDelta!.toStringAsFixed(1)} points between routine and non-routine days. Having predictable, caring rituals helps anchor your day.';
      experiment = filipino
          ? 'Ulitin ang isang maikling routine sa tatlong comparable days at mag-check in bago at pagkatapos para masubukan ang epekto nito.'
          : 'Repeat one short routine on three comparable days and check in before and after it to test how it supports you.';
    } else if (snapshot.activeDays < 3) {
      final anchor = journalEvidence.isEmpty ? null : journalEvidence.last;
      pattern = anchor == null
          ? (filipino
              ? 'Hindi pa sapat ang ilang active days para sabihing may repeated pattern. Mas tapat na ituring itong starting point kaysa conclusion.'
              : 'There are not yet enough active days to claim a repeated pattern. It is more honest to treat this as a starting point than a conclusion.')
          : (filipino
              ? 'Mahalaga ang mga sandaling naitala mo. Bagamat hindi pa sapat ang ilang active days para sa paulit-ulit na pattern, nagbibigay ito ng makabuluhang konteksto sa iyong linggo.'
              : 'The reflections you recorded provide meaningful context into your week. While there are not yet enough active days to call it a repeated pattern, the moments you wrote about offer a valuable window into what mattered most.');
      experiment = anchor == null
          ? (filipino
              ? 'Kung kaya, mag-check in sa halos parehong oras sa tatlong araw sa susunod na linggo. Pansinin ang damdamin, lakas, at stress; itala nang hiwalay ang tulog. Puwedeng lumiban kung kailangan.'
              : 'If it fits your week, check in at roughly the same time on three days next week. Notice mood, energy, and stress; log sleep separately. Skipping a day is okay.')
          : (filipino
              ? 'Pumili ng isang payapang sandali bukas upang kumustahin ang sarili: Pansinin ang nararamdaman mo ngayon nang walang paghuhusga.'
              : 'Take one quiet moment tomorrow to check in with yourself: Notice what your mind and body need without trying to fix or evaluate anything.');
    } else {
      pattern = journalEvidence.isNotEmpty
          ? (filipino
              ? 'Nagbibigay ng malalim na konteksto ang iyong mga isinulat. Ang paglalaan ng oras upang magmuni-muni ay nagpapakita ng iyong katatagan at pag-aalaga sa sarili.'
              : 'Your writing reveals thoughtful self-awareness and honesty. Taking intentional time to reflect is itself a powerful practice of resilience.')
          : (filipino
              ? 'Ipinapakita ng iyong mga tala ang isang maingat at balanseng ritmo. Ang bawat pagtatala ay hakbang sa pagkilala sa sarili.'
              : 'Your check-ins show a steady, observant rhythm across the week. Each log is a small step in staying connected to yourself.');
      experiment = filipino
          ? 'Sa susunod na check-in, magsulat ng isang pangungusap tungkol sa nagdulot ng kapayapaan at isang pangungusap tungkol sa kailangan mo.'
          : 'At your next check-in, write one sentence about what brought you a sense of calm and one sentence about what you needed.';
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
    Iterable<ActivityFeedbackRecord> feedback = const [],
  }) {
    final wellness = WellnessAnalytics.build(
      now: now,
      moods: moods,
      routines: routines,
      journalDates: journals.map((entry) => entry.createdAt),
      gratitudeDates: gratitudes.map((entry) => entry.createdAt),
      feedback: feedback,
    );
    final start = wellness.start;
    final end = wellness.endExclusive;
    bool isRecent(DateTime date) =>
        !date.toLocal().isBefore(start) && date.toLocal().isBefore(end) &&
        !date.isAfter(now);
    String dayKey(DateTime date) => wellnessDay(date).toIso8601String();

    final recentMoods = <String, MoodLog>{
      for (final item in moods)
        if (isRecent(item.createdAt) && item.moodScore >= 1 && item.moodScore <= 5)
          item.id: item,
    }.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recentJournals = journals
        .where((item) => isRecent(item.createdAt))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recentGratitudes = gratitudes
        .where((item) => isRecent(item.createdAt))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recentRoutines = <String, RoutineLog>{
      for (final item in routines)
        if (isRecent(item.completedAt)) item.id: item,
    }.values.toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    final moodByDay = <String, List<int>>{};
    final sleepByDay = <String, List<int>>{};
    for (final mood in recentMoods) {
      moodByDay
          .putIfAbsent(dayKey(mood.createdAt), () => [])
          .add(mood.moodScore);
    }
    final routineDays = <String>{};
    for (final routine in recentRoutines) {
      final key = dayKey(routine.completedAt);
      if (routineActivity(routine) == 'routine') routineDays.add(key);
      if (routine.sleepFeeling != null) {
        // Only explicit sleep logs are sleep evidence. Generic check-in
        // defaults cannot establish sleep quality or sleep/mood associations.
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

    final chronologicalMood = dailyMood.values.toList();
    double? moodTrend;
    if (chronologicalMood.length >= 6) {
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
      completedRoutines: wellness.metrics['routine']!.count,
      activeDays: wellness.activeDays,
      averageMood: wellness.metrics['mood']!.average,
      averageEnergy: wellness.energy,
      averageStress: wellness.stress,
      averageSleep: wellness.metrics['sleep']!.average,
      moodTrend: moodTrend,
      routineMoodDelta: routineMood.length >= 3 && nonRoutineMood.length >= 3
          ? _average(routineMood) - _average(nonRoutineMood)
          : null,
      pairedRoutineMoodDays: routineMood.length + nonRoutineMood.length,
      sleepMoodDelta: betterSleepMood.length >= 3 && lowerSleepMood.length >= 3
          ? _average(betterSleepMood) - _average(lowerSleepMood)
          : null,
      pairedSleepMoodDays: betterSleepMood.length + lowerSleepMood.length,
      journalExcerpts: recentJournals.reversed
          .map((entry) => _excerpt(entry.content))
          .where((text) => text.isNotEmpty)
          .take(5)
          .toList(growable: false),
      gratitudeExcerpts: recentGratitudes.reversed
          .map((entry) => _excerpt(entry.content, maxLength: 180))
          .where((text) => text.isNotEmpty)
          .take(7)
          .toList(growable: false),
      wellness: wellness,
    );
  }

  static String cleanJournalContent(String value) {
    if (value.trim().isEmpty) return '';
    var text = value;

    // 1. Remove numbered routine questions (e.g., "1. What went well today?",
    // "2. What challenged you, and how did you respond?", "### 1. ...")
    text = text.replaceAll(
      RegExp(
        r'(?:^|\s)(?:#{1,6}\s*)?(?:\*\*)?\d+[\.\)]\s+[^?\n:]+[\?:](?:\*\*)?\s*',
        multiLine: true,
      ),
      ' ',
    );

    // 2. Remove known routine question headings if present without numbers
    text = text.replaceAll(
      RegExp(
        r'(?:^|\s)(?:What went well today|What challenged you|What did you learn|What made you smile today|Who or what supported you|What small thing do you want to savor|What is on your mind right now|What feeling needs a little space|What would feel supportive tomorrow)\??\s*',
        caseSensitive: false,
        multiLine: true,
      ),
      ' ',
    );

    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isNotEmpty) return normalized;
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _excerpt(String value, {int maxLength = 320}) {
    final clean = cleanJournalContent(value);
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
