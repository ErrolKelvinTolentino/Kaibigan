import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/language_helper.dart';
import '../companion/companion_model.dart';
import '../settings/user_provider.dart';

class AppTutorialScreen extends StatefulWidget {
  final String? mascotId;
  final String? language;
  final bool isModal;
  final VoidCallback? onCompleted;

  const AppTutorialScreen({
    super.key,
    this.mascotId,
    this.language,
    this.isModal = false,
    this.onCompleted,
  });

  @override
  State<AppTutorialScreen> createState() => _AppTutorialScreenState();
}

class _AppTutorialScreenState extends State<AppTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() async {
    HapticFeedback.lightImpact();
    final user = context.read<UserProvider>();
    await user.completeAppTutorial();
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>();
    final activeMascotId = widget.mascotId ?? user.selectedCompanion;
    final activeLanguage = widget.language ?? user.preferredLanguage;
    final mascot = MascotInfo.getById(activeMascotId);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: mascot.primaryColor.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            mascot.materialIcon,
                            color: mascot.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Kaibigan Tour',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    key: const ValueKey('tutorial-skip-button'),
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      LanguageHelper.pick(
                        activeLanguage,
                        english: 'Skip',
                        filipino: 'Laktawan',
                        taglish: 'Skip',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildCompanionSlide(
                    context: context,
                    isDark: isDark,
                    mascot: mascot,
                    language: activeLanguage,
                  ),
                  _buildHomeSlide(
                    context: context,
                    isDark: isDark,
                    language: activeLanguage,
                  ),
                  _buildActivitiesSlide(
                    context: context,
                    isDark: isDark,
                    language: activeLanguage,
                  ),
                  _buildRecordsAndLessonsSlide(
                    context: context,
                    isDark: isDark,
                    language: activeLanguage,
                  ),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? mascot.primaryColor
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      key: const ValueKey('tutorial-next-button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mascot.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _pageCount - 1
                            ? LanguageHelper.pick(
                                activeLanguage,
                                english: 'Get Started',
                                filipino: 'Magsimula Na Natin',
                                taglish: 'Let’s Get Started',
                              )
                            : LanguageHelper.pick(
                                activeLanguage,
                                english: 'Next',
                                filipino: 'Susunod',
                                taglish: 'Next',
                              ),
                        style: AppTypography.labelButton(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildCompanionSlide({
    required BuildContext context,
    required bool isDark,
    required MascotInfo mascot,
    required String language,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Mascot Avatar Card
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: mascot.primaryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: mascot.primaryColor.withValues(alpha: 0.35),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: mascot.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                mascot.materialIcon,
                size: 72,
                color: mascot.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            LanguageHelper.pick(
              language,
              english: 'Meet ${mascot.name}, your companion',
              filipino: 'Kilalanin si ${mascot.name}',
              taglish: 'Meet si ${mascot.name}, your companion',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LanguageHelper.pick(
              language,
              english:
                  'Kaibigan is your private, judgment-free space to care for your mind. Whether you need a warm listener, a moment to breathe, or quiet reflection, ${mascot.name} is always here.',
              filipino:
                  'Ang Kaibigan ay iyong ligtas at pribadong espasyo. Walang panghuhusga—kung kailangan mo ng makikinig, sandaling paghinga, o katahimikan, laging nandito si ${mascot.name}.',
              taglish:
                  'Ang Kaibigan ay safe at judgment-free space mo. Kung kailangan mo ng makikinig, calming breathing, o quiet space, laging nandito si ${mascot.name} for you.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip(
                icon: Icons.lock_outline_rounded,
                label: LanguageHelper.pick(
                  language,
                  english: '100% Private',
                  filipino: 'Pribado',
                  taglish: 'Private & Secure',
                ),
                color: AppColors.sageGreen,
                isDark: isDark,
              ),
              _buildFeatureChip(
                icon: Icons.favorite_outline_rounded,
                label: LanguageHelper.pick(
                  language,
                  english: 'Empathetic',
                  filipino: 'Maunawain',
                  taglish: 'Empathetic Companion',
                ),
                color: AppColors.softRose,
                isDark: isDark,
              ),
              _buildFeatureChip(
                icon: Icons.spa_outlined,
                label: LanguageHelper.pick(
                  language,
                  english: 'Zero Pressure',
                  filipino: 'Walang Presyur',
                  taglish: 'No Pressure',
                ),
                color: AppColors.honeyAmber,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeSlide({
    required BuildContext context,
    required bool isDark,
    required String language,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.honeyLight.withValues(alpha: 0.7),
                  AppColors.warmHoney.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.honeyAmber.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.wb_sunny_rounded,
                size: 68,
                color: AppColors.honeyAmber,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            LanguageHelper.pick(
              language,
              english: 'Daily Check-in & Moments',
              filipino: 'Pang-araw-araw na Check-in',
              taglish: 'Daily Check-in & Moments',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LanguageHelper.pick(
              language,
              english:
                  'Start each day by checking in on your emotions. Set a gentle Morning Focus to guide your intentions, and capture a warm Highlight before you sleep.',
              filipino:
                  'Simulan ang araw sa simpleng pagtatala ng nadarama. Magtakda ng Pokus sa Umaga at balikan ang magandang sandali bago matulog.',
              taglish:
                  'Simulan ang day with a quick mood check-in. Mag-set ng Morning Focus for clarity, and balikan ang bright Highlight bago matulog.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip(
                icon: Icons.sentiment_satisfied_rounded,
                label: LanguageHelper.pick(
                  language,
                  english: 'Mood Tracker',
                  filipino: 'Tala ng Mood',
                  taglish: 'Mood Tracker',
                ),
                color: AppColors.honeyAmber,
                isDark: isDark,
              ),
              _buildFeatureChip(
                icon: Icons.wb_sunny_outlined,
                label: LanguageHelper.pick(
                  language,
                  english: 'Morning Focus',
                  filipino: 'Pokus sa Umaga',
                  taglish: 'Morning Focus',
                ),
                color: AppColors.warmPeach,
                isDark: isDark,
              ),
              _buildFeatureChip(
                icon: Icons.nights_stay_outlined,
                label: LanguageHelper.pick(
                  language,
                  english: 'Night Highlight',
                  filipino: 'Highlight sa Gabi',
                  taglish: 'Night Highlight',
                ),
                color: AppColors.periwinkle,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSlide({
    required BuildContext context,
    required bool isDark,
    required String language,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.sageGreen.withValues(alpha: 0.25),
                  AppColors.honeyLight.withValues(alpha: 0.4),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.sageGreen.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.spa_rounded,
                size: 68,
                color: AppColors.sageGreen,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            LanguageHelper.pick(
              language,
              english: 'Calming Activities',
              filipino: 'Mga Aktibidad sa Kapanatagan',
              taglish: 'Calming Activities Anytime',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LanguageHelper.pick(
              language,
              english:
                  'When stress or anxiety arrives, use guided breathing with soothing soundscapes, reset your senses with 5-4-3-2-1 grounding, or plant seeds in your Gratitude Garden.',
              filipino:
                  'Kapag mabigat ang isip, magpahinga gamit ang guided breathing na may banayad na tunog, 5-4-3-2-1 grounding sa Comfort Corner, o magtanim sa Hardin ng Pasasalamat.',
              taglish:
                  'Pag stressed o overwhelmed ka, mag-breathe with calming ambient sounds, i-ground ang 5 senses sa Comfort Corner, o magtanim sa Gratitude Garden.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip(
                icon: Icons.air_rounded,
                label: LanguageHelper.pick(
                  language,
                  english: 'Guided Breathing',
                  filipino: 'Pagsasanay sa Paghinga',
                  taglish: 'Mindful Breathing',
                ),
                color: AppColors.honeyAmber,
                isDark: isDark,
              ),
              _buildFeatureChip(
                icon: Icons.touch_app_outlined,
                label: LanguageHelper.pick(
                  language,
                  english: 'Comfort Corner',
                  filipino: 'Sulok ng Kapanatagan',
                  taglish: 'Grounding Corner',
                ),
                color: AppColors.warmPeach,
                isDark: isDark,
              ),
              _buildFeatureChip(
                icon: Icons.local_florist_outlined,
                label: LanguageHelper.pick(
                  language,
                  english: 'Gratitude Garden',
                  filipino: 'Hardin ng Pasasalamat',
                  taglish: 'Gratitude Garden',
                ),
                color: AppColors.softRose,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsAndLessonsSlide({
    required BuildContext context,
    required bool isDark,
    required String language,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.softRose.withValues(alpha: 0.25),
                  AppColors.periwinkle.withValues(alpha: 0.35),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.softRose.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_stories_rounded,
                size: 68,
                color: AppColors.softRose,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            LanguageHelper.pick(
              language,
              english: 'Records & Lessons',
              filipino: 'Mga Tala at Aralin',
              taglish: 'Records & Mental Health Lessons',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LanguageHelper.pick(
              language,
              english:
                  'Express yourself freely in the AI Journal with supportive reflections, seal future letters to yourself, and learn practical skills to support yourself and friends.',
              filipino:
                  'Malayang magpahayag sa AI Talaarawan, magpadala ng liham sa hinaharap, at magsanay sa mga praktikal na paraan ng pagtulong sa sarili at kaibigan.',
              taglish:
                  'Express freely sa AI Journal na may comforting companion response, magpadala ng future letters, at matuto ng friend support practice scenarios.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip(
                icon: Icons.book_outlined,
                label: LanguageHelper.pick(
                  language,
                  english: 'AI Journal',
                  filipino: 'AI Talaarawan',
                  taglish: 'AI Journal',
                ),
                color: AppColors.sageGreen,
                isDark: isDark,
              ),
              _buildFeatureChip(
                icon: Icons.mail_outline_rounded,
                label: LanguageHelper.pick(
                  language,
                  english: 'Future Letters',
                  filipino: 'Liham sa Hinaharap',
                  taglish: 'Future Letters',
                ),
                color: AppColors.lavenderMist,
                isDark: isDark,
              ),
              _buildFeatureChip(
                icon: Icons.school_outlined,
                label: LanguageHelper.pick(
                  language,
                  english: 'Mental Health Lessons',
                  filipino: 'Mga Aralin',
                  taglish: 'Lessons & Scenarios',
                ),
                color: AppColors.honeyGold,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.38 : 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
