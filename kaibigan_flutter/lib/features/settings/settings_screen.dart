import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/garden_appearance.dart';
import '../../core/theme/journal_appearance.dart';
import '../../core/utils/language_helper.dart';
import '../companion/companion_model.dart';
import 'user_provider.dart';
import 'profile_screen.dart';
import 'ai_memory_screen.dart';
import 'journal_appearance_screen.dart';
import 'sound_settings_screen.dart';
import 'privacy_data_screen.dart';
import '../auth_onboarding/app_tutorial_screen.dart';
import '../journaling/journal_provider.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../mood_tracking/mood_provider.dart';
import '../future_letters/letters_provider.dart';
import '../routines/routines_provider.dart';
import '../routines/routine_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  /// Cloud sync is only meaningfully "on" when there is a backend *and* the
  /// person has not chosen to keep everything on this device.
  static bool _syncActive(UserProvider user) =>
      SupabaseService.isInitialized &&
      user.isAuthenticated &&
      !user.hasPendingLocalImport &&
      !user.isImportingLocalData;

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final language = userProvider.language;
    String copy(String english, String filipino) => LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
        );
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
          copy('Settings', 'Mga setting'),
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
                                  ? copy(
                                      'Offline profile', 'Offline na profile')
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
                            Text(
                              copy('Manage profile', 'Ayusin ang profile'),
                              style: const TextStyle(
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
              copy('Preferences', 'Mga kagustuhan'),
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
                    title: copy('Companion', 'Kasama'),
                    subtitle: mascot.tag,
                    value: mascot.name,
                    onTap: () => _showCompanionPicker(context, userProvider),
                  ),
                  const Divider(height: 1, indent: 72),
                  KeyedSubtree(
                    key: const ValueKey('settings-routine-settings'),
                    child: _settingsTile(
                      context: context,
                      isDark: isDark,
                      leading: const Icon(Icons.tune_rounded,
                          color: AppColors.sageGreen, size: 22),
                      iconColor: AppColors.sageGreen,
                      title: copy('Routine settings', 'Mga setting ng routine'),
                      subtitle: copy('Activities, schedules, and reminders',
                          'Mga gawain, iskedyul, at paalala'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RoutineManagementScreen())),
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: Icon(
                      switch (userProvider.gardenAppearance) {
                        GardenAppearance.syncWithTime => Icons.schedule_rounded,
                        GardenAppearance.day => Icons.wb_sunny_rounded,
                        GardenAppearance.night => Icons.nightlight_round,
                      },
                      color: AppColors.sageGreen,
                      size: 22,
                    ),
                    iconColor: AppColors.sageGreen,
                    title: copy('Garden lighting', 'Ilaw ng garden'),
                    subtitle: copy(
                      'Choose when the garden changes',
                      'Piliin kung kailan magbabago ang garden',
                    ),
                    value: _gardenAppearanceLabel(
                      userProvider.gardenAppearance,
                      copy,
                    ),
                    onTap: () => _showGardenAppearancePicker(
                      context,
                      userProvider,
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: const Icon(Icons.translate_rounded,
                        color: AppColors.sageGreen, size: 22),
                    iconColor: AppColors.sageGreen,
                    title: copy('Language', 'Wika'),
                    subtitle: copy('App language', 'Wika ng app'),
                    value: _languageLabel(userProvider.language),
                    onTap: () => _showLanguagePicker(context, userProvider),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: Icon(
                      switch (userProvider.themeMode) {
                        ThemeMode.system => Icons.brightness_auto_rounded,
                        ThemeMode.light => Icons.light_mode_rounded,
                        ThemeMode.dark => Icons.dark_mode_rounded,
                      },
                      color: AppColors.honeyGold,
                      size: 22,
                    ),
                    iconColor: AppColors.honeyGold,
                    title: copy('Theme', 'Tema'),
                    subtitle: switch (userProvider.themeMode) {
                      ThemeMode.system => copy(
                          'Match your device appearance',
                          'Sundan ang tema ng device',
                        ),
                      ThemeMode.light => copy(
                          'Keep the warm daytime palette',
                          'Gamitin ang maliwanag na tema',
                        ),
                      ThemeMode.dark => copy(
                          'Gentle on your eyes at night',
                          'Mas magaan sa mata sa gabi',
                        ),
                    },
                    value: _themeModeLabel(userProvider.themeMode, copy),
                    onTap: () => _showThemePicker(
                      context,
                      userProvider,
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: Icon(
                      Icons.auto_stories_rounded,
                      color: userProvider.journalAccent.color,
                      size: 22,
                    ),
                    iconColor: userProvider.journalAccent.color,
                    title: copy('Journal appearance', 'Itsura ng talaarawan'),
                    subtitle: copy(
                      'Paper style and accent color',
                      'Estilo ng papel at kulay',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const JournalAppearanceScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: const Icon(
                      Icons.graphic_eq_rounded,
                      color: AppColors.sageGreen,
                      size: 22,
                    ),
                    iconColor: AppColors.sageGreen,
                    title: copy('Sound', 'Tunog'),
                    subtitle: copy(
                      'Quiet cues for taps and saves',
                      'Banayad na tunog sa pindot at pag-save',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SoundSettingsScreen(language: language),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: const Icon(
                      Icons.explore_outlined,
                      color: AppColors.honeyAmber,
                      size: 22,
                    ),
                    iconColor: AppColors.honeyAmber,
                    title: copy('App tour & tutorial', 'Gabay sa paggamit'),
                    subtitle: copy(
                      'Explore how Kaibigan spaces work',
                      'Alamin kung paano gamitin ang bawat espasyo',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppTutorialScreen(isModal: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              copy('AI & privacy', 'AI at privacy'),
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
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: const Icon(Icons.psychology_alt_rounded,
                        color: AppColors.honeyAmber, size: 22),
                    iconColor: AppColors.honeyAmber,
                    title: copy('AI memory controls', 'Kontrol sa AI memory'),
                    subtitle: copy(
                      'Review or pause what Kai remembers',
                      'Suriin o i-pause ang naaalala ni Kai',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiMemoryScreen(language: language),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _settingsTile(
                    context: context,
                    isDark: isDark,
                    leading: const Icon(Icons.shield_outlined,
                        color: AppColors.sageGreen, size: 22),
                    iconColor: AppColors.sageGreen,
                    title: copy('Privacy & your data', 'Privacy at iyong data'),
                    subtitle: copy(
                      'See what is stored, shared, or deleted',
                      'Alamin kung ano ang sine-save, ipinapadala, o binubura',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivacyDataScreen(language: language),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Account & Supabase Status
            // Offline mode is a working state, not a broken one, so the card
            // below describes where records are kept rather than only
            // whether a client object exists.
            Text(
              copy('Account & sync', 'Account at pag-sync'),
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
                          color: (_syncActive(userProvider)
                                  ? AppColors.sageGreen
                                  : Colors.orange)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _syncActive(userProvider)
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color: _syncActive(userProvider)
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
                              userProvider.isOffline
                                  ? copy(
                                      'Saved on this device',
                                      'Naka-save sa device na ito',
                                    )
                                  : userProvider.hasPendingLocalImport
                                      ? copy('Local backup pending',
                                          'Hinihintay ang lokal na backup')
                                      : _syncActive(userProvider)
                                          ? copy(
                                              'Cloud sync is on',
                                              'Naka-on ang cloud sync',
                                            )
                                          : copy(
                                              'Sync unavailable',
                                              'Hindi available ang pag-sync',
                                            ),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userProvider.isOffline
                                  ? copy(
                                      'Nothing is uploaded. Losing this phone loses these entries.',
                                      'Walang ina-upload. Kapag nawala ang telepono, mawawala rin ang mga tala.',
                                    )
                                  : userProvider.hasPendingLocalImport
                                      ? copy(
                                          'Your local entries are safe. Retry the backup when connected.',
                                          'Ligtas ang iyong mga lokal na tala. Subukan muli kapag may koneksiyon.')
                                      : _syncActive(userProvider)
                                          ? copy(
                                              'Signed-in entries sync securely with Supabase',
                                              'Ligtas na sini-sync sa Supabase ang iyong mga tala',
                                            )
                                          : copy(
                                              'New entries cannot be saved until sync is restored',
                                              'Hindi mase-save ang bagong tala hanggang bumalik ang sync',
                                            ),
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
                          color: (_syncActive(userProvider)
                                  ? AppColors.sageGreen
                                  : Colors.orange)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          userProvider.isOffline
                              ? copy('On device', 'Sa device')
                              : userProvider.hasPendingLocalImport
                                  ? copy('Pending', 'Nakabinbin')
                                  : _syncActive(userProvider)
                                      ? copy('Connected', 'Konektado')
                                      : 'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _syncActive(userProvider)
                                ? AppColors.sageGreen
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (userProvider.isOffline) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        key: const ValueKey('settings-leave-offline'),
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: Text(
                          copy('Sign in or create an account',
                              'Mag-sign in o gumawa ng account'),
                        ),
                        // Leaving offline mode never deletes what is on the
                        // device, so this is safe to tap and reversible.
                        onPressed: () async {
                          await userProvider.leaveOfflineMode(
                              importLocalData: true);
                          if (!context.mounted || userProvider.isOffline) {
                            return;
                          }
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      copy(
                        'Your saved entries will be added to the account you sign in to or create. A local backup stays on this device.',
                        'Idaragdag ang iyong mga tala sa account na gagawin mo o pag-sign in-an. May lokal na backup pa rin sa device na ito.',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                  if (userProvider.localImportError != null) ...[
                    const SizedBox(height: 12),
                    Text(userProvider.localImportError!,
                        key: const ValueKey('local-import-error')),
                  ],
                  if (userProvider.hasPendingLocalImport &&
                      userProvider.isAuthenticated) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('retry-local-import'),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(userProvider.isImportingLocalData
                          ? copy('Backing up…', 'Nagba-back up…')
                          : copy('Retry backup', 'Subukan muli ang backup')),
                      onPressed: userProvider.isImportingLocalData
                          ? null
                          : () async {
                              // Capture providers while this route is mounted. Refresh
                              // even after a partial upload so confirmed entries show.
                              final journal = context.read<JournalProvider>();
                              final gratitude =
                                  context.read<GratitudeProvider>();
                              final mood = context.read<MoodProvider>();
                              final letters = context.read<LettersProvider>();
                              final routines = context.read<RoutinesProvider>();
                              await userProvider.retryLocalImport();
                              if (!context.mounted ||
                                  !userProvider.isAuthenticated) {
                                return;
                              }
                              await Future.wait([
                                journal.fetchJournalEntries(),
                                gratitude.fetchGratitudeEntries(),
                                mood.fetchMoodLogs(),
                                letters.fetchLetters(),
                                routines.fetchRoutineLogs()
                              ]);
                            },
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      key: const ValueKey('settings-manage-account'),
                      icon: const Icon(Icons.manage_accounts_outlined,
                          size: 18, color: AppColors.sageGreen),
                      label: Text(
                        copy('Manage account', 'Pamahalaan ang account'),
                        style: const TextStyle(
                          color: AppColors.sageGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.sageGreen, width: 1.2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy(
                      'Your name and sign-out live with your account.',
                      'Nasa account ang pangalan mo at ang pag-sign out.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
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
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ] else ...[
                if (value != null && value.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      value,
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
                ],
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: secondaryColor,
                ),
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

  String _themeModeLabel(
    ThemeMode mode,
    String Function(String english, String filipino) copy,
  ) =>
      switch (mode) {
        ThemeMode.system => copy('System', 'System'),
        ThemeMode.light => copy('Light', 'Maliwanag'),
        ThemeMode.dark => copy('Dark', 'Madilim'),
      };

  String _gardenAppearanceLabel(
    GardenAppearance appearance,
    String Function(String english, String filipino) copy,
  ) =>
      switch (appearance) {
        GardenAppearance.syncWithTime =>
          copy('Sync with time', 'Sabay sa oras'),
        GardenAppearance.day => copy('Day', 'Araw'),
        GardenAppearance.night => copy('Night', 'Gabi'),
      };

  Future<void> _showThemePicker(
    BuildContext context,
    UserProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String copy(String english, String filipino) => LanguageHelper.pick(
          provider.language,
          english: english,
          filipino: filipino,
        );
    final options = [
      (
        ThemeMode.system,
        copy('Use device setting', 'Sundan ang device'),
        copy('Changes with your phone or computer',
            'Nagbabago kasabay ng iyong device'),
        Icons.brightness_auto_rounded,
      ),
      (
        ThemeMode.light,
        copy('Light', 'Maliwanag'),
        copy('Warm cream and honey colors', 'Warm cream at honey na kulay'),
        Icons.light_mode_rounded,
      ),
      (
        ThemeMode.dark,
        copy('Dark', 'Madilim'),
        copy('A calm forest-night palette', 'Mahinahong tema para sa gabi'),
        Icons.dark_mode_rounded,
      ),
    ];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy('Choose an appearance', 'Piliin ang tema'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                copy(
                  'The whole app updates immediately.',
                  'Agad na magbabago ang buong app.',
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: provider.themeMode == option.$1
                        ? AppColors.honeyAmber.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkBackground : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      key: ValueKey('theme-mode-${option.$1.name}'),
                      minTileHeight: 66,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.honeyAmber.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          option.$4,
                          color: AppColors.honeyAmber,
                          size: 21,
                        ),
                      ),
                      title: Text(
                        option.$2,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(option.$3),
                      trailing: provider.themeMode == option.$1
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.honeyAmber,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        provider.setThemeMode(option.$1);
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

  Future<void> _showGardenAppearancePicker(
    BuildContext context,
    UserProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String copy(String english, String filipino) => LanguageHelper.pick(
          provider.language,
          english: english,
          filipino: filipino,
        );
    final options = [
      (
        GardenAppearance.syncWithTime,
        copy('Sync with time', 'Sabay sa oras'),
        copy(
          'Day from 6 AM to 6 PM, then night',
          'Araw mula 6 AM hanggang 6 PM, tapos gabi',
        ),
        Icons.schedule_rounded,
      ),
      (
        GardenAppearance.day,
        copy('Always day', 'Palaging araw'),
        copy('Keep the garden bright', 'Panatilihing maliwanag ang garden'),
        Icons.wb_sunny_rounded,
      ),
      (
        GardenAppearance.night,
        copy('Always night', 'Palaging gabi'),
        copy('Keep the garden under moonlight',
            'Panatilihin sa liwanag ng buwan'),
        Icons.nightlight_round,
      ),
    ];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy('Garden lighting', 'Ilaw ng garden'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                copy(
                  'Choose the atmosphere for your gratitude garden.',
                  'Piliin ang atmosphere ng gratitude garden mo.',
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: provider.gardenAppearance == option.$1
                        ? AppColors.sageGreen.withValues(alpha: 0.14)
                        : (isDark ? AppColors.darkBackground : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      key: ValueKey('garden-appearance-${option.$1.name}'),
                      minTileHeight: 66,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          option.$4,
                          color: AppColors.sageGreen,
                          size: 21,
                        ),
                      ),
                      title: Text(
                        option.$2,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(option.$3),
                      trailing: provider.gardenAppearance == option.$1
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.sageGreen,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        provider.setGardenAppearance(option.$1);
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

  Future<void> _showCompanionPicker(
      BuildContext context, UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String copy(String english, String filipino) => LanguageHelper.pick(
          provider.language,
          english: english,
          filipino: filipino,
        );
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
              Text(copy('Choose your companion', 'Piliin ang iyong kasama'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                copy(
                  'Choose the companion whose style feels right for you.',
                  'Piliin ang kasamang akma sa iyo.',
                ),
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
    String copy(String english, String filipino) => LanguageHelper.pick(
          provider.language,
          english: english,
          filipino: filipino,
        );
    const languages = [
      ('taglish', 'Taglish', 'Filipino-English', '🇵🇭'),
      ('filipino', 'Filipino', 'Buong Filipino', '🇵🇭'),
      ('english', 'English', 'English', '🌐'),
    ];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy('Choose your language', 'Piliin ang iyong wika'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                copy(
                  'The whole interface updates immediately.',
                  'Agad na magbabago ang buong interface.',
                ),
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
        )),
      ),
    );
  }
}
