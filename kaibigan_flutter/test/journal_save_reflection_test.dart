import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_service.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_save_reflection_screen.dart';

void main() {
  JournalEntry entry({String title = ''}) => JournalEntry(
        id: 'entry',
        title: title,
        content: 'I had a happy, uninterrupted gaming session today.',
        companionId: 'kai',
        createdAt: DateTime(2026, 8, 25),
      );

  testWidgets('successful recap shows warm slides and AI emotion tags',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const summary = AIJournalSaveSummary(
      summary:
          'A worry-free stretch gave you room to enjoy something fully and simply rest.',
      emotions: ['happy', 'grateful'],
      moments: [
        AIJournalMoment(
          title: 'Room to switch off',
          reflection:
              'The uninterrupted time mattered because nothing else was asking for your attention.',
          emotions: ['happy', 'relieved'],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: JournalSaveReflectionScreen(
        entry: entry(),
        language: 'english',
        companionId: 'kai',
        summaryLoader: () async => summary,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('A moment in your life'), findsOneWidget);
    expect(find.text('Happy'), findsWidgets);
    expect(find.text('Grateful'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('journal-summary-success')), findsOneWidget);
    expect(find.byType(Spacer), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Room to switch off'), findsOneWidget);
    expect(find.text('Relieved'), findsOneWidget);
  });

  testWidgets('failed recap is simple and never shows emotion chips',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: JournalSaveReflectionScreen(
        entry: entry(title: 'A gaming afternoon'),
        language: 'english',
        companionId: 'kai',
        summaryLoader: () async => throw StateError('AI unavailable'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Kaibigan'), findsOneWidget);
    expect(find.text('Your moment is safely kept'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('journal-summary-fallback')), findsOneWidget);
    expect(find.text('Happy'), findsNothing);
    expect(find.text('Grateful'), findsNothing);
  });

  test('legacy untitled values receive the warmer display title', () {
    expect(entry(title: 'Untitled Entry').displayTitle('english'),
        'A moment in your life');
    expect(entry(title: 'Untitled Reflection').displayTitle('filipino'),
        'Isang sandali sa iyong buhay');
  });
}
