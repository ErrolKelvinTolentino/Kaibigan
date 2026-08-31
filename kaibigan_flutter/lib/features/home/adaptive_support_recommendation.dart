import '../mood_tracking/mood_model.dart';

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
      return AdaptiveSupportRecommendation(
        kind: AdaptiveSupportKind.grounding,
        reason: highStress && highAnxiety
            ? AdaptiveSupportReason.highStressAndAnxiety
            : highStress
                ? AdaptiveSupportReason.highStress
                : AdaptiveSupportReason.highAnxiety,
        source: latest,
      );
    }

    final lowEnergy = latest.energyLevel <= 2;
    final poorSleep = latest.sleepQuality <= 2;
    if (lowEnergy || poorSleep) {
      return AdaptiveSupportRecommendation(
        kind: AdaptiveSupportKind.breathing,
        reason: lowEnergy && poorSleep
            ? AdaptiveSupportReason.lowEnergyAndSleep
            : lowEnergy
                ? AdaptiveSupportReason.lowEnergy
                : AdaptiveSupportReason.poorSleep,
        source: latest,
      );
    }

    if (latest.moodScore <= 2) {
      return AdaptiveSupportRecommendation(
        kind: AdaptiveSupportKind.reflection,
        reason: AdaptiveSupportReason.lowMood,
        source: latest,
      );
    }

    if (latest.moodScore >= 4) {
      return AdaptiveSupportRecommendation(
        kind: AdaptiveSupportKind.gratitude,
        reason: AdaptiveSupportReason.positiveMood,
        source: latest,
      );
    }

    if (latest.energyLevel >= 4 && latest.stressLevel <= 3) {
      return AdaptiveSupportRecommendation(
        kind: AdaptiveSupportKind.focus,
        reason: AdaptiveSupportReason.readyToFocus,
        source: latest,
      );
    }

    return AdaptiveSupportRecommendation(
      kind: AdaptiveSupportKind.breathing,
      reason: AdaptiveSupportReason.balancedPause,
      source: latest,
    );
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
