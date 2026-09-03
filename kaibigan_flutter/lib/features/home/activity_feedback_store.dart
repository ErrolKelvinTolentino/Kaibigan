import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum ActivityHelpfulness { helped, unsure, notHelpful }

class ActivityFeedbackRecord {
  const ActivityFeedbackRecord({
    required this.activityId,
    required this.helpfulness,
    required this.createdAt,
  });

  final String activityId;
  final ActivityHelpfulness helpfulness;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'helpfulness': helpfulness.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ActivityFeedbackRecord.fromJson(Map<String, dynamic> json) {
    return ActivityFeedbackRecord(
      activityId: json['activityId'] as String? ?? '',
      helpfulness: ActivityHelpfulness.values.firstWhere(
        (value) => value.name == json['helpfulness'],
        orElse: () => ActivityHelpfulness.unsure,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ActivityFeedbackStore {
  static const _storageKey = 'companion_activity_feedback_v1';
  static const _maxRecords = 30;

  static Future<List<ActivityFeedbackRecord>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final records = decoded
          .whereType<Map<String, dynamic>>()
          .map(ActivityFeedbackRecord.fromJson)
          .where((record) => record.activityId.isNotEmpty)
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return const [];
    }
  }

  static Future<List<ActivityFeedbackRecord>> add(
    ActivityFeedbackRecord record,
  ) async {
    final current = await load();
    final updated =
        [record, ...current].take(_maxRecords).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    return updated;
  }
}
