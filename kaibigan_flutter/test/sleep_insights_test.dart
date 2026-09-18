import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/sleep_insights.dart';

void main() {
  RoutineLog sleepLog({
    required DateTime at,
    required String duration,
    SleepFeeling feeling = SleepFeeling.moderate,
    TimeOfDay? bedtime,
    TimeOfDay? wakeTime,
  }) {
    return RoutineLog(
      id: 'log-${at.millisecondsSinceEpoch}',
      routineId: 'sleep_${at.millisecondsSinceEpoch}',
      routineType: RoutineType.morning,
      sleepFeeling: feeling,
      focusOrHighlight: SleepLogCodec.encode(
        durationLabel: duration,
        feeling: feeling,
        bedtime: bedtime,
        wakeTime: wakeTime,
      ),
      completedAt: at,
    );
  }

  group('SleepLogCodec', () {
    test('round-trips clock times through the existing text column', () {
      final encoded = SleepLogCodec.encode(
        durationLabel: '7.5',
        feeling: SleepFeeling.wellRested,
        bedtime: const TimeOfDay(hour: 23, minute: 15),
        wakeTime: const TimeOfDay(hour: 6, minute: 45),
      );
      final times = SleepLogCodec.decodeTimes(encoded);

      expect(encoded, startsWith('Slept 7.5 hrs'));
      expect(times, isNotNull);
      expect(times!.bedtime, const TimeOfDay(hour: 23, minute: 15));
      expect(times.wakeTime, const TimeOfDay(hour: 6, minute: 45));
    });

    test('older rows without clock times still parse', () {
      final log = RoutineLog(
        id: 'legacy',
        routineId: 'sleep_legacy',
        routineType: RoutineType.morning,
        sleepFeeling: SleepFeeling.groggy,
        focusOrHighlight: 'Slept 6 hrs: Needed a bit more sleep to feel awake',
        completedAt: DateTime(2026, 9, 9, 7),
      );
      final night = SleepLogCodec.nightFrom(log);

      expect(night, isNotNull);
      expect(night!.hours, 6);
      expect(night.bedtime, isNull);
      expect(night.hasClockTimes, isFalse);
    });

    test('a non-sleep log is not read as a night', () {
      final log = RoutineLog(
        id: 'breathing',
        routineId: 'breathing_1',
        routineType: RoutineType.midday,
        focusOrHighlight: 'Completed 2 minute Box breathing exercise.',
        completedAt: DateTime(2026, 9, 9, 13),
      );
      expect(SleepLogCodec.nightFrom(log), isNull);
    });
  });

  group('SleepCycleCalculator', () {
    test('counts hours across midnight', () {
      expect(
        SleepCycleCalculator.hoursBetween(
          const TimeOfDay(hour: 23, minute: 0),
          const TimeOfDay(hour: 7, minute: 0),
        ),
        8,
      );
      expect(
        SleepCycleCalculator.hoursBetween(
          const TimeOfDay(hour: 1, minute: 30),
          const TimeOfDay(hour: 6, minute: 0),
        ),
        4.5,
      );
    });

    test('bedtimes leave 15 minutes to fall asleep before whole cycles', () {
      final options = SleepCycleCalculator.bedtimesFor(
        const TimeOfDay(hour: 7, minute: 0),
        cycles: const [5],
      );
      // 7:00 minus 7h30m of sleep minus 15 minutes to drop off.
      expect(options.single.bedtime, const TimeOfDay(hour: 23, minute: 15));
      expect(options.single.hours, 7.5);
    });

    test('wake times wrap past midnight correctly', () {
      final options = SleepCycleCalculator.wakeTimesFor(
        const TimeOfDay(hour: 22, minute: 30),
        cycles: const [5],
      );
      expect(options.single.wakeTime, const TimeOfDay(hour: 6, minute: 15));
    });
  });

  group('SleepInsights', () {
    final now = DateTime(2026, 9, 10, 9);

    test('sleep debt only counts shortfall inside the recent window', () {
      final insights = SleepInsights.build(
        [
          sleepLog(at: DateTime(2026, 9, 10, 7), duration: '6'),
          sleepLog(at: DateTime(2026, 9, 9, 7), duration: '5.5'),
          sleepLog(at: DateTime(2026, 9, 8, 7), duration: '9'),
          // Well outside the 14-day window: not tonight's problem.
          sleepLog(at: DateTime(2026, 1, 1, 7), duration: '3'),
        ],
        now: now,
      );

      // (8-6) + (8-5.5) + 0, with the January night excluded.
      expect(insights.debtHours, closeTo(4.5, 0.001));
      expect(insights.debtWindowNights, 3);
      expect(insights.averageHours, closeTo(6.833, 0.01));
    });

    test('a well-slept stretch reports no debt', () {
      final insights = SleepInsights.build(
        [
          sleepLog(at: DateTime(2026, 9, 10, 7), duration: '8'),
          sleepLog(at: DateTime(2026, 9, 9, 7), duration: '8.5'),
          sleepLog(at: DateTime(2026, 9, 8, 7), duration: '8'),
        ],
        now: now,
      );

      expect(insights.debtHours, 0);
      expect(
        insights.feedback.any((item) => item.title.contains('No sleep debt')),
        isTrue,
      );
    });

    test('the energy curve starts at the wake time and names peaks and dips',
        () {
      final insights = SleepInsights.build(
        [
          sleepLog(
            at: DateTime(2026, 9, 10, 7),
            duration: '8',
            feeling: SleepFeeling.wellRested,
            bedtime: const TimeOfDay(hour: 23, minute: 0),
            wakeTime: const TimeOfDay(hour: 7, minute: 0),
          ),
        ],
        now: now,
      );

      expect(insights.hasEnergyCurve, isTrue);
      expect(insights.energyCurve.first.hour, 7.0);
      expect(insights.peaks, isNotEmpty);

      // Sleep inertia: the first half hour awake is not the day's high point.
      final firstEnergy = insights.energyCurve.first.energy;
      final laterEnergy = insights.energyCurve
          .firstWhere((point) => point.hour >= 10)
          .energy;
      expect(laterEnergy, greaterThan(firstEnergy));

      // Every point stays inside the fixed 0-100 axis the chart draws.
      for (final point in insights.energyCurve) {
        expect(point.energy, inInclusiveRange(0, 100));
      }
    });

    test('a short night sits lower than a full one all day', () {
      List<EnergyPoint> curveFor(String duration, SleepFeeling feeling) =>
          SleepInsights.build(
            [
              sleepLog(
                at: DateTime(2026, 9, 10, 7),
                duration: duration,
                feeling: feeling,
                bedtime: const TimeOfDay(hour: 23, minute: 0),
                wakeTime: const TimeOfDay(hour: 7, minute: 0),
              ),
            ],
            now: now,
          ).energyCurve;

      final rested = curveFor('8', SleepFeeling.wellRested);
      final short = curveFor('4', SleepFeeling.groggy);

      expect(rested.length, short.length);
      for (var i = 0; i < rested.length; i++) {
        expect(
          short[i].energy,
          lessThan(rested[i].energy),
          reason: 'point $i should be lower after a short night',
        );
      }
    });

    test('feedback names the shortfall and one thing to do tonight', () {
      final insights = SleepInsights.build(
        [
          sleepLog(
            at: DateTime(2026, 9, 10, 7),
            duration: '5',
            feeling: SleepFeeling.groggy,
            bedtime: const TimeOfDay(hour: 2, minute: 0),
            wakeTime: const TimeOfDay(hour: 7, minute: 0),
          ),
        ],
        now: now,
      );

      expect(insights.headline, contains('3h short'));
      expect(
        insights.feedback.any(
          (item) => item.tone == SleepFeedbackTone.concern,
        ),
        isTrue,
      );
      expect(
        insights.feedback.any((item) => item.title.startsWith('Tonight, aim')),
        isTrue,
        reason: 'the read should end with something actionable',
      );
    });

    test('an irregular bedtime is called out once there is evidence', () {
      final insights = SleepInsights.build(
        [
          sleepLog(
            at: DateTime(2026, 9, 10, 7),
            duration: '7',
            bedtime: const TimeOfDay(hour: 0, minute: 30),
            wakeTime: const TimeOfDay(hour: 7, minute: 30),
          ),
          sleepLog(
            at: DateTime(2026, 9, 9, 7),
            duration: '8',
            bedtime: const TimeOfDay(hour: 21, minute: 30),
            wakeTime: const TimeOfDay(hour: 5, minute: 30),
          ),
        ],
        now: now,
      );

      expect(insights.bedtimeSpreadMinutes, 180);
      expect(
        insights.feedback.any((item) => item.title.contains('bedtime moves')),
        isTrue,
      );
    });

    test('no logs yields an honest empty read rather than invented numbers',
        () {
      final insights = SleepInsights.build(const [], now: now);

      expect(insights.hasEnergyCurve, isFalse);
      expect(insights.feedback, isEmpty);
      expect(insights.debtHours, 0);
      expect(insights.headline, contains('Log a night'));
    });
  });
}
