import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/supabase_service.dart';
import '../companion/companion_model.dart';
import 'user_provider.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Account Profile Box
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              elevation: isDark ? 0 : 1,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: mascot.primaryColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(mascot.avatarIcon,
                            style: const TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProvider.displayName.isEmpty
                                  ? 'Kaibigan User'
                                  : userProvider.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              userProvider.email.isEmpty
                                  ? 'Offline Profile'
                                  : userProvider.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Manage profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.sageGreen),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Preferences
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.honeyAmber,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: Text(mascot.avatarIcon,
                        style: const TextStyle(fontSize: 24)),
                    iconColor: mascot.primaryColor,
                    title: 'Companion Mascot',
                    subtitle: mascot.tag,
                    value: mascot.name,
                    onTap: () => _showCompanionPicker(context, userProvider),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: const Icon(Icons.translate_rounded,
                        color: AppColors.sageGreen, size: 22),
                    iconColor: AppColors.sageGreen,
                    title: 'Language / Wika',
                    subtitle: 'App language',
                    value: _languageLabel(userProvider.language),
                    onTap: () => _showLanguagePicker(context, userProvider),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: Icon(
                      userProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: AppColors.honeyGold,
                      size: 22,
                    ),
                    iconColor: AppColors.honeyGold,
                    title: 'Dark Mode',
                    subtitle: userProvider.isDarkMode
                        ? 'Gentle on your eyes at night'
                        : 'Use a cozy evening palette',
                    trailing: Switch(
                      value: userProvider.isDarkMode,
                      activeThumbColor: AppColors.honeyGold,
                      onChanged: userProvider.toggleDarkMode,
                    ),
                    onTap: () =>
                        userProvider.toggleDarkMode(!userProvider.isDarkMode),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Account & Supabase Status
            Text(
              'Account & Sync',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.honeyAmber,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (SupabaseService.isInitialized
                                  ? AppColors.sageGreen
                                  : Colors.orange)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          SupabaseService.isInitialized
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color: SupabaseService.isInitialized
                              ? AppColors.sageGreen
                              : Colors.orange,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              SupabaseService.isInitialized
                                  ? 'Cloud sync is on'
                                  : 'Sync Unavailable',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              SupabaseService.isInitialized
                                  ? 'Signed-in entries sync securely with Supabase'
                                  : 'New entries cannot be saved until sync is restored',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (SupabaseService.isInitialized
                                  ? AppColors.sageGreen
                                  : Colors.orange)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          SupabaseService.isInitialized
                              ? 'Connected'
                              : 'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: SupabaseService.isInitialized
                                ? AppColors.sageGreen
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 18),
                      label: const Text('Log Out',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.redAccent, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        await _confirmLogout(context, userProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required bool isDark,
    required Widget leading,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? value,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 82),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: leading,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: secondaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (trailing != null)
                trailing
              else ...[
                Flexible(
                  child: Text(
                    value ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: secondaryColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _languageLabel(String language) {
    switch (language) {
      case 'filipino':
        return 'Filipino 🇵🇭';
      case 'english':
        return 'English 🌐';
      default:
        return 'Taglish 🇵🇭';
    }
  }

  Future<void> _showCompanionPicker(
      BuildContext context, UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose your companion',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Pick the friend whose energy feels right for you.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              ...MascotInfo.companions.map(
                (companion) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: provider.selectedCompanion == companion.id
                        ? companion.primaryColor.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkBackground : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      minTileHeight: 68,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: companion.primaryColor.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Text(companion.avatarIcon,
                            style: const TextStyle(fontSize: 24)),
                      ),
                      title: Text(companion.name,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(companion.tag),
                      trailing: provider.selectedCompanion == companion.id
                          ? Icon(Icons.check_circle_rounded,
                              color: companion.primaryColor)
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        provider.setSelectedCompanion(companion.id);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(
      BuildContext context, UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const languages = [
      ('taglish', 'Taglish', 'Filipino-English', '🇵🇭'),
      ('filipino', 'Filipino', 'Buong Filipino', '🇵🇭'),
      ('english', 'English', 'English', '🌐'),
    ];

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose your language',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'You can change this anytime.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map(
                (language) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: provider.language == language.$1
                        ? AppColors.sageGreen.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkBackground : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      minTileHeight: 64,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      leading: Text(language.$4,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(language.$2,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(language.$3),
                      trailing: provider.language == language.$1
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.sageGreen)
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        provider.setLanguage(language.$1);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, UserProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        title: const Text('Log out of Kaibigan?'),
        content: const Text(
          'Your synced entries will stay safe. You can sign back in anytime.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.logout();
  }
}
