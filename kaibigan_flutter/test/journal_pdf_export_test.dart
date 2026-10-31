import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/pdf_service.dart';

void main() {
  String drawnText(String raw) => RegExp(r'\[\(([^)]*)\)\]TJ')
      .allMatches(raw)
      .map((match) => match.group(1)!)
      .join(' ');
  test('journal PDF contains title, body and reflection with readable text',
      () async {
    final bytes = await PDFService.buildJournalPdf(
        title: 'QA journal title',
        content: 'Journal body sentinel. Salamat sa tahimik na araw.',
        aiResponse: 'Reflection sentinel.',
        createdAt: DateTime(2026, 10, 19),
        compress: false);
    final raw = latin1.decode(bytes);
    expect(raw, startsWith('%PDF-'));
    expect(drawnText(raw), contains('Journal body sentinel'));
    expect(drawnText(raw), contains('Reflection sentinel'));
    final directory = Platform.environment['KAIBIGAN_PDF_QA_DIR'];
    if (directory != null) {
      await File('$directory/short.pdf').writeAsBytes(bytes);
    }
  });

  test(
      'long journal and long Kai response span pages without losing the ending',
      () async {
    final body = List.generate(
            120,
            (i) =>
                'Journal paragraph $i. A quiet walk helped me process the day.')
        .join('\n\n');
    final reflection =
        List.filled(100, 'A gentle reflection with space to think.')
            .join('\n\n');
    final bytes = await PDFService.buildJournalPdf(
        title: 'Long journal',
        content: '$body\nBODY END SENTINEL',
        aiResponse: '$reflection\nREFLECTION END SENTINEL',
        createdAt: DateTime(2026, 10, 19),
        compress: false);
    final raw = latin1.decode(bytes);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(raw).length, greaterThan(1));
    expect(drawnText(raw), contains('BODY END SENTINEL'));
    expect(drawnText(raw), contains('REFLECTION END SENTINEL'));
    final directory = Platform.environment['KAIBIGAN_PDF_QA_DIR'];
    if (directory != null) {
      await File('$directory/long.pdf').writeAsBytes(bytes);
    }
  });
}
