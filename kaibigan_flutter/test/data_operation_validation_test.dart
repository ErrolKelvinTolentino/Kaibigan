import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('data operation validation', () {
    test('journal rejects an entirely empty create', () async {
      final provider = JournalProvider();

      final result = await provider.addJournalEntry(
        title: '   ',
        content: '   ',
        companionId: 'kai',
        mood: 'calm',
      );

      expect(result, isNull);
      expect(provider.entries, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });

    test('gratitude rejects an empty create', () async {
      final provider = GratitudeProvider();

      final result = await provider.addGratitudeEntry('   ');

      expect(result, isNull);
      expect(provider.entries, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });

    test('mood rejects scores outside the supported range', () async {
      final provider = MoodProvider();

      final result = await provider.logMood(score: 8, label: 'Invalid');

      expect(result, isNull);
      expect(provider.logs, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });

    test('future letters reject delivery dates in the past', () async {
      final provider = LettersProvider();

      final result = await provider.createLetter(
        title: 'Later',
        content: 'Remember this.',
        deliverAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(result, isNull);
      expect(provider.letters, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });

    test('routine logs reject invalid mood values before persistence',
        () async {
      final provider = RoutinesProvider();

      final saved = await provider.addLog(
        RoutineLog(
          id: '',
          routineId: 'night',
          routineType: RoutineType.night,
          completedAt: DateTime.now(),
          moodScore: 9,
        ),
      );

      expect(saved, isFalse);
      expect(provider.logs, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });
  });
}
