import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/date_formatter.dart';

class PDFService {
  static Future<void> exportJournalToPDF({
    required String title,
    required String content,
    String? aiResponse,
    String? companionName,
    required DateTime createdAt,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Kaibigan - Journal Entry',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700,
                        ),
                      ),
                      pw.Text(
                        DateFormatter.formatShortDate(createdAt),
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  content,
                  style: const pw.TextStyle(fontSize: 14, height: 1.5),
                ),
                if (aiResponse != null && aiResponse.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    '• ${companionName ?? "Kaibigan Mascot"} Reflection:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    aiResponse,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.teal900,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${title.replaceAll(' ', '_')}_journal.pdf',
    );
  }
}

class PdfService {
  static Future<void> exportJournalPdf({
    required String title,
    required String content,
    String? aiResponse,
    String? companionName,
    required DateTime createdAt,
  }) async {
    await PDFService.exportJournalToPDF(
      title: title,
      content: content,
      aiResponse: aiResponse,
      companionName: companionName,
      createdAt: createdAt,
    );
  }
}
