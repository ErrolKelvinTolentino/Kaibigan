import '../mood_tracking/mood_model.dart';
import 'activity_feedback_store.dart';

enum AdaptiveSupportKind {
  checkIn,
  grounding,
  breathing,
  reflection,
  gratitude,
  focus,
}

enum AdaptiveSupportReason {
  noRecentCheckIn,
  highStress,
  highAnxiety,
  highStressAndAnxiety,
  lowEnergy,
  poorSleep,
  lowEnergyAndSleep,
  lowMood,
  positiveMood,
  readyToFocus,
  balancedPause,
}

class AdaptiveSupportRecommendation {
  final AdaptiveSupportKind kind;
  final AdaptiveSupportReason reason;
  final MoodLog? source;

  const AdaptiveSupportRecommendation({
    required this.kind,
    required this.reason,
    this.source,
  });

  bool get usesRecentCheckIn => source != null;
}

/// Chooses one existing Kaibigan activity using only structured mood-check-in
/// values. Journal content and AI are deliberately not involved.
class AdaptiveSupportEngine {
  static const Duration recentCheckInWindow = Duration(hours: 36);

  static AdaptiveSupportRecommendation recommend({
    required Iterable<MoodLog> logs,
    required DateTime now,
    Iterable<ActivityFeedbackRecord> feedback = const [],
  }) {
    final latest = _latest(logs);
    if (latest == null ||
        latest.createdAt.isAfter(now.add(const Duration(minutes: 5))) ||
        now.difference(latest.createdAt) > recentCheckInWindow) {
      return const AdaptiveSupportRecommendation(
        kind: AdaptiveSupportKind.checkIn,
        reason: AdaptiveSupportReason.noRecentCheckIn,
      );
    }

    final highStress = latest.stressLevel >= 4;
    final highAnxiety = latest.anxietyLevel >= 4;
    if (highStress || highAnxiety) {
      return _adjustForFeedback(
        AdaptiveSupportRecommendation(
          kind: AdaptiveSupportKind.grounding,
          reason: highStress && highAnxiety
              ? AdaptiveSupportReason.highStressAndAnxiety
              : highStress
                  ? AdaptiveSupportReason.highStress
                  : AdaptiveSupportReason.highAnxiety,
          source: latest,
        ),
        feedback,
        now,
      );
    }

    final lowEnergy = latest.energyLevel <= 2;
    final poorSleep = latest.sleepQuality <= 2;
    if (lowEnergy || poorSleep) {
      return _adjustForFeedback(
        AdaptiveSupportRecommendation(
          kind: AdaptiveSupportKind.breathing,
          reason: lowEnergy && poorSleep
              ? AdaptiveSupportReason.lowEnergyAndSleep
              : lowEnergy
                  ? AdaptiveSupportReason.lowEnergy
                  : AdaptiveSupportReason.poorSleep,
          source: latest,
        ),
        feedback,
        now,
      );
    }

    if (latest.moodScore <= 2) {
      return _adjustForFeedback(
        AdaptiveSupportRecommendation(
          kind: AdaptiveSupportKind.reflection,
          reason: AdaptiveSupportReason.lowMood,
          source: latest,
        ),
        feedback,
        now,
      );
    }

    if (latest.moodScore >= 4) {
      return _adjustForFeedback(
        AdaptiveSupportRecommendation(
          kind: AdaptiveSupportKind.gratitude,
          reason: AdaptiveSupportReason.positiveMood,
          source: latest,
        ),
        feedback,
        now,
      );
    }

    if (latest.energyLevel >= 4 && latest.stressLevel <= 3) {
      return _adjustForFeedback(
        AdaptiveSupportRecommendation(
          kind: AdaptiveSupportKind.focus,
          reason: AdaptiveSupportReason.readyToFocus,
          source: latest,
        ),
        feedback,
        now,
      );
    }

    return _adjustForFeedback(
      AdaptiveSupportRecommendation(
        kind: AdaptiveSupportKind.breathing,
        reason: AdaptiveSupportReason.balancedPause,
        source: latest,
      ),
      feedback,
      now,
    );
  }

  static AdaptiveSupportRecommendation _adjustForFeedback(
    AdaptiveSupportRecommendation recommendation,
    Iterable<ActivityFeedbackRecord> feedback,
    DateTime now,
  ) {
    final candidates = switch (recommendation.kind) {
      AdaptiveSupportKind.grounding => const [
          AdaptiveSupportKind.grounding,
          AdaptiveSupportKind.breathing,
          AdaptiveSupportKind.reflection,
        ],
      AdaptiveSupportKind.breathing => const [
          AdaptiveSupportKind.breathing,
          AdaptiveSupportKind.grounding,
          AdaptiveSupportKind.reflection,
        ],
      AdaptiveSupportKind.reflection => const [
          AdaptiveSupportKind.reflection,
          AdaptiveSupportKind.grounding,
          AdaptiveSupportKind.breathing,
        ],
      AdaptiveSupportKind.gratitude => const [
          AdaptiveSupportKind.gratitude,
          AdaptiveSupportKind.reflection,
          AdaptiveSupportKind.breathing,
        ],
      AdaptiveSupportKind.focus => const [
          AdaptiveSupportKind.focus,
          AdaptiveSupportKind.breathing,
          AdaptiveSupportKind.grounding,
        ],
      AdaptiveSupportKind.checkIn => const [AdaptiveSupportKind.checkIn],
    };
    final selected = candidates.firstWhere(
      (candidate) => !_wasRecentlyUnhelpful(candidate, feedback, now),
      orElse: () => candidates.last,
    );
    if (selected == recommendation.kind) return recommendation;
    return AdaptiveSupportRecommendation(
      kind: selected,
      reason: recommendation.reason,
      source: recommendation.source,
    );
  }

  static bool _wasRecentlyUnhelpful(
    AdaptiveSupportKind kind,
    Iterable<ActivityFeedbackRecord> feedback,
    DateTime now,
  ) {
    ActivityFeedbackRecord? latest;
    for (final record in feedback) {
      final matches = record.activityId == kind.name ||
          (kind == AdaptiveSupportKind.reflection &&
              record.activityId == 'journal') ||
          (kind == AdaptiveSupportKind.gratitude &&
              record.activityId == 'highlight') ||
          (kind == AdaptiveSupportKind.focus &&
              record.activityId.startsWith('routine:'));
      if (!matches ||
          record.createdAt.isAfter(now.add(const Duration(minutes: 5))) ||
          now.difference(record.createdAt) > const Duration(hours: 18)) {
        continue;
      }
      if (latest == null || record.createdAt.isAfter(latest.createdAt)) {
        latest = record;
      }
    }
    return latest?.helpfulness == ActivityHelpfulness.notHelpful;
  }

  static MoodLog? _latest(Iterable<MoodLog> logs) {
    MoodLog? latest;
    for (final log in logs) {
      if (latest == null || log.createdAt.isAfter(latest.createdAt)) {
        latest = log;
      }
    }
    return latest;
  }
}
