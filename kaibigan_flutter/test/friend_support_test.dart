import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_catalog.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_hub_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_lesson_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_quiz_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_hub_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_progress_store.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
    });
  });

  group('Friend Support Catalog Tests', () {
    test('catalog contains exactly 3 lessons with 3 questions each', () {
      expect(FriendSupportCatalog.lessons.length, equals(3));

      final expectedLessonIds = [
        'friend-support-listen',
        'friend-support-safety',
        'friend-support-boundaries',
      ];
      expect(
        FriendSupportCatalog.lessons.map((l) => l.id).toList(),
        equals(expectedLessonIds),
      );

      for (final lesson in FriendSupportCatalog.lessons) {
        expect(lesson.title.english.isNotEmpty, isTrue);
        expect(lesson.title.filipino.isNotEmpty, isTrue);
        expect(lesson.subtitle.english.isNotEmpty, isTrue);
        expect(lesson.subtitle.filipino.isNotEmpty, isTrue);
        expect(lesson.whatYoullLearn.english.isNotEmpty, isTrue);
        expect(lesson.whatYoullLearn.filipino.isNotEmpty, isTrue);
        expect(lesson.pointsHeader.english.isNotEmpty, isTrue);
        expect(lesson.points.isNotEmpty, isTrue);
        expect(lesson.questions.length, equals(3));

        for (final question in lesson.questions) {
          expect(question.id.isNotEmpty, isTrue);
          expect(question.prompt.english.isNotEmpty, isTrue);
          expect(question.prompt.filipino.isNotEmpty, isTrue);
          expect(question.options.length, equals(4));
          expect(question.correctIndex, inInclusiveRange(0, 3));
          expect(question.hint.english.isNotEmpty, isTrue);
          expect(question.hint.filipino.isNotEmpty, isTrue);
          expect(question.correctExplanation.english.isNotEmpty, isTrue);
          expect(question.correctExplanation.filipino.isNotEmpty, isTrue);

          for (final option in question.options) {
            expect(option.id, isIn(['A', 'B', 'C', 'D']));
            expect(option.text.english.isNotEmpty, isTrue);
            expect(option.text.filipino.isNotEmpty, isTrue);
            expect(option.explanation.english.isNotEmpty, isTrue);
            expect(option.explanation.filipino.isNotEmpty, isTrue);
          }
        }
      }

      expect(FriendSupportCatalog.takeaways.length, equals(6));
      for (final takeaway in FriendSupportCatalog.takeaways) {
        expect(takeaway.english.isNotEmpty, isTrue);
        expect(takeaway.filipino.isNotEmpty, isTrue);
      }
    });

    test('catalog byId resolves correctly', () {
      expect(
        FriendSupportCatalog.byId('friend-support-listen')?.title.english,
        equals('Listen Before You Fix'),
      );
      expect(
        FriendSupportCatalog.byId('friend-support-safety')?.title.english,
        equals('Take Suicidal Thoughts Seriously'),
      );
      expect(
        FriendSupportCatalog.byId('friend-support-boundaries')?.title.english,
        equals('You Don\'t Have to Handle It Alone'),
      );
      expect(FriendSupportCatalog.byId('non-existent'), isNull);
    });
  });

  group('LearningProgressStore Quiz Score Tests', () {
    test('stores and retrieves quiz scores preserving best score', () async {
      final store = LearningProgressStore();
      const lessonId = 'friend-support-listen';

      expect(await store.loadQuizScore(lessonId), isNull);

      await store.saveQuizScore(lessonId, 2, 3);
      final scoreData1 = await store.loadQuizScore(lessonId);
      expect(scoreData1?.score, equals(2));
      expect(scoreData1?.total, equals(3));

      // Higher score updates
      await store.saveQuizScore(lessonId, 3, 3);
      final scoreData2 = await store.loadQuizScore(lessonId);
      expect(scoreData2?.score, equals(3));
      expect(scoreData2?.total, equals(3));

      // Lower score does not overwrite best score
      await store.saveQuizScore(lessonId, 1, 3);
      final scoreData3 = await store.loadQuizScore(lessonId);
      expect(scoreData3?.score, equals(3));
      expect(scoreData3?.total, equals(3));
    });
  });

  group('Friend Support UI Tests', () {
    Widget buildTestWidget({
      required Widget child,
      String language = 'english',
    }) {
      SharedPreferences.setMockInitialValues({
        'preferred_language': language,
      });
      return ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: child,
        ),
      );
    }

    testWidgets('FriendSupportHubScreen renders lessons and crisis support',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(child: const FriendSupportHubScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Friend Support Lessons'), findsOneWidget);
      expect(find.byKey(const ValueKey('friend-support-hub-hero')),
          findsOneWidget);
      expect(find.text('Listen Before You Fix'), findsOneWidget);
      expect(find.text('Take Suicidal Thoughts Seriously'), findsOneWidget);
      expect(find.text('You Don\'t Have to Handle It Alone'), findsOneWidget);

      // Tap Need Help button
      await tester
          .tap(find.byKey(const ValueKey('friend-support-hub-need-help')));
      await tester.pumpAndSettle();

      // Crisis resources bottom sheet is visible
      expect(find.text('911'), findsOneWidget);
      expect(find.text('1553'), findsOneWidget);
      expect(find.text('0917 899 8727'), findsOneWidget);
      expect(
        find.textContaining('You don\'t have to handle a crisis alone'),
        findsOneWidget,
      );
    });

    testWidgets('FriendSupportLessonScreen renders content and starts quiz',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final lesson = FriendSupportCatalog.lessons.first;
      await tester.pumpWidget(
        buildTestWidget(child: FriendSupportLessonScreen(lesson: lesson)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lesson 1'), findsOneWidget);
      expect(find.text('Listen Before You Fix'), findsOneWidget);
      expect(find.text('What You\'ll Learn'), findsOneWidget);
      expect(find.text('Helpful Responses'), findsOneWidget);
      expect(find.text('Try to Avoid'), findsOneWidget);

      // Quiz button exists
      final quizBtn = find.byKey(const ValueKey('start-friend-quiz-btn'));
      expect(quizBtn, findsOneWidget);

      // Scroll to button and tap to push FriendSupportQuizScreen
      await tester.ensureVisible(quizBtn);
      await tester.pumpAndSettle();
      await tester.tap(quizBtn);
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 3'), findsOneWidget);
    });

    testWidgets(
        'FriendSupportQuizScreen locks selection, gives feedback, and navigates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final lesson = FriendSupportCatalog.lessons.first;
      await tester.pumpWidget(
        buildTestWidget(child: FriendSupportQuizScreen(lesson: lesson)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 3'), findsOneWidget);

      // Tap 💡 Help hint button
      await tester
          .tap(find.byKey(const ValueKey('friend-support-quiz-hint-btn')));
      await tester.pumpAndSettle();
      expect(find.text('Helpful Guidance'), findsOneWidget);
      expect(
        find.textContaining('safe enough to open up'),
        findsOneWidget,
      );

      // Close hint modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Select option A (incorrect choice for Q1)
      final optA = find.byKey(const ValueKey('quiz-option-A'));
      await tester.ensureVisible(optA);
      await tester.tap(optA);
      await tester.pumpAndSettle();

      // Feedback panel appears
      expect(find.byKey(const ValueKey('quiz-feedback-panel')), findsOneWidget);
      expect(find.text('Correct Answer: C'), findsOneWidget);
      expect(find.textContaining('“Everyone feels overwhelmed” may be true'),
          findsOneWidget);

      // Attempt to tap option B - should remain locked
      final optB = find.byKey(const ValueKey('quiz-option-B'));
      await tester.ensureVisible(optB);
      await tester.tap(optB);
      await tester.pumpAndSettle();
      // Still Option A's feedback is shown
      expect(find.textContaining('About Option A:'), findsOneWidget);

      // Advance to Question 2
      final nextBtn1 = find.byKey(const ValueKey('quiz-next-question-btn'));
      await tester.ensureVisible(nextBtn1);
      await tester.tap(nextBtn1);
      await tester.pumpAndSettle();
      expect(find.text('Question 2 of 3'), findsOneWidget);

      // Answer Question 2 correctly (Option C)
      final optC2 = find.byKey(const ValueKey('quiz-option-C'));
      await tester.ensureVisible(optC2);
      await tester.tap(optC2);
      await tester.pumpAndSettle();
      expect(find.text('Correct! Well done.'), findsOneWidget);

      // Advance to Question 3
      final nextBtn2 = find.byKey(const ValueKey('quiz-next-question-btn'));
      await tester.ensureVisible(nextBtn2);
      await tester.tap(nextBtn2);
      await tester.pumpAndSettle();
      expect(find.text('Question 3 of 3'), findsOneWidget);

      // Answer Question 3 correctly (Option C)
      final optC3 = find.byKey(const ValueKey('quiz-option-C'));
      await tester.ensureVisible(optC3);
      await tester.tap(optC3);
      await tester.pumpAndSettle();
      expect(find.text('Correct! Well done.'), findsOneWidget);

      // Tap Complete Lesson
      final completeBtn = find.byKey(const ValueKey('quiz-next-question-btn'));
      await tester.ensureVisible(completeBtn);
      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // Completion screen shown
      expect(find.text('Lesson Completed'), findsOneWidget);
      expect(
        find.textContaining('You\'re learning how to be a better Kaibigan.'),
        findsOneWidget,
      );
      expect(find.text('Quiz Score: 2 / 3'), findsOneWidget);
      expect(find.text('Listen before trying to fix'), findsOneWidget);
      expect(find.byKey(const ValueKey('friend-support-practice-more-btn')),
          findsOneWidget);

      final practiceMore =
          find.byKey(const ValueKey('friend-support-practice-more-btn'));
      await tester.ensureVisible(practiceMore);
      await tester.tap(practiceMore);
      await tester.pumpAndSettle();

      expect(find.byType(FriendSupportQuizScreen), findsOneWidget);
      expect(find.text('Question 1 of 3'), findsOneWidget);
      expect(find.text('Lesson Completed'), findsNothing);
    });

    testWidgets('Filipino localization renders correct terms', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final lesson = FriendSupportCatalog.lessons.first;
      await tester.pumpWidget(
        buildTestWidget(
          child: FriendSupportLessonScreen(lesson: lesson),
          language: 'filipino',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aralin 1'), findsOneWidget);
      expect(find.text('Makinig Bago Magbigay ng Solusyon'), findsOneWidget);
      expect(find.text('Ano ang Matututunan Mo'), findsOneWidget);
      expect(find.text('Mga Makakatulong na Sagot'), findsOneWidget);
      expect(find.text('Mga Dapat Iwasan'), findsOneWidget);
      expect(find.text('Tulong?'), findsOneWidget);
    });

    testWidgets('LearningHubScreen includes Friend Support entry card',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(child: const LearningHubScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('friend-support-entry-card')),
          findsOneWidget);
      expect(find.text('Friend Support Lessons'), findsOneWidget);
      expect(find.text('3 Interactive Lessons & Quizzes'), findsOneWidget);

      // Tap entry card to navigate to FriendSupportHubScreen
      await tester.tap(find.byKey(const ValueKey('friend-support-entry-card')));
      await tester.pumpAndSettle();

      expect(find.text('How to be there for a friend'), findsOneWidget);
    });
  });
}
