import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/wellness_journey/daily_goals_provider.dart';

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
    });

    test('daily goals wait for an authenticated per-user store', () {
      expect(DailyGoalsProvider().goals, isEmpty);
    });
  });
}
