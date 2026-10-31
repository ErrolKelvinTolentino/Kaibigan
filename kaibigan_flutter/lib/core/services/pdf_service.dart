import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/date_formatter.dart';
import 'pdf_file_exporter.dart';

class PDFService {
  static Future<bool> exportJournalToPDF({
    required String title,
    required String content,
    String? aiResponse,
    String? companionName,
    required DateTime createdAt,
  }) async {
    return PdfFileExporter.save(
      await buildJournalPdf(
          title: title,
          content: content,
          aiResponse: aiResponse,
          companionName: companionName,
          createdAt: createdAt),
      '${title.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_')}_journal.pdf',
    );
  }

  /// Keep text as direct spanning children. A fixed page/boxed Column clips
  /// longer entries and can produce a PDF with no visible journal body.
  static Future<Uint8List> buildJournalPdf({
    required String title,
    required String content,
    String? aiResponse,
    String? companionName,
    required DateTime createdAt,
    bool compress = true,
  }) async {
    final pdf = pw.Document(compress: compress);
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      maxPages: 1000,
      theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique()),
      header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Text('Kaibigan - Journal Entry',
              style:
                  const pw.TextStyle(fontSize: 12, color: PdfColors.teal700))),
      footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber}',
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
      build: (_) => [
        pw.Text(title,
            overflow: pw.TextOverflow.span,
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black)),
        pw.SizedBox(height: 6),
        pw.Text(DateFormatter.formatShortDate(createdAt),
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        pw.SizedBox(height: 18),
        pw.Text(content,
            overflow: pw.TextOverflow.span,
            style: const pw.TextStyle(
                fontSize: 12, lineSpacing: 4, color: PdfColors.black)),
        if (aiResponse != null && aiResponse.trim().isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.Text('${companionName ?? 'Kaibigan'} Reflection',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800)),
          pw.SizedBox(height: 8),
          pw.Text(aiResponse,
              overflow: pw.TextOverflow.span,
              style: const pw.TextStyle(
                  fontSize: 12, lineSpacing: 4, color: PdfColors.black)),
        ],
      ],
    ));
    return pdf.save();
  }

  static Future<bool> exportWellnessReportToPDF({
    required String title,
    required String headline,
    required String subhead,
    required List<MapEntry<String, String>> metrics,
    required List<String> observations,
    required DateTime startDate,
    required DateTime endDate,
    String? userName,
  }) async {
    return PdfFileExporter.save(
        await buildWellnessReportPdf(
          title: title,
          headline: headline,
          subhead: subhead,
          metrics: metrics,
          observations: observations,
          startDate: startDate,
          endDate: endDate,
          userName: userName,
        ),
        'Kaibigan_Wellness_Summary.pdf');
  }

  static Future<Uint8List> buildWellnessReportPdf({
    required String title,
    required String headline,
    required String subhead,
    required List<MapEntry<String, String>> metrics,
    required List<String> observations,
    required DateTime startDate,
    required DateTime endDate,
    String? userName,
    bool compress = true,
  }) async {
    final pdf = pw.Document(compress: compress);
    final range =
        '${DateFormatter.formatShortDate(startDate)} - ${DateFormatter.formatShortDate(endDate.subtract(const Duration(days: 1)))}';
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      maxPages: 1000,
      header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Text('Kaibigan - Wellness Summary',
              style:
                  const pw.TextStyle(fontSize: 12, color: PdfColors.teal800))),
      footer: (context) => pw.Column(children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Text(
            'Confidential. For personal reflection, not an automated diagnosis or medical assessment.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.Text('Page ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 9)),
      ]),
      build: (_) => [
        pw.Text(title,
            overflow: pw.TextOverflow.span,
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800)),
        if (userName != null && userName.trim().isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text('Prepared for $userName', overflow: pw.TextOverflow.span),
        ],
        pw.SizedBox(height: 6),
        pw.Text(range,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        pw.SizedBox(height: 20),
        pw.Text(headline,
            overflow: pw.TextOverflow.span,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(subhead,
            overflow: pw.TextOverflow.span,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
        pw.SizedBox(height: 20),
        pw.Text('Weekly Care & Practice Summary',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800)),
        pw.SizedBox(height: 10),
        for (final metric in metrics) ...[
          pw.Text('${metric.key}: ${metric.value}',
              overflow: pw.TextOverflow.span,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
          pw.SizedBox(height: 6),
        ],
        if (observations.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Noted Patterns & Context',
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800)),
          pw.SizedBox(height: 10),
          for (final observation in observations) ...[
            pw.Text(observation,
                overflow: pw.TextOverflow.span,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
            pw.SizedBox(height: 10),
          ],
        ],
      ],
    ));
    return pdf.save();
  }
}

class PdfService {
  static Future<bool> exportJournalPdf({
    required String title,
    required String content,
    String? aiResponse,
    String? companionName,
    required DateTime createdAt,
  }) async {
    return PDFService.exportJournalToPDF(
      title: title,
      content: content,
      aiResponse: aiResponse,
      companionName: companionName,
      createdAt: createdAt,
    );
  }

  static Future<bool> exportWellnessReportPdf({
    required String title,
    required String headline,
    required String subhead,
    required List<MapEntry<String, String>> metrics,
    required List<String> observations,
    required DateTime startDate,
    required DateTime endDate,
    String? userName,
  }) async {
    return PDFService.exportWellnessReportToPDF(
      title: title,
      headline: headline,
      subhead: subhead,
      metrics: metrics,
      observations: observations,
      startDate: startDate,
      endDate: endDate,
      userName: userName,
    );
  }
}
