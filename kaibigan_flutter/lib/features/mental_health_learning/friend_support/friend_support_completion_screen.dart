import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../../../core/widgets/mobile_layout.dart';
import 'friend_support_catalog.dart';
import 'friend_support_model.dart';
import 'friend_support_safety_sheet.dart';

class FriendSupportCompletionScreen extends StatelessWidget {
  const FriendSupportCompletionScreen({
    super.key,
    required this.lesson,
    required this.score,
    required this.total,
    required this.language,
    required this.onPracticeAgain,
  });

  final FriendSupportLesson lesson;
  final int score;
  final int total;
  final String language;
  final VoidCallback onPracticeAgain;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final isPerfect = score == total;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          LanguageHelper.pick(
            language,
            english: 'Lesson Completed',
            filipino: 'Tapos na ang Aralin',
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            key: const ValueKey('friend-support-completion-need-help'),
            onPressed: () => FriendSupportSafetySheet.show(
              context,
              language: language,
            ),
            icon: Icon(
              Icons.health_and_safety_outlined,
              color: palette.danger,
              size: 18,
            ),
            label: Text(
              LanguageHelper.pick(
                language,
                english: 'Need Help?',
                filipino: 'Kailangan ng Tulong?',
              ),
              style: TextStyle(
                color: palette.danger,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: MobileContent(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MobileLayout.horizontalPadding(context),
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mascot / Celebration Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        palette.accentSubtle,
                        Theme.of(context).brightness == Brightness.dark
                            ? palette.surfaceElevated
                            : AppColors.pollenGlow.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.95),
                              palette.accentSubtle,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.accent.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🐝',
                            style: TextStyle(fontSize: 42),
                          ),
                        ),
                      ).animate().scale(
                            curve: Curves.easeOutBack,
                            duration: 500.ms,
                          ),
                      const SizedBox(height: 18),
                      Text(
                        LanguageHelper.pick(
                          language,
                          english:
                              'You\'re learning how to be a better Kaibigan.',
                          filipino:
                              'Natututo kang maging mas mabuting Kaibigan.',
                        ),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lesson.title.resolve(language),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Score Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isPerfect
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? palette.surfaceElevated
                                  : Colors.white.withValues(alpha: 0.9))
                              : palette.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPerfect
                                ? palette.accent
                                : palette.border.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.shadow.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPerfect
                                  ? Icons.emoji_events_rounded
                                  : Icons.check_circle_rounded,
                              color: isPerfect
                                  ? palette.accentStrong
                                  : palette.accent,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                LanguageHelper.pick(
                                  language,
                                  english: 'Quiz Score: $score / $total',
                                  filipino: 'Iskor sa Quiz: $score / $total',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Key Takeaways
                Text(
                  LanguageHelper.pick(
                    language,
                    english: 'You learned how to:',
                    filipino: 'Natutunan mo kung paano:',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                ...FriendSupportCatalog.takeaways.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: KaibiganSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: palette.accentSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: palette.accentStrong,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.resolve(language),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.honeyGold,
                        AppColors.honeyAmber,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.honeyAmber.withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    key: const ValueKey('friend-support-practice-more-btn'),
                    onPressed: onPracticeAgain,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.onHoney,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            LanguageHelper.pick(
                              language,
                              english: 'Practice More →',
                              filipino: 'Magsanay Pa →',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const ValueKey('friend-support-back-to-lessons-btn'),
                  onPressed: () {
                    // Pop back to lessons list
                    Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == 'friend_support_hub');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: palette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    LanguageHelper.pick(
                      language,
                      english: 'Back to Friend Lessons',
                      filipino: 'Bumalik sa mga Aralin',
                    ),
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
