import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

enum AIReplyFeedback { helpful, notHelpful }

enum AIReplyFeedbackReason {
  tooGeneric,
  wrongLanguage,
  tooMuchAdvice,
  repetitive,
  missedThePoint,
}

/// What repeated feedback has taught the app about how this person wants to be
/// answered.
///
/// A single "not helpful" is noise — people misread a reply, or the moment was
/// simply wrong. A reason chosen several times inside a recent window is a
/// preference, and it is worth carrying into later conversations instead of
/// only fixing the one reply in front of them.
class AIPreferenceProfile {
  const AIPreferenceProfile({
    required this.helpfulCount,
    required this.notHelpfulCount,
    required this.reasonCounts,
  });

  static const AIPreferenceProfile empty = AIPreferenceProfile(
    helpfulCount: 0,
    notHelpfulCount: 0,
    reasonCounts: {},
  );

  final int helpfulCount;
  final int notHelpfulCount;
  final Map<AIReplyFeedbackReason, int> reasonCounts;

  /// How many times a reason must appear in the recent window before it steers
  /// anything. Two is enough to separate a pattern from a bad day.
  static const int learningThreshold = 2;

  int get totalCount => helpfulCount + notHelpfulCount;

  /// Reasons that have crossed the threshold, strongest first.
  List<AIReplyFeedbackReason> get learnedReasons {
    final learned = reasonCounts.entries
        .where((entry) => entry.value >= learningThreshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // More than two standing corrections starts to crowd out the actual
    // conversation, so only the strongest signals are carried.
    return learned.take(2).map((entry) => entry.key).toList(growable: false);
  }

  bool get hasSignal => learnedReasons.isNotEmpty;

  /// Durable prompt lines describing what this person has repeatedly asked
  /// for. Phrased as standing preferences, not as corrections to one reply.
  List<String> get steeringDirectives => learnedReasons
      .map(
        (reason) => switch (reason) {
          AIReplyFeedbackReason.tooGeneric =>
            'This person has repeatedly found replies too generic. Anchor every '
                'reply in a concrete detail they actually wrote, and skip '
                'openers that would fit any entry.',
          AIReplyFeedbackReason.wrongLanguage =>
            'This person has repeatedly found the language balance wrong. '
                'Mirror the exact mix of English and Filipino in their latest '
                'message rather than defaulting to one.',
          AIReplyFeedbackReason.tooMuchAdvice =>
            'This person has repeatedly found replies too advice-heavy. Default '
                'to listening and reflecting; offer a step only when they ask '
                'for one.',
          AIReplyFeedbackReason.repetitive =>
            'This person has repeatedly found replies repetitive. Vary your '
                'openings, framing and closing questions, and never reuse a '
                'structure from earlier in the conversation.',
          AIReplyFeedbackReason.missedThePoint =>
            'This person has repeatedly felt misread. Centre the most concrete '
                'concern in their message, keep interpretations tentative, and '
                'ask rather than assume when the meaning is unclear.',
        },
      )
      .toList(growable: false);

  /// Human-readable lines for the settings screen, so the learning is visible
  /// and can be reset rather than silently accumulating.
  List<String> get userFacingSummary => learnedReasons
      .map(
        (reason) => switch (reason) {
          AIReplyFeedbackReason.tooGeneric => 'Be more specific',
          AIReplyFeedbackReason.wrongLanguage => 'Match my language',
          AIReplyFeedbackReason.tooMuchAdvice => 'Give less advice',
          AIReplyFeedbackReason.repetitive => 'Do not repeat yourself',
          AIReplyFeedbackReason.missedThePoint => 'Read me more carefully',
        },
      )
      .toList(growable: false);
}

class AIResponseFeedbackService {
  static const String _storageKey = 'ai_response_feedback_v1';
  static const int _maximumRecords = 100;

  /// Only recent feedback shapes replies. Something corrected months ago
  /// should not still be steering the companion.
  static const int _learningWindow = 30;

  static AIPreferenceProfile? _cachedProfile;

  static void reset() {
    _cachedProfile = null;
  }

  static String _keyForUser([String? userId]) {
    final uid = userId ??
        (SupabaseService.isInitialized
            ? SupabaseService.client.auth.currentUser?.id
            : null);
    return uid != null ? 'ai_response_feedback_v1_$uid' : _storageKey;
  }

  /// Saves only quality metadata. Journal and response text are deliberately
  /// excluded so feedback never creates a second copy of private writing.
  static Future<void> record({
    required AIReplyFeedback feedback,
    AIReplyFeedbackReason? reason,
    required String companionId,
    required String mode,
    required bool wasOffline,
    String? userId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _keyForUser(userId);
    final stored = preferences.getString(key) ?? preferences.getString(_storageKey);
    final records = <Map<String, dynamic>>[];
    if (stored != null) {
      try {
        records.addAll(
          (jsonDecode(stored) as List<dynamic>)
              .whereType<Map<String, dynamic>>(),
        );
      } catch (_) {
        // Corrupt analytics should never interrupt the journal experience.
      }
    }
    records.insert(0, {
      'feedback': feedback.name,
      'reason': reason?.name,
      'companion': companionId,
      'mode': mode,
      'offline': wasOffline,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    if (records.length > _maximumRecords) {
      records.removeRange(_maximumRecords, records.length);
    }
    await preferences.setString(key, jsonEncode(records));
    _cachedProfile = _profileFrom(records);
  }

  /// The profile used while building a prompt. Cached because it is read on
  /// every AI request and changes only when feedback is given.
  static AIPreferenceProfile get cachedProfile =>
      _cachedProfile ?? AIPreferenceProfile.empty;

  static Future<AIPreferenceProfile> loadProfile([String? userId]) async {
    final cached = _cachedProfile;
    if (cached != null) return cached;
    try {
      final preferences = await SharedPreferences.getInstance();
      final key = _keyForUser(userId);
      final stored = preferences.getString(key) ?? preferences.getString(_storageKey);
      if (stored == null) {
        return _cachedProfile = AIPreferenceProfile.empty;
      }
      final decoded = jsonDecode(stored);
      if (decoded is! List) {
        return _cachedProfile = AIPreferenceProfile.empty;
      }
      return _cachedProfile = _profileFrom(
        decoded.whereType<Map<String, dynamic>>().toList(),
      );
    } catch (_) {
      return _cachedProfile = AIPreferenceProfile.empty;
    }
  }

  /// Forgets what feedback has taught the companion, without touching
  /// anything the person wrote.
  static Future<void> clearLearnedPreferences([String? userId]) async {
    _cachedProfile = AIPreferenceProfile.empty;
    try {
      final preferences = await SharedPreferences.getInstance();
      final key = _keyForUser(userId);
      await preferences.remove(key);
      await preferences.remove(_storageKey);
    } catch (_) {
      // The in-memory reset above is what steers the next reply.
    }
  }

  /// Test seam: drops the cache so the next read comes from storage.
  static void resetCacheForTesting() => _cachedProfile = null;

  static AIPreferenceProfile _profileFrom(List<Map<String, dynamic>> records) {
    final recent = records.take(_learningWindow);
    var helpful = 0;
    var notHelpful = 0;
    final reasons = <AIReplyFeedbackReason, int>{};

    for (final record in recent) {
      // Offline replies come from a canned fallback, not the model, so rating
      // one says nothing about how the companion should write.
      if (record['offline'] == true) continue;
      if (record['feedback'] == AIReplyFeedback.helpful.name) {
        helpful++;
        continue;
      }
      if (record['feedback'] != AIReplyFeedback.notHelpful.name) continue;
      notHelpful++;
      final rawReason = record['reason']?.toString();
      if (rawReason == null) continue;
      for (final reason in AIReplyFeedbackReason.values) {
        if (reason.name == rawReason) {
          reasons[reason] = (reasons[reason] ?? 0) + 1;
          break;
        }
      }
    }

    return AIPreferenceProfile(
      helpfulCount: helpful,
      notHelpfulCount: notHelpful,
      reasonCounts: Map.unmodifiable(reasons),
    );
  }
}
