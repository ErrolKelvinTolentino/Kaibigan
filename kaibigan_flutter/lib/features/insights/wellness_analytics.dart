import '../../core/utils/language_helper.dart';
import '../home/activity_feedback_store.dart';
import '../mood_tracking/mood_model.dart';
import '../routines/routine_model.dart';

/// Calendar arithmetic intentionally avoids subtracting 24 hours across DST.
DateTime wellnessDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

class WellnessStreak {
  const WellnessStreak(this.current, this.longest, this.todayCompleted);
  final int current;
  final int longest;
  final bool todayCompleted;

  static WellnessStreak fromDates(Iterable<DateTime> dates, {DateTime? now}) {
    final today = wellnessDay(now ?? DateTime.now());
    final days = dates.map(wellnessDay).where((d) => !d.isAfter(today)).toSet();
    var cursor = days.contains(today)
        ? today
        : DateTime(today.year, today.month, today.day - 1);
    var current = 0;
    while (days.contains(cursor)) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    final sorted = days.toList()..sort();
    var longest = 0;
    var run = 0;
    DateTime? previous;
    for (final date in sorted) {
      run = previous != null &&
              date == DateTime(previous.year, previous.month, previous.day + 1)
          ? run + 1
          : 1;
      if (run > longest) longest = run;
      previous = date;
    }
    return WellnessStreak(current, longest, days.contains(today));
  }
}

/// Only known storage identifiers count as completed practices. Opening a
/// feature and free text mentioning an activity are not completion evidence.
String routineActivity(RoutineLog log) {
  final id = log.routineId;
  if (id.startsWith('breathing_')) return 'breathing';
  if (id.startsWith('grounding_')) return 'grounding';
  if (id == 'sleep' || id.startsWith('sleep_') || log.sleepFeeling != null) {
    return 'sleep';
  }
  if (id == 'morning' ||
      id == 'midday' ||
      id == 'night' ||
      id.startsWith('custom_') || log.routineType == RoutineType.custom) {
    // Legacy individual steps also used the morning/night identifiers.
    if (log.focusOrHighlight != null ||
        log.moodScore != null ||
        log.gratitudeContent != null ||
        log.moodNote != null) {
      return 'reflection';
    }
    return 'routine';
  }
  return 'reflection';
}

/// Numeric values are read only from the app's existing persisted templates.
/// Ranges ("10+", "less than 1") stay unknown rather than becoming exact hours.
double? loggedSleepHours(RoutineLog log) {
  if (routineActivity(log) != 'sleep') return null;
  final match = RegExp(r'^Slept\s+(\d+(?:\.\d+)?)\s*(?:hrs|hours)\b',
          caseSensitive: false)
      .firstMatch(log.focusOrHighlight ?? '');
  final value = double.tryParse(match?.group(1) ?? '');
  return value != null && value >= 0 && value <= 24 ? value : null;
}

double? loggedBreathingMinutes(RoutineLog log) {
  if (routineActivity(log) != 'breathing') return null;
  final text = log.focusOrHighlight ?? '';
  if (text.startsWith('Completed a 30-second ')) return .5;
  final match = RegExp(r'^Completed (\d+) minute ').firstMatch(text);
  final value = double.tryParse(match?.group(1) ?? '');
  return value != null && value > 0 && value <= 60 ? value : null;
}

class WellnessMetric {
  const WellnessMetric(
      {required this.id,
      required this.count,
      required this.days,
      required this.previousCount,
      this.average,
      this.previousAverage,
      this.numericDays = 0,
      this.previousNumericDays = 0,
      this.totalMinutes,
      this.knownDurationCount = 0});
  final String id;
  final int count;
  final int days;
  final int previousCount;
  final double? average;
  final double? previousAverage;
  final int numericDays;
  final int previousNumericDays;
  final double? totalMinutes;
  final int knownDurationCount;
  double? get change => numericDays >= 3 &&
          previousNumericDays >= 3 &&
          average != null &&
          previousAverage != null
      ? average! - previousAverage!
      : null;
}

class WellnessObservation {
  const WellnessObservation(this.id, this.english, this.filipino, this.taglish);
  final String id;
  final String english;
  final String filipino;
  final String taglish;
  String text(String language) => LanguageHelper.pick(language,
      english: english, filipino: filipino, taglish: taglish);
}

class WellnessSnapshot {
  const WellnessSnapshot(
      {required this.start,
      required this.endExclusive,
      required this.metrics,
      required this.activeDays,
      required this.dayCounts,
      required this.observations,
      required this.sleepHours,
      required this.sleepDurationDays,
      required this.feedbackCount,
      required this.helpedCount,
      required this.stress,
      required this.energy});
  final DateTime start;
  final DateTime endExclusive;
  final Map<String, WellnessMetric> metrics;
  final int activeDays;
  final Map<DateTime, int> dayCounts;
  final List<WellnessObservation> observations;
  final double? sleepHours;
  final int sleepDurationDays;
  final int feedbackCount;
  final int helpedCount;
  final double? stress;
  final double? energy;
  bool get hasData => activeDays > 0;

  String toPromptContext() => [
        'Deterministic wellness analytics, local calendar window '
            '${start.toIso8601String()} to ${endExclusive.toIso8601String()} (exclusive).',
        'Active days: $activeDays. Missing days are unknown, not zero wellbeing.',
        for (final metric in metrics.values)
          '${metric.id}: ${metric.count} saved records on ${metric.days} days; '
              'preceding equal-length window ${metric.previousCount} records; '
              'daily-weighted score ${metric.average?.toStringAsFixed(2) ?? "unknown"}/5 '
              'from ${metric.numericDays} days; comparison delta '
              '${metric.change?.toStringAsFixed(2) ?? "insufficient days (minimum 3 each)"}. '
              '${metric.id == "breathing" ? "Known duration ${metric.totalMinutes ?? 0} minutes from ${metric.knownDurationCount} records." : ""}',
        'Sleep duration ${sleepHours?.toStringAsFixed(2) ?? "unknown"} hours '
            'from $sleepDurationDays days with exact durations. Sleep quality is separate.',
        'Self-reported helpful feedback: $helpedCount of $feedbackCount responses. '
            'Not an effectiveness rating; feedback is optional and device-local.',
        'Rules: ${observations.map((o) => o.english).join(" ")}',
        'Describe observations tentatively. Counts do not prove symptom relief; '
            'do not diagnose, infer causation, or invent missing durations or emotions.',
      ].join('\n');
}

abstract final class WellnessAnalytics {
  static WellnessSnapshot build(
      {required DateTime now,
      Iterable<MoodLog> moods = const [],
      Iterable<RoutineLog> routines = const [],
      Iterable<DateTime> journalDates = const [],
      Iterable<DateTime> gratitudeDates = const [],
      Iterable<ActivityFeedbackRecord> feedback = const [],
      int days = 7}) {
    assert(days > 0);
    final today = wellnessDay(now);
    final end = DateTime(today.year, today.month, today.day + 1);
    final start = DateTime(today.year, today.month, today.day - days + 1);
    final previousStart = DateTime(start.year, start.month, start.day - days);
    bool inWindow(DateTime value, DateTime from, DateTime until) {
      final local = value.toLocal();
      return !local.isBefore(from) &&
          local.isBefore(until) &&
          !local.isAfter(now);
    }

    final validMoods = <String, MoodLog>{
      for (final m in moods)
        if (m.moodScore >= 1 && m.moodScore <= 5) m.id: m
    }.values.toList();
    final validRoutines = <String, RoutineLog>{
      for (final r in routines)
        (r.id.isEmpty ? '${r.routineId}:${r.completedAt}' : r.id): r
    }.values.toList();
    final dates = <String, List<DateTime>>{
      'mood': validMoods.map((m) => m.createdAt).toList(),
      'sleep': [],
      'breathing': [],
      'grounding': [],
      'routine': [],
      'reflection': [],
      'journal': journalDates.toList(),
      'gratitude': gratitudeDates.toList(),
    };
    for (final r in validRoutines) {
      dates[routineActivity(r)]!.add(r.completedAt);
    }
    final dayCounts = <DateTime, int>{
      for (var i = 0; i < days; i++)
        DateTime(start.year, start.month, start.day + i): 0
    };
    for (final date in dates.values.expand((d) => d)) {
      if (inWindow(date, start, end)) {
        final day = wellnessDay(date);
        dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      }
    }
    final scores = <String, Map<DateTime, List<double>>>{
      'mood': {},
      'sleep': {},
      'hours': {},
      'stress': {},
      'energy': {}
    };
    void score(String kind, DateTime at, double value) {
      if (!inWindow(at, previousStart, end)) return;
      scores[kind]!.putIfAbsent(wellnessDay(at), () => []).add(value);
    }

    for (final m in validMoods) {
      score('mood', m.createdAt, m.moodScore.toDouble());
      if (m.stressLevel >= 1 && m.stressLevel <= 5) {
        score('stress', m.createdAt, m.stressLevel.toDouble());
      }
      if (m.energyLevel >= 1 && m.energyLevel <= 5) {
        score('energy', m.createdAt, m.energyLevel.toDouble());
      }
    }
    // Latest sleep log per calendar day represents that night's entry. This
    // prevents edits/repeated logging from weighting a night multiple times.
    final sleepByDay = <DateTime, RoutineLog>{};
    for (final r in validRoutines.where((r) => routineActivity(r) == 'sleep')) {
      if (!inWindow(r.completedAt, previousStart, end)) continue;
      final day = wellnessDay(r.completedAt);
      if (sleepByDay[day] == null ||
          r.completedAt.isAfter(sleepByDay[day]!.completedAt)) {
        sleepByDay[day] = r;
      }
    }
    for (final r in sleepByDay.values) {
      if (r.sleepFeeling != null) {
        score('sleep', r.completedAt, r.sleepFeeling!.score.toDouble());
      }
      final hours = loggedSleepHours(r);
      if (hours != null) score('hours', r.completedAt, hours);
    }
    List<double> dailyScores(String kind, DateTime from, DateTime until) =>
        scores[kind]!
            .entries
            .where((e) => !e.key.isBefore(from) && e.key.isBefore(until))
            .map((e) => e.value.reduce((a, b) => a + b) / e.value.length)
            .toList();
    double? mean(List<double> values) =>
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
    final durations = validRoutines
        .where((r) => inWindow(r.completedAt, start, end))
        .map(loggedBreathingMinutes)
        .whereType<double>()
        .toList();
    final metrics = <String, WellnessMetric>{};
    for (final entry in dates.entries) {
      final current =
          entry.value.where((d) => inWindow(d, start, end)).toList();
      final past =
          entry.value.where((d) => inWindow(d, previousStart, start)).toList();
      final currentScores = scores.containsKey(entry.key)
          ? dailyScores(entry.key, start, end)
          : <double>[];
      final pastScores = scores.containsKey(entry.key)
          ? dailyScores(entry.key, previousStart, start)
          : <double>[];
      metrics[entry.key] = WellnessMetric(
          id: entry.key,
          count: current.length,
          days: current.map(wellnessDay).toSet().length,
          previousCount: past.length,
          average: mean(currentScores),
          previousAverage: mean(pastScores),
          numericDays: currentScores.length,
          previousNumericDays: pastScores.length,
          totalMinutes: entry.key == 'breathing' && durations.isNotEmpty
              ? durations.reduce((a, b) => a + b)
              : null,
          knownDurationCount: entry.key == 'breathing' ? durations.length : 0);
    }
    final observations = <WellnessObservation>[];
    final mood = metrics['mood']!;
    if (mood.numericDays < 3) {
      observations.add(const WellnessObservation(
          'mood_sparse',
          'A few more check-in days will make mood patterns easier to read. Missing days are left blank.',
          'Mas madaling makita ang takbo ng damdamin kapag may tala sa ilan pang araw. Iniiwang blangko ang araw na walang tala.',
          'A few more check-in days can help. Blangko ang days na walang tala, at okay lang iyon.'));
    } else if (mood.change != null && mood.change!.abs() >= .4) {
      final higher = mood.change! > 0;
      observations.add(WellnessObservation(
          'mood_change',
          'Your average mood was ${higher ? "higher" : "lower"} than the preceding $days days. This describes the days you logged, not every day or a diagnosis.',
          '${higher ? "Mas mataas" : "Mas mababa"} ang karaniwang damdamin kaysa sa nakaraang $days araw. Batay lamang ito sa mga araw na may tala, at hindi ito pagsusuring medikal.',
          '${higher ? "Mas mataas" : "Mas mababa"} ang average mood kaysa sa previous $days days. Logged days lang ang batayan nito.'));
    } else {
      observations.add(const WellnessObservation(
          'mood_observe',
          'Notice which days felt easier or harder. A short note can add context that an average cannot show.',
          'Pansinin kung aling araw ang mas magaan o mabigat. Makakatulong ang maikling tala para mas maunawaan ito.',
          'Notice which days felt lighter or harder. Kahit maikling note can add context.'));
    }
    final practiceCount =
        metrics['breathing']!.count + metrics['grounding']!.count;
    if (practiceCount > 0) {
      observations.add(WellnessObservation(
          'practice',
          'You made space for $practiceCount breathing or grounding ${practiceCount == 1 ? "session" : "sessions"}. Repetition shows participation; only you can say what felt helpful.',
          'Naglaan ka ng oras para sa $practiceCount pagsasanay sa paghinga o pagtuon sa paligid. Ikaw ang makapagsasabi kung alin ang nakatulong.',
          'You made time for $practiceCount breathing or grounding sessions. Ikaw ang makapagsasabi kung what helped.'));
    }
    final sleepDays = metrics['sleep']!.days;
    if (sleepDays > 0) {
      observations.add(const WellnessObservation(
          'sleep_context',
          'Sleep duration and how rested you feel tell different stories. Try noting both when you log your next night.',
          'Magkaiba ang haba ng tulog at pakiramdam pagkagising. Subukang itala ang pareho sa susunod.',
          'Sleep hours and how rested you feel are different. Try logging both next time.'));
    }
    final responses =
        feedback.where((f) => inWindow(f.createdAt, start, end)).toList();
    return WellnessSnapshot(
        start: start,
        endExclusive: end,
        metrics: metrics,
        activeDays: dayCounts.values.where((v) => v > 0).length,
        dayCounts: dayCounts,
        observations: observations,
        sleepHours: mean(dailyScores('hours', start, end)),
        sleepDurationDays: dailyScores('hours', start, end).length,
        feedbackCount: responses.length,
        helpedCount: responses
            .where((f) => f.helpfulness == ActivityHelpfulness.helped)
            .length,
        stress: mean(dailyScores('stress', start, end)),
        energy: mean(dailyScores('energy', start, end)));
  }
}
