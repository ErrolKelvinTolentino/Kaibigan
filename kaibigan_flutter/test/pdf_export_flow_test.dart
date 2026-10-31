import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/pdf_file_exporter.dart';
import 'package:kaibigan_flutter/core/services/pdf_service.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/insights/wellness_analytics.dart';
import 'package:kaibigan_flutter/features/insights/wellness_insights_panel.dart';
import 'package:kaibigan_flutter/features/journaling/journal_editor_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  late Future<Object?> Function(MethodCall) respond;

  setUp(() {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
    calls.clear();
    respond = (_) async => true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PdfFileExporter.channel, (call) {
      calls.add(call);
      return respond(call);
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PdfFileExporter.channel, null);
  });

  Future<void> pump(WidgetTester tester,
      {required bool journal, bool empty = false}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: journal
              ? JournalEditorScreen(
                  entry: empty
                      ? null
                      : JournalEntry(
                          id: 'export-entry',
                          title: 'QA export journal',
                          content: 'Keep the complete journal body.',
                          companionId: 'kai',
                          createdAt: DateTime(2026, 10, 19)))
              : Scaffold(
                  body: SingleChildScrollView(
                      child: WellnessInsightsPanel(
                          snapshot: WellnessAnalytics.build(
                              now: DateTime(2026, 10, 19)),
                          language: 'english'))),
        )));
    await tester.pumpAndSettle();
  }

  Future<void> tapExport(WidgetTester tester, bool journal) async {
    if (journal) {
      await tester.tap(find.byTooltip('More journal actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export as PDF'));
    } else {
      final button =
          find.byKey(const ValueKey('wellness-export-summary-button'));
      await tester.scrollUntilVisible(button.hitTestable(), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(button);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final journal in [true, false]) {
    for (final outcome in ['saved', 'canceled', 'failed']) {
      testWidgets(
          '${journal ? 'journal' : 'wellness'} export button reports $outcome from the native save action',
          (tester) async {
        respond = (_) async {
          if (outcome == 'failed') {
            throw PlatformException(code: 'WRITE_FAILED');
          }
          return outcome == 'saved';
        };
        await pump(tester, journal: journal);
        await tapExport(tester, journal);
        await tester.pumpAndSettle();
        expect(calls, hasLength(1));
        expect(calls.single.method, 'savePdf');
        final args = calls.single.arguments as Map;
        expect(args['filename'], endsWith('.pdf'));
        expect(String.fromCharCodes((args['bytes'] as Uint8List).take(5)),
            '%PDF-');
        expect(
            find.text(switch (outcome) {
              'saved' => 'PDF saved.',
              'canceled' => 'PDF export canceled.',
              _ => 'The PDF could not be saved. Please try again.',
            }),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        if (outcome == 'failed') {
          respond = (_) async => true;
          // Let the error notice clear so it no longer covers the bottom button.
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
          await tapExport(tester, journal);
          await tester.pumpAndSettle();
          expect(calls, hasLength(2));
          expect(find.text('PDF saved.'), findsOneWidget);
        }
      });
    }
  }

  testWidgets(
      'empty journal export explains what is missing rather than doing nothing',
      (tester) async {
    await pump(tester, journal: true, empty: true);
    await tapExport(tester, true);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(
        find.text('Write something before exporting a PDF.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final journal in [true, false]) {
    testWidgets(
        '${journal ? 'journal' : 'wellness'} export shows progress and prevents a duplicate save request',
        (tester) async {
      final pending = Completer<Object?>();
      respond = (_) => pending.future;
      await pump(tester, journal: journal);
      await tapExport(tester, journal);
      expect(calls, hasLength(1));
      if (journal) {
        expect(find.byKey(const ValueKey('journal-export-progress')),
            findsOneWidget);
        await tester.tap(find.byTooltip('More journal actions'));
        await tester.pump(const Duration(milliseconds: 400));
        final exportItem = find.byWidgetPredicate((widget) =>
            widget is PopupMenuItem<String> && widget.value == 'export');
        expect(
            tester.widget<PopupMenuItem<String>>(exportItem).enabled, isFalse);
        Navigator.of(tester.element(exportItem)).pop();
      } else {
        expect(find.text('Preparing PDF…'), findsOneWidget);
        final button = find.descendant(
            of: find.byKey(const ValueKey('wellness-export-summary-button')),
            matching: find.byType(OutlinedButton));
        expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      }
      expect(calls, hasLength(1));
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('PDF saved.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('invalid PDF bytes cannot open a save picker or produce a blank file',
      () async {
    await expectLater(
        PdfFileExporter.save(Uint8List(0), 'blank.pdf'), throwsFormatException);
    expect(calls, isEmpty);
  });

  test(
      'wellness summary paginates long reports and keeps the final observation',
      () async {
    final bytes = await PDFService.buildWellnessReportPdf(
        title: 'QA wellness report',
        headline: 'A week of small steps',
        subhead: 'Summary of saved activity.',
        metrics: const [MapEntry('Mood', 'Four check-ins')],
        observations: [
          ...List.filled(75,
              'A repeated observation that must stay readable in the saved document.'),
          'WELLNESS END SENTINEL'
        ],
        startDate: DateTime(2026, 10, 12),
        endDate: DateTime(2026, 10, 19),
        compress: false);
    final raw = latin1.decode(bytes);
    final text = RegExp(r'\[\(([^)]*)\)\]TJ')
        .allMatches(raw)
        .map((m) => m.group(1)!)
        .join(' ');
    expect(RegExp(r'/Type\s*/Page\b').allMatches(raw).length, greaterThan(1));
    expect(text, contains('WELLNESS END SENTINEL'));
  });
}
