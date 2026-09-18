import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/theme/journal_appearance.dart';
import 'package:kaibigan_flutter/core/widgets/journal_format_toolbar.dart';

void main() {
  TextEditingValue valueOf(String text, {int? start, int? end}) {
    return TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: start ?? text.length,
        extentOffset: end ?? text.length,
      ),
    );
  }

  group('JournalTextFormatter inline marks', () {
    test('wraps the selection and keeps it selected', () {
      final result = JournalTextFormatter.toggleInline(
        valueOf('a hard day', start: 2, end: 6),
        '**',
      );
      expect(result.text, 'a **hard** day');
      expect(result.selection.textInside(result.text), 'hard');
    });

    test('unwraps a selection that is already marked', () {
      final result = JournalTextFormatter.toggleInline(
        valueOf('a **hard** day', start: 2, end: 10),
        '**',
      );
      expect(result.text, 'a hard day');
    });

    test('unwraps when the marks sit just outside the selection', () {
      final result = JournalTextFormatter.toggleInline(
        valueOf('a **hard** day', start: 4, end: 8),
        '**',
      );
      expect(result.text, 'a hard day');
      expect(result.selection.textInside(result.text), 'hard');
    });

    test('with no selection, drops the caret between the marks', () {
      final result = JournalTextFormatter.toggleInline(
        valueOf('today ', start: 6, end: 6),
        '_',
      );
      expect(result.text, 'today __');
      expect(result.selection.baseOffset, 7);
      expect(result.selection.isCollapsed, isTrue);
    });

    test('italic uses a marker that does not collide with bold', () {
      final bolded = JournalTextFormatter.toggleInline(
        valueOf('tired', start: 0, end: 5),
        '**',
      );
      final both = JournalTextFormatter.toggleInline(
        bolded.copyWith(
          selection: const TextSelection(baseOffset: 2, extentOffset: 7),
        ),
        '_',
      );
      expect(both.text, '**_tired_**');
    });
  });

  group('JournalTextFormatter lists', () {
    test('numbers every line in the selection from one', () {
      final result = JournalTextFormatter.toggleList(
        valueOf('call mum\nbook the test\nwalk', start: 0, end: 26),
        ordered: true,
      );
      expect(result.text, '1. call mum\n2. book the test\n3. walk');
    });

    test('bullets every line in the selection', () {
      final result = JournalTextFormatter.toggleList(
        valueOf('rest\nwater', start: 0, end: 10),
        ordered: false,
      );
      expect(result.text, '- rest\n- water');
    });

    test('toggling off removes the markers again', () {
      final listed = JournalTextFormatter.toggleList(
        valueOf('rest\nwater', start: 0, end: 10),
        ordered: false,
      );
      final plain = JournalTextFormatter.toggleList(
        listed.copyWith(
          selection: TextSelection(
            baseOffset: 0,
            extentOffset: listed.text.length,
          ),
        ),
        ordered: false,
      );
      expect(plain.text, 'rest\nwater');
    });

    test('switching a bulleted list to numbered replaces the markers', () {
      final bulleted = JournalTextFormatter.toggleList(
        valueOf('rest\nwater', start: 0, end: 10),
        ordered: false,
      );
      final numbered = JournalTextFormatter.toggleList(
        bulleted.copyWith(
          selection: TextSelection(
            baseOffset: 0,
            extentOffset: bulleted.text.length,
          ),
        ),
        ordered: true,
      );
      expect(numbered.text, '1. rest\n2. water');
    });

    test('blank lines are left alone rather than given a marker', () {
      final result = JournalTextFormatter.toggleList(
        valueOf('one\n\ntwo', start: 0, end: 8),
        ordered: true,
      );
      expect(result.text, '1. one\n\n2. two');
    });

    test('a single line with no selection still becomes a list item', () {
      final result = JournalTextFormatter.toggleList(
        valueOf('breathe', start: 7, end: 7),
        ordered: false,
      );
      expect(result.text, '- breathe');
    });
  });

  group('JournalFormatToolbar', () {
    testWidgets('applies formatting to the field it is given', (tester) async {
      final controller = TextEditingController(text: 'a hard day');
      controller.selection =
          const TextSelection(baseOffset: 2, extentOffset: 6);
      addTearDown(controller.dispose);
      var size = JournalTextSize.normal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => JournalFormatToolbar(
                controller: controller,
                textSize: size,
                onTextSizeChanged: (value) => setState(() => size = value),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('journal-format-bold')));
      await tester.pump();
      expect(controller.text, 'a **hard** day');

      await tester.tap(
        find.byKey(const ValueKey('journal-format-numbered-list')),
      );
      await tester.pump();
      expect(controller.text, '1. a **hard** day');

      await tester.tap(find.byKey(const ValueKey('journal-text-size-large')));
      await tester.pump();
      expect(size, JournalTextSize.large);
    });

    testWidgets('formatting is disabled when there is no field to act on',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JournalFormatToolbar(
              controller: null,
              textSize: JournalTextSize.normal,
              onTextSizeChanged: (_) {},
            ),
          ),
        ),
      );

      final bold = tester.widget<IconButton>(
        find.byKey(const ValueKey('journal-format-bold')),
      );
      expect(bold.onPressed, isNull);
    });
  });

  test('text sizes keep the writing rhythm in step with the ruled paper', () {
    for (final size in JournalTextSize.values) {
      // The rules have to sit far enough apart to hold the glyphs at that size.
      expect(size.lineHeight, greaterThan(16.5 * size.scale));
    }
    expect(
      JournalTextSize.small.lineHeight,
      lessThan(JournalTextSize.large.lineHeight),
    );
  });
}
