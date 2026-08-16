import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';
import '../main_navigation_screen.dart';

class MascotSelectionScreen extends StatefulWidget {
  final bool isInitialOnboarding;
  const MascotSelectionScreen({super.key, this.isInitialOnboarding = true});

  @override
  State<MascotSelectionScreen> createState() => _MascotSelectionScreenState();
}

class _MascotSelectionScreenState extends State<MascotSelectionScreen> {
  String _selectedId = 'kai';
  String _selectedLang = 'taglish';

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _selectedId = userProvider.selectedCompanion;
    _selectedLang = userProvider.preferredLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedMascot = MascotInfo.getById(_selectedId);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Sino ang gusto mong makasama?',
                style: AppTypography.titleLarge(context, isDark: isDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Piliin ang kaibigan mo para sa araw-araw mong wellness check-in.',
                style: AppTypography.bodyMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 20),

              // Language Switcher Chips
              Row(
                children: [
                  _buildLangChip('taglish', 'Taglish'),
                  const SizedBox(width: 8),
                  _buildLangChip('filipino', 'Filipino'),
                  const SizedBox(width: 8),
                  _buildLangChip('english', 'English'),
                ],
              ),
              const SizedBox(height: 24),

              // Mascot List
              Expanded(
                child: ListView.separated(
                  itemCount: MascotInfo.companions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final companion = MascotInfo.companions[index];
                    final isSelected = companion.id == _selectedId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedId = companion.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.darkCardBorder
                                  : companion.lightBgColor)
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? companion.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: companion.primaryColor
                                        .withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: companion.primaryColor
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  companion.materialIcon,
                                  color: companion.primaryColor,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companion.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    companion.tag,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: companion.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedMascot.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final userProvider =
                        Provider.of<UserProvider>(context, listen: false);
                    await userProvider.setCompanion(_selectedId);
                    await userProvider.setLanguage(_selectedLang);

                    if (!context.mounted) return;

                    if (widget.isInitialOnboarding) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MainNavigationScreen()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Magsimula tayo, ${selectedMascot.name}',
                    style: AppTypography.labelButton(context),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip(String langKey, String label) {
    final isSelected = _selectedLang == langKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.sageGreen,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.warmCream,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedLang = langKey;
          });
        }
      },
    );
  }
}
