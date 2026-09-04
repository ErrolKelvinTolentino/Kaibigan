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

  testWidgets('long AI summary does not overflow on small mobile screens',
      (tester) async {
    // Standard compact mobile viewport
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const longSummary = AIJournalSaveSummary(
      summary:
          'Today brought a heavy wave of pressure with competing priorities and lots of background noise. Even though you felt like you had very little left to give, you still paused to acknowledge what mattered and gave yourself grace for making it through each small challenge one step at a time.',
      emotions: [
        'overwhelmed',
        'tired',
        'grateful',
        'hopeful',
        'anxious',
        'relieved'
      ],
      moments: [
        AIJournalMoment(
          title: 'Holding on through the afternoon fog',
          reflection:
              'The moment where you decided to step away and catch your breath was crucial. It allowed your nervous system to reset even when everything else felt chaotic.',
          emotions: ['tired', 'calm', 'hopeful'],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(
      home: JournalSaveReflectionScreen(
        entry: entry(title: 'A long and overwhelming day that needed reflection'),
        language: 'english',
        companionId: 'kai',
        summaryLoader: () async => longSummary,
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('journal-summary-success')), findsOneWidget);
    expect(find.text('Overwhelmed'), findsOneWidget);
    expect(find.text('Relieved'), findsOneWidget);

    // Can continue to moments slide without overflow
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Holding on through the afternoon fog'), findsOneWidget);
  });

  test('legacy untitled values receive the warmer display title', () {
    expect(entry(title: 'Untitled Entry').displayTitle('english'),
        'A moment in your life');
    expect(entry(title: 'Untitled Reflection').displayTitle('filipino'),
        'Isang sandali sa iyong buhay');
  });
}
