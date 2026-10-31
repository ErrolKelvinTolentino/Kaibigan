import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kaibigan_flutter/features/journaling/journal_editor_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_reply_reveal.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const reply =
      'It makes sense that today felt heavy. Take this one small step at a time.';

  Widget app({
    String text = reply,
    bool animate = true,
    int revision = 1,
    bool reduceMotion = false,
    bool accessibleNavigation = false,
  }) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduceMotion,
            accessibleNavigation: accessibleNavigation,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
                child: JournalReplyReveal(
              text: text,
              animate: animate,
              revision: revision,
              builder: (context, visibleText, isRevealing, showFullReply) =>
                  Column(
                children: [
                  Text(visibleText, key: const ValueKey('reply-text')),
                  if (isRevealing)
                    TextButton(
                      onPressed: showFullReply,
                      child: const Text('Show full reflection'),
                    ),
                ],
              ),
            )),
          ),
        ),
      );

  String visible(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('reply-text'))).data!;

  testWidgets('new replies fade in and reveal words before completing',
      (tester) async {
    await tester.pumpWidget(app());
    expect(visible(tester), isEmpty);
    expect(find.text('Show full reflection'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 180));
    expect(visible(tester), isNotEmpty);
    expect(visible(tester).length, lessThan(reply.length));
    expect(reply.startsWith(visible(tester)), isTrue);
    await tester.pumpAndSettle();
    expect(visible(tester), reply);
    expect(find.text('Show full reflection'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('readers can reveal the complete reply immediately',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(find.text('Show full reflection'));
    await tester.pump();
    expect(visible(tester), reply);
    expect(find.text('Show full reflection'), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved replies and nonanimated safety messages appear in full',
      (tester) async {
    await tester.pumpWidget(app(animate: false));
    expect(visible(tester), reply);
    expect(find.text('Show full reflection'), findsNothing);
  });

  testWidgets('reduced motion and accessible navigation skip the reveal',
      (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    expect(visible(tester), reply);
    await tester.pumpWidget(app(accessibleNavigation: true, revision: 2));
    expect(visible(tester), reply);
    expect(find.text('Show full reflection'), findsNothing);
  });

  testWidgets('rebuilds do not replay replies but regeneration does',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    expect(visible(tester), reply);
    await tester.pumpWidget(app(revision: 2));
    expect(visible(tester), isEmpty);
    await tester.pumpAndSettle();
    expect(visible(tester), reply);
  });

  testWidgets('Unicode words stay intact and long replies finish promptly',
      (tester) async {
    final text =
        List.filled(70, 'Dahan-dahan 💛👨‍👩‍👧‍👦 kaibigan.').join(' ');
    await tester.pumpWidget(app(text: text));
    await tester.pump(const Duration(milliseconds: 200));
    final partial = visible(tester);
    expect(text.startsWith(partial), isTrue);
    expect(partial.endsWith(' '), isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(visible(tester), text);
    await tester.pumpAndSettle();
  });

  testWidgets('disabling motion mid-reply finishes it and disposing is safe',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(app(reduceMotion: true));
    expect(visible(tester), reply);
    await tester.pumpWidget(app(revision: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  for (final urgent in [false, true]) {
    testWidgets(
        urgent
            ? 'fresh safety guidance bypasses animation in the journal'
            : 'fresh journal reply reveals gradually and can be shown in full',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'selected_companion': 'kai',
        'preferred_language': 'english',
      });
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(home: JournalEditorScreen()),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('active-journal-writing-field')),
          urgent
              ? 'I want to die.'
              : 'I had a busy day and need time to rest.');
      await tester.pump();
      await tester.tap(find.text('Share with Kai'));
      for (var i = 0;
          i < 20 && find.byType(JournalReplyReveal).evaluate().isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      final reveal =
          tester.widget<JournalReplyReveal>(find.byType(JournalReplyReveal));
      if (urgent) {
        expect(reveal.animate, isFalse);
        expect(tester.widget<MarkdownBody>(find.byType(MarkdownBody)).data,
            reveal.text);
        expect(find.text('Show full reflection'), findsNothing);
      } else {
        expect(reveal.animate, isTrue);
        expect(
            tester.widget<MarkdownBody>(find.byType(MarkdownBody)).data.length,
            lessThan(reveal.text.length));
        await tester.pump(const Duration(milliseconds: 120));
        await tester.tap(find.text('Show full reflection'));
        await tester.pump();
        expect(tester.widget<MarkdownBody>(find.byType(MarkdownBody)).data,
            reveal.text);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
