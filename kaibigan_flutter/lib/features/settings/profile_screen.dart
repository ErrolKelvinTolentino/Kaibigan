import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../companion/companion_model.dart';
import '../auth_onboarding/mascot_selection_screen.dart';
import 'user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile 👤',
          style: AppTypography.titleLarge(context, isDark: isDark),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Avatar & Member Card
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: mascot.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: mascot.primaryColor, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        mascot.avatarIcon,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.sageGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'kaibigan member 🛡️',
                style: AppTypography.bodySmall(context, isDark: isDark, color: AppColors.sageGreen),
              ),
            ),
            const SizedBox(height: 24),

            // Display Name Card
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Name:', style: AppTypography.bodySmall(context, isDark: isDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: AppTypography.titleSmall(context, isDark: isDark),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.sageGreen),
                        onPressed: () {
                          if (_nameController.text.trim().isNotEmpty) {
                            userProvider.updateDisplayName(_nameController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name updated successfully!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Companion Selection Section
            Text('Your Companion', style: AppTypography.titleMedium(context, isDark: isDark)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Text(mascot.avatarIcon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mascot.name, style: AppTypography.titleSmall(context, isDark: isDark)),
                        const SizedBox(height: 2),
                        Text(mascot.tag, style: AppTypography.bodySmall(context, isDark: isDark)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sageGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MascotSelectionScreen(isInitialOnboarding: false),
                        ),
                      );
                    },
                    child: const Text('Change', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferred Language Section
            Text('Language Preference', style: AppTypography.titleMedium(context, isDark: isDark)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildLanguageOption(context, userProvider, 'english', '🇺🇸 English'),
                  const Divider(height: 1),
                  _buildLanguageOption(context, userProvider, 'filipino', '🇵🇭 Filipino'),
                  const Divider(height: 1),
                  _buildLanguageOption(context, userProvider, 'taglish', '🇵🇭 Taglish (Mix)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, UserProvider provider, String langKey, String label) {
    final isSelected = provider.preferredLanguage == langKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      title: Text(label, style: AppTypography.bodyMedium(context, isDark: isDark)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.sageGreen) : null,
      onTap: () => provider.setLanguage(langKey),
    );
  }
}
