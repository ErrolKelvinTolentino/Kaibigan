import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/journaling/journal_editor_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_save_reflection_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AI journal starts as one natural, uncluttered conversation',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_companion': 'kai',
      'preferred_language': 'taglish',
    });
    await tester.binding.setSurfaceSize(const Size(620, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: JournalEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Write it as it comes'), findsOneWidget);
    expect(find.text('Share with Kai'), findsOneWidget);
    expect(find.text('What has been sitting with you?'), findsOneWidget);

    expect(find.text('Just Venting'), findsNothing);
    expect(find.text('Gentle Advice'), findsNothing);
    expect(find.text('Kalmado'), findsNothing);
    expect(find.text('Reflection'), findsNothing);

    final activeField = tester.widget<TextField>(
      find.byKey(const ValueKey('active-journal-writing-field')),
    );
    expect(activeField.minLines, 7);
    expect(
      tester.getSize(find.byKey(const ValueKey('ai-journal-paper'))).height,
      greaterThanOrEqualTo(420),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('journal-paper-breathing-room')))
          .height,
      84,
    );

    await tester.tap(find.text('Need a starting point?'));
    await tester.pumpAndSettle();

    expect(
      find.text('What is occupying the most space in your head right now?'),
      findsOneWidget,
    );
  });

  testWidgets('automatic attunement keeps configuration out of the journal',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: JournalEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auto'), findsNothing);
    expect(find.text('How does this moment feel?'), findsNothing);
    expect(find.text('Calm'), findsNothing);
    expect(find.text('How should your companion respond?'), findsNothing);
    expect(find.text('Name this moment (optional)'), findsOneWidget);
    expect(find.byTooltip('More journal actions'), findsOneWidget);
    expect(find.byTooltip('Save journal'), findsOneWidget);
  });

  testWidgets('long AI exchange keeps a generous fresh writing area on a phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final longEntry = List.filled(
      12,
      'I am trying to understand everything that happened today.',
    ).join(' ');
    final longReply = List.filled(
      8,
      'It makes sense that this has been taking up so much space.',
    ).join(' ');
    final entry = JournalEntry(
      id: 'long-exchange',
      title: 'A full page',
      content: longEntry,
      aiResponse: longReply,
      companionId: 'kai',
      createdAt: DateTime(2026, 8, 27),
      conversationTurns: [
        JournalConversationTurn(
          userText: longEntry,
          aiResponse: longReply,
          companionId: 'kai',
        ),
        const JournalConversationTurn(
          userText: '',
          companionId: 'kai',
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(home: JournalEditorScreen(entry: entry)),
      ),
    );
    await tester.pumpAndSettle();

    final activeFinder =
        find.byKey(const ValueKey('active-journal-writing-field'));
    final activeField = tester.widget<TextField>(activeFinder);
    expect(activeField.minLines, 7);
    expect(tester.getSize(activeFinder).height, greaterThan(180));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('journal-paper-breathing-room')))
          .height,
      84,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved conversations reopen in chat-response order',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(620, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final entry = JournalEntry(
      id: 'entry',
      title: 'A remembered conversation',
      content: 'First chat\n\nSecond chat',
      aiResponse: 'First response\n\n---\n\nSecond response',
      companionId: 'kai',
      createdAt: DateTime(2026, 8, 25),
      conversationTurns: const [
        JournalConversationTurn(
          userText: 'First chat',
          aiResponse: 'First response',
          companionId: 'kai',
        ),
        JournalConversationTurn(
          userText: 'Second chat',
          aiResponse: 'Second response',
          companionId: 'kai',
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(home: JournalEditorScreen(entry: entry)),
      ),
    );
    await tester.pumpAndSettle();

    final firstChat = tester.getTopLeft(find.text('First chat')).dy;
    final firstResponse = tester.getTopLeft(find.text('First response')).dy;
    final secondChat = tester.getTopLeft(find.text('Second chat')).dy;
    final secondResponse = tester.getTopLeft(find.text('Second response')).dy;
    expect(firstChat, lessThan(firstResponse));
    expect(firstResponse, lessThan(secondChat));
    expect(secondChat, lessThan(secondResponse));
  });

  testWidgets('saving an unchanged record closes without another AI recap',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final entry = JournalEntry(
      id: 'entry',
      title: 'A quiet entry',
      content: 'Nothing changed here.',
      aiResponse: 'It sounds like a quiet moment.',
      companionId: 'kai',
      createdAt: DateTime(2026, 8, 25),
      conversationTurns: const [
        JournalConversationTurn(
          userText: 'Nothing changed here.',
          aiResponse: 'It sounds like a quiet moment.',
          companionId: 'kai',
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalEditorScreen(entry: entry),
                    ),
                  ),
                  child: const Text('Open record'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open record'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save journal'));
    await tester.pumpAndSettle();

    expect(find.text('Open record'), findsOneWidget);
    expect(find.byType(JournalSaveReflectionScreen), findsNothing);
  });
}
