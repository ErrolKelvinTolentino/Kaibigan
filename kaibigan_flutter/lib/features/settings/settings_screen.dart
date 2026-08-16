import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/supabase_service.dart';
import '../companion/companion_model.dart';
import '../auth_onboarding/auth_screen.dart';
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: mascot.primaryColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(mascot.avatarIcon, style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProvider.displayName.isEmpty ? 'Kaibigan User' : userProvider.displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userProvider.email.isEmpty ? 'Offline Profile' : userProvider.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ],
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
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  // Companion Picker (Kai vs Ann)
                  ListTile(
                    leading: Text(mascot.avatarIcon, style: const TextStyle(fontSize: 22)),
                    title: const Text('Companion Mascot', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${mascot.name} (${mascot.tag})'),
                    trailing: DropdownButton<String>(
                      value: userProvider.selectedCompanion,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(16),
                      items: MascotInfo.companions.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.avatarIcon} ${c.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          userProvider.setSelectedCompanion(val);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),

                  // Language Picker
                  ListTile(
                    leading: const Icon(Icons.translate_rounded, color: AppColors.sageGreen),
                    title: const Text('Language / Wika', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      userProvider.language == 'filipino'
                          ? 'Filipino'
                          : (userProvider.language == 'taglish' ? 'Taglish (Filipino-English)' : 'English'),
                    ),
                    trailing: DropdownButton<String>(
                      value: userProvider.language,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(value: 'taglish', child: Text('Taglish 🇵🇭')),
                        DropdownMenuItem(value: 'filipino', child: Text('Filipino 🇵🇭')),
                        DropdownMenuItem(value: 'english', child: Text('English 🌐')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          userProvider.setLanguage(val);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),

                  // Dark Mode Switch
                  SwitchListTile(
                    secondary: Icon(
                      userProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.honeyGold,
                    ),
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Cozy nature palette for evening'),
                    value: userProvider.isDarkMode,
                    activeThumbColor: AppColors.honeyGold,
                    onChanged: (val) => userProvider.toggleDarkMode(val),
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
                border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        SupabaseService.isInitialized ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: SupabaseService.isInitialized ? AppColors.sageGreen : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              SupabaseService.isInitialized ? 'Cloud Sync Active' : 'Offline Mode',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              SupabaseService.isInitialized
                                  ? 'All entries safely synced with Supabase'
                                  : 'Data stored locally on this device',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                      label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        await userProvider.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                            (route) => false,
                          );
                        }
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
}
