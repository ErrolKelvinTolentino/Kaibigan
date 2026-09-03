import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_service.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/weekly_reflection/weekly_reflection_service.dart';

void main() {
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
    expect(snapshot.completedRoutines, 1);
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
      now: DateTime(2026, 8, 29),
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
    expect(local.experiment, contains('What I needed then was'));
  });
}
