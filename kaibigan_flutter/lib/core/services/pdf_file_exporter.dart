import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

/// Export means choosing a real destination, rather than silently invoking a
/// share sheet that may have no PDF-capable targets on the device.
abstract final class PdfFileExporter {
  static const channel = MethodChannel('com.kaibigan.app/pdf_export');

  static Future<bool> save(Uint8List bytes, String filename) async {
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('The PDF could not be created.');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final saved = await channel.invokeMethod<bool>('savePdf', {
        'bytes': bytes,
        'filename': filename,
      });
      if (saved == null) {
        throw StateError('The PDF save dialog did not return a result.');
      }
      return saved;
    }
    return Printing.layoutPdf(onLayout: (_) async => bytes, name: filename);
  }
}
