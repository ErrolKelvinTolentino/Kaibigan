import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/notification_service.dart';
import '../companion/companion_model.dart';
import '../auth_onboarding/mascot_selection_screen.dart';
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
      appBar: AppBar(
        title: Text(
          'Settings & Profile',
          style: AppTypography.titleLarge(context, isDark: isDark),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // User & Companion Profile Box (Tapping opens ProfileScreen)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: mascot.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(mascot.avatarIcon,
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProvider.displayName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Companion: ${mascot.name} (${mascot.tag})',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Supabase Integration & RLS Verification Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SupabaseService.isInitialized
                    ? AppColors.sageGreen.withOpacity(0.15)
                    : AppColors.warmPeach.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SupabaseService.isInitialized
                      ? AppColors.sageGreen
                      : AppColors.warmPeach,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    SupabaseService.isInitialized
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    color: SupabaseService.isInitialized
                        ? AppColors.sageGreen
                        : AppColors.annPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SupabaseService.isInitialized
                              ? 'Supabase Connected'
                              : 'Local Development Mode',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          SupabaseService.isInitialized
                              ? 'RLS Disabled for dev. All tables (profiles, journal, gratitude, mood) synced.'
                              : 'Place your SUPABASE_URL and SUPABASE_ANON_KEY inside .env file.',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // General Settings List
            Text('Preferences',
                style: AppTypography.titleMedium(context, isDark: isDark)),
            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.face),
              title: const Text('Change Companion Mascot'),
              subtitle: Text('Currently paired with ${mascot.name}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MascotSelectionScreen(isInitialOnboarding: false),
                  ),
                );
              },
            ),
            const Divider(),

            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable calming dark theme for nighttime'),
              value: userProvider.isDarkMode,
              activeThumbColor: AppColors.sageGreen,
              onChanged: (val) => userProvider.toggleDarkMode(val),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Test Daily Reminder'),
              subtitle: const Text('Send a gentle wellness notification now'),
              onTap: () {
                NotificationService.showNotification(
                  id: 1,
                  title: 'Kaibigan Reminder 🌿',
                  body:
                      'Kamusta ka? Take a brief moment to write your journal or visit your Gratitude Garden.',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
