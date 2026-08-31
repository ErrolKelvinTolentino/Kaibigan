import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/home/adaptive_support_recommendation.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';

void main() {
  final now = DateTime(2026, 8, 25, 12);

  MoodLog log({
    DateTime? createdAt,
    int mood = 3,
    int stress = 3,
    int energy = 3,
    int sleep = 3,
    int anxiety = 3,
  }) {
    return MoodLog(
      id: '$createdAt-$mood-$stress-$energy-$sleep-$anxiety',
      moodScore: mood,
      moodLabel: MoodLog.getMoodLabel(mood),
      stressLevel: stress,
      energyLevel: energy,
      sleepQuality: sleep,
      anxietyLevel: anxiety,
      createdAt: createdAt ?? now,
    );
  }

  group('AdaptiveSupportEngine', () {
    test('asks for a check-in when there is no recent mood data', () {
      final empty = AdaptiveSupportEngine.recommend(logs: const [], now: now);
      final stale = AdaptiveSupportEngine.recommend(
        logs: [log(createdAt: now.subtract(const Duration(hours: 37)))],
        now: now,
      );

      expect(empty.kind, AdaptiveSupportKind.checkIn);
      expect(stale.kind, AdaptiveSupportKind.checkIn);
      expect(stale.usesRecentCheckIn, isFalse);
    });

    test('uses the newest log even when the input is not sorted', () {
      final result = AdaptiveSupportEngine.recommend(
        logs: [
          log(createdAt: now.subtract(const Duration(hours: 2)), mood: 5),
          log(createdAt: now.subtract(const Duration(hours: 1)), stress: 5),
        ],
        now: now,
      );

      expect(result.kind, AdaptiveSupportKind.grounding);
      expect(result.reason, AdaptiveSupportReason.highStress);
    });

    test('prioritizes grounding when stress or anxiety is high', () {
      final result = AdaptiveSupportEngine.recommend(
        logs: [log(stress: 5, anxiety: 4, energy: 1, mood: 1)],
        now: now,
      );

      expect(result.kind, AdaptiveSupportKind.grounding);
      expect(result.reason, AdaptiveSupportReason.highStressAndAnxiety);
    });

    test('offers a low-effort breathing pause for low energy or sleep', () {
      final result = AdaptiveSupportEngine.recommend(
        logs: [log(energy: 2, sleep: 1)],
        now: now,
      );

      expect(result.kind, AdaptiveSupportKind.breathing);
      expect(result.reason, AdaptiveSupportReason.lowEnergyAndSleep);
    });

    test('offers reflection for low mood without stronger signals', () {
      final result = AdaptiveSupportEngine.recommend(
        logs: [log(mood: 2, stress: 3, anxiety: 3, energy: 3, sleep: 3)],
        now: now,
      );

      expect(result.kind, AdaptiveSupportKind.reflection);
      expect(result.reason, AdaptiveSupportReason.lowMood);
    });

    test('helps a positive mood become a gratitude memory', () {
      final result = AdaptiveSupportEngine.recommend(
        logs: [log(mood: 5, energy: 5)],
        now: now,
      );

      expect(result.kind, AdaptiveSupportKind.gratitude);
      expect(result.reason, AdaptiveSupportReason.positiveMood);
    });

    test('suggests focus for neutral mood with steady energy', () {
      final result = AdaptiveSupportEngine.recommend(
        logs: [log(mood: 3, energy: 4, stress: 2)],
        now: now,
      );

      expect(result.kind, AdaptiveSupportKind.focus);
      expect(result.reason, AdaptiveSupportReason.readyToFocus);
    });

    test('uses a neutral breathing pause for a balanced check-in', () {
      final result = AdaptiveSupportEngine.recommend(
        logs: [log()],
        now: now,
      );

      expect(result.kind, AdaptiveSupportKind.breathing);
      expect(result.reason, AdaptiveSupportReason.balancedPause);
    });
  });
}
