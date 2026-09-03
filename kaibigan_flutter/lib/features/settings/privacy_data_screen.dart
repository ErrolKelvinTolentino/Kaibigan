import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/language_helper.dart';
import 'user_provider.dart';

class PrivacyDataScreen extends StatefulWidget {
  const PrivacyDataScreen({super.key, required this.language});

  final String language;

  @override
  State<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends State<PrivacyDataScreen> {
  bool _deleting = false;

  String copy(String english, String filipino) => LanguageHelper.pick(
        widget.language,
        english: english,
        filipino: filipino,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _deleting ? null : () => Navigator.pop(context),
        ),
        title: Text(
          copy('Privacy & your data', 'Privacy at iyong data'),
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _introCard(isDark, textSecondary),
            const SizedBox(height: 20),
            _dataCard(
              isDark: isDark,
              icon: Icons.cloud_done_outlined,
              color: AppColors.sageGreen,
              title: copy('Saved to your account', 'Sine-save sa account mo'),
              body: copy(
                'Your profile, journal conversations, moods, gratitude garden, completed activities, sleep logs, future letters, lesson progress, and enabled AI memories sync to Supabase under your signed-in account.',
                'Ang profile, journal conversation, mood, gratitude garden, natapos na activity, sleep log, future letter, progreso sa lesson, at naka-enable na AI memory ay sini-sync sa Supabase sa ilalim ng account mo.',
              ),
            ),
            const SizedBox(height: 12),
            _dataCard(
              isDark: isDark,
              icon: Icons.auto_awesome_outlined,
              color: AppColors.honeyAmber,
              title: copy('When you ask Kai', 'Kapag tinanong mo si Kai'),
              body: copy(
                'The text needed for a reflection or lesson answer is sent through Kaibigan’s authenticated AI service to the configured AI provider. Learning questions are not added to your journal or AI memory. Avoid sharing details you do not want processed by that provider.',
                'Ang text na kailangan para sa reflection o sagot sa lesson ay ipinapadala sa authenticated AI service ng Kaibigan at sa naka-configure na AI provider. Hindi idinadagdag sa journal o AI memory ang mga tanong sa lesson. Iwasang magbahagi ng detalyeng ayaw mong maproseso ng provider.',
              ),
            ),
            const SizedBox(height: 12),
            _dataCard(
              isDark: isDark,
              icon: Icons.phone_android_outlined,
              color: AppColors.skyBlue,
              title: copy('Kept on this device', 'Nananatili sa device'),
              body: copy(
                'Routine settings and unfinished routine sessions, weekly reflections, appearance choices, onboarding status, and activity feedback stay on this device. Lesson progress also has an account-specific offline cache. Deleting your account clears Kaibigan’s local preferences here.',
                'Nananatili sa device ang routine settings at hindi pa tapos na session, weekly reflection, appearance, onboarding status, at activity feedback. May offline cache rin ang progreso sa lesson para sa bawat account. Kapag binura ang account, malilinis din ang lokal na preference ng Kaibigan dito.',
              ),
            ),
            const SizedBox(height: 12),
            _dataCard(
              isDark: isDark,
              icon: Icons.health_and_safety_outlined,
              color: AppColors.warmPeach,
              title:
                  copy('Wellness, not medical care', 'Wellness, hindi gamutan'),
              body: copy(
                'Kaibigan does not diagnose, treat, or replace a clinician or emergency service. Safety guidance may appear when concerning language is detected, but automated detection can miss context.',
                'Hindi nagdi-diagnose, gumagamot, o pumapalit ang Kaibigan sa clinician o emergency service. Maaaring magpakita ng safety guidance kapag may nakitang nakababahalang salita, pero maaaring hindi makuha ng automated detection ang buong konteksto.',
              ),
            ),
            const SizedBox(height: 28),
            Text(
              copy('Delete your account', 'Burahin ang account'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              copy(
                'This permanently removes your account and synced wellness data. This cannot be undone.',
                'Permanenteng buburahin nito ang account at naka-sync na wellness data. Hindi na ito maibabalik.',
              ),
              style:
                  TextStyle(fontSize: 13, height: 1.45, color: textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const ValueKey('delete-account-button'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _deleting ? null : _confirmDeletion,
              icon: _deleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: Text(
                _deleting
                    ? copy('Deleting…', 'Binubura…')
                    : copy(
                        'Permanently delete account', 'Permanenteng burahin'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introCard(bool isDark, Color textSecondary) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.sageGreen.withValues(alpha: isDark ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.sageGreen.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.privacy_tip_outlined,
                color: AppColors.sageGreen, size: 28),
            const SizedBox(height: 12),
            Text(
              copy('Clear, human-sized privacy', 'Malinaw na privacy'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              copy(
                'Here is the practical version of what Kaibigan stores and processes. You stay in control of AI memory and your account.',
                'Narito ang praktikal na paliwanag kung ano ang sine-save at pinoproseso ng Kaibigan. Ikaw ang may kontrol sa AI memory at account mo.',
              ),
              style:
                  TextStyle(fontSize: 13.5, height: 1.5, color: textSecondary),
            ),
          ],
        ),
      );

  Widget _dataCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? AppColors.darkCardBorder
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12.8,
                      height: 1.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _confirmDeletion() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 34),
          title: Text(copy('Delete everything?', 'Burahin ang lahat?')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                copy(
                  'Your account, journal, Kai reflections, moods, routines, sleep logs, gratitude garden, letters, goals, and AI memories will be permanently removed.',
                  'Permanenteng buburahin ang account, journal, reflection ni Kai, mood, routine, sleep log, gratitude garden, letter, goal, at AI memory.',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('delete-account-confirmation'),
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: copy('Type DELETE to confirm',
                      'I-type ang DELETE para kumpirmahin'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(copy('Keep my account', 'Panatilihin ang account')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: controller.text.trim().toUpperCase() == 'DELETE'
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(copy('Delete forever', 'Burahin permanente')),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final provider = context.read<UserProvider>();
    final deleted = await provider.deleteAccount();
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.dataError ??
            copy('Account deletion failed. Please try again.',
                'Hindi nabura ang account. Subukan muli.')),
      ),
    );
  }
}
