import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_service.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_reflection_insights.dart';
import 'package:kaibigan_flutter/features/journaling/journal_save_reflection_screen.dart';

void main() {
  final now = DateTime(2026, 8, 25, 21);

  JournalEntry entry({
    String id = 'entry',
    int daysAgo = 0,
    String content = 'A long day that I wanted to write down before bed.',
    List<String> emotions = const [],
  }) =>
      JournalEntry(
        id: id,
        title: '',
        content: content,
        companionId: 'kai',
        createdAt: now.subtract(Duration(days: daysAgo)),
        summary: emotions.isEmpty
            ? null
            : AIJournalSaveSummary(
                summary: 'A saved recap.',
                emotions: emotions,
                moments: const [],
              ),
      );

  const summary = AIJournalSaveSummary(
    summary: 'A worry-free stretch gave you room to rest.',
    emotions: ['tired', 'grateful'],
    moments: [],
  );

  JournalContextReading readingFor(
    List<JournalEntry> previous, {
    AIJournalSaveSummary? withSummary = summary,
    String language = 'english',
  }) =>
      JournalReflectionInsights.read(
        entry: entry(),
        previousEntries: previous,
        language: language,
        summary: withSummary,
        now: now,
      );

  group('writing rhythm', () {
    test('the first entry is named as a beginning, not as a gap', () {
      final reading = readingFor(const []);

      expect(reading.daysSinceLastEntry, isNull);
      expect(reading.entriesThisWeek, 1);
      expect(reading.continuityNote, contains('first entry you have kept'));
    });

    test('a long silence is welcomed rather than counted against the person',
        () {
      final reading = readingFor([entry(id: 'old', daysAgo: 9)]);

      expect(reading.daysSinceLastEntry, 9);
      expect(reading.continuityNote, contains('first entry in 9 days'));
      expect(reading.continuityNote, contains('worth as much'));
    });

    test('three entries in a week is called out as enough for a pattern', () {
      final reading = readingFor([
        entry(id: 'a', daysAgo: 1),
        entry(id: 'b', daysAgo: 3),
      ]);

      expect(reading.entriesThisWeek, 3);
      expect(reading.continuityNote, contains('third entry in seven days'));
    });

    test('two entries close together are connected to each other', () {
      final reading = readingFor([entry(id: 'a', daysAgo: 1)]);

      expect(reading.continuityNote, contains('yesterday'));
    });
  });

  group('recurring emotions', () {
    test('an emotion in one earlier entry is a coincidence, not a pattern',
        () {
      final reading = readingFor([
        entry(id: 'a', daysAgo: 2, emotions: ['tired']),
      ]);

      expect(reading.recurringEmotions, isEmpty);
      expect(reading.recurrenceNote, isNull);
    });

    test('an emotion across three entries is named and explained', () {
      final reading = readingFor([
        entry(id: 'a', daysAgo: 2, emotions: ['tired', 'anxious']),
        entry(id: 'b', daysAgo: 5, emotions: ['tired']),
      ]);

      expect(reading.recurringEmotions, ['tired']);
      expect(reading.recurrenceNote, contains('Tired'));
      expect(reading.recurrenceNote, contains('situation behind it'));
    });

    test('entries beyond the recent window stop counting', () {
      final reading = readingFor([
        entry(id: 'a', daysAgo: 2, emotions: ['tired']),
        entry(id: 'b', daysAgo: 60, emotions: ['tired']),
      ]);

      expect(reading.recurringEmotions, isEmpty);
    });

    test('nothing recurs before the companion has labelled this entry', () {
      final reading = readingFor(
        [
          entry(id: 'a', daysAgo: 2, emotions: ['tired']),
          entry(id: 'b', daysAgo: 4, emotions: ['tired']),
        ],
        withSummary: null,
      );

      expect(reading.recurringEmotions, isEmpty);
      // The rhythm is still readable without the model.
      expect(reading.continuityNote, isNotNull);
    });
  });

  group('follow-ups', () {
    List<JournalFollowUpKind> kindsFor(List<String> emotions) =>
        JournalReflectionInsights.followUpsFor(
          emotions: emotions,
          language: 'english',
        ).map((followUp) => followUp.kind).toList();

    test('a hard feeling is answered before a pleasant one', () {
      expect(
        kindsFor(['grateful', 'overwhelmed']).first,
        JournalFollowUpKind.breathing,
      );
    });

    test('repeated tiredness is pointed at the sleep log', () {
      expect(kindsFor(['tired']), contains(JournalFollowUpKind.sleepLog));
    });

    test('loneliness is offered somewhere to sit, not something to fix', () {
      expect(kindsFor(['lonely']), [JournalFollowUpKind.comfortCorner]);
    });

    test('a good moment is offered the garden', () {
      expect(kindsFor(['proud']), [JournalFollowUpKind.gratitude]);
    });

    test('an unlabelled entry still gets one useful move', () {
      expect(kindsFor(const []), [JournalFollowUpKind.moodCheckIn]);
    });

    test('never more than two, so the page does not become a to-do list', () {
      expect(
        kindsFor(['anxious', 'frustrated', 'tired', 'lonely', 'proud']).length,
        2,
      );
    });

    test('each suggestion carries the reason it was chosen', () {
      final followUps = JournalReflectionInsights.followUpsFor(
        emotions: ['anxious'],
        language: 'english',
      );
      expect(followUps.single.rationale, contains('out-breath'));
    });
  });

  test('the whole reading follows the chosen language', () {
    final reading = readingFor(
      [
        entry(id: 'a', daysAgo: 2, emotions: ['tired']),
        entry(id: 'b', daysAgo: 4, emotions: ['tired']),
      ],
      language: 'filipino',
    );

    expect(reading.recurrenceNote, contains('Pagod'));
    expect(reading.followUps.first.title, contains('kagabi'));
  });

  group('JournalSaveReflectionScreen', () {
    const rich = AIJournalSaveSummary(
      summary: 'You gave yourself an evening with nothing asked of it.',
      emotions: ['tired', 'relieved'],
      moments: [
        AIJournalMoment(
          title: 'Room to switch off',
          reflection: 'Nothing else was asking for your attention.',
          emotions: ['relieved'],
        ),
      ],
      advice: 'Try leaving tomorrow evening unplanned as well.',
      question: 'What made it possible to stop tonight?',
    );

    Future<void> pump(
      WidgetTester tester, {
      required JournalSummaryLoader loader,
      List<JournalEntry> previous = const [],
    }) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: JournalSaveReflectionScreen(
          entry: entry(),
          language: 'english',
          companionId: 'kai',
          summaryLoader: loader,
          previousEntries: previous,
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> advanceTo(WidgetTester tester, String label) async {
      for (var step = 0; step < 6; step++) {
        if (find.text(label).evaluate().isNotEmpty) return;
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
      fail('never reached the card containing "$label"');
    }

    testWidgets('an open question is offered without asking for an answer',
        (tester) async {
      await pump(tester, loader: () async => rich);
      await advanceTo(tester, 'No answer needed today');

      expect(find.text('What made it possible to stop tonight?'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('journal-summary-question-card')),
          findsOneWidget);
    });

    testWidgets('the page ends somewhere to go, not at the last sentence',
        (tester) async {
      await pump(tester, loader: () async => rich);
      // The follow-up card is the last one, so the button changes to the
      // closing label once it is the settled page.
      await advanceTo(tester, 'Done');

      expect(find.byKey(const ValueKey('journal-summary-followup-card')),
          findsOneWidget);
      expect(find.text('Carry it forward'), findsOneWidget);
      expect(find.text('Log last night'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('what keeps coming back is shown when it genuinely recurs',
        (tester) async {
      await pump(
        tester,
        loader: () async => rich,
        previous: [
          entry(id: 'a', daysAgo: 2, emotions: ['tired']),
          entry(id: 'b', daysAgo: 4, emotions: ['tired']),
        ],
      );
      await advanceTo(tester, 'This keeps coming back');

      expect(find.byKey(const ValueKey('journal-summary-context-card')),
          findsOneWidget);
      expect(find.textContaining('Tired'), findsWidgets);
    });

    testWidgets('a failed recap still leaves the on-device look-back',
        (tester) async {
      await pump(
        tester,
        loader: () async => throw StateError('AI unavailable'),
        previous: [entry(id: 'a', daysAgo: 9)],
      );

      expect(
          find.byKey(const ValueKey('journal-summary-fallback')), findsOneWidget);
      expect(find.byKey(const ValueKey('journal-summary-fallback-context')),
          findsOneWidget);
      expect(find.textContaining('first entry in 9 days'), findsOneWidget);
      // Without emotions to go on, the neutral move is still offered.
      expect(find.text('Check in on where you are now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
