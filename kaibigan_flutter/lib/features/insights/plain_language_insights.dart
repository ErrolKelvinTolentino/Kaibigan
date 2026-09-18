import '../../core/utils/language_helper.dart';
import 'wellness_analytics.dart';

/// Whether a change is movement toward or away from what the person is
/// likely hoping for. Stress inverts: a higher number is a worse week.
enum InsightDirection { better, worse, steady, unknown }

/// One metric restated so it can be understood without doing arithmetic.
///
/// A panel of "3.4 / 5" tiles asks the reader to remember the scale, recall
/// last week, and work out whether 3.4 is good. Each reading answers those
/// three questions before the number is shown.
class PlainMetricReading {
  const PlainMetricReading({
    required this.id,
    required this.headline,
    required this.value,
    required this.support,
    required this.direction,
    required this.trendLabel,
    this.exactChange,
  });

  final String id;

  /// The plain-word answer: "Mostly okay days", "Running low".
  final String headline;

  /// The figure itself, kept as supporting evidence rather than the point.
  final String value;

  /// What the figure was measured from, so it can be trusted or discounted.
  final String support;

  final InsightDirection direction;

  /// The comparison in words: "a bit better than last week".
  final String trendLabel;

  /// The signed difference, when one could honestly be calculated.
  final double? exactChange;
}

/// The easiest logged day set beside the hardest one, with what else was
/// saved on each. Descriptive only: it says what accompanied each day, never
/// what caused it.
class DayContrast {
  const DayContrast({
    required this.bestDay,
    required this.bestScore,
    required this.hardestDay,
    required this.hardestScore,
    required this.bestCompanions,
    required this.hardestCompanions,
  });

  final DateTime bestDay;
  final double bestScore;
  final DateTime hardestDay;
  final double hardestScore;

  /// Activity identifiers also logged on each day.
  final List<String> bestCompanions;
  final List<String> hardestCompanions;

  double get spread => bestScore - hardestScore;
}

/// An association between two things the person logged, stated as an
/// association and nothing more.
class InsightLink {
  const InsightLink({
    required this.id,
    required this.statement,
    required this.caveat,
    required this.difference,
    required this.withDays,
    required this.withoutDays,
  });

  final String id;
  final String statement;
  final String caveat;
  final double difference;
  final int withDays;
  final int withoutDays;
}

/// Everything the weekly panel needs in order to lead with meaning instead
/// of leading with figures.
class WeekReading {
  const WeekReading({
    required this.headline,
    required this.subhead,
    required this.keyFigure,
    required this.keyFigureLabel,
    required this.metrics,
    required this.links,
    this.contrast,
  });

  /// One line that answers "how was my week?".
  final String headline;

  /// One line that answers "compared to what?".
  final String subhead;

  /// The single number worth putting in large type.
  final String keyFigure;
  final String keyFigureLabel;

  final List<PlainMetricReading> metrics;
  final List<InsightLink> links;
  final DayContrast? contrast;

  PlainMetricReading? metric(String id) {
    for (final reading in metrics) {
      if (reading.id == id) return reading;
    }
    return null;
  }
}

/// Turns a [WellnessSnapshot] into sentences.
///
/// Everything here is arithmetic on the person's own logs: no model is
/// called, nothing is inferred about days that were not logged, and no
/// association is reported as a cause.
abstract final class PlainLanguageInsights {
  /// Below this the week-to-week difference is noise on a five-point scale.
  static const double meaningfulChange = 0.4;

  /// A clear rather than marginal move.
  static const double clearChange = 1.0;

  /// A within-week grouping needs this many days on each side before it is
  /// worth stating. Two good days against one bad one is a coincidence.
  static const int minimumGroupDays = 3;

  static WeekReading read(
    WellnessSnapshot snapshot, {
    required String language,
  }) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);

    final metrics = <PlainMetricReading>[
      for (final id in snapshot.metrics.keys)
        _readMetric(snapshot, id, language),
    ];

    final mood = snapshot.metrics['mood']!;
    final days = snapshot.dayCounts.length;

    // The headline answers the question people actually arrive with, in the
    // order they would ask it: did anything change, and how did it feel?
    String headline;
    String subhead;
    if (!snapshot.hasData) {
      headline = pick('Nothing logged yet', 'Wala pang naitatala');
      subhead = pick(
        'This week has no saved moments to read. One check-in is enough to '
            'start.',
        'Wala pang naitalang sandali ngayong linggo. Sapat na ang isang '
            'check-in para magsimula.',
      );
    } else if (mood.change != null && mood.change!.abs() >= meaningfulChange) {
      final better = mood.change! > 0;
      headline = better
          ? pick('An easier week than the last', 'Mas magaan kaysa nakaraan')
          : pick('A harder week than the last', 'Mas mabigat kaysa nakaraan');
      subhead = pick(
        'Your check-ins averaged '
            '${_signed(mood.change!)} points against the previous $days days. '
            'That is your logged days talking, not every day.',
        'Ang average ng check-in mo ay ${_signed(mood.change!)} puntos '
            'kumpara sa nakaraang $days araw. Ang mga araw na may tala lang '
            'ang batayan nito.',
      );
    } else if (mood.average != null) {
      headline = _moodWord(mood.average!, language);
      subhead = mood.change != null
          ? pick(
              'Much like the $days days before it, across '
                  '${mood.numericDays} logged ${_dayWord(mood.numericDays, language)}.',
              'Halos katulad ng nakaraang $days araw, batay sa '
                  '${mood.numericDays} araw na may tala.',
            )
          : pick(
              'From ${mood.numericDays} logged '
                  '${_dayWord(mood.numericDays, language)}. A couple more '
                  'makes week-to-week comparison possible.',
              'Mula sa ${mood.numericDays} araw na may tala. Ilan pa at '
                  'maihahambing na ito sa nakaraang linggo.',
            );
    } else {
      headline = pick(
        'You showed up on ${snapshot.activeDays} of $days days',
        'May tala ka sa ${snapshot.activeDays} sa $days araw',
      );
      subhead = pick(
        'No mood check-ins yet, so there is no felt-experience read — only a '
            'record of what you did.',
        'Wala pang mood check-in, kaya tala lang ito ng ginawa mo at hindi ng '
            'naramdaman mo.',
      );
    }

    final (keyFigure, keyFigureLabel) = _keyFigure(snapshot, language);

    return WeekReading(
      headline: headline,
      subhead: subhead,
      keyFigure: keyFigure,
      keyFigureLabel: keyFigureLabel,
      metrics: metrics,
      links: _links(snapshot, language),
      contrast: _contrast(snapshot),
    );
  }

  // -----------------------------------------------------------------------
  // Metric readings
  // -----------------------------------------------------------------------

  static PlainMetricReading _readMetric(
    WellnessSnapshot snapshot,
    String id,
    String language,
  ) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    final metric = snapshot.metrics[id]!;
    final change = metric.change;

    // Scored series read as a level; everything else reads as a count.
    if (metric.average != null) {
      final headline = switch (id) {
        'mood' => _moodWord(metric.average!, language),
        'sleep' => _sleepWord(metric.average!, language),
        _ => _moodWord(metric.average!, language),
      };
      return PlainMetricReading(
        id: id,
        headline: headline,
        value: '${metric.average!.toStringAsFixed(1)}/5',
        support: pick(
          'averaged over ${metric.numericDays} logged '
              '${_dayWord(metric.numericDays, language)}',
          'karaniwan sa ${metric.numericDays} araw na may tala',
        ),
        direction: _direction(change, higherIsBetter: true),
        trendLabel: _trendLabel(change, language, higherIsBetter: true),
        exactChange: change,
      );
    }

    final count = metric.count;
    final delta = count - metric.previousCount;
    return PlainMetricReading(
      id: id,
      headline: count == 0
          ? pick('None this week', 'Wala ngayong linggo')
          : pick(
              '$count saved',
              '$count ang naitala',
            ),
      value: '$count',
      support: count == 0
          ? pick('nothing saved in this window', 'walang naitala sa panahong ito')
          : pick(
              'across ${metric.days} ${_dayWord(metric.days, language)}',
              'sa ${metric.days} araw',
            ),
      direction: count == 0 && metric.previousCount == 0
          ? InsightDirection.unknown
          : delta > 0
              ? InsightDirection.better
              : delta < 0
                  ? InsightDirection.worse
                  : InsightDirection.steady,
      trendLabel: count == 0 && metric.previousCount == 0
          ? pick('nothing to compare yet', 'wala pang maihahambing')
          : delta == 0
              ? pick('same as last week', 'kapareho ng nakaraang linggo')
              : delta > 0
                  ? pick(
                      '$delta more than last week',
                      '$delta ang dagdag kaysa nakaraang linggo',
                    )
                  : pick(
                      '${-delta} fewer than last week',
                      '${-delta} ang kulang kaysa nakaraang linggo',
                    ),
      exactChange: delta.toDouble(),
    );
  }

  static InsightDirection _direction(
    double? change, {
    required bool higherIsBetter,
  }) {
    if (change == null) return InsightDirection.unknown;
    if (change.abs() < meaningfulChange) return InsightDirection.steady;
    final up = change > 0;
    return up == higherIsBetter
        ? InsightDirection.better
        : InsightDirection.worse;
  }

  static String _trendLabel(
    double? change,
    String language, {
    required bool higherIsBetter,
  }) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    if (change == null) {
      return pick(
        'needs 3 logged days in each week to compare',
        'kailangan ng 3 araw na may tala bawat linggo',
      );
    }
    if (change.abs() < meaningfulChange) {
      return pick('about the same as last week', 'halos ganoon din noong nakaraan');
    }
    final better = (change > 0) == higherIsBetter;
    final clear = change.abs() >= clearChange;
    if (better) {
      return clear
          ? pick('clearly better than last week', 'malinaw na mas maganda kaysa noong nakaraan')
          : pick('a little better than last week', 'bahagyang mas maganda kaysa noong nakaraan');
    }
    return clear
        ? pick('clearly harder than last week', 'malinaw na mas mabigat kaysa noong nakaraan')
        : pick('a little harder than last week', 'bahagyang mas mabigat kaysa noong nakaraan');
  }

  // -----------------------------------------------------------------------
  // Headline figure
  // -----------------------------------------------------------------------

  /// The one number worth large type: whichever is best supported, in the
  /// order a person would find useful.
  static (String, String) _keyFigure(
    WellnessSnapshot snapshot,
    String language,
  ) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    final days = snapshot.dayCounts.length;
    final mood = snapshot.metrics['mood']!;
    if (mood.average != null && mood.numericDays >= 3) {
      return (
        mood.average!.toStringAsFixed(1),
        pick(
          'average mood out of 5, over ${mood.numericDays} logged days',
          'karaniwang mood sa 5, sa ${mood.numericDays} araw na may tala',
        ),
      );
    }
    if (snapshot.sleepHours != null && snapshot.sleepDurationDays >= 2) {
      return (
        '${snapshot.sleepHours!.toStringAsFixed(1)}h',
        pick(
          'average sleep across ${snapshot.sleepDurationDays} timed nights',
          'karaniwang tulog sa ${snapshot.sleepDurationDays} gabing may oras',
        ),
      );
    }
    return (
      '${snapshot.activeDays}/$days',
      pick('days with a moment of care', 'araw na may pag-aalaga sa sarili'),
    );
  }

  // -----------------------------------------------------------------------
  // Best and hardest day
  // -----------------------------------------------------------------------

  /// Only worth drawing when there are enough days to have a best and a
  /// worst, and enough distance between them for the comparison to mean
  /// something. Mood is logged in whole points, so a one-point gap is the
  /// smallest difference the scale can express and not yet a contrast.
  static const double minimumContrastSpread = 1.5;

  static DayContrast? _contrast(WellnessSnapshot snapshot) {
    final moodDays = snapshot.moodByDay;
    if (moodDays.length < 3) return null;
    var best = moodDays.first;
    var worst = moodDays.first;
    for (final entry in moodDays) {
      if (entry.value > best.value) best = entry;
      if (entry.value < worst.value) worst = entry;
    }
    if (best.key == worst.key) return null;
    if (best.value - worst.value < minimumContrastSpread) return null;

    List<String> companions(DateTime day) => [
          for (final entry in snapshot.activityDays.entries)
            if (entry.key != 'mood' && entry.value.contains(day)) entry.key,
        ]..sort();

    return DayContrast(
      bestDay: best.key,
      bestScore: best.value,
      hardestDay: worst.key,
      hardestScore: worst.value,
      bestCompanions: companions(best.key),
      hardestCompanions: companions(worst.key),
    );
  }

  // -----------------------------------------------------------------------
  // Associations
  // -----------------------------------------------------------------------

  static List<InsightLink> _links(
    WellnessSnapshot snapshot,
    String language,
  ) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    final moodDays = snapshot.dayScores['mood'] ?? const <DateTime, double>{};
    if (moodDays.length < minimumGroupDays * 2) return const [];

    final links = <InsightLink>[];
    final caveat = pick(
      'Two things happening together is not one causing the other. It is a '
          'place to look, not a conclusion.',
      'Ang magkasabay na dalawang bagay ay hindi nangangahulugang isa ang '
          'sanhi ng isa. Simula ito ng pagsusuri, hindi konklusyon.',
    );

    void compare({
      required String id,
      required bool Function(DateTime day) isInGroup,
      required String Function(String difference) statementEn,
      required String Function(String difference) statementFil,
    }) {
      final inGroup = <double>[];
      final outGroup = <double>[];
      for (final entry in moodDays.entries) {
        (isInGroup(entry.key) ? inGroup : outGroup).add(entry.value);
      }
      if (inGroup.length < minimumGroupDays ||
          outGroup.length < minimumGroupDays) {
        return;
      }
      final difference = _mean(inGroup) - _mean(outGroup);
      if (difference.abs() < meaningfulChange + 0.1) return;
      final formatted = _signed(difference);
      links.add(InsightLink(
        id: id,
        statement: pick(statementEn(formatted), statementFil(formatted)),
        caveat: caveat,
        difference: difference,
        withDays: inGroup.length,
        withoutDays: outGroup.length,
      ));
    }

    // Sleep quality against mood, using the nights that were actually rated.
    final sleepDays = snapshot.dayScores['sleep'] ?? const <DateTime, double>{};
    if (sleepDays.length >= minimumGroupDays * 2) {
      compare(
        id: 'sleep_mood',
        isInGroup: (day) => (sleepDays[day] ?? 0) >= 4,
        statementEn: (difference) =>
            'After the nights you rated well-rested, your mood ran '
            '$difference points against your other logged days.',
        statementFil: (difference) =>
            'Pagkatapos ng mga gabing sabi mo ay nakapagpahinga ka, ang mood '
            'mo ay $difference puntos kumpara sa ibang araw na may tala.',
      );
    }

    // A completed routine against mood.
    final routineDays =
        snapshot.activityDays['routine'] ?? const <DateTime>{};
    compare(
      id: 'routine_mood',
      isInGroup: routineDays.contains,
      statementEn: (difference) =>
          'On the days you finished a routine, your mood ran $difference '
          'points against the days you did not.',
      statementFil: (difference) =>
          'Sa mga araw na natapos mo ang routine, ang mood mo ay $difference '
          'puntos kumpara sa mga araw na hindi.',
    );

    // Breathing or grounding against mood.
    final practiceDays = <DateTime>{
      ...?snapshot.activityDays['breathing'],
      ...?snapshot.activityDays['grounding'],
    };
    compare(
      id: 'practice_mood',
      isInGroup: practiceDays.contains,
      statementEn: (difference) =>
          'On the days you practiced breathing or grounding, your mood ran '
          '$difference points against the days you did not.',
      statementFil: (difference) =>
          'Sa mga araw na nagsanay ka ng paghinga o grounding, ang mood mo ay '
          '$difference puntos kumpara sa mga araw na hindi.',
    );

    links.sort(
      (left, right) => right.difference.abs().compareTo(left.difference.abs()),
    );
    return links.take(2).toList(growable: false);
  }

  // -----------------------------------------------------------------------
  // Words for numbers
  // -----------------------------------------------------------------------

  /// The word for a mood average, so every surface that shows a
  /// five-point score can say the same thing about the same number.
  static String moodWord(double average, String language) =>
      _moodWord(average, language);

  /// The word for a sleep-quality average, on the same five-point scale.
  static String sleepWord(double average, String language) =>
      _sleepWord(average, language);

  static String _moodWord(double average, String language) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    if (average >= 4.3) return pick('A good week', 'Magandang linggo');
    if (average >= 3.5) return pick('Mostly okay days', 'Karamihan ay ayos');
    if (average >= 2.6) return pick('A mixed week', 'Halo-halong linggo');
    if (average >= 1.8) return pick('A heavy week', 'Mabigat na linggo');
    return pick('A very heavy week', 'Napakabigat na linggo');
  }

  static String _sleepWord(double average, String language) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    if (average >= 4.3) return pick('Waking up rested', 'Nagigising na panatag');
    if (average >= 3.5) return pick('Mostly rested', 'Karaniwang napapahinga');
    if (average >= 2.6) return pick('Patchy rest', 'Pabago-bagong pahinga');
    if (average >= 1.8) return pick('Not much rest', 'Kulang ang pahinga');
    return pick('Barely resting', 'Halos walang pahinga');
  }

  static String _dayWord(int count, String language) => LanguageHelper.pick(
        language,
        english: count == 1 ? 'day' : 'days',
        filipino: 'araw',
      );

  static String _signed(double value) =>
      '${value >= 0 ? '+' : '−'}${value.abs().toStringAsFixed(1)}';

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;
}
