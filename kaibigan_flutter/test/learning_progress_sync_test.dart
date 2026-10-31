import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_progress_store.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_progress_sync.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lesson completion, ideas, and position restore on another device',
      () async {
    final cloud = _Cloud();
    LearningProgressStore device() => LearningProgressStore(
        sync:
            LearningProgressSync(cloud: cloud, currentUserId: () => 'user-a'));
    final first = device();
    await first.setCompleted('sleep-and-mind', true);
    await first.markIdeaViewed('sleep-and-mind', 2);
    await first.setIdeaHelpful('sleep-and-mind', 2, true);
    await first.rememberPosition('sleep-and-mind', 2);

    SharedPreferences.setMockInitialValues({});
    final second = device();
    expect(await second.loadCompleted(), {'sleep-and-mind'});
    expect(await second.loadViewedIdeas('sleep-and-mind'), {2});
    expect(await second.loadHelpfulIdeas('sleep-and-mind'), {2});
    expect(await second.loadAllHelpfulIdeaRefs(), {'sleep-and-mind:2'});
    expect(await second.loadLastLessonId(), 'sleep-and-mind');
    expect(await second.loadIdeaIndex('sleep-and-mind', max: 5), 2);
    await second.setCompleted('sleep-and-mind', false);
    await second.setIdeaHelpful('sleep-and-mind', 2, false);
    expect(await second.loadCompleted(), isEmpty);
    expect(await second.loadHelpfulIdeas('sleep-and-mind'), isEmpty);
  });

  test(
      'offline edits survive restart and retry without uploading another owner',
      () async {
    final cloud = _Cloud()..online = false;
    LearningProgressStore device() => LearningProgressStore(
        sync:
            LearningProgressSync(cloud: cloud, currentUserId: () => 'user-a'));
    await device().setCompleted('sleep-and-mind', true);
    expect(await device().loadCompleted(), {'sleep-and-mind'});
    expect(cloud.records, isEmpty);
    cloud.online = true;
    expect(await device().loadCompleted(), {'sleep-and-mind'});
    expect(cloud.records['user-a']!['sleep-and-mind']!['completed'], true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('learning_progress_pending_v1_user-a'), '{}');
  });

  test('account changes never claim legacy unowned progress', () async {
    SharedPreferences.setMockInitialValues({
      'mental_health_learning_completed_ids': ['legacy-unowned'],
    });
    final cloud = _Cloud();
    String? owner = 'user-a';
    final store = LearningProgressStore(
        sync: LearningProgressSync(cloud: cloud, currentUserId: () => owner));
    expect(await store.loadCompleted(), isEmpty);
    await store.setCompleted('lesson-a', true);
    owner = 'user-b';
    expect(await store.loadCompleted(), isEmpty);
    await store.setCompleted('lesson-b', true);
    owner = 'user-a';
    expect(await store.loadCompleted(), {'lesson-a'});
    expect(cloud.records['user-b']!.keys, ['lesson-b']);
    owner = null;
    expect(await store.loadCompleted(), {'legacy-unowned'});
  });

  test('simultaneous views preserve both viewed ideas', () async {
    final cloud = _Cloud();
    LearningProgressStore device() => LearningProgressStore(
        sync:
            LearningProgressSync(cloud: cloud, currentUserId: () => 'user-a'));
    await Future.wait([
      device().markIdeaViewed('lesson', 1),
      device().markIdeaViewed('lesson', 2),
    ]);
    expect(await device().loadViewedIdeas('lesson'), {1, 2});
  });

  test(
      'quiz and practice results sync without transcripts or crossing accounts',
      () async {
    final cloud = _Cloud()..online = false;
    var owner = 'user-a';
    LearningProgressStore device() => LearningProgressStore(
        sync: LearningProgressSync(cloud: cloud, currentUserId: () => owner));
    final store = device();
    await store.saveQuizScore('friend-support-listen', 2, 3);
    await store.savePracticeResult(
        lessonId: 'friend-support-listen',
        scenarioId: 'practice-overwhelm',
        replies: 3,
        supportiveReplies: 2);
    expect(cloud.records, isEmpty);
    cloud.online = true;
    expect(await device().loadQuizScore('friend-support-listen'),
        (score: 2, total: 3));
    final row = cloud.records[owner]!['friend-support-listen']!;
    expect(row['practice_count'], 1);
    expect(row['practice_supportive_count'], 2);
    expect(row.keys, isNot(contains('transcript')));
    await device().saveQuizScore('friend-support-listen', 1, 3);
    expect(await device().loadQuizScore('friend-support-listen'),
        (score: 2, total: 3));
    owner = 'user-b';
    expect(await device().loadQuizScore('friend-support-listen'), isNull);
  });

  test('switching identity during fetch cannot persist a pending edit',
      () async {
    final cloud = _Cloud()..gate = Completer<void>();
    var owner = 'user-a';
    final store = LearningProgressStore(
        sync: LearningProgressSync(cloud: cloud, currentUserId: () => owner));
    final change = store.setCompleted('private-lesson', true);
    await cloud.fetchStarted.future;
    owner = 'user-b';
    cloud.gate!.complete();
    expect(await change, isEmpty);
    expect(cloud.records, isEmpty);
  });
}

class _Cloud implements LearningProgressCloud {
  bool online = true;
  final Map<String, LessonRecords> records = {};
  Completer<void>? gate;
  final fetchStarted = Completer<void>();

  @override
  Future<List<Map<String, dynamic>>> fetch(String userId) async {
    if (!fetchStarted.isCompleted) fetchStarted.complete();
    if (gate != null) await gate!.future;
    if (!online) throw StateError('Offline');
    return (records[userId] ?? {})
        .entries
        .map((item) => {
              ...item.value,
              'lesson_id': item.key,
              'user_id': userId,
            })
        .toList();
  }

  @override
  Future<void> save(
      String userId, String lessonId, Map<String, dynamic> patch) async {
    if (!online) throw StateError('Offline');
    final rows = records.putIfAbsent(userId, () => {});
    rows[lessonId] = {...?rows[lessonId], ...patch};
  }
}
