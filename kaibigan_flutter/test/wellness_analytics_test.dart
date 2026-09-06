import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/insights/wellness_analytics.dart';
import 'package:kaibigan_flutter/features/insights/wellness_insights_panel.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';

void main() {
  final now = DateTime(2026, 9, 6, 20);
  MoodLog mood(String id, int day, int score, [int hour = 9]) => MoodLog(
    id: id, moodScore: score, moodLabel: 'Test', createdAt: DateTime(2026, 9, day, hour));
  RoutineLog log(String id, String activity, int day, {String? text, SleepFeeling? sleep}) => RoutineLog(
    id: id, routineId: activity, routineType: RoutineType.morning,
    completedAt: DateTime(2026, 9, day, 9), focusOrHighlight: text, sleepFeeling: sleep);

  test('streak requires an activity, allows today, breaks after a missed day', () {
    expect(WellnessStreak.fromDates([], now: now).current, 0);
    final streak = WellnessStreak.fromDates([
      DateTime(2026, 9, 5), DateTime(2026, 9, 4), DateTime(2026, 9, 4, 17),
      DateTime(2026, 9, 2), DateTime(2026, 9, 1), DateTime(2026, 8, 31),
      DateTime(2026, 9, 7)], now: now);
    expect(streak.current, 2);
    expect(streak.longest, 3);
    expect(streak.todayCompleted, false);
    expect(WellnessStreak.fromDates([DateTime(2026, 9, 4)], now: now).current, 0);
  });

  test('month and year boundary use consecutive calendar days', () {
    expect(WellnessStreak.fromDates([DateTime(2025, 12, 31), DateTime(2026, 1, 1)],
      now: DateTime(2026, 1, 1, 20)).current, 2);
  });

  test('averages give every logged day equal weight; exclude duplicate/future/invalid scores', () {
    final snapshot = WellnessAnalytics.build(now: now, moods: [
      mood('a', 6, 5), mood('b', 6, 5, 12), mood('c', 5, 1),
      mood('c', 5, 1), mood('future', 7, 2), mood('invalid', 4, 9)]);
    expect(snapshot.metrics['mood']!.count, 3);
    expect(snapshot.metrics['mood']!.average, 3);
    expect(snapshot.activeDays, 2);
    expect(snapshot.dayCounts.values.where((v) => v == 0).length, 5);
    expect(snapshot.metrics['mood']!.change, isNull);
  });

  test('practice counts never masquerade as completed routines or inferred sleep', () {
    final snapshot = WellnessAnalytics.build(now: now, routines: [
      log('b', 'breathing_1', 6, text: 'Completed 2 minute Calm exhale breathing exercise.'),
      log('g', 'grounding_1', 5, text: 'Completed 5-4-3-2-1 grounding.'),
      log('r', 'morning', 4),
      log('note', 'highlight_1', 4, text: 'I need more sleep'),
      log('legacy', 'morning', 3, sleep: SleepFeeling.groggy),
    ]);
    expect(snapshot.metrics['routine']!.count, 1);
    expect(snapshot.metrics['breathing']!.count, 1);
    expect(snapshot.metrics['breathing']!.totalMinutes, 2);
    expect(snapshot.metrics['grounding']!.count, 1);
    expect(snapshot.metrics['sleep']!.count, 1);
    expect(snapshot.sleepHours, isNull);
    expect(snapshot.toPromptContext(), contains('do not diagnose'));
  });

  test('unknown and ranged sleep durations never become exact average hours', () {
    final snapshot = WellnessAnalytics.build(now: now, routines: [
      log('a', 'sleep_1', 6, sleep: SleepFeeling.energized, text: 'Slept 8 hrs: okay'),
      log('b', 'sleep_2', 5, sleep: SleepFeeling.groggy, text: 'Slept 10+ hrs'),
      log('c', 'sleep_3', 4, sleep: SleepFeeling.restless),
      log('d', 'sleep_4', 3, text: 'Slept Less than 1 hrs'),
      log('e', 'sleep_5', 2, text: 'Slept 99 hours'),
    ]);
    expect(snapshot.sleepHours, 8);
    expect(snapshot.sleepDurationDays, 1);
    expect(snapshot.metrics['sleep']!.numericDays, 3);
  });

  test('score comparison needs three logged days in each period', () {
    final snapshot = WellnessAnalytics.build(now: now, moods: [
      mood('a', 6, 4), mood('b', 5, 4), mood('c', 4, 4),
      mood('d', -1, 2), mood('e', -2, 2), mood('f', -3, 2),
    ]);
    expect(snapshot.metrics['mood']!.change, 2);
    expect(snapshot.observations.map((o) => o.id), contains('mood_change'));
  });

  testWidgets('analytics lead with a verbal insight and helpful next step',
      (tester) async {
    final snapshot = WellnessAnalytics.build(
      now: now,
      moods: [
        mood('a', 6, 4),
        mood('b', 5, 3),
        mood('c', 4, 4),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WellnessInsightsPanel(
              snapshot: snapshot,
              language: 'english',
              feature: 'mood',
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('wellness-verbal-insight')),
        findsOneWidget);
    expect(find.text('What your logs are saying'), findsOneWidget);
    expect(find.byKey(const ValueKey('wellness-next-step')), findsOneWidget);
    expect(find.text('The numbers behind it'), findsOneWidget);
  });

  for (final language in ['english', 'filipino', 'taglish']) {
    testWidgets('insights fit 320px with enlarged $language text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme,
        home: MediaQuery(data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.8)),
          child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16),
            child: WellnessInsightsPanel(snapshot: WellnessAnalytics.build(now: now,
              moods: [mood('a', 6, 2)]), language: language))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
