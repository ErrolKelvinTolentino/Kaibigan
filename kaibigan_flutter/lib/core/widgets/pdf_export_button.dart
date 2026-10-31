import 'package:flutter/material.dart';

import '../utils/language_helper.dart';

class PdfExportButton extends StatefulWidget {
  const PdfExportButton(
      {super.key,
      required this.label,
      required this.language,
      required this.onExport,
      this.style});

  final String label;
  final String language;
  final Future<bool> Function() onExport;
  final ButtonStyle? style;

  @override
  State<PdfExportButton> createState() => _PdfExportButtonState();
}

class _PdfExportButtonState extends State<PdfExportButton> {
  bool _exporting = false;
  String _copy(String english, String filipino) =>
      LanguageHelper.pick(widget.language,
          english: english, filipino: filipino);

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    try {
      // Paint the progress state before PDF layout starts on the UI isolate.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final saved = await widget.onExport();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(saved
              ? _copy('PDF saved.', 'Na-save ang PDF.')
              : _copy('PDF export canceled.',
                  'Kinansela ang pag-export ng PDF.'))));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(_copy('The PDF could not be saved. Please try again.',
              'Hindi na-save ang PDF. Pakisubukang muli.'))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: _exporting ? null : _export,
        icon: _exporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.picture_as_pdf_outlined, size: 18),
        label: Text(_exporting
            ? _copy('Preparing PDF…', 'Inihahanda ang PDF…')
            : widget.label),
        style: widget.style,
      );
}
