import 'package:shared_preferences/shared_preferences.dart';

class LearningProgressStore {
  static const _completedKey = 'mental_health_learning_completed_ids';
  static const _helpfulKey = 'mental_health_learning_helpful_ideas';
  static const _viewedKey = 'mental_health_learning_viewed_ideas';
  static const _lastLessonKey = 'mental_health_learning_last_lesson_id';
  static const _ideaPositionPrefix = 'mental_health_learning_idea_position_';

  Future<Set<String>> loadCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_completedKey)?.toSet() ?? <String>{};
  }

  Future<Set<String>> setCompleted(String lessonId, bool completed) async {
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
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_helpfulKey) ?? const <String>[]).toSet();
  }

  Future<Set<int>> loadViewedIdeas(String lessonId) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_viewedKey) ?? const <String>[])
        .where((value) => value.startsWith('$lessonId:'))
        .map((value) => int.tryParse(value.substring(lessonId.length + 1)))
        .whereType<int>()
        .toSet();
  }

  Future<Set<int>> markIdeaViewed(String lessonId, int ideaIndex) async {
    final preferences = await SharedPreferences.getInstance();
    final values =
        (preferences.getStringList(_viewedKey) ?? const <String>[]).toSet();
    values.add('$lessonId:$ideaIndex');
    await preferences.setStringList(_viewedKey, values.toList()..sort());
    return loadViewedIdeas(lessonId);
  }

  Future<String?> loadLastLessonId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastLessonKey);
  }

  Future<int> loadIdeaIndex(String lessonId, {required int max}) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getInt('$_ideaPositionPrefix$lessonId') ?? 0;
    if (max <= 0) return 0;
    return saved.clamp(0, max - 1);
  }

  Future<void> rememberPosition(String lessonId, int ideaIndex) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_lastLessonKey, lessonId),
      preferences.setInt('$_ideaPositionPrefix$lessonId', ideaIndex),
    ]);
  }
}
