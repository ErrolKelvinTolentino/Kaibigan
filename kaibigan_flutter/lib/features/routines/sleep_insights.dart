import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/language_helper.dart';
import '../insights/wellness_analytics.dart';
import 'routine_model.dart';

/// One night as it was logged, including bed and wake clock times when the
/// person supplied them.
@immutable
class SleepNight {
  const SleepNight({
    required this.loggedAt,
    required this.feeling,
    this.hours,
    this.bedtime,
    this.wakeTime,
  });

  final DateTime loggedAt;
  final SleepFeeling feeling;

  /// Null when the entry only recorded a range such as "10+".
  final double? hours;
  final TimeOfDay? bedtime;
  final TimeOfDay? wakeTime;

  bool get hasClockTimes => bedtime != null && wakeTime != null;

  /// The night this entry describes: a log filed in the morning is about the
  /// sleep that started the evening before.
  DateTime get nightOf {
    final date = DateTime(loggedAt.year, loggedAt.month, loggedAt.day);
    return loggedAt.hour < 18 ? date.subtract(const Duration(days: 1)) : date;
  }
}

/// Encodes and recovers sleep details inside the existing `focus_or_highlight`
/// text column, so richer logs need no schema change and older rows keep
/// parsing exactly as before.
class SleepLogCodec {
  const SleepLogCodec._();

  static final _timesPattern = RegExp(
    r'\((\d{1,2}):(\d{2})\s*(?:->|→|-|–|to)\s*(\d{1,2}):(\d{2})\)',
  );

  static String encode({
    required String durationLabel,
    required SleepFeeling feeling,
    TimeOfDay? bedtime,
    TimeOfDay? wakeTime,
  }) {
    final times = bedtime != null && wakeTime != null
        ? ' (${_pad(bedtime)}->${_pad(wakeTime)})'
        : '';
    return 'Slept $durationLabel hrs$times: ${feeling.description}';
  }

  static ({TimeOfDay bedtime, TimeOfDay wakeTime})? decodeTimes(String? text) {
    if (text == null) return null;
    final match = _timesPattern.firstMatch(text);
    if (match == null) return null;
    final bedHour = int.tryParse(match.group(1)!) ?? -1;
    final bedMinute = int.tryParse(match.group(2)!) ?? -1;
    final wakeHour = int.tryParse(match.group(3)!) ?? -1;
    final wakeMinute = int.tryParse(match.group(4)!) ?? -1;
    if (bedHour < 0 || bedHour > 23 || wakeHour < 0 || wakeHour > 23) {
      return null;
    }
    if (bedMinute < 0 || bedMinute > 59 || wakeMinute < 0 || wakeMinute > 59) {
      return null;
    }
    return (
      bedtime: TimeOfDay(hour: bedHour, minute: bedMinute),
      wakeTime: TimeOfDay(hour: wakeHour, minute: wakeMinute),
    );
  }

  static SleepNight? nightFrom(RoutineLog log) {
    if (routineActivity(log) != 'sleep') return null;
    final times = decodeTimes(log.focusOrHighlight);
    return SleepNight(
      loggedAt: log.completedAt,
      feeling: log.sleepFeeling ?? SleepFeeling.moderate,
      hours: loggedSleepHours(log),
      bedtime: times?.bedtime,
      wakeTime: times?.wakeTime,
    );
  }

  static String _pad(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

/// Bedtime and wake-time suggestions built on 90-minute sleep cycles.
///
/// Waking between cycles rather than mid-cycle is the reason two people who
/// slept the same number of hours can feel very differently on waking.
class SleepCycleCalculator {
  const SleepCycleCalculator._();

  static const Duration cycle = Duration(minutes: 90);

  /// The usual allowance for actually falling asleep once in bed.
  static const Duration fallAsleepBuffer = Duration(minutes: 15);

  /// Bedtimes that land [cycles] whole cycles before [wakeTime], newest need
  /// first. Five and six cycles (7.5h and 9h) are the healthy middle.
  static List<({int cycles, TimeOfDay bedtime, double hours})> bedtimesFor(
    TimeOfDay wakeTime, {
    List<int> cycles = const [6, 5, 4, 3],
  }) {
    return cycles.map((count) {
      final total = cycle * count + fallAsleepBuffer;
      return (
        cycles: count,
        bedtime: _shift(wakeTime, -total),
        hours: cycle.inMinutes * count / 60,
      );
    }).toList(growable: false);
  }

  /// Wake times that land on a cycle boundary if sleep starts now.
  static List<({int cycles, TimeOfDay wakeTime, double hours})> wakeTimesFor(
    TimeOfDay bedtime, {
    List<int> cycles = const [4, 5, 6],
  }) {
    return cycles.map((count) {
      final total = cycle * count + fallAsleepBuffer;
      return (
        cycles: count,
        wakeTime: _shift(bedtime, total),
        hours: cycle.inMinutes * count / 60,
      );
    }).toList(growable: false);
  }

  static TimeOfDay _shift(TimeOfDay time, Duration by) {
    final total = time.hour * 60 + time.minute + by.inMinutes;
    final wrapped = ((total % 1440) + 1440) % 1440;
    return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
  }

  static double hoursBetween(TimeOfDay bedtime, TimeOfDay wakeTime) {
    final bed = bedtime.hour * 60 + bedtime.minute;
    final wake = wakeTime.hour * 60 + wakeTime.minute;
    final minutes = wake >= bed ? wake - bed : wake + 1440 - bed;
    return minutes / 60;
  }
}

enum EnergyWindowKind { peak, dip }

@immutable
class EnergyWindow {
  const EnergyWindow({
    required this.kind,
    required this.startHour,
    required this.endHour,
    required this.centreHour,
    required this.level,
    required this.label,
    required this.suggestion,
  });

  final EnergyWindowKind kind;
  final double startHour;
  final double endHour;
  final double centreHour;

  /// 0–100 estimated alertness at the centre of the window.
  final double level;

  final String label;
  final String suggestion;
}

@immutable
class EnergyPoint {
  const EnergyPoint(this.hour, this.energy);

  /// Clock hour as a decimal, e.g. 14.5 for 2:30 PM. May exceed 24 when the
  /// day runs past midnight.
  final double hour;

  /// 0–100.
  final double energy;

  double get wrappedHour => hour % 24;
}

/// How far behind on sleep the recent nights put someone.
///
/// The level is read from the accumulated debt, then escalated when the
/// shortfall is large on every logged night: three nights at four hours is a
/// different situation from a fortnight of being twenty minutes short.
enum SleepDebtLevel { none, slight, moderate, high, severe }

/// A repayment schedule the person can actually keep.
///
/// Sleep debt is repaid in instalments. A single long lie-in shifts the body
/// clock later and clears less than people expect, so the plan always spreads
/// the shortfall over several ordinary nights.
@immutable
class SleepRecoveryPlan {
  const SleepRecoveryPlan({
    required this.extraMinutesPerNight,
    required this.nights,
    required this.debtHours,
    required this.clearsDebt,
  });

  final int extraMinutesPerNight;
  final int nights;
  final double debtHours;

  /// False when the debt is too large to clear inside one sensible week, so
  /// the plan is a first instalment rather than the whole repayment.
  final bool clearsDebt;

  double get repaidHours => extraMinutesPerNight * nights / 60;
}

/// The plain-language read on sleep debt: what it adds up to, what it is
/// likely doing to the person today, and what clears it.
@immutable
class SleepStatus {
  const SleepStatus({
    required this.level,
    required this.title,
    required this.meaning,
    required this.action,
    required this.debtHours,
    required this.needHours,
    required this.loggedNights,
    this.recovery,
    this.symptomNote,
  });

  final SleepDebtLevel level;

  /// Two or three words a person can read at a glance: the answer to "am I
  /// sleep deprived?" before any number is parsed.
  final String title;

  /// The debt restated as nights of sleep, which is easier to feel than a
  /// count of hours.
  final String meaning;

  /// The single next move.
  final String action;

  final double debtHours;
  final double needHours;
  final int loggedNights;
  final SleepRecoveryPlan? recovery;

  /// What this level of debt tends to do to a person, named only once it is
  /// large enough to be doing something.
  final String? symptomNote;

  bool get isDeprived =>
      level == SleepDebtLevel.high || level == SleepDebtLevel.severe;

  bool get hasDebt => level != SleepDebtLevel.none;

  /// Debt expressed as a share of one full night, for a meter. Capped at two
  /// nights so a very large number still draws something readable.
  double get nightsBehind =>
      needHours <= 0 ? 0 : (debtHours / needHours).clamp(0.0, 2.0);
}

enum SleepTipCategory { tonight, schedule, daytime, environment, support }

/// One concrete change, chosen because the logged nights point at it.
@immutable
class SleepTip {
  const SleepTip({
    required this.id,
    required this.title,
    required this.detail,
    required this.category,
  });

  final String id;
  final String title;
  final String detail;
  final SleepTipCategory category;
}

enum SleepFeedbackTone { good, watch, concern }

@immutable
class SleepFeedbackItem {
  const SleepFeedbackItem({
    required this.title,
    required this.detail,
    required this.tone,
  });

  final String title;
  final String detail;
  final SleepFeedbackTone tone;
}

/// Everything the sleep screens need, derived from logged nights alone.
@immutable
class SleepInsights {
  const SleepInsights({
    required this.nights,
    required this.needHours,
    required this.debtHours,
    required this.debtWindowNights,
    required this.averageHours,
    required this.bedtimeSpreadMinutes,
    required this.energyCurve,
    required this.windows,
    required this.feedback,
    required this.headline,
    required this.status,
    required this.tips,
    this.lastNight,
    this.typicalBedtime,
    this.typicalWakeTime,
  });

  /// Nights the analysis is based on, newest first.
  final List<SleepNight> nights;

  /// Hours of sleep treated as this person's target.
  final double needHours;

  /// Accumulated shortfall across [debtWindowNights].
  final double debtHours;
  final int debtWindowNights;

  final double averageHours;

  /// How far apart the earliest and latest bedtimes were. Null when fewer than
  /// two nights recorded a bedtime.
  final int? bedtimeSpreadMinutes;

  final List<EnergyPoint> energyCurve;
  final List<EnergyWindow> windows;
  final List<SleepFeedbackItem> feedback;

  /// One sentence summarising the night, for the top of the screen.
  final String headline;

  /// The verdict on sleep debt, written so it can be understood without
  /// reading any of the numbers around it.
  final SleepStatus status;

  /// Concrete changes chosen from what the logged nights actually show.
  final List<SleepTip> tips;

  final SleepNight? lastNight;

  /// The bedtime and wake time this person keeps on average, once at least
  /// two nights recorded clock times. Null before that.
  final TimeOfDay? typicalBedtime;
  final TimeOfDay? typicalWakeTime;

  bool get hasEnergyCurve => energyCurve.length > 2;

  List<EnergyWindow> get peaks =>
      windows.where((w) => w.kind == EnergyWindowKind.peak).toList();

  List<EnergyWindow> get dips =>
      windows.where((w) => w.kind == EnergyWindowKind.dip).toList();

  static const double defaultNeedHours = 8;

  /// Nights older than this stop counting toward debt: sleep debt from months
  /// ago is not something tonight can repay.
  static const int debtWindow = 14;

  static SleepInsights build(
    List<RoutineLog> logs, {
    double needHours = defaultNeedHours,
    DateTime? now,
    String language = 'english',
  }) {
    final reference = now ?? DateTime.now();
    final nights = logs
        .map(SleepLogCodec.nightFrom)
        .whereType<SleepNight>()
        .toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    final windowStart = reference.subtract(
      const Duration(days: debtWindow),
    );
    final recent =
        nights.where((night) => night.loggedAt.isAfter(windowStart)).toList();
    final measured =
        recent.where((night) => night.hours != null).toList(growable: false);

    final debt = measured.fold<double>(
      0,
      (total, night) => total + math.max(0, needHours - night.hours!),
    );
    final average = measured.isEmpty
        ? 0.0
        : measured.fold<double>(0, (sum, n) => sum + n.hours!) /
            measured.length;

    final lastNight = nights.isEmpty ? null : nights.first;
    final curve = _buildEnergyCurve(
      lastNight: lastNight,
      debtHours: debt,
      needHours: needHours,
    );

    final spread = _bedtimeSpread(recent);
    final typicalBedtime = _typicalTime(recent.map((night) => night.bedtime));
    final status = _buildStatus(
      debtHours: debt,
      needHours: needHours,
      measuredNights: measured.length,
      language: language,
    );

    return SleepInsights(
      nights: nights,
      needHours: needHours,
      debtHours: debt,
      debtWindowNights: measured.length,
      averageHours: average,
      bedtimeSpreadMinutes: spread,
      energyCurve: curve,
      windows: _findWindows(curve),
      feedback: _buildFeedback(
        lastNight: lastNight,
        recent: recent,
        measured: measured,
        debtHours: debt,
        averageHours: average,
        needHours: needHours,
        bedtimeSpreadMinutes: spread,
        language: language,
      ),
      headline: _headline(lastNight, needHours, language),
      status: status,
      tips: _buildTips(
        status: status,
        lastNight: lastNight,
        measured: measured,
        recent: recent,
        averageHours: average,
        needHours: needHours,
        bedtimeSpreadMinutes: spread,
        typicalBedtime: typicalBedtime,
        language: language,
      ),
      lastNight: lastNight,
      typicalBedtime: typicalBedtime,
      typicalWakeTime: _typicalTime(recent.map((night) => night.wakeTime)),
    );
  }

  // ---------------------------------------------------------------------
  // Sleep debt status
  // ---------------------------------------------------------------------

  /// Debt thresholds in hours, read against a fortnight of logging. Four
  /// hours is roughly half a night; eight is a whole night gone; fifteen is
  /// the point where the shortfall stops being something a weekend absorbs.
  static const double slightDebtHours = 1;
  static const double moderateDebtHours = 4;
  static const double highDebtHours = 8;
  static const double severeDebtHours = 15;

  static SleepStatus _buildStatus({
    required double debtHours,
    required double needHours,
    required int measuredNights,
    required String language,
  }) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);

    var level = switch (debtHours) {
      < slightDebtHours => SleepDebtLevel.none,
      < moderateDebtHours => SleepDebtLevel.slight,
      < highDebtHours => SleepDebtLevel.moderate,
      < severeDebtHours => SleepDebtLevel.high,
      _ => SleepDebtLevel.severe,
    };

    // A large shortfall on every single night is worse than the same total
    // spread thinly, because no recovered night sits in between.
    final perNight = measuredNights == 0 ? 0.0 : debtHours / measuredNights;
    if (measuredNights >= 3 &&
        perNight >= 1.5 &&
        level != SleepDebtLevel.none) {
      level = SleepDebtLevel
          .values[math.min(level.index + 1, SleepDebtLevel.severe.index)];
    }

    final recovery = _recoveryPlan(debtHours);
    final nightsBehind = needHours <= 0 ? 0.0 : debtHours / needHours;

    final title = switch (level) {
      SleepDebtLevel.none => measuredNights == 0
          ? pick('No sleep debt recorded', 'Walang naitalang sleep debt')
          : pick('You are keeping up with sleep', 'Nakakasabay ka sa tulog'),
      SleepDebtLevel.slight =>
        pick('A small sleep gap', 'May kaunting kulang sa tulog'),
      SleepDebtLevel.moderate =>
        pick('You are carrying sleep debt', 'May dala kang sleep debt'),
      SleepDebtLevel.high =>
        pick('You are sleep deprived', 'Kulang ka sa tulog'),
      SleepDebtLevel.severe =>
        pick('You are badly sleep deprived', 'Malubha ang kulang mo sa tulog'),
    };

    final nights = measuredNights == 1
        ? pick('1 logged night', '1 gabing may tala')
        : pick(
            '$measuredNights logged nights',
            '$measuredNights gabing may tala',
          );

    final meaning = level == SleepDebtLevel.none
        ? (measuredNights == 0
            ? pick(
                'Log a night with its hours and this becomes a running total '
                    'of the sleep you are owed.',
                'Magtala ng gabi kasama ang oras at makikita mo rito ang '
                    'kabuuang tulog na kulang sa iyo.',
              )
            : pick(
                'Across your last $nights you slept close to the '
                    '${_formatHours(needHours)} you are aiming for. There is '
                    'nothing to pay back.',
                'Sa huling $nights mo, malapit ka sa '
                    '${_formatHours(needHours)} na target mo. Wala kang '
                    'kailangang bawiin.',
              ))
        : pick(
            '${_formatHours(debtHours)} missed across your last $nights — '
                '${_nightsPhrase(nightsBehind, language)}.',
            '${_formatHours(debtHours)} ang kulang sa huling $nights mo — '
                '${_nightsPhrase(nightsBehind, language)}.',
          );

    final action = recovery == null
        ? pick(
            'Keep the bedtime you have been using. Steady beats occasionally '
                'perfect.',
            'Panatilihin ang oras ng paghiga na ginagawa mo. Mas mabuti ang '
                'tuloy-tuloy kaysa paminsan-minsang perpekto.',
          )
        : recovery.clearsDebt
            ? pick(
                'Sleep ${recovery.extraMinutesPerNight} minutes longer for '
                    '${recovery.nights} nights and you are even again.',
                'Matulog nang dagdag na ${recovery.extraMinutesPerNight} '
                    'minuto sa loob ng ${recovery.nights} gabi at patas ka na '
                    'ulit.',
              )
            : pick(
                'Start with ${recovery.extraMinutesPerNight} extra minutes a '
                    'night this week. That clears about '
                    '${_formatHours(recovery.repaidHours)} of it, and the '
                    'rest follows the same way.',
                'Magsimula sa dagdag na ${recovery.extraMinutesPerNight} '
                    'minuto bawat gabi ngayong linggo. Mababawi nito ang mga '
                    '${_formatHours(recovery.repaidHours)}, at ganoon din ang '
                    'natitira.',
              );

    final symptomNote = switch (level) {
      SleepDebtLevel.high => pick(
          'At this much debt most people notice slower thinking, a shorter '
              'fuse, and stronger cravings — and rate their own sharpness '
              'higher than it actually is. Today is one to plan around '
              'rather than push through.',
          'Sa ganitong laki ng kulang sa tulog, karaniwang bumabagal ang '
              'pag-iisip, mas maikli ang pasensya, at mas malakas ang gana sa '
              'pagkain — at kadalasang akala ng tao mas gising sila kaysa sa '
              'totoo. Planuhin ang araw, huwag pilitin.',
        ),
      SleepDebtLevel.severe => pick(
          'This is the range where lapses in attention stop responding to '
              'effort. Treat rest as the task today, and be careful with '
              'driving or anything that punishes a lapse. If it has been '
              'like this for weeks, tell a doctor.',
          'Sa antas na ito, hindi na kayang pigilan ng pagsisikap ang '
              'pagkawala ng pokus. Unahin ang pahinga ngayong araw, at '
              'mag-ingat sa pagmamaneho o anumang delikado. Kung ganito na ng '
              'ilang linggo, magpatingin sa doktor.',
        ),
      _ => null,
    };

    return SleepStatus(
      level: level,
      title: title,
      meaning: meaning,
      action: action,
      debtHours: debtHours,
      needHours: needHours,
      loggedNights: measuredNights,
      recovery: recovery,
      symptomNote: symptomNote,
    );
  }

  /// Spreads the shortfall over the fewest nights that still keeps each
  /// night's extra sleep realistic. A week is the longest plan worth writing
  /// down; anything larger is presented as a first instalment.
  static SleepRecoveryPlan? _recoveryPlan(double debtHours) {
    if (debtHours < slightDebtHours) return null;
    final debtMinutes = (debtHours * 60).round();
    for (final perNight in const [30, 45, 60]) {
      final nights = (debtMinutes / perNight).ceil();
      if (nights <= 7) {
        return SleepRecoveryPlan(
          extraMinutesPerNight: perNight,
          nights: nights,
          debtHours: debtHours,
          clearsDebt: true,
        );
      }
    }
    return SleepRecoveryPlan(
      extraMinutesPerNight: 60,
      nights: 7,
      debtHours: debtHours,
      clearsDebt: false,
    );
  }

  /// The debt restated in nights, which is the unit people actually feel.
  static String _nightsPhrase(double nights, String language) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    if (nights < 0.35) {
      return pick(
        'less than half a night of sleep',
        'wala pang kalahating gabi ng tulog',
      );
    }
    if (nights < 0.75) {
      return pick('about half a night of sleep', 'mga kalahating gabi ng tulog');
    }
    if (nights < 1.3) {
      return pick(
        'about a full night of sleep',
        'mga isang buong gabi ng tulog',
      );
    }
    if (nights < 1.8) {
      return pick(
        'about a night and a half of sleep',
        'mga isa at kalahating gabi ng tulog',
      );
    }
    final whole = nights.round();
    return pick(
      'roughly $whole full nights of sleep',
      'humigit-kumulang $whole buong gabi ng tulog',
    );
  }

  /// The average of several clock times, measured from 18:00 so evening and
  /// after-midnight times average together instead of cancelling out.
  static TimeOfDay? _typicalTime(Iterable<TimeOfDay?> times) {
    final minutes = times
        .whereType<TimeOfDay>()
        .map((time) => ((time.hour * 60 + time.minute) - 18 * 60 + 1440) % 1440)
        .toList();
    if (minutes.length < 2) return null;
    final mean = minutes.reduce((a, b) => a + b) / minutes.length;
    final clock = (mean.round() + 18 * 60) % 1440;
    return TimeOfDay(hour: clock ~/ 60, minute: clock % 60);
  }

  // ---------------------------------------------------------------------
  // Tips
  // ---------------------------------------------------------------------

  /// A bedtime past midnight, or close enough that the night is already being
  /// squeezed from the front.
  static bool _isLateBedtime(TimeOfDay bedtime) =>
      bedtime.hour < 6 || (bedtime.hour == 23 && bedtime.minute >= 45);

  /// Picks at most four changes, each because something in the logs points at
  /// it. A generic sleep-hygiene list would be longer and worth less.
  static List<SleepTip> _buildTips({
    required SleepStatus status,
    required SleepNight? lastNight,
    required List<SleepNight> measured,
    required List<SleepNight> recent,
    required double averageHours,
    required double needHours,
    required int? bedtimeSpreadMinutes,
    required TimeOfDay? typicalBedtime,
    required String language,
  }) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);

    final tips = <SleepTip>[];
    void add(
      String id,
      SleepTipCategory category,
      String titleEn,
      String titleFil,
      String detailEn,
      String detailFil,
    ) {
      if (tips.length >= 4 || tips.any((tip) => tip.id == id)) return;
      tips.add(SleepTip(
        id: id,
        category: category,
        title: pick(titleEn, titleFil),
        detail: pick(detailEn, detailFil),
      ));
    }

    if (recent.isEmpty) {
      add(
        'start_logging',
        SleepTipCategory.schedule,
        'Log tonight with clock times',
        'Itala ang oras ng paghiga at paggising',
        'Bed and wake times turn this screen from a diary into a plan: they '
            'give you a bedtime target and a read on when your energy will '
            'dip tomorrow.',
        'Ang oras ng paghiga at paggising ang gumagawa nitong plano at hindi '
            'talaarawan lang: bibigyan ka nito ng target na oras ng tulog at '
            'babala kung kailan bababa ang lakas mo bukas.',
      );
      return tips;
    }

    final quality = lastNight?.feeling.score ?? 3;
    final lastHours = lastNight?.hours;
    final restlessNights = recent
        .where((night) =>
            night.feeling == SleepFeeling.restless ||
            night.feeling == SleepFeeling.groggy)
        .length;
    final longButTired =
        lastHours != null && lastHours >= needHours - 0.5 && quality <= 2;
    final isLate = typicalBedtime != null && _isLateBedtime(typicalBedtime);

    // Fewer than three measured nights cannot separate a rough night from a
    // pattern. That caveat qualifies every tip after it, so it goes first
    // rather than competing for the last slot.
    if (measured.length < 3) {
      add(
        'log_more_nights',
        SleepTipCategory.schedule,
        'A few more nights sharpens this',
        'Ilan pang gabi ang magpapalinaw nito',
        'With three or four logged nights this screen can tell the difference '
            'between one rough night and a pattern worth changing.',
        'Sa tatlo o apat na gabing may tala, malalaman dito kung isang '
            'mahirap na gabi lang ito o pattern na dapat baguhin.',
      );
    }

    // 1. The one move that repays debt without pushing the body clock later.
    if (status.hasDebt) {
      add(
        'earlier_bedtime',
        SleepTipCategory.tonight,
        'Move bedtime, not the alarm',
        'Ang paghiga ang galawin, hindi ang alarm',
        'Going to bed 30 minutes earlier is easier to control than sleeping '
            'in, and it does not push tomorrow morning later the way a lie-in '
            'does.',
        'Mas madaling kontrolin ang paghiga nang 30 minutong mas maaga kaysa '
            'sa pagtulog nang mahaba sa umaga. Hindi rin nito naitutulak nang '
            'mas huli ang umaga mo.',
      );
    }

    // 2. Irregularity costs more than most people expect.
    if (bedtimeSpreadMinutes != null && bedtimeSpreadMinutes >= 90) {
      add(
        'anchor_wake_time',
        SleepTipCategory.schedule,
        'Anchor one wake time first',
        'Ayusin muna ang isang oras ng paggising',
        'Your bedtimes move by ${_formatMinutes(bedtimeSpreadMinutes)}. Pick '
            'a wake time you can keep every day, weekends included — bedtime '
            'follows a steady morning within a week or two.',
        'Umaabot sa ${_formatMinutes(bedtimeSpreadMinutes)} ang pagkakaiba ng '
            'oras ng paghiga mo. Pumili ng oras ng paggising na kaya mo '
            'araw-araw, pati weekend — susunod ang paghiga sa loob ng isa o '
            'dalawang linggo.',
      );
    }

    // 3. Enough hours but unrefreshing points at the night itself rather than
    // its length, so the useful change is what happens before and in bed.
    if (longButTired) {
      add(
        'room_setup',
        SleepTipCategory.environment,
        'Cool, dark and quiet beats longer',
        'Malamig, madilim, tahimik — hindi mas mahaba',
        'You had the hours but not the rest. A few degrees cooler, proper '
            'darkness, and no late heavy meals or alcohol fix broken sleep '
            'that extra time in bed cannot.',
        'Sapat ang oras pero hindi ang pahinga. Mas malamig na kuwarto, tunay '
            'na dilim, at walang mabigat na kain o alak bago matulog — iyan '
            'ang lunas sa putol-putol na tulog, hindi ang dagdag na oras.',
      );
    }

    // 4. Grogginess and a late clock both answer to morning light.
    if (quality <= 3 || isLate) {
      add(
        'morning_light',
        SleepTipCategory.daytime,
        'Daylight in your first 30 minutes',
        'Sikat ng araw sa unang 30 minuto',
        'Ten minutes of outdoor light after waking is the strongest signal '
            'your body clock gets, and it is what makes you sleepy at a '
            'reasonable hour tonight.',
        'Sampung minuto ng liwanag sa labas pagkagising ang pinakamalakas na '
            'senyas sa body clock mo, at ito ang magpapaantok sa iyo sa tamang '
            'oras mamayang gabi.',
      );
    }

    // 5. Debt large enough that today needs managing, not only tonight.
    if (status.isDeprived || (lastHours != null && lastHours < needHours - 2)) {
      add(
        'short_nap',
        SleepTipCategory.daytime,
        'Nap short and early, or not at all',
        'Maikli at maagang idlip, o huwag na lang',
        'Twenty minutes before 3 PM takes the edge off without stealing from '
            'tonight. Longer or later and you wake groggier and sleep worse.',
        'Dalawampung minuto bago mag-3 PM — nakakabawas ito ng pagod nang '
            'hindi nanakaw sa gabi. Kapag mas mahaba o mas huli, mas hilo ka '
            'paggising at mas masama ang tulog mo.',
      );
    }

    // 6. The lie-in myth is the most common way sleep debt is mismanaged.
    if (status.level == SleepDebtLevel.high ||
        status.level == SleepDebtLevel.severe) {
      add(
        'instalments',
        SleepTipCategory.schedule,
        'Repay in instalments, not one lie-in',
        'Bawiin nang paunti-unti, hindi sa isang mahabang tulog',
        'One twelve-hour weekend does not clear a week of short nights, and '
            'it shifts your clock so Monday is worse. Several ordinary nights '
            'do clear it.',
        'Hindi mabubura ng isang labindalawang-oras na tulog sa weekend ang '
            'isang linggong kulang, at nailalayo pa nito ang body clock kaya '
            'mas mahirap ang Lunes. Ang ilang karaniwang gabi ang nakakabawi.',
      );
    }

    // 7. Restless nights: the bed should not become where you lie awake.
    if (restlessNights >= 2) {
      add(
        'get_up_if_awake',
        SleepTipCategory.tonight,
        'Awake 20 minutes? Get up',
        'Gising pa pagkalipas ng 20 minuto? Bumangon',
        'Leave the bed, keep the lights low, and come back when you feel '
            'sleepy. It stops your body learning that bed is where you lie '
            'awake.',
        'Umalis sa kama, panatilihing mahina ang ilaw, at bumalik kapag '
            'inaantok ka na. Pinipigilan nito ang katawan mong matutong ang '
            'kama ay lugar ng paggising.',
      );
    }

    // 8. Caffeine is the most common invisible cause of a thin night.
    if (status.hasDebt && quality <= 3) {
      add(
        'caffeine_curfew',
        SleepTipCategory.daytime,
        'Caffeine has a long tail',
        'Matagal bago mawala ang caffeine',
        'Half of a 2 PM coffee is still in you around 8 PM. An early cut-off '
            'protects the deep part of the night even when the hours stay the '
            'same.',
        'Kalahati ng kape mong 2 PM ay nasa katawan mo pa rin ng mga 8 PM. '
            'Ang maagang hinto ay nag-iingat sa malalim na bahagi ng gabi '
            'kahit hindi nagbago ang haba ng tulog.',
      );
    }

    // 9. Wind-down, for nights that start late.
    if (isLate) {
      add(
        'wind_down',
        SleepTipCategory.tonight,
        'Give the night a landing strip',
        'Bigyan ng paglapag ang gabi mo',
        'You usually get to bed around ${_formatTime(typicalBedtime)}. Give '
            'yourself thirty dim, low-effort minutes before that — no '
            'problem-solving, no bright screens. Sleep is a slowdown, not a '
            'switch.',
        'Karaniwan kang nahihiga ng mga ${_formatTime(typicalBedtime)}. '
            'Maglaan ng tatlumpung tahimik na minuto bago iyon — walang '
            'iniisip na problema, walang maliwanag na screen. Ang tulog ay '
            'unti-unting paghina, hindi switch.',
      );
    }

    // 10. Far enough along to be a health question, not a habit one.
    if (status.level == SleepDebtLevel.severe ||
        (longButTired && restlessNights >= 3)) {
      add(
        'seek_support',
        SleepTipCategory.support,
        'This is worth telling someone',
        'Sabihin mo na ito sa iba',
        'Weeks of short or unrefreshing sleep is a health matter, not a '
            'willpower one. A doctor or campus clinic can check causes a log '
            'cannot show — breathing, pain, mood, medication.',
        'Ang ilang linggong kulang o hindi nakakapagpahingang tulog ay usapin '
            'ng kalusugan, hindi ng kusa. May matutukoy ang doktor o clinic na '
            'hindi makikita sa tala — paghinga, sakit, timpla, gamot.',
      );
    }

    // 11. Nothing wrong: name what is working so it survives a busy week.
    if (tips.isEmpty) {
      add(
        'protect_it',
        SleepTipCategory.schedule,
        'Protect what is already working',
        'Ingatan ang gumagana na',
        measured.isEmpty
            ? 'Add the hours to your next log and this becomes a running read '
                'on how rested you actually are.'
            : 'Your last ${measured.length} nights averaged '
                '${_formatHours(averageHours)}. Keep the bedtime that '
                'produced it — most people lose this to one busy week.',
        measured.isEmpty
            ? 'Isama ang bilang ng oras sa susunod mong tala para makita mo '
                'kung gaano ka talaga kapahinga.'
            : 'Umabot sa ${_formatHours(averageHours)} ang karaniwan sa huling '
                '${measured.length} gabi mo. Panatilihin ang oras ng paghiga '
                'na nagdulot nito — madalas itong nawawala sa isang abalang '
                'linggo.',
      );
    }

    return tips;
  }

  // ---------------------------------------------------------------------
  // Energy model
  // ---------------------------------------------------------------------

  /// Sleep pressure after being awake for [awakeHours] (Process S), 0–1.
  /// Pressure builds quickly at first and then flattens.
  static double _sleepPressure(double awakeHours) =>
      1 - math.exp(-math.max(0, awakeHours) / 13.5);

  /// Body-clock alertness at clock hour [hour] (Process C), roughly -1.3…1.3.
  /// The 24-hour term puts the low point before dawn; the 12-hour term is what
  /// creates the familiar early-afternoon dip.
  static double _circadian(double hour) =>
      math.cos(2 * math.pi * (hour - 17.5) / 24) +
      0.32 * math.cos(2 * math.pi * (hour - 8.5) / 12);

  static const double _circadianRange = 1.32;

  /// A half-hourly estimate from waking until bedtime.
  ///
  /// This is a shape, not a measurement: it says when energy is likely to rise
  /// and fall, given how long and how well someone slept.
  static List<EnergyPoint> _buildEnergyCurve({
    required SleepNight? lastNight,
    required double debtHours,
    required double needHours,
  }) {
    if (lastNight == null) return const [];

    final wake = lastNight.wakeTime;
    final wakeHour = wake == null ? 7.0 : wake.hour + wake.minute / 60;
    final slept = lastNight.hours ?? needHours;
    final quality = lastNight.feeling.score; // 1–5

    // Baseline: how much fuel the night actually provided.
    final shortfall = ((slept - needHours) / needHours).clamp(-1.0, 0.4);
    final base = 0.62 +
        0.10 * (quality - 3) / 2 +
        0.17 * shortfall -
        0.011 * debtHours.clamp(0, 24);

    // Awake for about 16 hours, or until the usual bedtime if it is known.
    final bed = lastNight.bedtime;
    var awakeSpan = 16.0;
    if (bed != null && wake != null) {
      final asleep = SleepCycleCalculator.hoursBetween(bed, wake);
      awakeSpan = (24 - asleep).clamp(10.0, 19.0);
    }

    final points = <EnergyPoint>[];
    for (var step = 0; step <= (awakeSpan * 2).round(); step++) {
      final awakeHours = step / 2;
      final hour = wakeHour + awakeHours;
      // Sleep inertia: the first hour after waking is genuinely foggy, and
      // more so after a poor night.
      final inertia = awakeHours < 1.2
          ? (1.2 - awakeHours) / 1.2 * (0.20 + 0.06 * (3 - quality))
          : 0.0;
      final value = base +
          0.26 * (_circadian(hour % 24) / _circadianRange) -
          0.34 * _sleepPressure(awakeHours) -
          inertia;
      points.add(EnergyPoint(hour, (value.clamp(0.05, 1.0)) * 100));
    }
    return points;
  }

  /// Turning points in the curve, described in plain clock terms.
  static List<EnergyWindow> _findWindows(List<EnergyPoint> curve) {
    if (curve.length < 5) return const [];
    final windows = <EnergyWindow>[];

    for (var i = 2; i < curve.length - 2; i++) {
      final value = curve[i].energy;
      final isPeak = value >= curve[i - 1].energy &&
          value >= curve[i - 2].energy &&
          value >= curve[i + 1].energy &&
          value > curve[i + 2].energy;
      final isDip = value <= curve[i - 1].energy &&
          value <= curve[i - 2].energy &&
          value <= curve[i + 1].energy &&
          value < curve[i + 2].energy;
      if (!isPeak && !isDip) continue;
      windows.add(
        _describeWindow(
          kind: isPeak ? EnergyWindowKind.peak : EnergyWindowKind.dip,
          curve: curve,
          index: i,
        ),
      );
    }

    // The first sustained rise after waking is a peak people feel even when
    // the curve is still climbing at the sampling resolution.
    if (windows.every((w) => w.kind != EnergyWindowKind.peak)) {
      var bestIndex = 0;
      for (var i = 1; i < curve.length; i++) {
        if (curve[i].energy > curve[bestIndex].energy) bestIndex = i;
      }
      windows.add(
        _describeWindow(
          kind: EnergyWindowKind.peak,
          curve: curve,
          index: bestIndex,
        ),
      );
    }

    windows.sort((a, b) => a.centreHour.compareTo(b.centreHour));
    return windows;
  }

  static EnergyWindow _describeWindow({
    required EnergyWindowKind kind,
    required List<EnergyPoint> curve,
    required int index,
  }) {
    final centre = curve[index].hour;
    final start = curve[math.max(0, index - 2)].hour;
    final end = curve[math.min(curve.length - 1, index + 2)].hour;
    final clockHour = centre % 24;
    final isPeak = kind == EnergyWindowKind.peak;

    final label = isPeak
        ? (clockHour < 12
            ? 'Morning peak'
            : clockHour < 17
                ? 'Afternoon peak'
                : 'Evening peak')
        : (clockHour < 12
            ? 'Late-morning dip'
            : clockHour < 17
                ? 'Afternoon dip'
                : 'Evening wind-down');

    final suggestion = isPeak
        ? 'Put your hardest task here — focus is cheapest to come by.'
        : (clockHour >= 17
            ? 'Energy is meant to fall now. Let it, rather than pushing on.'
            : 'Expect this. A short walk or daylight helps more than caffeine.');

    return EnergyWindow(
      kind: kind,
      startHour: start,
      endHour: end,
      centreHour: centre,
      level: curve[index].energy,
      label: label,
      suggestion: suggestion,
    );
  }

  // ---------------------------------------------------------------------
  // Feedback
  // ---------------------------------------------------------------------

  static int? _bedtimeSpread(List<SleepNight> nights) {
    final bedtimes = nights
        .map((night) => night.bedtime)
        .whereType<TimeOfDay>()
        // Measure from 18:00 so times either side of midnight stay adjacent.
        .map((time) => ((time.hour * 60 + time.minute) - 18 * 60 + 1440) % 1440)
        .toList();
    if (bedtimes.length < 2) return null;
    bedtimes.sort();
    return bedtimes.last - bedtimes.first;
  }

  static String _headline(
    SleepNight? lastNight,
    double needHours,
    String language,
  ) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    if (lastNight == null) {
      return pick(
        'Log a night to see how your energy is likely to run.',
        'Magtala ng gabi para makita kung paano tatakbo ang lakas mo.',
      );
    }
    final hours = lastNight.hours;
    if (hours == null) {
      return pick(
        'Logged as ${lastNight.feeling.label.toLowerCase()}. Add the hours '
            'next time for a sharper read.',
        'Naitala bilang ${lastNight.feeling.label.toLowerCase()}. Isama ang '
            'bilang ng oras sa susunod para mas malinaw.',
      );
    }
    final rounded = _formatHours(hours);
    if (hours >= needHours) {
      return pick(
        '$rounded of sleep — at or above the ${_formatHours(needHours)} you '
            'are aiming for.',
        '$rounded ng tulog — abot o lampas sa ${_formatHours(needHours)} na '
            'target mo.',
      );
    }
    final short = _formatHours(needHours - hours);
    return pick(
      '$rounded of sleep, $short short of your target.',
      '$rounded ng tulog, kulang ng $short sa target mo.',
    );
  }

  static List<SleepFeedbackItem> _buildFeedback({
    required SleepNight? lastNight,
    required List<SleepNight> recent,
    required List<SleepNight> measured,
    required double debtHours,
    required double averageHours,
    required double needHours,
    required int? bedtimeSpreadMinutes,
    required String language,
  }) {
    if (lastNight == null) return const [];
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);

    final items = <SleepFeedbackItem>[];
    void add(
      SleepFeedbackTone tone,
      String titleEn,
      String titleFil,
      String detailEn,
      String detailFil,
    ) {
      items.add(SleepFeedbackItem(
        tone: tone,
        title: pick(titleEn, titleFil),
        detail: pick(detailEn, detailFil),
      ));
    }

    final hours = lastNight.hours;
    final quality = lastNight.feeling.score;
    final nightCount = measured.length;
    final nightWord = pick(
      nightCount == 1 ? 'night' : 'nights',
      'gabi',
    );

    // 1. Last night against the target.
    if (hours != null) {
      if (hours >= needHours) {
        add(
          SleepFeedbackTone.good,
          'You gave yourself a full night',
          'Binigyan mo ang sarili ng buong gabi',
          '${_formatHours(hours)} meets the ${_formatHours(needHours)} '
              'target. Whatever you did last night is worth repeating.',
          'Abot ng ${_formatHours(hours)} ang target na '
              '${_formatHours(needHours)}. Ulitin ang ginawa mo kagabi.',
        );
      } else if (hours >= needHours - 1.5) {
        add(
          SleepFeedbackTone.watch,
          'A little under, not alarming',
          'Kaunting kulang, hindi nakakabahala',
          '${_formatHours(hours)} is ${_formatHours(needHours - hours)} '
              'short. One night like this is normal; a week of them adds up.',
          'Ang ${_formatHours(hours)} ay kulang ng '
              '${_formatHours(needHours - hours)}. Normal ang isang ganitong '
              'gabi; nagiipon ito kapag isang linggo na.',
        );
      } else {
        add(
          SleepFeedbackTone.concern,
          'That was a short night',
          'Maikli ang gabing iyon',
          'At ${_formatHours(hours)} you are '
              '${_formatHours(needHours - hours)} under. Expect slower '
              'thinking and a shorter fuse today, and plan around it rather '
              'than through it.',
          'Sa ${_formatHours(hours)}, kulang ka ng '
              '${_formatHours(needHours - hours)}. Asahan ang mabagal na '
              'pag-iisip at maikling pasensya ngayong araw — planuhin ito, '
              'huwag pilitin.',
        );
      }
    }

    // 2. Quality that disagrees with duration usually means broken sleep.
    if (hours != null && hours >= needHours - 0.5 && quality <= 2) {
      add(
        SleepFeedbackTone.watch,
        'Enough hours, but not enough rest',
        'Sapat ang oras, kulang ang pahinga',
        'Long but unrefreshing sleep usually points at broken sleep rather '
            'than short sleep — late meals, alcohol, a warm room, or waking '
            'repeatedly. If it keeps happening, it is worth raising with a '
            'doctor.',
        'Ang mahaba pero hindi nakakapagpahingang tulog ay kadalasang senyales '
            'ng putol-putol na tulog — huling kain, alak, mainit na kuwarto, o '
            'paulit-ulit na paggising. Kung tuloy-tuloy ito, sabihin sa '
            'doktor.',
      );
    } else if (hours != null && hours < needHours - 1.5 && quality >= 4) {
      add(
        SleepFeedbackTone.watch,
        'You feel fine now — that can be borrowed',
        'Maayos ka ngayon — pero hiram pa lang iyan',
        'Feeling good on short sleep is common in the first hours. The cost '
            'usually shows up in the afternoon rather than the morning.',
        'Karaniwan ang pakiramdam na maayos kahit kulang sa tulog sa mga '
            'unang oras. Kadalasan, sa hapon lumalabas ang bayad nito, hindi '
            'sa umaga.',
      );
    }

    // 3. Debt.
    if (debtHours >= 1) {
      final tone = debtHours >= 8
          ? SleepFeedbackTone.concern
          : debtHours >= 4
              ? SleepFeedbackTone.watch
              : SleepFeedbackTone.good;
      add(
        tone,
        '${_formatHours(debtHours)} of sleep debt built up',
        'Umabot sa ${_formatHours(debtHours)} ang sleep debt',
        debtHours >= 4
            ? 'Across your last $nightCount logged $nightWord. Debt is repaid '
                'in small instalments — an extra 45–60 minutes for several '
                'nights works, one long lie-in does not.'
            : 'Across your last $nightCount logged $nightWord. That is a '
                'small amount and one good night clears most of it.',
        debtHours >= 4
            ? 'Sa huling $nightCount na $nightWord na may tala. Bawiin ito '
                'nang paunti-unti — 45 hanggang 60 dagdag na minuto sa loob ng '
                'ilang gabi, hindi isang mahabang tulog.'
            : 'Sa huling $nightCount na $nightWord na may tala. Maliit lang '
                'ito at halos mabubura ng isang magandang gabi.',
      );
    } else if (nightCount >= 3) {
      add(
        SleepFeedbackTone.good,
        'No sleep debt worth chasing',
        'Walang sleep debt na dapat habulin',
        'Your last $nightCount nights averaged ${_formatHours(averageHours)}. '
            'This is the part most people never reach — protect it.',
        'Umabot sa ${_formatHours(averageHours)} ang karaniwan sa huling '
            '$nightCount gabi mo. Ito ang hindi naaabot ng karamihan — '
            'ingatan mo ito.',
      );
    }

    // 4. Consistency. An irregular schedule costs more than most people think.
    if (bedtimeSpreadMinutes != null) {
      if (bedtimeSpreadMinutes >= 120) {
        add(
          SleepFeedbackTone.watch,
          'Your bedtime moves by ${_formatMinutes(bedtimeSpreadMinutes)}',
          'Umaabot sa ${_formatMinutes(bedtimeSpreadMinutes)} ang galaw ng '
              'oras ng paghiga mo',
          'A body clock keeps worse time than a schedule does. Holding '
              'bedtime inside a one-hour window usually improves how you feel '
              'more than adding hours does.',
          'Mas hindi tumpak ang body clock kaysa sa iskedyul. Kadalasan, mas '
              'nakakabuti ang panatilihin ang paghiga sa loob ng isang oras na '
              'saklaw kaysa sa dagdag na oras ng tulog.',
        );
      } else {
        add(
          SleepFeedbackTone.good,
          'Your schedule is steady',
          'Matatag ang iskedyul mo',
          'Your bedtimes sit close together. A regular body clock is doing '
              'quiet work for you.',
          'Magkakalapit ang oras ng paghiga mo. Tahimik na tumutulong sa iyo '
              'ang regular na body clock.',
        );
      }
    }

    // 5. One concrete thing to do tonight.
    final wake = lastNight.wakeTime;
    if (wake != null) {
      final options = SleepCycleCalculator.bedtimesFor(wake, cycles: const [5]);
      final target = options.first.bedtime;
      add(
        SleepFeedbackTone.good,
        'Tonight, aim for ${_formatTime(target)}',
        'Mamayang gabi, tumutok sa ${_formatTime(target)}',
        'To wake at ${_formatTime(wake)} after five full sleep cycles (7.5 '
            'hours), with 15 minutes to fall asleep. Waking between cycles is '
            'why the same hours can feel very different.',
        'Para magising ng ${_formatTime(wake)} matapos ang limang buong sleep '
            'cycle (7.5 oras), may 15 minuto para makatulog. Ang paggising sa '
            'pagitan ng mga cycle ang dahilan kung bakit magkaiba ang '
            'pakiramdam sa parehong bilang ng oras.',
      );
    } else {
      add(
        SleepFeedbackTone.good,
        'Add your bed and wake times next time',
        'Isama ang oras ng paghiga at paggising sa susunod',
        'With clock times this screen can work out your best bedtime and show '
            'when your energy is likely to peak and dip.',
        'Sa oras ng paghiga at paggising, matutukoy dito ang pinakamainam na '
            'oras ng tulog at kung kailan tataas o bababa ang lakas mo.',
      );
    }

    return items;
  }

  static String _formatHours(double hours) {
    final total = (hours * 60).round();
    final whole = total ~/ 60;
    final minutes = total % 60;
    if (whole == 0) return '${minutes}m';
    if (minutes == 0) return '${whole}h';
    return '${whole}h ${minutes}m';
  }

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes / 60;
    return hours == hours.roundToDouble()
        ? '${hours.round()} hours'
        : '${hours.toStringAsFixed(1)} hours';
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String formatHours(double hours) => _formatHours(hours);
  static String formatTime(TimeOfDay time) => _formatTime(time);

  static String formatDecimalHour(double hour) {
    final wrapped = ((hour % 24) + 24) % 24;
    final wholeHour = wrapped.floor();
    final minutes = ((wrapped - wholeHour) * 60).round();
    return _formatTime(
      TimeOfDay(hour: wholeHour % 24, minute: minutes.clamp(0, 59)),
    );
  }
}
