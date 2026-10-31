import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/insights/plain_language_insights.dart';
import 'package:kaibigan_flutter/features/insights/wellness_analytics.dart';
import 'package:kaibigan_flutter/features/insights/wellness_insights_panel.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';

void main() {
  final now = DateTime(2026, 9, 6, 20);

  MoodLog mood(String id, int day, int score, [int hour = 9]) => MoodLog(
        id: id,
        moodScore: score,
        moodLabel: 'Test',
        createdAt: DateTime(2026, 9, day, hour),
      );

  RoutineLog routine(String id, String activity, int day,
          {String? text, SleepFeeling? sleep}) =>
      RoutineLog(
        id: id,
        routineId: activity,
        routineType: RoutineType.morning,
        completedAt: DateTime(2026, 9, day, 9),
        focusOrHighlight: text,
        sleepFeeling: sleep,
      );

  WeekReading readingFor({
    List<MoodLog> moods = const [],
    List<RoutineLog> routines = const [],
    Iterable<DateTime> journalDates = const [],
    Iterable<DateTime> gratitudeDates = const [],
    String language = 'english',
  }) =>
      PlainLanguageInsights.read(
        WellnessAnalytics.build(
          now: now,
          moods: moods,
          routines: routines,
          journalDates: journalDates,
          gratitudeDates: gratitudeDates,
        ),
        language: language,
      );

  group('week headline', () {
    test('an empty week says so instead of describing a pattern', () {
      final reading = readingFor();

      expect(reading.headline, 'Nothing logged yet');
      expect(reading.subhead, contains('One check-in is enough'));
      expect(reading.contrast, isNull);
      expect(reading.links, isEmpty);
    });

    test('a comparable improvement leads with the change, not the average',
        () {
      final reading = readingFor(moods: [
        mood('a', 6, 4),
        mood('b', 5, 4),
        mood('c', 4, 5),
        mood('d', -1, 2),
        mood('e', -2, 2),
        mood('f', -3, 2),
      ]);

      expect(reading.headline, 'An easier week than the last');
      expect(reading.subhead, contains('+2.'));
      expect(reading.subhead, contains('not every day'));
    });

    test('a comparable decline is named plainly rather than softened', () {
      final reading = readingFor(moods: [
        mood('a', 6, 2),
        mood('b', 5, 2),
        mood('c', 4, 2),
        mood('d', -1, 4),
        mood('e', -2, 4),
        mood('f', -3, 4),
      ]);

      expect(reading.headline, 'A harder week than the last');
      expect(reading.subhead, contains('−2.0'));
    });

    test('without a comparison the headline describes this week only', () {
      final reading = readingFor(moods: [
        mood('a', 6, 4),
        mood('b', 5, 4),
        mood('c', 4, 3),
      ]);

      expect(reading.headline, 'Mostly okay days');
      expect(reading.subhead, contains('3 logged days'));
    });

    test('activity without any check-in does not invent a felt experience',
        () {
      final reading = readingFor(routines: [
        routine('b', 'breathing_1', 6,
            text: 'Completed 2 minute Calm exhale breathing exercise.'),
      ]);

      expect(reading.headline, contains('You showed up on 1 of 7 days'));
      expect(reading.subhead, contains('No mood check-ins yet'));
    });
  });

  group('key figure', () {
    test('mood wins when there are enough logged days', () {
      final reading = readingFor(moods: [
        mood('a', 6, 4),
        mood('b', 5, 3),
        mood('c', 4, 5),
      ]);

      expect(reading.keyFigure, '4.0');
      expect(reading.keyFigureLabel, contains('out of 5'));
    });

    test('sleep hours stand in when mood is too sparse to average', () {
      final reading = readingFor(routines: [
        routine('s1', 'sleep_1', 6,
            sleep: SleepFeeling.wellRested, text: 'Slept 7 hrs: ok'),
        routine('s2', 'sleep_2', 5,
            sleep: SleepFeeling.moderate, text: 'Slept 8 hrs: ok'),
      ]);

      expect(reading.keyFigure, '7.5h');
      expect(reading.keyFigureLabel, contains('2 timed nights'));
    });

    test('otherwise it falls back to days of care, never to a made-up score',
        () {
      final reading = readingFor(moods: [mood('a', 6, 4)]);

      expect(reading.keyFigure, '1/7');
      expect(reading.keyFigureLabel, contains('days with a moment of care'));
    });
  });

  group('metric readings', () {
    test('a score becomes a word, with the figure kept as evidence', () {
      final reading = readingFor(moods: [
        mood('a', 6, 2),
        mood('b', 5, 2),
        mood('c', 4, 2),
      ]);
      final plain = reading.metric('mood')!;

      expect(plain.headline, 'A heavy week');
      expect(plain.value, '2.0/5');
      expect(plain.support, contains('3 logged days'));
    });

    test('a small week-on-week move reads as steady rather than as progress',
        () {
      final reading = readingFor(moods: [
        mood('a', 6, 3),
        mood('b', 5, 3),
        mood('c', 4, 4),
        mood('d', -1, 3),
        mood('e', -2, 3),
        mood('f', -3, 3),
      ]);
      final plain = reading.metric('mood')!;

      expect(plain.direction, InsightDirection.steady);
      expect(plain.trendLabel, 'about the same as last week');
    });

    test('an incomparable metric says what is missing, not "no change"', () {
      final reading = readingFor(moods: [mood('a', 6, 4), mood('b', 5, 4)]);
      final plain = reading.metric('mood')!;

      expect(plain.direction, InsightDirection.unknown);
      expect(plain.trendLabel, contains('3 logged days in each week'));
    });

    test('counted activities compare counts in words', () {
      final reading = readingFor(routines: [
        routine('b1', 'breathing_1', 6, text: 'Completed 2 minute a exercise.'),
        routine('b2', 'breathing_2', 5, text: 'Completed 2 minute a exercise.'),
        routine('b3', 'breathing_3', -2,
            text: 'Completed 2 minute a exercise.'),
      ]);
      final plain = reading.metric('breathing')!;

      expect(plain.headline, '2 saved');
      expect(plain.direction, InsightDirection.better);
      expect(plain.trendLabel, '1 more than last week');
    });
  });

  group('lightest and heaviest day', () {
    test('needs three logged days and a real gap between them', () {
      expect(
        readingFor(moods: [mood('a', 6, 5), mood('b', 5, 1)]).contrast,
        isNull,
        reason: 'two days is not enough to have a best and a worst',
      );
      expect(
        readingFor(moods: [
          mood('a', 6, 3),
          mood('b', 5, 3),
          mood('c', 4, 4),
        ]).contrast,
        isNull,
        reason: 'a one-point spread is the smallest step the scale has',
      );
    });

    test('names both days and what else was logged on each', () {
      final contrast = readingFor(
        moods: [mood('a', 6, 5), mood('b', 5, 3), mood('c', 4, 1)],
        routines: [
          routine('b1', 'breathing_1', 6,
              text: 'Completed 2 minute Calm exhale breathing exercise.'),
        ],
      ).contrast!;

      expect(contrast.bestDay, DateTime(2026, 9, 6));
      expect(contrast.hardestDay, DateTime(2026, 9, 4));
      expect(contrast.spread, 4);
      expect(contrast.bestCompanions, contains('breathing'));
      expect(contrast.hardestCompanions, isEmpty);
    });
  });

  group('associations', () {
    test('a grouping with too few days on one side is not reported', () {
      final reading = readingFor(
        moods: [
          for (var day = 0; day < 6; day++) mood('m$day', 6 - day, 3),
        ],
        routines: [
          routine('r1', 'morning', 6),
          routine('r2', 'morning', 5),
        ],
      );

      expect(reading.links, isEmpty);
    });

    test('a real split is reported as an association with its caveat', () {
      final reading = readingFor(
        moods: [
          mood('m1', 6, 5),
          mood('m2', 5, 5),
          mood('m3', 4, 4),
          mood('m4', 3, 2),
          mood('m5', 2, 2),
          mood('m6', 1, 2),
        ],
        routines: [
          routine('r1', 'morning', 6),
          routine('r2', 'morning', 5),
          routine('r3', 'morning', 4),
        ],
      );
      final link = reading.links.firstWhere((l) => l.id == 'routine_mood');

      expect(link.statement, contains('finished a routine'));
      expect(link.statement, contains('+2.'));
      expect(link.withDays, 3);
      expect(link.withoutDays, 3);
      expect(link.caveat, contains('not one causing the other'));
    });

    test('at most two associations are shown, strongest first', () {
      final reading = readingFor(
        moods: [
          mood('m1', 6, 5),
          mood('m2', 5, 5),
          mood('m3', 4, 5),
          mood('m4', 3, 1),
          mood('m5', 2, 1),
          mood('m6', 1, 1),
        ],
        routines: [
          routine('r1', 'morning', 6),
          routine('r2', 'morning', 5),
          routine('r3', 'morning', 4),
          routine('g1', 'grounding_1', 6, text: 'Completed grounding.'),
          routine('g2', 'grounding_2', 5, text: 'Completed grounding.'),
          routine('g3', 'grounding_3', 4, text: 'Completed grounding.'),
        ],
      );

      expect(reading.links.length, lessThanOrEqualTo(2));
      expect(reading.links, isNotEmpty);
    });
  });

  test('every reading follows the chosen language', () {
    final reading = readingFor(
      moods: [mood('a', 6, 2), mood('b', 5, 2), mood('c', 4, 2)],
      language: 'filipino',
    );

    expect(reading.headline, 'Mabigat na linggo');
    expect(reading.metric('mood')!.support, contains('araw na may tala'));
  });

  group('WellnessInsightsPanel', () {
    testWidgets('leads with the plain headline before any figure',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WellnessInsightsPanel(
              snapshot: WellnessAnalytics.build(now: now, moods: [
                mood('a', 6, 5),
                mood('b', 5, 3),
                mood('c', 4, 1),
              ]),
              language: 'english',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('wellness-plain-headline')), findsOneWidget);
      expect(find.byKey(const ValueKey('wellness-plain-mood')), findsOneWidget);
      expect(find.byKey(const ValueKey('wellness-day-contrast')), findsOneWidget);
      expect(find.text('Your lightest and heaviest day'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final language in ['english', 'filipino']) {
      testWidgets(
          'the full $language panel fits 320px with enlarged text',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // A week with enough data for every card: headline, associations,
        // the day contrast and the tiles.
        final snapshot = WellnessAnalytics.build(
          now: now,
          moods: [
            mood('m1', 6, 5),
            mood('m2', 5, 5),
            mood('m3', 4, 4),
            mood('m4', 3, 1),
            mood('m5', 2, 1),
            mood('m6', 1, 2),
          ],
          routines: [
            routine('r1', 'morning', 6),
            routine('r2', 'morning', 5),
            routine('r3', 'morning', 4),
          ],
        );

        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.8),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: WellnessInsightsPanel(
                  snapshot: snapshot,
                  language: language,
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('wellness-links')), findsOneWidget);

        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -4000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a single feature view keeps to that feature', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WellnessInsightsPanel(
              snapshot: WellnessAnalytics.build(now: now, moods: [
                mood('a', 6, 5),
                mood('b', 5, 3),
                mood('c', 4, 1),
              ]),
              language: 'english',
              feature: 'mood',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('wellness-plain-headline')), findsNothing);
      expect(find.byKey(const ValueKey('wellness-day-contrast')), findsNothing);
      expect(find.byKey(const ValueKey('wellness-plain-mood')), findsOneWidget);
      expect(find.byKey(const ValueKey('wellness-feature-rhythm-mood')), findsOneWidget);
      expect(find.byKey(const ValueKey('wellness-export-summary-button')), findsOneWidget);
    });

    test('journaling against mood is recognized as an association', () {
      final reading = readingFor(
        moods: [
          mood('m1', 6, 5),
          mood('m2', 5, 5),
          mood('m3', 4, 4),
          mood('m4', 3, 2),
          mood('m5', 2, 2),
          mood('m6', 1, 2),
        ],
        journalDates: [
          DateTime(2026, 9, 6, 9),
          DateTime(2026, 9, 5, 9),
          DateTime(2026, 9, 4, 9),
        ],
      );

      final link = reading.links.firstWhere((l) => l.id == 'journal_mood');
      expect(link.statement, contains('wrote in your journal'));
      expect(link.withDays, 3);
    });
  });

  test('the prompt context carries a day-by-day record, not only averages',
      () {
    final snapshot = WellnessAnalytics.build(now: now, moods: [
      mood('a', 6, 5),
      mood('b', 4, 1),
    ], routines: [
      routine('b1', 'breathing_1', 6,
          text: 'Completed 2 minute Calm exhale breathing exercise.'),
    ]);
    final prompt = snapshot.toPromptContext();

    expect(prompt, contains('Day-by-day record'));
    expect(prompt, contains('2026-09-06: mood 5.0/5'));
    expect(prompt, contains('logged breathing'));
    expect(prompt, contains('2026-09-05: nothing logged'));
    expect(prompt, contains('unknown, not a bad'));
  });
}
