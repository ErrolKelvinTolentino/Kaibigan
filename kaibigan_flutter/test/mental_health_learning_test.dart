import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_state_view.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_catalog.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_hub_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_lesson_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_model.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_progress_store.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_toolkit_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/medline_plus_service.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
    });
  });

  test('catalog offers a substantial set of structured offline lessons', () {
    expect(LearningCatalog.lessons.length, greaterThanOrEqualTo(23));
    expect(LearningCatalog.paths.length, greaterThanOrEqualTo(4));
    expect(
      LearningCatalog.lessons.every((lesson) => lesson.sections.length >= 4),
      isTrue,
    );
    expect(
      LearningCatalog.lessons.map((lesson) => lesson.id).toSet().length,
      LearningCatalog.lessons.length,
    );

    const expectedConditionIds = {
      'understanding-anxiety',
      'low-mood-depression',
      'understanding-adhd',
      'understanding-ocd',
      'understanding-bipolar',
      'understanding-ptsd',
      'understanding-eating-disorders',
      'understanding-schizophrenia',
      'social-anxiety',
      'substance-use-mental-health',
    };
    final conditionIds = LearningCatalog.lessons
        .where((lesson) => lesson.category == LearningCategory.conditions)
        .map((lesson) => lesson.id)
        .toSet();
    expect(conditionIds, containsAll(expectedConditionIds));

    final contacts = LearningCatalog.byId('philippines-support-contacts');
    final contactCopy =
        contacts.sections.map((section) => section.body.english).join(' ');
    expect(contactCopy, contains('911'));
    expect(contactCopy, contains('1553'));
    expect(contactCopy, contains('0917-899-8727'));
    expect(LearningCatalog.byId('suicide-safety').sensitivityNotice, isNotNull);
    expect(
      LearningCatalog.byId('social-anxiety')
          .sections
          .map((section) => section.type)
          .toSet()
          .length,
      greaterThan(2),
    );
  });

  test('MedlinePlus XML response is parsed into attributed reading', () {
    const response = '''
      <nlmSearchResult>
        <list>
          <document url="https://medlineplus.gov/anxiety.html">
            <content name="title">Anxiety</content>
            <content name="FullSummary"><p>A trusted overview.</p></content>
          </document>
        </list>
      </nlmSearchResult>
    ''';

    final articles = MedlinePlusService.parseResponse(response);

    expect(articles, hasLength(1));
    expect(articles.single.title, 'Anxiety');
    expect(articles.single.summary, 'A trusted overview.');
    expect(articles.single.url.host, 'medlineplus.gov');
  });

  test('lesson completion persists locally', () async {
    final store = LearningProgressStore();

    await store.setCompleted('understanding-anxiety', true);
    expect(await store.loadCompleted(), contains('understanding-anxiety'));

    await store.setCompleted('understanding-anxiety', false);
    expect(
        await store.loadCompleted(), isNot(contains('understanding-anxiety')));

    await store.setIdeaHelpful('understanding-anxiety', 2, true);
    expect(
      await store.loadHelpfulIdeas('understanding-anxiety'),
      contains(2),
    );
    await store.setIdeaHelpful('understanding-anxiety', 2, false);
    expect(
      await store.loadHelpfulIdeas('understanding-anxiety'),
      isNot(contains(2)),
    );

    await store.rememberPosition('understanding-anxiety', 2);
    expect(await store.loadLastLessonId(), 'understanding-anxiety');
    expect(
      await store.loadIdeaIndex('understanding-anxiety', max: 4),
      2,
    );
    expect(
      await store.loadIdeaIndex('understanding-anxiety', max: 2),
      1,
    );

    await store.markIdeaViewed('understanding-anxiety', 1);
    await store.markIdeaViewed('understanding-anxiety', 3);
    expect(
      await store.loadViewedIdeas('understanding-anxiety'),
      containsAll({1, 3}),
    );
  });

  testWidgets('search understands everyday language and prioritizes safety',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LearningHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('learning-search-field')),
      'willpower',
    );
    await tester.pump();
    expect(find.text('Substance use and mental health'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('learning-search-field')),
      'want to die',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('learning-safety-search-result')),
      findsOneWidget,
    );
    expect(find.textContaining('Call 911'), findsOneWidget);
  });

  testWidgets('saved helpful ideas appear in the personal toolkit',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'mental_health_learning_helpful_ideas': ['social-anxiety:1'],
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LearningToolkitScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('saved-idea-social-anxiety-1')),
      findsOneWidget,
    );
    expect(find.text('The mind and body can both react'), findsOneWidget);
  });

  testWidgets('learning hub offers a saved resume point', (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'mental_health_learning_last_lesson_id': 'sleep-and-mind',
      'mental_health_learning_idea_position_sleep-and-mind': 2,
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LearningHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('continue-learning-card')), findsOneWidget);
    expect(find.text('Continue learning'), findsOneWidget);
    expect(find.text('Sleep and your mind'), findsWidgets);
    expect(find.text('Idea 3 of 4'), findsOneWidget);
  });

  testWidgets('learning hub searches and opens the idea-card reader',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LearningHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('learning-intro-card')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('learning-search-field')),
      'panic',
    );
    await tester.pump();

    expect(find.text('When panic takes over'), findsOneWidget);
    expect(find.text('Sleep and your mind'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('When panic takes over'),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('learning-hub-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('When panic takes over'));
    await tester.pumpAndSettle();

    expect(find.byType(LearningLessonScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('learning-idea-page-view')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('learning-idea-1')), findsOneWidget);
    expect(find.text('4 key ideas'), findsOneWidget);
    expect(find.text('Idea 1 of 4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('learning-idea-progress')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('learning-idea-1')),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey('helpful-learning-idea-0')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('next-learning-idea')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('learning-lesson-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('next-learning-idea')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(
      await LearningProgressStore().loadIdeaIndex('panic-attacks', max: 4),
      1,
    );
  });

  testWidgets('last idea reveals reflection without a layout error',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'mental_health_learning_idea_position_panic-attacks': 3,
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: LearningLessonScreen(
            lesson: LearningCatalog.byId('panic-attacks'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('next-learning-idea')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('learning-lesson-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('next-learning-idea')),
        )
        .onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Pause and reflect'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Pause and reflect')).dy, lessThan(844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Kaibigan loading mark fits its narrow contract',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 42,
              child: KaibiganLoadingMark(
                color: Colors.black,
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(KaibiganLoadingMark)).width, 42);
  });

  testWidgets('idea reader remains swipeable on a narrow phone with large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.25),
            ),
            child: child!,
          ),
          home: LearningLessonScreen(
            lesson: LearningCatalog.byId('asking-for-help'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('learning-idea-page-view')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('learning-lesson-scroll-view')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const ValueKey('learning-idea-page-view')),
      const Offset(-250, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Idea 2 of 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Philippine support contacts reflow without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.25),
            ),
            child: child!,
          ),
          home: LearningLessonScreen(
            lesson: LearningCatalog.byId('philippines-support-contacts'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final contactCard =
        find.byKey(const ValueKey('philippines-support-contacts-card'));
    expect(contactCard, findsOneWidget);

    expect(find.text('911'), findsOneWidget);
    expect(find.text('1553'), findsOneWidget);
    expect(find.text('0917 899 8727'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
