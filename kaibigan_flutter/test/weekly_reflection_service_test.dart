import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_service.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/weekly_reflection/weekly_reflection_service.dart';

void main() {
  test('AI shares analytics and does not infer sleep from check-in defaults', () {
    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 29, 18),
      moods: [MoodLog(id: 'm', moodScore: 3, moodLabel: 'Okay',
          createdAt: DateTime(2026, 8, 29, 9))],
      routines: [RoutineLog(id: 'b', routineId: 'breathing_box',
          routineType: RoutineType.morning,
          completedAt: DateTime(2026, 8, 29, 9),
          focusOrHighlight: 'Completed 2 minute box breathing')],
    );
    expect(snapshot.averageSleep, isNull);
    expect(snapshot.completedRoutines, 0);
    expect(snapshot.toCompactPrompt(language: 'english'), contains('breathing: 1'));
    expect(snapshot.toCompactPrompt(language: 'english'), contains('Counts do not prove symptom relief'));
  });

  test('small comparison groups and future logs do not create a pattern', () {
    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 29, 18),
      moods: [
        MoodLog(id: 'a', moodScore: 1, moodLabel: 'Low', createdAt: DateTime(2026, 8, 27)),
        MoodLog(id: 'b', moodScore: 5, moodLabel: 'Good', createdAt: DateTime(2026, 8, 28)),
        MoodLog(id: 'future', moodScore: 5, moodLabel: 'Good', createdAt: DateTime(2026, 8, 29, 22)),
      ],
      routines: [RoutineLog(id: 'r', routineId: 'morning',
          routineType: RoutineType.morning, completedAt: DateTime(2026, 8, 28))],
    );
    expect(snapshot.moodCheckIns, 2);
    expect(snapshot.routineMoodDelta, isNull);
    expect(snapshot.moodTrend, isNull);
  });

  test('weekly reflection uses only the latest seven calendar days', () {
    final now = DateTime(2026, 8, 25, 18);
    final snapshot = WeeklyReflectionService.build(
      now: now,
      moods: [
        MoodLog(
          id: 'm1',
          moodScore: 4,
          moodLabel: 'Good',
          energyLevel: 4,
          stressLevel: 2,
          sleepQuality: 5,
          createdAt: DateTime(2026, 8, 25, 8),
        ),
        MoodLog(
          id: 'old',
          moodScore: 1,
          moodLabel: 'Low',
          createdAt: DateTime(2026, 8, 18),
        ),
      ],
      journals: [
        JournalEntry(
          id: 'j1',
          title: 'Today',
          content: 'Private content',
          companionId: 'kai',
          createdAt: DateTime(2026, 8, 23),
        ),
      ],
      gratitudes: [
        GratitudeEntry(
          id: 'g1',
          content: 'A quiet morning',
          createdAt: DateTime(2026, 8, 24),
        ),
      ],
      routines: [
        RoutineLog(
          id: 'r1',
          routineId: 'morning',
          routineType: RoutineType.morning,
          completedAt: DateTime(2026, 8, 25, 9),
          sleepFeeling: SleepFeeling.wellRested,
        ),
      ],
    );

    expect(snapshot.moodCheckIns, 1);
    expect(snapshot.journalEntries, 1);
    expect(snapshot.gratitudeEntries, 1);
    expect(snapshot.completedRoutines, 0,
        reason: 'A legacy sleep step is not a completed routine.');
    expect(snapshot.wellness.metrics['sleep']!.count, 1);
    expect(snapshot.activeDays, 3);
    expect(snapshot.averageMood, 4);
    expect(snapshot.averageSleep, 4,
        reason: 'An explicit routine sleep log replaces the generic value.');
  });

  test('weekly AI prompt includes user writing but not Kai replies', () {
    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 25),
      journals: [
        JournalEntry(
          id: 'j1',
          title: 'Secret title',
          content: 'My highly private journal sentence',
          aiResponse: 'Kai response that must not be included',
          companionId: 'ann',
          createdAt: DateTime(2026, 8, 24),
        ),
      ],
    );

    final prompt = snapshot.toCompactPrompt(language: 'english');
    expect(prompt, contains('User-authored journal entries'));
    expect(prompt, contains('1 journal entries'));
    expect(prompt, contains('My highly private journal sentence'));
    expect(prompt, isNot(contains('Kai response that must not be included')));
    expect(prompt, isNot(contains('not logged/5')));
  });

  test('aggregate signature changes when the underlying weekly totals change',
      () {
    final before = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 25),
      moods: [
        MoodLog(
          id: 'm1',
          moodScore: 3,
          moodLabel: 'Okay',
          createdAt: DateTime(2026, 8, 25),
        ),
      ],
    );
    final after = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 25),
      moods: [
        MoodLog(
          id: 'm1',
          moodScore: 3,
          moodLabel: 'Okay',
          createdAt: DateTime(2026, 8, 25),
        ),
        MoodLog(
          id: 'm2',
          moodScore: 5,
          moodLabel: 'Great',
          createdAt: DateTime(2026, 8, 24),
        ),
      ],
    );

    expect(before.dataSignature, isNot(after.dataSignature));
    expect(before.dataSignature, isNot(contains('Okay')));
  });

  test('weekly mode owns the structure instead of treating it as journal text',
      () {
    final prompt = AIService.getSystemPrompt(
      companionId: 'kai',
      language: 'english',
      mode: CompanionMode.weeklyReflection,
    );

    expect(prompt, contains('CURRENT MODE: WEEKLY REFLECTION'));
    expect(prompt, contains('**Evidence**'));
    expect(prompt, contains('**Pattern**'));
    expect(prompt, contains('**One experiment**'));
    expect(prompt, contains('Never invent events'));
  });

  test('structured weekly narrative parses but generic fallback does not', () {
    const structured = '''
**Evidence**

Mood averaged 3.5/5 across four check-ins.

**Pattern**

Energy and stress moved in opposite directions.

**One experiment**

Check in before and after the busiest period on three days.
''';
    const genericFallback = '''
**What I noticed**

The emotional weight seems closest to today.

**Today's theme**

Pressure and limited energy.

**A question to sit with**

Which part feels important?
''';

    final narrative = WeeklyReflectionNarrative.tryParse(structured);
    expect(narrative, isNotNull);
    expect(narrative!.evidence, contains('3.5/5'));
    expect(narrative.experiment, contains('three days'));
    expect(WeeklyReflectionNarrative.tryParse(genericFallback), isNull);
  });

  test('device reflection remains structured and honest with sparse data', () {
    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 29, 18),
      moods: [
        MoodLog(
          id: 'one-check-in',
          moodScore: 3,
          moodLabel: 'Okay',
          energyLevel: 2,
          stressLevel: 4,
          sleepQuality: 2,
          createdAt: DateTime(2026, 8, 29, 9),
        ),
      ],
    );

    final local = WeeklyReflectionService.buildLocalNarrative(
      snapshot,
      language: 'english',
    );
    final parsed = WeeklyReflectionNarrative.tryParse(local.toMarkdown());

    expect(parsed, isNotNull);
    expect(parsed!.evidence, contains('1 mood check-in'));
    expect(parsed.evidence, isNot(contains('/5')));
    expect(parsed.pattern, contains('not yet enough active days'));
    expect(parsed.experiment, contains('three days next week'));
  });

  test('device reflection uses the words from weekly journal entries', () {
    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 29),
      journals: [
        JournalEntry(
          id: 'journal-context',
          title: 'A hard afternoon',
          content: 'I felt overwhelmed, then a short walk helped me breathe.',
          aiResponse: 'Kai said something separate.',
          companionId: 'kai',
          createdAt: DateTime(2026, 8, 28),
        ),
      ],
    );

    final local = WeeklyReflectionService.buildLocalNarrative(
      snapshot,
      language: 'english',
    );

    expect(local.evidence, contains('a short walk helped me breathe'));
    expect(local.evidence, isNot(contains('Kai said something separate')));
    expect(local.experiment, contains('grounding'));
  });

  test('routine template questions are stripped from journal excerpts', () {
    const rawContent = '''
1. What went well today?
i did an activity with my friends.

2. What challenged you today?
i didn't feel energized.

3. What did you learn or feel grateful for?
that the day doesn't need to be perfect for me to feel satisfaction from it
''';

    final cleaned = WeeklyReflectionService.cleanJournalContent(rawContent);
    expect(cleaned, isNot(contains('1. What went well today?')));
    expect(cleaned, isNot(contains('2. What challenged you today?')));
    expect(cleaned, isNot(contains('3. What did you learn')));
    expect(cleaned, contains('i did an activity with my friends.'));
    expect(cleaned, contains("i didn't feel energized."));
    expect(cleaned, contains("that the day doesn't need to be perfect"));

    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 29),
      journals: [
        JournalEntry(
          id: 'routine-journal',
          title: 'Daily Reflection',
          content: rawContent,
          companionId: 'kai',
          createdAt: DateTime(2026, 8, 28),
        ),
      ],
    );

    expect(snapshot.journalExcerpts.first, isNot(contains('1. What went well today?')));
    expect(snapshot.journalExcerpts.first, contains('activity with my friends'));
  });

  test('crisis journal entries trigger supportive crisis guidance and are never used as anchors', () {
    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 29),
      journals: [
        JournalEntry(
          id: 'crisis-entry',
          title: 'Heavy day',
          content: 'sa totoo lang parang gusto ko na mamatay',
          companionId: 'kai',
          createdAt: DateTime(2026, 8, 28),
        ),
      ],
    );

    final localFilipino = WeeklyReflectionService.buildLocalNarrative(
      snapshot,
      language: 'filipino',
    );
    expect(localFilipino.experiment, contains('1553'));
    expect(localFilipino.experiment, contains('0917-899-8727'));
    expect(localFilipino.experiment, isNot(contains('gusto ko na mamatay')));
    expect(localFilipino.pattern, isNot(contains('do not establish a repeated pattern')));

    final localEnglish = WeeklyReflectionService.buildLocalNarrative(
      snapshot,
      language: 'english',
    );
    expect(localEnglish.experiment, contains('1553'));
    expect(localEnglish.experiment, contains('0917-899-8727'));
    expect(localEnglish.experiment, contains('NCMH'));
    expect(localEnglish.experiment, isNot(contains('gusto ko na mamatay')));
    expect(localEnglish.experiment, isNot(contains('What I needed then was')));
  });

  test('self-compassion and perfectionism theme generates tailored practice of good enough', () {
    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 29),
      journals: [
        JournalEntry(
          id: 'perfectionism-entry',
          title: 'Evening reflection',
          content: 'I realized that the day does not need to be perfect for me to feel satisfaction from it.',
          companionId: 'kai',
          createdAt: DateTime(2026, 8, 28),
        ),
      ],
    );

    final local = WeeklyReflectionService.buildLocalNarrative(
      snapshot,
      language: 'english',
    );
    expect(local.pattern, contains('self-compassion'));
    expect(local.pattern, contains('good enough'));
    expect(local.experiment, contains('good enough'));
    expect(local.pattern, isNot(contains('do not establish a repeated pattern')));
  });

  test('connection and fatigue theme generates tailored supportive experiment', () {
    final snapshot = WeeklyReflectionService.build(
      now: DateTime(2026, 8, 29),
      journals: [
        JournalEntry(
          id: 'connection-fatigue-entry',
          title: 'Friends and low battery',
          content: 'Spent time with friends even though my energy was drained and I felt exhausted.',
          companionId: 'kai',
          createdAt: DateTime(2026, 8, 28),
        ),
      ],
    );

    final local = WeeklyReflectionService.buildLocalNarrative(
      snapshot,
      language: 'english',
    );
    expect(local.pattern, contains('Connection'));
    expect(local.pattern, contains('low battery'));
    expect(local.experiment, contains('recharge'));
  });

  group('sleep debt reaches the weekly reflection', () {
    final now = DateTime(2026, 8, 29, 18);

    List<RoutineLog> shortNights(int count) => List.generate(
          count,
          (index) => RoutineLog(
            id: 'sleep-$index',
            routineId: 'sleep_$index',
            routineType: RoutineType.morning,
            sleepFeeling: SleepFeeling.groggy,
            focusOrHighlight: 'Slept 6 hrs: Needed a bit more sleep',
            completedAt: now.subtract(Duration(days: index)),
          ),
        );

    test('the accumulated shortfall is carried on the snapshot', () {
      final snapshot = WeeklyReflectionService.build(
        now: now,
        routines: shortNights(4),
      );

      expect(snapshot.sleepDebtHours, closeTo(8, 0.001));
      expect(snapshot.sleepDebtNights, 4);
      expect(snapshot.sleepStatusTitle, isNotEmpty);
      expect(snapshot.sleepRecoveryAction, isNotEmpty);
    });

    test('the prompt states the debt and forbids treating it as the cause',
        () {
      final prompt = WeeklyReflectionService.build(
        now: now,
        routines: shortNights(4),
      ).toCompactPrompt(language: 'english');

      expect(prompt, contains('Sleep debt: 8.0 hours'));
      expect(prompt, contains('never present it as the cause'));
    });

    test('nights without exact durations leave the debt unknown, not zero',
        () {
      final prompt = WeeklyReflectionService.build(
        now: now,
        routines: [
          RoutineLog(
            id: 'ranged',
            routineId: 'sleep_ranged',
            routineType: RoutineType.morning,
            sleepFeeling: SleepFeeling.moderate,
            focusOrHighlight: 'Slept 10+ hrs: Slept okay',
            completedAt: now,
          ),
        ],
      ).toCompactPrompt(language: 'english');

      expect(prompt, contains('unknown rather than zero'));
    });

    test('a standing debt becomes the local pattern and a testable step', () {
      final narrative = WeeklyReflectionService.buildLocalNarrative(
        WeeklyReflectionService.build(now: now, routines: shortNights(4)),
        language: 'english',
      );

      expect(narrative.pattern, contains('8.0 hours of missed sleep'));
      expect(narrative.experiment, contains('30 minutes earlier'));
    });

    test('changing only the debt invalidates a saved reflection', () {
      String signature(int nights) => WeeklyReflectionService.build(
            now: now,
            routines: shortNights(nights),
          ).dataSignature;

      expect(signature(3), isNot(signature(4)));
    });
  });
}
