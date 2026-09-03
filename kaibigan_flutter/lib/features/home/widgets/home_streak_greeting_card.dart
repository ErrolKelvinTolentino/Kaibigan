import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/language_helper.dart';

class HomeStreakGreetingCard extends StatelessWidget {
  const HomeStreakGreetingCard({
    super.key,
    required this.name,
    required this.language,
    required this.isDark,
    required this.streakCount,
    required this.activeDates,
    this.onStreakTap,
  });

  final String name;
  final String language;
  final bool isDark;
  final int streakCount;
  final Set<DateTime> activeDates;
  final VoidCallback? onStreakTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));

    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      key: const ValueKey('home-greeting-streak-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF2E2C22), Color(0xFF22231E)]
              : const [Color(0xFFFFF9EC), Color(0xFFFFFCF6)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.honeyBorder.withValues(alpha: 0.90),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.honeyAmber.withValues(
              alpha: isDark ? 0.08 : 0.09,
            ),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date Pill + Fire Streak Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.honeyAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(now),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.honeyAmber,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Fire Streak Badge
              GestureDetector(
                onTap: onStreakTap,
                child: Container(
                  key: const ValueKey('home-streak-badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9E45), Color(0xFFFF6B00)],
                    ),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.32),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streakCount ${LanguageHelper.pick(
                          language,
                          english: streakCount == 1 ? 'day' : 'days',
                          filipino: 'araw',
                        )}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Greeting Text
          Text.rich(
            TextSpan(
              text: LanguageHelper.pick(
                language,
                english: 'Hi, ',
                filipino: 'Kumusta, ',
                taglish: 'Kamusta, ',
              ),
              children: [
                TextSpan(
                  text: name,
                  style: const TextStyle(color: AppColors.honeyAmber),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryText,
              fontSize: 27,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            LanguageHelper.pick(
              language,
              english: 'What would feel supportive today?',
              filipino: 'Ano ang makakatulong sa iyo ngayon?',
              taglish: 'Ano ang makakatulong sa iyo today?',
            ),
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // 7 Subtle Dots Lined Up (no white container box)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              key: const ValueKey('home-7-day-streak-row'),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final dayDate = monday.add(Duration(days: index));
                final isToday = dayDate.isAtSameMomentAs(today);
                final isFuture = dayDate.isAfter(today);
                final isActive = activeDates.any((d) =>
                    d.year == dayDate.year &&
                    d.month == dayDate.month &&
                    d.day == dayDate.day);
                final label = dayLabels[index];

                return _SubtleDayDot(
                  label: label,
                  isActive: isActive,
                  isToday: isToday,
                  isFuture: isFuture,
                  isDark: isDark,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtleDayDot extends StatelessWidget {
  const _SubtleDayDot({
    required this.label,
    required this.isActive,
    required this.isToday,
    required this.isFuture,
    required this.isDark,
  });

  final String label;
  final bool isActive;
  final bool isToday;
  final bool isFuture;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final honey = isDark ? AppColors.honeyGold : AppColors.honeyAmber;
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.11);
    final futureColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: isActive ? 12 : (isToday ? 10 : 8),
          height: isActive ? 12 : (isToday ? 10 : 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB800), Color(0xFFFF7A00)],
                  )
                : null,
            color: isActive
                ? null
                : isToday
                    ? null
                    : isFuture
                        ? futureColor
                        : muted,
            border: isToday && !isActive
                ? Border.all(color: honey, width: 1.5)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.45),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isActive || isToday ? FontWeight.w800 : FontWeight.w500,
            color: isActive
                ? honey
                : isToday
                    ? (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight)
                    : (isDark
                        ? AppColors.textSecondaryDark.withValues(alpha: 0.65)
                        : AppColors.textSecondaryLight.withValues(alpha: 0.65)),
          ),
        ),
      ],
    );
  }
}
