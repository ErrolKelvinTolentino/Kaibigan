import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_practice_model.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_practice_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_practice_service.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final overwhelm = PracticeScenarios.byId('practice-overwhelm');
  final hopeless = PracticeScenarios.byId('practice-hopeless');

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'display_name': 'Sam',
    });
  });

  PracticeTurnResult grade(
    String reply, {
    PracticeScenario? scenario,
    int turnIndex = 0,
  }) {
    return LocalPracticeCoach.evaluate(
      scenario: scenario ?? overwhelm,
      userReply: reply,
      language: 'english',
      turnIndex: turnIndex,
    );
  }

  group('scenarios', () {
    test('every scenario points at a lesson that exists in the catalogue', () {
      const lessonIds = {
        'friend-support-listen',
        'friend-support-safety',
        'friend-support-boundaries',
      };
      for (final scenario in PracticeScenarios.all) {
        expect(lessonIds, contains(scenario.lessonId));
        expect(scenario.skillFocus, isNotEmpty);
        expect(scenario.opener.english.trim(), isNotEmpty);
      }
    });

    test('only the safety scenario is flagged sensitive', () {
      final sensitive =
          PracticeScenarios.all.where((s) => s.isSensitive).toList();
      expect(sensitive, hasLength(1));
      expect(sensitive.single.lessonId, 'friend-support-safety');
    });
  });

  group('LocalPracticeCoach', () {
    test('credits a reply that validates and asks an open question', () {
      final result = grade(
        "That sounds really heavy, and I'm here. What has it been like?",
      );

      expect(result.tone, PracticeFeedbackTone.strong);
      expect(result.points.every((point) => point.isStrength), isTrue);
      expect(result.headline, contains('landed well'));
      expect(
        result.hasModelPhrase,
        isFalse,
        reason: 'a strong reply does not need a replacement phrase',
      );
    });

    test('names minimising for what it is', () {
      final result = grade("At least you have a job. It's not that bad.");

      expect(result.tone, PracticeFeedbackTone.offTrack);
      expect(
        result.points.any((point) => point.label.contains('bright side')),
        isTrue,
      );
      expect(result.hasModelPhrase, isTrue);
    });

    test('flags jumping to advice even when it is well meant', () {
      final result = grade('You should just talk to your manager about it.');

      expect(
        result.points.any((point) => !point.isStrength),
        isTrue,
      );
      expect(
        result.points.any((point) => point.label.contains('listening')),
        isTrue,
      );
    });

    test('flags turning the conversation back on yourself', () {
      final result = grade('Same here, I went through exactly this last year.');
      expect(
        result.points.any((point) => point.label.contains('about them')),
        isTrue,
      );
    });

    test('a very short reply is called out as distance', () {
      final result = grade('ok');
      expect(result.tone, PracticeFeedbackTone.offTrack);
      expect(
        result.points.any((point) => point.label.contains('more to hold')),
        isTrue,
      );
    });

    test('a mixed reply is graded as mixed, not as a failure', () {
      final result = grade(
        "That sounds really difficult. You should try to sleep earlier.",
      );
      expect(result.tone, PracticeFeedbackTone.mixed);
      expect(result.points.any((point) => point.isStrength), isTrue);
      expect(result.points.any((point) => !point.isStrength), isTrue);
    });

    test('asking about safety is credited in the safety scenario', () {
      final result = grade(
        'I want to ask directly — are you safe right now?',
        scenario: hopeless,
      );
      expect(
        result.points.any((point) => point.label.contains('directly')),
        isTrue,
      );
      expect(result.tone, PracticeFeedbackTone.strong);
    });

    test('after a turn, not asking about safety is raised in that scenario',
        () {
      final result = grade(
        "That sounds really hard, and I'm here with you.",
        scenario: hopeless,
        turnIndex: 1,
      );
      expect(
        result.points.any((point) => point.label.contains('direct question')),
        isTrue,
      );
      expect(result.hasModelPhrase, isTrue);
    });

    test('the friend pulls back after a dismissive reply', () {
      final dismissive = grade('At least it could be worse.');
      final warm = grade("That sounds heavy. I'm here — what happened?");
      expect(dismissive.friendReply, isNot(warm.friendReply));
      expect(dismissive.friendReply.toLowerCase(), contains('sorry'));
    });
  });

  group('practice service safety', () {
    test('a real crisis in the box stops the roleplay', () async {
      final result = await const FriendSupportPracticeService().respond(
        scenario: overwhelm,
        userReply: 'I want to kill myself',
        history: const [],
        language: 'english',
      );

      expect(result.endsPractice, isTrue);
      expect(result.tone, PracticeFeedbackTone.unsafe);
      expect(result.friendReply, contains('1553'));
    });

    test('an empty reply is refused without calling anything', () async {
      final result = await const FriendSupportPracticeService().respond(
        scenario: overwhelm,
        userReply: '   ',
        history: const [],
        language: 'english',
      );
      expect(result.headline, contains('Write something'));
      expect(result.points, isEmpty);
    });
  });

  group('practice screen', () {
    Widget screenFor(PracticeScenario scenario) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
          ],
          child: MaterialApp(
            home: FriendSupportPracticeScreen(
              scenario: scenario,
              service: const _OfflinePracticeService(),
            ),
          ),
        );

    testWidgets('briefs, then runs a graded exchange', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(screenFor(overwhelm));
      await tester.pumpAndSettle();

      // The briefing says who this is and what to practise.
      expect(find.byKey(const ValueKey('practice-briefing')), findsOneWidget);
      expect(find.textContaining('Mika needs a friend'), findsOneWidget);
      expect(
        find.textContaining('written by the app, not a real person'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('start-practice-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('practice-transcript')), findsOneWidget);
      expect(find.textContaining('everything just feels like too much'),
          findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('practice-reply-field')),
        "That sounds really heavy. I'm here. What has it been like?",
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('practice-send-button')));
      await tester.pumpAndSettle();

      // The reply is graded and the friend answers.
      expect(
        find.byKey(const ValueKey('practice-feedback-card')),
        findsOneWidget,
      );
      expect(find.textContaining('landed well'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('the safety scenario keeps help one tap away', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(screenFor(hopeless));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('practice-need-help')), findsOneWidget);
      expect(
        find.textContaining('touches on hopelessness'),
        findsOneWidget,
      );
    });
  });
}

/// Forces the offline coach so the widget tests never reach a provider.
class _OfflinePracticeService extends FriendSupportPracticeService {
  const _OfflinePracticeService();

  @override
  Future<PracticeTurnResult> respond({
    required PracticeScenario scenario,
    required String userReply,
    required List<dynamic> history,
    required String language,
    dynamic cancellationToken,
  }) async {
    return LocalPracticeCoach.evaluate(
      scenario: scenario,
      userReply: userReply,
      language: language,
      turnIndex: history.length ~/ 2,
    );
  }
}
