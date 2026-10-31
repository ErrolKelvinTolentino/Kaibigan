import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import 'flower_suggestion.dart';
import 'gratitude_model.dart';
import 'gratitude_provider.dart';
import 'polished_flower_asset.dart';

class FlowerDetailSheet {
  static Future<void> show(
    BuildContext rootContext, {
    required GratitudeEntry entry,
    required String language,
    VoidCallback? onDeleted,
    VoidCallback? onUpdated,
  }) async {
    final provider = rootContext.read<GratitudeProvider>();
    final isDark = Theme.of(rootContext).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: rootContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final current = provider.entries.firstWhere(
          (candidate) => candidate.id == entry.id,
          orElse: () => entry,
        );
        final matchedSuggestion = FlowerMatcher.isSuggestedFor(
          current.content,
          current.flowerType,
        );
        return Container(
          key: const ValueKey('flower-detail-sheet'),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                PolishedFlowerAsset(
                  flowerType: current.flowerType,
                  width: 82 * GratitudeEntry.getFlowerScale(current.flowerType),
                  height:
                      142 * GratitudeEntry.getFlowerScale(current.flowerType),
                  glowOpacity: 0.18,
                  glowBlur: 7,
                  cacheWidth: 246,
                  cacheHeight: 450,
                ).animate().fadeIn(duration: 250.ms).scale(
                      begin: const Offset(0.88, 0.88),
                      end: const Offset(1, 1),
                      alignment: Alignment.bottomCenter,
                    ),
                const SizedBox(height: 6),
                Text(
                  GratitudeEntry.getFlowerName(current.flowerType),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${GratitudeEntry.getFlowerMeaning(current.flowerType)} • Garden ${current.gardenIndex + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.softOlive : AppColors.sageGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormatter.formatFullDate(
                    current.createdAt,
                    language: language,
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 11.5,
                  ),
                ),
                if (matchedSuggestion) ...[
                  const SizedBox(height: 11),
                  Container(
                    key: const ValueKey('flower-matched-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.honeyAmber
                          .withValues(alpha: isDark ? 0.17 : 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppColors.honeyAmber.withValues(alpha: 0.36),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.honeyAmber,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            LanguageHelper.pick(
                              language,
                              english: 'Matched to what you wrote',
                              filipino: 'Tugma sa iyong isinulat',
                            ),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.17)
                        : const Color(0xFFF5F4EF),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    '“${current.content}”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontSize: 15,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('edit-gratitude-button'),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          showEditDialog(
                            rootContext,
                            entry: current,
                            provider: provider,
                            onUpdated: onUpdated,
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(LanguageHelper.pick(
                          language,
                          english: 'Edit gratitude',
                          filipino: 'I-edit ang pasasalamat',
                        )),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.honeyAmber,
                          foregroundColor: AppColors.onHoney,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      key: const ValueKey('delete-gratitude-button'),
                      tooltip: 'Remove flower',
                      onPressed: () async {
                        final confirmed = await CozyConfirmSheet.show(
                          rootContext,
                          title: LanguageHelper.pick(
                            language,
                            english: 'Remove this gratitude flower?',
                            filipino: 'Alisin ang bulaklak ng pasasalamat?',
                          ),
                          message: LanguageHelper.pick(
                            language,
                            english:
                                'Its plot will become available for another memory.',
                            filipino: 'Magiging bakante muli ang puwesto nito.',
                          ),
                          confirmLabel: 'Remove',
                          cancelLabel: 'Keep flower',
                          icon: Icons.local_florist_outlined,
                        );
                        if (!confirmed) return;
                        final deleted =
                            await provider.deleteGratitudeEntry(current.id);
                        if (!sheetContext.mounted) return;
                        if (deleted) {
                          Navigator.of(sheetContext).pop();
                          onDeleted?.call();
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showEditDialog(
    BuildContext context, {
    required GratitudeEntry entry,
    required GratitudeProvider provider,
    VoidCallback? onUpdated,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditGratitudeDialog(
        entry: entry,
        provider: provider,
        onUpdated: onUpdated,
      ),
    );
  }
}

// The route future completes before its exit animation unmounts the TextField.
// Own the controller here so it stays alive until that field is removed.
class _EditGratitudeDialog extends StatefulWidget {
  const _EditGratitudeDialog(
      {required this.entry, required this.provider, this.onUpdated});
  final GratitudeEntry entry;
  final GratitudeProvider provider;
  final VoidCallback? onUpdated;

  @override
  State<_EditGratitudeDialog> createState() => _EditGratitudeDialogState();
}

class _EditGratitudeDialogState extends State<_EditGratitudeDialog> {
  late final _controller = TextEditingController(text: widget.entry.content);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.provider
        .updateGratitudeEntry(widget.entry.id, _controller.text);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      widget.onUpdated?.call();
    } else {
      setState(() {
        _saving = false;
        _error = widget.provider.errorMessage ??
            'This change could not be saved. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit gratitude'),
        content: TextField(
          controller: _controller,
          enabled: !_saving,
          maxLines: 3,
          decoration: InputDecoration(
              hintText: 'Update this gratitude memory…', errorText: _error),
        ),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save')),
        ],
      );
}
