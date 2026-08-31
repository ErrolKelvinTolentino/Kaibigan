import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum AIReplyFeedback { helpful, notHelpful }

enum AIReplyFeedbackReason {
  tooGeneric,
  wrongLanguage,
  tooMuchAdvice,
  repetitive,
  missedThePoint,
}

class AIResponseFeedbackService {
  static const String _storageKey = 'ai_response_feedback_v1';
  static const int _maximumRecords = 100;

  /// Saves only quality metadata. Journal and response text are deliberately
  /// excluded so feedback never creates a second copy of private writing.
  static Future<void> record({
    required AIReplyFeedback feedback,
    AIReplyFeedbackReason? reason,
    required String companionId,
    required String mode,
    required bool wasOffline,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
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
    await preferences.setString(_storageKey, jsonEncode(records));
  }
}
