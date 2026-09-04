import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../settings/user_provider.dart';
import 'mood_model.dart';
import 'mood_provider.dart';

class MoodDetailSheet {
  static Future<void> show(
    BuildContext context, {
    required MoodLog log,
    required bool isDark,
    VoidCallback? onDeleted,
    VoidCallback? onUpdated,
  }) async {
    final provider = context.read<MoodProvider>();
    final palette = context.kaibigan;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Padding(
          key: const ValueKey('mood-detail-sheet'),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  MoodLog.getMoodAssetPath(log.moodScore),
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    MoodLog.getMoodEmoji(log.moodScore),
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Mood: ${log.moodLabel}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MoodLog.getMoodColor(log.moodScore),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(log.createdAt),
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              const SizedBox(height: 12),
              // Metric pills
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _metricPill('Stress: ${log.stressLevel}/5', palette, isDark),
                  _metricPill('Energy: ${log.energyLevel}/5', palette, isDark),
                  _metricPill('Sleep: ${log.sleepQuality}/5', palette, isDark),
                  _metricPill('Anxiety: ${log.anxietyLevel}/5', palette, isDark),
                ],
              ),
              if (log.note != null && log.note!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '"${log.note}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('edit-mood-note-button'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showEditMoodNoteDialog(
                          context,
                          log: log,
                          provider: provider,
                          isDark: isDark,
                          onUpdated: onUpdated,
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Note',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.honeyAmber,
                        side: const BorderSide(color: AppColors.honeyAmber),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const ValueKey('delete-mood-button'),
                      onPressed: () async {
                        final language = context.read<UserProvider>().language;
                        final confirmed = await CozyConfirmSheet.show(
                          context,
                          title: LanguageHelper.pick(
                            language,
                            english: 'Delete this mood check-in?',
                            filipino: 'Burahin ang tala ng damdamin?',
                          ),
                          message: LanguageHelper.pick(
                            language,
                            english:
                                'This mood check-in will be permanently removed.',
                            filipino:
                                'Permanenteng buburahin ang tala ng damdamin.',
                          ),
                          confirmLabel: LanguageHelper.pick(
                            language,
                            english: 'Delete',
                            filipino: 'Burahin',
                          ),
                          cancelLabel: LanguageHelper.pick(
                            language,
                            english: 'Keep check-in',
                            filipino: 'Panatilihin',
                          ),
                          icon: Icons.sentiment_neutral_rounded,
                        );
                        if (confirmed && context.mounted) {
                          final deleted = await provider.deleteMoodLog(log.id);
                          if (!context.mounted) return;
                          if (deleted) {
                            Navigator.pop(ctx);
                            onDeleted?.call();
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                deleted
                                    ? 'Mood check-in gently removed.'
                                    : provider.errorMessage ??
                                        'The mood check-in could not be removed.',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.white),
                      label: const Text('Let Go',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  static Widget _metricPill(
      String label, KaibiganPalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: palette.textSecondary,
        ),
      ),
    );
  }

  static void showEditMoodNoteDialog(
    BuildContext context, {
    required MoodLog log,
    required MoodProvider provider,
    required bool isDark,
    VoidCallback? onUpdated,
  }) {
    final noteController = TextEditingController(text: log.note ?? '');
    final palette = context.kaibigan;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Reflection Note',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'Add or edit your note...',
            filled: true,
            fillColor: palette.surfaceSubtle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.honeyGold,
              foregroundColor: AppColors.onHoney,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              final updated = log.copyWith(note: noteController.text.trim());
              final saved = await provider.updateMoodLog(updated);
              if (!ctx.mounted) return;
              if (saved) {
                Navigator.pop(ctx);
                onUpdated?.call();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    saved
                        ? 'Mood note updated! ✨'
                        : provider.errorMessage ??
                            'The mood note could not be updated.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save Note',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
