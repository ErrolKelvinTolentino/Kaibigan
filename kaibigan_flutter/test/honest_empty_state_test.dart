import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';

void main() {
  group('honest unauthenticated state', () {
    test('personal history providers do not seed fabricated records', () {
      expect(JournalProvider().entries, isEmpty);
      expect(MoodProvider().logs, isEmpty);
      expect(GratitudeProvider().entries, isEmpty);
      expect(LettersProvider().letters, isEmpty);
      expect(RoutinesProvider().logs, isEmpty);
    });

    test('empty mood history has no invented positive average', () {
      expect(MoodProvider().averageWeeklyScore, 0);
      expect(MoodProvider().weeklyMoodAverage, isNull,
          reason: 'an unlogged week has no average, which is not the same '
              'as an average of zero');
    });
  });

  group('weekly mood average', () {
    MoodLog log(String id, int daysAgo, int score, [int hour = 9]) {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day - daysAgo, hour);
      return MoodLog(
        id: id,
        moodScore: score,
        moodLabel: 'Test',
        createdAt: day,
      );
    }

    MoodProvider providerWith(List<MoodLog> logs) =>
        MoodProvider(initialLogs: logs, syncOnCreate: false);

    test('a day with several check-ins still counts as one day', () {
      final provider = providerWith([
        log('a', 0, 5),
        log('b', 0, 5, 12),
        log('c', 0, 5, 18),
        log('d', 1, 1),
      ]);

      expect(provider.weeklyMoodAverage, 3);
    });

    test('days older than the window are left out of the week', () {
      final provider = providerWith([log('recent', 1, 4), log('old', 20, 1)]);

      expect(provider.weeklyMoodAverage, 4);
    });

    test('a week with nothing logged reports no average, not a low one', () {
      final provider = providerWith([log('old', 30, 2)]);

      expect(provider.weeklyMoodAverage, isNull);
      expect(provider.logs, isNotEmpty);
    });

    test('out-of-range scores are ignored rather than skewing the week', () {
      final provider = providerWith([log('bad', 0, 9), log('good', 1, 4)]);

      expect(provider.weeklyMoodAverage, 4);
    });
  });
}
