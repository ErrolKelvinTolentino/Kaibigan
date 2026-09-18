import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/journaling/journal_reply_starters.dart';

void main() {
  List<String> visible(
    List<String> suggested, {
    bool isAnsweringTurn = true,
    bool activeTurnIsEmpty = true,
    bool isBusy = false,
  }) =>
      JournalReplyStarters.visibleStarters(
        suggested,
        isAnsweringTurn: isAnsweringTurn,
        activeTurnIsEmpty: activeTurnIsEmpty,
        isBusy: isBusy,
      );

  group('when starters are offered', () {
    test('on the turn about to be answered, while it is still blank', () {
      expect(
        visible(['I think what got to me was', 'Honestly I just felt']),
        ['I think what got to me was', 'Honestly I just felt'],
      );
    });

    test('never once the person has started writing their own words', () {
      expect(
        visible(['I think what got to me was'], activeTurnIsEmpty: false),
        isEmpty,
      );
    });

    test('never on an older turn further up the conversation', () {
      expect(
        visible(['I think what got to me was'], isAnsweringTurn: false),
        isEmpty,
      );
    });

    test('never while a reply is still being generated', () {
      expect(visible(['Something'], isBusy: true), isEmpty);
    });

    test('at most two, so the page does not become a menu', () {
      expect(visible(const ['One', 'Two', 'Three', 'Four']), hasLength(2));
    });

    test('blank and runaway suggestions are dropped', () {
      expect(
        visible(['   ', 'A usable opener', 'x' * 200]),
        ['A usable opener'],
      );
    });
  });

  group('the starter row', () {
    Widget rowWith(List<String> starters, {ValueChanged<String>? onSelected}) =>
        MaterialApp(
          home: Scaffold(
            body: JournalReplyStarters(
              starters: starters,
              label: 'IF IT HELPS TO START',
              isDark: false,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        );

    testWidgets('hands back the starter that was tapped', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        rowWith(
          const ['I think what got to me was', 'Honestly I just felt'],
          onSelected: (value) => chosen = value,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('journal-reply-starters')),
        findsOneWidget,
      );
      expect(find.text('IF IT HELPS TO START'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('reply-starter-Honestly I just felt'),
        ),
      );
      await tester.pump();
      expect(chosen, 'Honestly I just felt');
    });

    testWidgets('takes up no space when there is nothing to offer',
        (tester) async {
      await tester.pumpWidget(rowWith(const []));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('journal-reply-starters')),
        findsNothing,
      );
      expect(
        tester.getSize(find.byType(JournalReplyStarters)),
        Size.zero,
      );
    });

    testWidgets('a long starter wraps instead of overflowing a narrow phone',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        rowWith(const [
          'I think the part that actually got to me was how quiet it went',
        ]),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
