import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/home/activity_feedback_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('activity feedback persists privately on device', () async {
    SharedPreferences.setMockInitialValues({});
    final createdAt = DateTime(2026, 9, 1, 9, 30);

    await ActivityFeedbackStore.add(
      ActivityFeedbackRecord(
        activityId: 'grounding',
        helpfulness: ActivityHelpfulness.helped,
        createdAt: createdAt,
      ),
    );
    final restored = await ActivityFeedbackStore.load();

    expect(restored, hasLength(1));
    expect(restored.single.activityId, 'grounding');
    expect(restored.single.helpfulness, ActivityHelpfulness.helped);
    expect(restored.single.createdAt, createdAt);
  });

  test('activity feedback keeps only the most recent 30 answers', () async {
    SharedPreferences.setMockInitialValues({});

    for (var index = 0; index < 35; index++) {
      await ActivityFeedbackStore.add(
        ActivityFeedbackRecord(
          activityId: 'activity-$index',
          helpfulness: ActivityHelpfulness.unsure,
          createdAt: DateTime(2026, 9, 1).add(Duration(minutes: index)),
        ),
      );
    }
    final restored = await ActivityFeedbackStore.load();

    expect(restored, hasLength(30));
    expect(restored.first.activityId, 'activity-34');
    expect(restored.last.activityId, 'activity-5');
  });
}
