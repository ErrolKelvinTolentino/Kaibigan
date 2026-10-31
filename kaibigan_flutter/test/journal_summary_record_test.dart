import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_service.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_save_reflection_screen.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:kaibigan_flutter/features/unified_entries/unified_entry_detail_screen.dart';
import 'package:kaibigan_flutter/features/unified_entries/unified_feed_item.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _summary = AIJournalSaveSummary(
  summary: 'The evening freed up and you let yourself stop, which is rarer '
      'than the entry gives it credit for.',
  emotions: ['relieved', 'calm'],
  advice: 'If tomorrow ends the same way, try leaving the last hour unplanned '
      'on purpose and see whether it still feels like rest.',
  moments: [
    AIJournalMoment(
      title: 'Choosing to stop',
      reflection: 'Stopping was a decision here, not something that happened '
          'to you.',
      emotions: ['proud'],
    ),
  ],
);

JournalEntry entryWithSummary({AIJournalSaveSummary? summary}) => JournalEntry(
      id: '3f6d1c8e-9a2b-4c7d-8e1f-5b3a2c9d7e40',
      title: 'A quiet evening',
      content: 'Nothing was asking for me tonight so I just sat down.',
      aiResponse: 'That sounds like a real pause.',
      companionId: 'kai',
      createdAt: DateTime(2026, 9, 9, 21),
      summary: summary,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'display_name': 'Sam',
    });
  });

  group('summary persistence', () {
    test('round-trips through the database map', () {
      final restored = JournalEntry.fromMap(
        Map<String, dynamic>.from(entryWithSummary(summary: _summary).toMap()),
      );

      expect(restored.summary, isNotNull);
      expect(restored.summary!.summary, _summary.summary);
      expect(restored.summary!.advice, _summary.advice);
      expect(restored.summary!.emotions, ['relieved', 'calm']);
      expect(restored.summary!.moments.single.title, 'Choosing to stop');
      expect(restored.summary!.hasAdvice, isTrue);
    });

    test('a record saved before this feature simply has no cards', () {
      final legacy = JournalEntry.fromMap({
        'id': 'legacy',
        'title': 'Older entry',
        'content': 'Written before summaries were kept.',
        'companion_id': 'kai',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      });

      expect(legacy.summary, isNull);
    });

    test('a malformed stored summary is discarded rather than half-rendered',
        () {
      expect(AIJournalSaveSummary.tryParse('not an object'), isNull);
      expect(AIJournalSaveSummary.tryParse({'summary': '   '}), isNull);
      expect(AIJournalSaveSummary.tryParse(null), isNull);

      final partial = AIJournalSaveSummary.tryParse({
        'summary': 'Kept.',
        'moments': [
          {'title': 'no reflection', 'reflection': ''},
        ],
      });
      expect(partial, isNotNull);
      expect(partial!.moments, isEmpty);
      expect(partial.hasAdvice, isFalse);
    });
  });

  group('summary screen', () {
    testWidgets('offers advice as its own final card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      AIJournalSaveSummary? handedBack;

      await tester.pumpWidget(
        MaterialApp(
          home: JournalSaveReflectionScreen(
            entry: entryWithSummary(),
            language: 'english',
            companionId: 'kai',
            summaryLoader: () async => _summary,
            onSummaryReady: (value) async {
              handedBack = value;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The caller is handed the summary so it can be kept with the record.
      expect(handedBack, isNotNull);

      // Recap, then the moment, then the advice.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choosing to stop'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('journal-summary-advice-card')),
        findsOneWidget,
      );
      expect(find.text('SOMETHING YOU COULD TRY'), findsOneWidget);
      expect(find.textContaining('leaving the last hour unplanned'),
          findsOneWidget);
      expect(
        find.textContaining('An option, not an instruction'),
        findsOneWidget,
        reason: 'advice must not read as a prescription',
      );
    });

    testWidgets('shows no advice card when the model had nothing to suggest',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: JournalSaveReflectionScreen(
            entry: entryWithSummary(),
            language: 'english',
            companionId: 'kai',
            summaryLoader: () async => const AIJournalSaveSummary(
              summary: 'A short, plain day.',
              emotions: [],
              moments: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('journal-summary-advice-card')),
        findsNothing,
      );
    });
  });

  group('record view', () {
    Widget detailFor(JournalEntry entry) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider(create: (_) => JournalProvider()),
            ChangeNotifierProvider(create: (_) => GratitudeProvider()),
            ChangeNotifierProvider(create: (_) => MoodProvider()),
            ChangeNotifierProvider(
              create: (_) => RoutinesProvider(syncOnCreate: false),
            ),
          ],
          child: MaterialApp(
            home: UnifiedEntryDetailScreen(
              item: UnifiedFeedItem(
                id: entry.id,
                category: EntryCategory.journal,
                categoryTag: 'Journal',
                categoryColor: const Color(0xFFE8B35E),
                iconAssetOrEmoji: '📓',
                title: entry.title,
                content: entry.content,
                timestamp: entry.createdAt,
                rawData: entry,
              ),
            ),
          ),
        );

    testWidgets('Insights opens saved cards in the original carousel',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(detailFor(entryWithSummary(summary: _summary)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('record-summary-deck')), findsNothing);
      expect(find.text('WHAT THIS ENTRY LEFT YOU WITH'), findsNothing);
      expect(find.text('THE JOURNAL'), findsOneWidget);
      expect(find.text(_summary.summary), findsNothing);
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.byType(JournalSaveReflectionScreen), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text(_summary.summary), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(find.text('Choosing to stop'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('THE JOURNAL'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
    });
    testWidgets('an entry without a summary shows the conversation alone',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(detailFor(entryWithSummary()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('record-summary-deck')), findsNothing);
      expect(find.text('THE JOURNAL'), findsOneWidget);
    });
  });
}
