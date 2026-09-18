import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/screens/sleep_status_card.dart';
import 'package:kaibigan_flutter/features/routines/sleep_insights.dart';

void main() {
  RoutineLog night({
    required DateTime at,
    required String duration,
    SleepFeeling feeling = SleepFeeling.moderate,
    TimeOfDay? bedtime,
    TimeOfDay? wakeTime,
  }) =>
      RoutineLog(
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

  final now = DateTime(2026, 9, 10, 9);

  List<RoutineLog> nightsOf(
    String duration, {
    int count = 3,
    SleepFeeling feeling = SleepFeeling.moderate,
  }) =>
      List.generate(
        count,
        (index) => night(
          at: now.subtract(Duration(days: index)),
          duration: duration,
          feeling: feeling,
        ),
      );

  group('sleep debt level', () {
    test('a full-length stretch is named as keeping up, with nothing to repay',
        () {
      final status = SleepInsights.build(nightsOf('8'), now: now).status;

      expect(status.level, SleepDebtLevel.none);
      expect(status.isDeprived, isFalse);
      expect(status.hasDebt, isFalse);
      expect(status.recovery, isNull);
      expect(status.title, 'You are keeping up with sleep');
      expect(status.symptomNote, isNull);
    });

    test('a small shortfall stays small rather than being called deprivation',
        () {
      final status = SleepInsights.build(nightsOf('7.5'), now: now).status;

      expect(status.debtHours, closeTo(1.5, 0.001));
      expect(status.level, SleepDebtLevel.slight);
      expect(status.isDeprived, isFalse);
      expect(status.meaning, contains('less than half a night'));
    });

    test('six hours a night is called sleep deprivation, not a moderate debt',
        () {
      // 6 hours short of 8 on every night is the escalation case: the same
      // six-hour total spread over a fortnight would not be deprivation.
      final status = SleepInsights.build(nightsOf('6'), now: now).status;

      expect(status.debtHours, closeTo(6, 0.001));
      expect(status.level, SleepDebtLevel.high);
      expect(status.isDeprived, isTrue);
      expect(status.title, 'You are sleep deprived');
      expect(status.symptomNote, isNotNull);
      expect(status.symptomNote, contains('shorter fuse'));
    });

    test('the same total spread thinly is not escalated', () {
      // Six hours of debt across twelve nights: 30 minutes short each night.
      final logs = List.generate(
        12,
        (index) => night(
          at: now.subtract(Duration(days: index)),
          duration: '7.5',
        ),
      );
      final status = SleepInsights.build(logs, now: now).status;

      expect(status.debtHours, closeTo(6, 0.001));
      expect(status.level, SleepDebtLevel.moderate);
      expect(status.isDeprived, isFalse);
    });

    test('a very large debt reports the severe level and its warning', () {
      final status = SleepInsights.build(nightsOf('4', count: 5), now: now)
          .status;

      expect(status.debtHours, closeTo(20, 0.001));
      expect(status.level, SleepDebtLevel.severe);
      expect(status.symptomNote, contains('doctor'));
      expect(status.meaning, contains('full nights of sleep'));
    });

    test('no timed nights says so instead of reporting zero debt', () {
      final status = SleepInsights.build(const [], now: now).status;

      expect(status.level, SleepDebtLevel.none);
      expect(status.loggedNights, 0);
      expect(status.title, 'No sleep debt recorded');
      expect(status.meaning, contains('Log a night'));
    });
  });

  group('recovery plan', () {
    test('a small debt is cleared inside a few nights of modest extra sleep',
        () {
      final plan = SleepInsights.build(nightsOf('7.5'), now: now)
          .status
          .recovery!;

      expect(plan.extraMinutesPerNight, 30);
      expect(plan.nights, 3);
      expect(plan.clearsDebt, isTrue);
      expect(plan.repaidHours, closeTo(1.5, 0.001));
    });

    test('a larger debt raises the nightly amount before extending the plan',
        () {
      final plan = SleepInsights.build(nightsOf('6'), now: now).status.recovery!;

      expect(plan.nights, lessThanOrEqualTo(7));
      expect(plan.extraMinutesPerNight, 60);
      expect(plan.clearsDebt, isTrue);
    });

    test('a debt too large for one week is offered as a first instalment', () {
      final status = SleepInsights.build(nightsOf('4', count: 5), now: now)
          .status;
      final plan = status.recovery!;

      expect(plan.clearsDebt, isFalse);
      expect(plan.nights, 7);
      expect(plan.extraMinutesPerNight, 60);
      expect(status.action, contains('this week'));
    });

    test('the plan never promises repayment by sleeping in', () {
      final status = SleepInsights.build(nightsOf('6'), now: now).status;
      expect(status.action, contains('60 minutes longer'));
      expect(status.action, isNot(contains('lie-in')));
    });
  });

  group('tips', () {
    test('a debt leads with moving bedtime rather than the alarm', () {
      final tips = SleepInsights.build(nightsOf('6'), now: now).tips;

      expect(tips.first.id, 'earlier_bedtime');
      expect(tips.length, lessThanOrEqualTo(4));
    });

    test('deprivation adds the instalment warning about one long lie-in', () {
      final tips = SleepInsights.build(nightsOf('6'), now: now).tips;
      expect(tips.map((tip) => tip.id), contains('instalments'));
    });

    test('an irregular schedule is answered with a fixed wake time', () {
      final logs = [
        night(
          at: now,
          duration: '7',
          bedtime: const TimeOfDay(hour: 0, minute: 30),
          wakeTime: const TimeOfDay(hour: 7, minute: 30),
        ),
        night(
          at: now.subtract(const Duration(days: 1)),
          duration: '8',
          bedtime: const TimeOfDay(hour: 21, minute: 30),
          wakeTime: const TimeOfDay(hour: 5, minute: 30),
        ),
      ];
      final tips = SleepInsights.build(logs, now: now).tips;

      expect(tips.map((tip) => tip.id), contains('anchor_wake_time'));
      expect(
        tips.firstWhere((tip) => tip.id == 'anchor_wake_time').detail,
        contains('3 hours'),
      );
    });

    test('enough hours but no rest points at the room, not at more time', () {
      final logs = [
        night(at: now, duration: '8', feeling: SleepFeeling.restless),
        night(
          at: now.subtract(const Duration(days: 1)),
          duration: '8',
          feeling: SleepFeeling.restless,
        ),
      ];
      final tips = SleepInsights.build(logs, now: now).tips;

      expect(tips.map((tip) => tip.id), contains('room_setup'));
      expect(tips.map((tip) => tip.id), contains('get_up_if_awake'));
    });

    test('a well-slept stretch is told what to protect instead of what to fix',
        () {
      final tips = SleepInsights.build(
        nightsOf('8', feeling: SleepFeeling.wellRested),
        now: now,
      ).tips;

      expect(tips.map((tip) => tip.id), contains('protect_it'));
      expect(tips.map((tip) => tip.id), isNot(contains('earlier_bedtime')));
    });

    test('too few nights says so rather than inventing a pattern', () {
      final tips = SleepInsights.build(
        [night(at: now, duration: '5')],
        now: now,
      ).tips;

      expect(tips.map((tip) => tip.id), contains('log_more_nights'));
    });

    test('no logs at all asks for clock times and stops there', () {
      final tips = SleepInsights.build(const [], now: now).tips;

      expect(tips, hasLength(1));
      expect(tips.single.id, 'start_logging');
    });
  });

  test('status, feedback and tips all follow the chosen language', () {
    final insights = SleepInsights.build(
      nightsOf('6'),
      now: now,
      language: 'filipino',
    );

    expect(insights.status.title, 'Kulang ka sa tulog');
    expect(insights.headline, contains('ng tulog'));
    expect(insights.tips.first.title, contains('paghiga'));
    expect(
      insights.feedback.any((item) => item.title.contains('gabi')),
      isTrue,
    );
  });

  group('SleepStatusCard', () {
    Widget host(SleepInsights insights) => MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SleepStatusCard(insights: insights),
            ),
          ),
        );

    testWidgets('names the level, the shortfall and the way back', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(host(SleepInsights.build(nightsOf('6'), now: now)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sleep-status-title')), findsOneWidget);
      expect(find.text('You are sleep deprived'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('sleep-status-symptoms')), findsOneWidget);
      expect(find.byKey(const ValueKey('sleep-status-plan')), findsOneWidget);
      expect(find.text('+60m'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a clear week shows no warning and no repayment chips',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(host(SleepInsights.build(nightsOf('8'), now: now)));
      await tester.pumpAndSettle();

      expect(find.text('You are keeping up with sleep'), findsOneWidget);
      expect(find.byKey(const ValueKey('sleep-status-symptoms')), findsNothing);
      expect(find.textContaining('per night'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a narrow screen with enlarged text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.8),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SleepStatusCard(
                      insights:
                          SleepInsights.build(nightsOf('4', count: 5), now: now),
                    ),
                    SleepTipsCard(
                      insights:
                          SleepInsights.build(nightsOf('4', count: 5), now: now),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
