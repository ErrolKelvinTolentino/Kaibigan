import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/journal_appearance.dart';

/// Applies lightweight Markdown formatting to a plain-text controller.
///
/// Entries are stored as text, not as a rich-text document, so formatting has
/// to survive a round trip through the database, the AI prompt and the PDF
/// export. Markdown does; a proprietary span model would not.
class JournalTextFormatter {
  const JournalTextFormatter._();

  /// Wraps the selection in [marker], or unwraps it when it is already wrapped.
  /// With no selection, inserts the pair and places the caret between them.
  static TextEditingValue toggleInline(
    TextEditingValue value,
    String marker,
  ) {
    final text = value.text;
    var selection = value.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: text.length);
    }
    final start = selection.start;
    final end = selection.end;
    final selected = text.substring(start, end);

    // Already wrapped on the inside of the selection.
    if (selected.length >= marker.length * 2 &&
        selected.startsWith(marker) &&
        selected.endsWith(marker)) {
      final stripped =
          selected.substring(marker.length, selected.length - marker.length);
      return TextEditingValue(
        text: text.replaceRange(start, end, stripped),
        selection: TextSelection(
          baseOffset: start,
          extentOffset: start + stripped.length,
        ),
      );
    }

    // Already wrapped just outside the selection.
    final outerStart = start - marker.length;
    final outerEnd = end + marker.length;
    if (outerStart >= 0 &&
        outerEnd <= text.length &&
        text.substring(outerStart, start) == marker &&
        text.substring(end, outerEnd) == marker) {
      return TextEditingValue(
        text: text.replaceRange(end, outerEnd, '').replaceRange(
              outerStart,
              start,
              '',
            ),
        selection: TextSelection(
          baseOffset: outerStart,
          extentOffset: outerStart + selected.length,
        ),
      );
    }

    final wrapped = '$marker$selected$marker';
    return TextEditingValue(
      text: text.replaceRange(start, end, wrapped),
      selection: selected.isEmpty
          ? TextSelection.collapsed(offset: start + marker.length)
          : TextSelection(
              baseOffset: start + marker.length,
              extentOffset: start + marker.length + selected.length,
            ),
    );
  }

  /// Adds or removes a list marker on every line the selection touches.
  /// Numbered lists renumber from one so the result is always well formed.
  static TextEditingValue toggleList(
    TextEditingValue value, {
    required bool ordered,
  }) {
    final text = value.text;
    var selection = value.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: text.length);
    }

    final lineStart = _lineStart(text, selection.start);
    final lineEnd = _lineEnd(text, selection.end);
    final block = text.substring(lineStart, lineEnd);
    final lines = block.split('\n');

    final alreadyMarked = lines
        .where((line) => line.trim().isNotEmpty)
        .every((line) => _hasMarker(line, ordered: ordered));

    var counter = 1;
    final rewritten = lines.map((line) {
      if (line.trim().isEmpty) return line;
      final bare = _stripMarker(line);
      if (alreadyMarked) return bare;
      return ordered ? '${counter++}. $bare' : '- $bare';
    }).join('\n');

    final newText = text.replaceRange(lineStart, lineEnd, rewritten);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (lineStart + rewritten.length).clamp(0, newText.length),
      ),
    );
  }

  static final _orderedMarker = RegExp(r'^\s*\d+\.\s+');
  static final _bulletMarker = RegExp(r'^\s*[-*]\s+');

  static bool _hasMarker(String line, {required bool ordered}) =>
      ordered ? _orderedMarker.hasMatch(line) : _bulletMarker.hasMatch(line);

  static String _stripMarker(String line) =>
      line.replaceFirst(_orderedMarker, '').replaceFirst(_bulletMarker, '');

  static int _lineStart(String text, int offset) {
    final index = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    return index == -1 ? 0 : index + 1;
  }

  static int _lineEnd(String text, int offset) {
    final index = text.indexOf('\n', offset);
    return index == -1 ? text.length : index;
  }
}

/// The formatting strip shown above the keyboard while writing an entry.
class JournalFormatToolbar extends StatelessWidget {
  const JournalFormatToolbar({
    super.key,
    required this.controller,
    required this.textSize,
    required this.onTextSizeChanged,
    this.enabled = true,
  });

  /// The field the formatting buttons act on. Null disables them, which is what
  /// happens between turns when no field has focus yet.
  final TextEditingController? controller;

  final JournalTextSize textSize;
  final ValueChanged<JournalTextSize> onTextSizeChanged;
  final bool enabled;

  void _apply(TextEditingValue Function(TextEditingValue) transform) {
    final target = controller;
    if (target == null) return;
    target.value = transform(target.value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canFormat = enabled && controller != null;
    final foreground =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return TextFieldTapRegion(
        child: Container(
      key: const ValueKey('journal-format-toolbar'),
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkCardBorder
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _ToolbarButton(
              id: 'bold',
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              enabled: canFormat,
              foreground: foreground,
              onPressed: () => _apply(
                (value) => JournalTextFormatter.toggleInline(value, '**'),
              ),
            ),
            _ToolbarButton(
              id: 'italic',
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              enabled: canFormat,
              foreground: foreground,
              onPressed: () => _apply(
                (value) => JournalTextFormatter.toggleInline(value, '_'),
              ),
            ),
            _ToolbarDivider(isDark: isDark),
            _ToolbarButton(
              id: 'bulleted-list',
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bulleted list',
              enabled: canFormat,
              foreground: foreground,
              onPressed: () => _apply(
                (value) =>
                    JournalTextFormatter.toggleList(value, ordered: false),
              ),
            ),
            _ToolbarButton(
              id: 'numbered-list',
              icon: Icons.format_list_numbered_rounded,
              tooltip: 'Numbered list',
              enabled: canFormat,
              foreground: foreground,
              onPressed: () => _apply(
                (value) =>
                    JournalTextFormatter.toggleList(value, ordered: true),
              ),
            ),
            _ToolbarDivider(isDark: isDark),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child:
                  Icon(Icons.format_size_rounded, size: 17, color: foreground),
            ),
            ...JournalTextSize.values.map(
              (size) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _SizeChip(
                  size: size,
                  selected: size == textSize,
                  isDark: isDark,
                  onTap: () => onTextSizeChanged(size),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.id,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.foreground,
    required this.onPressed,
  });

  final String id;
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey('journal-format-$id'),
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 20, color: foreground),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      color: isDark ? AppColors.darkCardBorder : const Color(0xFFE8E0D6),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.size,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final JournalTextSize size;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${size.label} text',
      child: Material(
        color: selected
            ? AppColors.honeyAmber
            : (isDark ? Colors.white10 : const Color(0xFFF3EFE6)),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          key: ValueKey('journal-text-size-${size.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Text(
              size.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected
                    ? AppColors.onHoney
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
