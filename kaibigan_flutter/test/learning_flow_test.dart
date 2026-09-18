import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_catalog.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_hub_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_model.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_progress_store.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget hub() => MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
        child: const MaterialApp(home: LearningHubScreen()),
      );

  group('catalogue progress', () {
    testWidgets('an untouched library says so plainly', (tester) async {
      SharedPreferences.setMockInitialValues({
        'preferred_language': 'english',
      });
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('learning-catalogue-progress')),
        findsOneWidget,
      );
      expect(find.text('Nothing finished yet — that is fine'), findsOneWidget);
    });

    testWidgets('finished lessons are counted', (tester) async {
      final first = LearningCatalog.lessons.first.id;
      final second = LearningCatalog.lessons[1].id;
      SharedPreferences.setMockInitialValues({
        'preferred_language': 'english',
        'mental_health_learning_completed_ids': [first, second],
      });
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();

      expect(
        find.text('2 of ${LearningCatalog.lessons.length} lessons finished'),
        findsOneWidget,
      );
    });
  });

  group('resuming a part-read lesson', () {
    testWidgets('its own card says where you stopped', (tester) async {
      final lesson = LearningCatalog.lessons.first;
      SharedPreferences.setMockInitialValues({
        'preferred_language': 'english',
        'mental_health_learning_idea_position_${lesson.id}': 2,
      });
      // Tall enough that the first lesson card is built without scrolling:
      // driving a scroll here leaves the hub's reveal animations mid-flight.
      await tester.binding.setSurfaceSize(const Size(390, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('lesson-resume-${lesson.id}')),
        findsOneWidget,
      );
      expect(
        find.text('Idea 3/${lesson.sections.length}'),
        findsOneWidget,
      );
    });

    testWidgets('a finished lesson shows no resume label', (tester) async {
      final lesson = LearningCatalog.lessons.first;
      SharedPreferences.setMockInitialValues({
        'preferred_language': 'english',
        'mental_health_learning_idea_position_${lesson.id}': 2,
        'mental_health_learning_completed_ids': [lesson.id],
      });
      await tester.binding.setSurfaceSize(const Size(390, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(hub());
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('lesson-resume-${lesson.id}')),
        findsNothing,
      );
    });
  });

  group('reading positions', () {
    test('are read in one pass and clamped to each lesson', () async {
      final lesson = LearningCatalog.lessons.first;
      SharedPreferences.setMockInitialValues({
        'mental_health_learning_idea_position_${lesson.id}': 999,
        'mental_health_learning_idea_position_never-opened': 3,
      });
      final store = LearningProgressStore();

      final positions = await store.loadIdeaPositions({
        lesson.id: lesson.sections.length,
        'not-saved': 5,
      });

      // Clamped to the last real idea rather than trusting stored data.
      expect(positions[lesson.id], lesson.sections.length - 1);
      // Lessons that were never opened simply have no entry.
      expect(positions.containsKey('not-saved'), isFalse);
      expect(positions.containsKey('never-opened'), isFalse);
    });

    test('an empty request does no work', () async {
      expect(await LearningProgressStore().loadIdeaPositions(const {}), isEmpty);
    });
  });

  group('what comes next', () {
    test('every reason reads as a heading in both languages', () {
      for (final reason in LearningNextReason.values) {
        for (final language in const ['english', 'filipino']) {
          final label = reason.label(language);
          expect(label.trim(), isNotEmpty);
          expect(label, label.toUpperCase());
        }
      }
    });

    test('related lesson ids all point at real lessons', () {
      for (final lesson in LearningCatalog.lessons) {
        for (final id in lesson.relatedLessonIds) {
          expect(
            LearningCatalog.byId(id).id,
            id,
            reason: '${lesson.id} points at a missing lesson "$id"',
          );
        }
      }
    });

    test('paths only reference lessons that exist', () {
      for (final path in LearningCatalog.paths) {
        expect(path.lessonIds, isNotEmpty);
        for (final id in path.lessonIds) {
          expect(LearningCatalog.byId(id).id, id, reason: '${path.id} -> $id');
        }
      }
    });
  });
}
