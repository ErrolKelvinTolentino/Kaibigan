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
      greaterThanOrEqualTo(300),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('journal-paper-breathing-room')))
          .height,
      32,
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
      32,
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
    final freshReplyField = find.byKey(
      const ValueKey('active-journal-writing-field'),
    );
    expect(firstChat, lessThan(firstResponse));
    expect(firstResponse, lessThan(secondChat));
    expect(secondChat, lessThan(secondResponse));
    expect(freshReplyField, findsOneWidget);
    expect(secondResponse, lessThan(tester.getTopLeft(freshReplyField).dy));

    await tester.ensureVisible(freshReplyField);
    await tester.pumpAndSettle();
    await tester.tap(freshReplyField);
    await tester.enterText(freshReplyField, 'This is what I want to say next.');
    expect(find.text('First chat'), findsOneWidget);
    expect(find.text('This is what I want to say next.'), findsOneWidget);
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

  testWidgets('crisis response renders without overflow on narrow screens',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const crisisText =
        'Your safety comes first right now. National Center for Mental Health (NCMH) Crisis Hotline: 1553';
    final entry = JournalEntry(
      id: 'crisis-entry',
      title: 'Need help',
      content: 'I need help',
      aiResponse: crisisText,
      companionId: 'kai',
      createdAt: DateTime(2026, 8, 25),
      conversationTurns: const [
        JournalConversationTurn(
          userText: 'I need help',
          aiResponse: crisisText,
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

    expect(find.text('24/7 Free Crisis Support (Philippines)'), findsOneWidget);
    expect(find.text('Emergency 911'), findsOneWidget);
    expect(find.text('Call NCMH 1553'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'sending closes keyboard, shows the reply start, and waits for a tap',
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

    final inputField =
        find.byKey(const ValueKey('active-journal-writing-field'));
    await tester.tap(inputField);
    await tester.enterText(
        inputField, 'I had a really busy and overwhelming day.');
    await tester.pumpAndSettle();

    final textFieldWidget = tester.widget<TextField>(inputField);
    expect(textFieldWidget.focusNode?.hasFocus, isTrue);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final shareButton = find.text('Share with Kai');
    expect(shareButton, findsOneWidget);
    await tester.tap(shareButton);
    await tester.pump();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();

    // The reply from the companion arrives and renders in the journal stream
    expect(find.text('a quiet note'), findsOneWidget);
    final nextInput = tester.widget<TextField>(inputField);
    expect(textFieldWidget.focusNode?.hasFocus, isFalse);
    expect(nextInput.focusNode?.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    final reply = find.byKey(const ValueKey('journal-ai-reply-0'));
    final viewport = find.byKey(const ValueKey('journal-editor-scroll'));
    expect(tester.getTopLeft(reply).dy,
        closeTo(tester.getTopLeft(viewport).dy, 2));
    await tester.ensureVisible(inputField);
    await tester.tap(inputField);
    await tester.pump();
    expect(nextInput.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('cleanLegacyMarkdownHeadings converts legacy ### markdown headings to bold', () {
    const raw = '''
### What you shared
Felt tired today.

### What may connect
Work stress.
''';
    final cleaned = JournalTurn.cleanLegacyMarkdownHeadings(raw);
    expect(cleaned, contains('**What you shared**'));
    expect(cleaned, contains('**What may connect**'));
    expect(cleaned, isNot(contains('###')));
  });

  testWidgets('Journal title field allows multiline text without single-line clipping',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_companion': 'kai',
      'preferred_language': 'english',
    });
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: JournalEditorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final titleFieldFinder = find.byKey(const ValueKey('journal-title-field'));
    expect(titleFieldFinder, findsOneWidget);

    final titleField = tester.widget<TextField>(titleFieldFinder);
    expect(titleField.maxLines, isNull);
    expect(titleField.keyboardType, TextInputType.multiline);

    await tester.enterText(titleFieldFinder, 'Weekly Reflection (Oct 12 – Oct 18)');
    await tester.pumpAndSettle();

    expect(find.text('Weekly Reflection (Oct 12 – Oct 18)'), findsOneWidget);
  });
}

