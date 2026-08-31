import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/language_helper.dart';
import '../../affirmations/affirmation_model.dart';

class TodayMomentsCard extends StatelessWidget {
  final String language;
  final bool isDark;
  final AffirmationCategory? category;
  final String affirmation;
  final int arrivedLetterCount;
  final VoidCallback onLettersTap;

  const TodayMomentsCard({
    super.key,
    required this.language,
    required this.isDark,
    required this.category,
    required this.affirmation,
    required this.arrivedLetterCount,
    required this.onLettersTap,
  });

  @override
  Widget build(BuildContext context) {
    String copy(String english, String filipino, [String? taglish]) =>
        LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
          taglish: taglish,
        );
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final radius = BorderRadius.circular(26);
    return Material(
      key: const ValueKey('today-moments-card'),
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        key: const ValueKey('today-moments-surface'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF332B1F), Color(0xFF242723)]
                : const [Color(0xFFFFF1C9), Color(0xFFFFFBF2)],
          ),
          borderRadius: radius,
          border: Border.all(
            color: isDark
                ? AppColors.darkHoneyBorder
                : AppColors.honeyGold.withValues(alpha: 0.34),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppColors.honeyAmber.withValues(alpha: isDark ? 0.08 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: -24,
              child: Icon(
                Icons.format_quote_rounded,
                size: 118,
                color: AppColors.honeyAmber.withValues(alpha: 0.065),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.honeyGold, AppColors.warmPeach],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 17, 6),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.honeyAmber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        copy('A NOTE FOR TODAY', 'PAALALA NGAYON',
                            'A NOTE FOR TODAY'),
                        style: const TextStyle(
                          color: AppColors.honeyAmber,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.65,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  key: const ValueKey('today-affirmation-quote'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 17),
                  child: Text(
                    affirmation,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontFamily: 'serif',
                      fontSize: 17,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (category != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                    child: Text(
                      category!.title,
                      style: const TextStyle(
                        color: AppColors.honeyAmber,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (arrivedLetterCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: InkWell(
                      key: const ValueKey('arrived-future-letter-action'),
                      onTap: onLettersTap,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF382E2A), Color(0xFF302A2D)]
                                : const [Color(0xFFFFE5D4), Color(0xFFF7E6EF)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.warmPeach.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 39,
                              height: 39,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warmPeach.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_outlined,
                                color: AppColors.warmPeach,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    arrivedLetterCount == 1
                                        ? copy(
                                            'A Future Letter has arrived',
                                            'Dumating na ang isang Liham',
                                            'A Future Letter has arrived',
                                          )
                                        : copy(
                                            '$arrivedLetterCount Future Letters have arrived',
                                            '$arrivedLetterCount Liham ang dumating',
                                            '$arrivedLetterCount Future Letters have arrived',
                                          ),
                                    style: TextStyle(
                                      color: foreground,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    copy(
                                      'Past you left something for today.',
                                      'May iniwan ang dating ikaw para sa araw na ito.',
                                      'Past you left something for today.',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: secondary, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.warmPeach,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
