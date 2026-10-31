import 'package:shared_preferences/shared_preferences.dart';

import 'learning_progress_sync.dart';

class LearningProgressStore {
  LearningProgressStore({LearningProgressSync? sync})
      : _sync = sync ?? LearningProgressSync();

  final LearningProgressSync _sync;

  Set<int> _indices(Map<String, dynamic>? row, String field) =>
      (row?[field] as List? ?? const []).whereType<int>().toSet();

  Set<String> _completed(LessonRecords records) => records.entries
      .where((item) => item.value['completed'] == true)
      .map((item) => item.key)
      .toSet();
  static const _completedKey = 'mental_health_learning_completed_ids';
  static const _helpfulKey = 'mental_health_learning_helpful_ideas';
  static const _viewedKey = 'mental_health_learning_viewed_ideas';
  static const _lastLessonKey = 'mental_health_learning_last_lesson_id';
  static const _ideaPositionPrefix = 'mental_health_learning_idea_position_';

  Future<Set<String>> loadCompleted() async {
    final owner = _sync.userId;
    if (owner != null) return _completed(await _sync.load(owner));
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_completedKey)?.toSet() ?? <String>{};
  }

  Future<Set<String>> setCompleted(String lessonId, bool completed) async {
    final owner = _sync.userId;
    if (owner != null) {
      return _completed(await _sync.change(
        owner,
        lessonId,
        (_) => {'completed': completed},
      ));
    }
    final preferences = await SharedPreferences.getInstance();
    final ids = preferences.getStringList(_completedKey)?.toSet() ?? <String>{};
    if (completed) {
      ids.add(lessonId);
    } else {
      ids.remove(lessonId);
    }
    await preferences.setStringList(_completedKey, ids.toList()..sort());
    return ids;
  }

  Future<Set<int>> loadHelpfulIdeas(String lessonId) async {
    final owner = _sync.userId;
    if (owner != null) {
      return _indices((await _sync.load(owner))[lessonId], 'helpful_ideas');
    }
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_helpfulKey) ?? const <String>[])
        .where((value) => value.startsWith('$lessonId:'))
        .map((value) => int.tryParse(value.substring(lessonId.length + 1)))
        .whereType<int>()
        .toSet();
  }

  Future<Set<int>> setIdeaHelpful(
    String lessonId,
    int ideaIndex,
    bool helpful,
  ) async {
    if (ideaIndex < 0) throw ArgumentError.value(ideaIndex, 'ideaIndex');
    final owner = _sync.userId;
    if (owner != null) {
      final records = await _sync.change(owner, lessonId, (row) {
        final values = _indices(row, 'helpful_ideas');
        helpful ? values.add(ideaIndex) : values.remove(ideaIndex);
        return {'helpful_ideas': values.toList()..sort()};
      });
      return _indices(records[lessonId], 'helpful_ideas');
    }
    final preferences = await SharedPreferences.getInstance();
    final values =
        (preferences.getStringList(_helpfulKey) ?? const <String>[]).toSet();
    final value = '$lessonId:$ideaIndex';
    if (helpful) {
      values.add(value);
    } else {
      values.remove(value);
    }
    await preferences.setStringList(_helpfulKey, values.toList()..sort());
    return loadHelpfulIdeas(lessonId);
  }

  Future<Set<String>> loadAllHelpfulIdeaRefs() async {
    final owner = _sync.userId;
    if (owner != null) {
      final records = await _sync.load(owner);
      return {
        for (final item in records.entries)
          for (final index in _indices(item.value, 'helpful_ideas'))
            '${item.key}:$index',
      };
    }
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_helpfulKey) ?? const <String>[]).toSet();
  }

  Future<Set<int>> loadViewedIdeas(String lessonId) async {
    final owner = _sync.userId;
    if (owner != null) {
      return _indices((await _sync.load(owner))[lessonId], 'viewed_ideas');
    }
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_viewedKey) ?? const <String>[])
        .where((value) => value.startsWith('$lessonId:'))
        .map((value) => int.tryParse(value.substring(lessonId.length + 1)))
        .whereType<int>()
        .toSet();
  }

  Future<Set<int>> markIdeaViewed(String lessonId, int ideaIndex) async {
    if (ideaIndex < 0) throw ArgumentError.value(ideaIndex, 'ideaIndex');
    final owner = _sync.userId;
    if (owner != null) {
      final records = await _sync.change(owner, lessonId, (row) {
        final values = _indices(row, 'viewed_ideas')..add(ideaIndex);
        return {'viewed_ideas': values.toList()..sort()};
      });
      return _indices(records[lessonId], 'viewed_ideas');
    }
    final preferences = await SharedPreferences.getInstance();
    final values =
        (preferences.getStringList(_viewedKey) ?? const <String>[]).toSet();
    values.add('$lessonId:$ideaIndex');
    await preferences.setStringList(_viewedKey, values.toList()..sort());
    return loadViewedIdeas(lessonId);
  }

  Future<String?> loadLastLessonId() async {
    final owner = _sync.userId;
    if (owner != null) {
      final records = (await _sync.load(owner))
          .entries
          .where((item) => item.value['last_opened_at'] != null)
          .toList()
        ..sort((a, b) => DateTime.parse(b.value['last_opened_at'] as String)
            .compareTo(DateTime.parse(a.value['last_opened_at'] as String)));
      return records.isEmpty ? null : records.first.key;
    }
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastLessonKey);
  }

  Future<int> loadIdeaIndex(String lessonId, {required int max}) async {
    final owner = _sync.userId;
    if (owner != null) {
      final row = (await _sync.load(owner))[lessonId];
      final saved = row?['last_idea_index'] as int? ?? 0;
      return max <= 0 ? 0 : saved.clamp(0, max - 1);
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getInt('$_ideaPositionPrefix$lessonId') ?? 0;
    if (max <= 0) return 0;
    return saved.clamp(0, max - 1);
  }

  /// Reading position for several lessons at once.
  ///
  /// The hub needs this for every card. Asking lesson by lesson would mean one
  /// round trip each; the synced path already returns every record in a single
  /// read, so this collapses to one call there and to one preferences load
  /// locally.
  Future<Map<String, int>> loadIdeaPositions(
    Map<String, int> lengthByLessonId,
  ) async {
    if (lengthByLessonId.isEmpty) return const {};
    final positions = <String, int>{};
    final owner = _sync.userId;

    if (owner != null) {
      final records = await _sync.load(owner);
      for (final entry in lengthByLessonId.entries) {
        final saved = records[entry.key]?['last_idea_index'] as int?;
        if (saved == null || entry.value <= 0) continue;
        positions[entry.key] = saved.clamp(0, entry.value - 1);
      }
      return positions;
    }

    final preferences = await SharedPreferences.getInstance();
    for (final entry in lengthByLessonId.entries) {
      final saved = preferences.getInt('$_ideaPositionPrefix${entry.key}');
      if (saved == null || entry.value <= 0) continue;
      positions[entry.key] = saved.clamp(0, entry.value - 1);
    }
    return positions;
  }

  Future<void> rememberPosition(String lessonId, int ideaIndex) async {
    if (ideaIndex < 0) throw ArgumentError.value(ideaIndex, 'ideaIndex');
    final owner = _sync.userId;
    if (owner != null) {
      await _sync.change(
          owner,
          lessonId,
          (_) => {
                'last_idea_index': ideaIndex,
                'last_opened_at': DateTime.now().toUtc().toIso8601String(),
              });
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_lastLessonKey, lessonId),
      preferences.setInt('$_ideaPositionPrefix$lessonId', ideaIndex),
    ]);
  }

  static const _quizScorePrefix = 'friend_support_quiz_score_';
  static const _quizTotalPrefix = 'friend_support_quiz_total_';

  Future<({int score, int total})?> loadQuizScore(String lessonId) async {
    final owner = _sync.userId;
    if (owner != null) {
      final row = (await _sync.load(owner))[lessonId];
      final score = row?['quiz_score'] as int?;
      final total = row?['quiz_total'] as int?;
      return score == null || total == null
          ? null
          : (score: score, total: total);
    }
    final preferences = await SharedPreferences.getInstance();
    final score = preferences.getInt('$_quizScorePrefix$lessonId');
    final total = preferences.getInt('$_quizTotalPrefix$lessonId');
    if (score == null || total == null) return null;
    return (score: score, total: total);
  }

  Future<void> saveQuizScore(String lessonId, int score, int total) async {
    if (total <= 0 || score < 0 || score > total) {
      throw ArgumentError('Invalid quiz result');
    }
    final owner = _sync.userId;
    if (owner != null) {
      await _sync.change(owner, lessonId, (row) {
        final current = row['quiz_score'] as int?;
        return current == null || score >= current
            ? {'quiz_score': score, 'quiz_total': total}
            : <String, dynamic>{};
      });
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getInt('$_quizScorePrefix$lessonId');
    if (current == null || score >= current) {
      await Future.wait([
        preferences.setInt('$_quizScorePrefix$lessonId', score),
        preferences.setInt('$_quizTotalPrefix$lessonId', total),
      ]);
    }
  }

  /// Only completion counts and scenario identifiers are retained, never chat.
  Future<void> savePracticeResult(
      {required String lessonId,
      required String scenarioId,
      required int replies,
      required int supportiveReplies}) async {
    if (replies < 1 || supportiveReplies < 0 || supportiveReplies > replies) {
      throw ArgumentError('Invalid practice result');
    }
    Map<String, dynamic> patch(Map<String, dynamic> row) => {
          'practice_count': (row['practice_count'] as int? ?? 0) + 1,
          'last_practice_scenario': scenarioId,
          'last_practiced_at': DateTime.now().toUtc().toIso8601String(),
          'practice_reply_count': replies,
          'practice_supportive_count': supportiveReplies,
        };
    final owner = _sync.userId;
    if (owner != null) {
      await _sync.change(owner, lessonId, patch);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = 'friend_support_practice_count_$lessonId';
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }
}
