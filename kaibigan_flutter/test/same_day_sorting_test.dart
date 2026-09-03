import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/utils/date_formatter.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Same-day sorting and UTC serialization', () {
    test('models serialize timestamps in UTC ISO8601 with Z', () {
      final localTime = DateTime(2026, 9, 4, 14, 30, 0);

      final journal = JournalEntry(
        id: 'journal-1',
        title: 'Morning thought',
        content: 'Content',
        companionId: 'kai',
        createdAt: localTime,
      );
      final journalMap = journal.toMap();
      expect(journalMap['created_at'], endsWith('Z'));
      final parsedJournal = JournalEntry.fromMap(journalMap);
      expect(parsedJournal.createdAt.isUtc, isFalse);
      expect(parsedJournal.createdAt.hour, localTime.hour);
      expect(parsedJournal.createdAt.minute, localTime.minute);

      final mood = MoodLog(
        id: 'mood-1',
        moodScore: 4,
        moodLabel: 'Good',
        createdAt: localTime,
      );
      final moodMap = mood.toMap();
      expect(moodMap['created_at'], endsWith('Z'));
      final parsedMood = MoodLog.fromMap(moodMap);
      expect(parsedMood.createdAt.isUtc, isFalse);
      expect(parsedMood.createdAt.hour, localTime.hour);

      final gratitude = GratitudeEntry(
        id: 'gratitude-1',
        content: 'Sunny sky',
        createdAt: localTime,
      );
      final gratitudeMap = gratitude.toMap();
      expect(gratitudeMap['created_at'], endsWith('Z'));
      final parsedGratitude = GratitudeEntry.fromMap(gratitudeMap);
      expect(parsedGratitude.createdAt.isUtc, isFalse);
      expect(parsedGratitude.createdAt.hour, localTime.hour);

      final routine = RoutineLog(
        id: 'routine-1',
        routineId: 'morning',
        routineType: RoutineType.morning,
        completedAt: localTime,
      );
      final routineMap = routine.toMap();
      expect(routineMap['completed_at'], endsWith('Z'));
      final parsedRoutine = RoutineLog.fromMap(routineMap);
      expect(parsedRoutine.completedAt.isUtc, isFalse);
      expect(parsedRoutine.completedAt.hour, localTime.hour);

      final letter = FutureLetter(
        id: 'letter-1',
        title: 'Future note',
        content: 'Content',
        deliverAt: localTime.add(const Duration(days: 7)),
        createdAt: localTime,
      );
      final letterMap = letter.toMap();
      expect(letterMap['created_at'], endsWith('Z'));
      expect(letterMap['deliver_at'], endsWith('Z'));
      final parsedLetter = FutureLetter.fromMap(letterMap);
      expect(parsedLetter.createdAt.isUtc, isFalse);
      expect(parsedLetter.createdAt.hour, localTime.hour);
    });

    test('JournalEntry sorts same-day entries with newest at the top', () {
      final baseDay = DateTime(2026, 9, 4);

      final morning = JournalEntry(
        id: 'journal-morning',
        title: 'Morning entry',
        content: 'Coffee and quiet',
        companionId: 'kai',
        createdAt: baseDay.add(const Duration(hours: 8, minutes: 15)),
      );
      final afternoon = JournalEntry(
        id: 'journal-afternoon',
        title: 'Afternoon walk',
        content: 'Walked in the park',
        companionId: 'kai',
        createdAt: baseDay.add(const Duration(hours: 14, minutes: 30)),
      );
      final evening = JournalEntry(
        id: 'journal-evening',
        title: 'Night reflection',
        content: 'Ready for sleep',
        companionId: 'kai',
        createdAt: baseDay.add(const Duration(hours: 21, minutes: 0)),
      );

      final rawList = [
        morning.toMap(),
        evening.toMap(),
        afternoon.toMap(),
      ];

      final mapped = rawList.map((m) => JournalEntry.fromMap(m)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(mapped[0].title, 'Night reflection');
      expect(mapped[1].title, 'Afternoon walk');
      expect(mapped[2].title, 'Morning entry');
    });

    test('MoodProvider sorts same-day check-ins with newest at the top', () {
      final baseDay = DateTime(2026, 9, 4);

      final checkIn1 = MoodLog(
        id: 'mood-8am',
        moodScore: 3,
        moodLabel: 'Okay',
        createdAt: baseDay.add(const Duration(hours: 8)),
      );
      final checkIn2 = MoodLog(
        id: 'mood-1pm',
        moodScore: 4,
        moodLabel: 'Good',
        createdAt: baseDay.add(const Duration(hours: 13)),
      );
      final checkIn3 = MoodLog(
        id: 'mood-9pm',
        moodScore: 5,
        moodLabel: 'Great',
        createdAt: baseDay.add(const Duration(hours: 21)),
      );

      final logs = [checkIn1, checkIn3, checkIn2]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(logs.first.id, 'mood-9pm');
      expect(logs[1].id, 'mood-1pm');
      expect(logs.last.id, 'mood-8am');
    });

    test('DateFormatter.formatJournalDate displays time on same-day entries', () {
      final now = DateTime.now();
      final todayMorning = DateTime(now.year, now.month, now.day, 9, 30);
      final todayAfternoon = DateTime(now.year, now.month, now.day, 15, 45);

      final morningFormatted =
          DateFormatter.formatJournalDate(todayMorning, language: 'english');
      final afternoonFormatted =
          DateFormatter.formatJournalDate(todayAfternoon, language: 'english');

      expect(morningFormatted, startsWith('Today •'));
      expect(morningFormatted, contains('9:30 AM'));
      expect(afternoonFormatted, startsWith('Today •'));
      expect(afternoonFormatted, contains('3:45 PM'));

      final filipinoFormatted =
          DateFormatter.formatJournalDate(todayMorning, language: 'filipino');
      expect(filipinoFormatted, startsWith('Ngayon •'));
      expect(filipinoFormatted, contains('9:30 AM'));

      final pastDate = DateTime(2026, 8, 15, 10, 0);
      final pastFormatted =
          DateFormatter.formatJournalDate(pastDate, language: 'english');
      expect(pastFormatted, contains('Aug 15, 2026 • 10:00 AM'));
    });
  });
}
