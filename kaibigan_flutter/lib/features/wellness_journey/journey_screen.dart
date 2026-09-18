import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_feature_banner.dart';
import '../../core/widgets/cozy_motion.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../insights/plain_language_insights.dart';
import '../insights/wellness_analytics.dart';
import '../journaling/journal_provider.dart';
import '../mood_tracking/mood_provider.dart';
import '../settings/user_provider.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final journal = context.watch<JournalProvider>();
    final garden = context.watch<GratitudeProvider>();
    final mood = context.watch<MoodProvider>();
    final language = context.watch<UserProvider>().language;
    String copy(String english, String filipino) => LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
        );

    final activityDates = <DateTime>[
      ...journal.entries.map((entry) => entry.createdAt),
      ...garden.entries.map((entry) => entry.createdAt),
      ...mood.logs.map((entry) => entry.createdAt),
    ];
    final streak = _currentStreak(activityDates);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = DateTime(today.year, today.month, today.day - 6);
    final loggedToday = activityDates
        .map(wellnessDay)
        .any((date) => date == today);
    final longestStreak =
        WellnessStreak.fromDates(activityDates, now: now).longest;
    int since(Iterable<DateTime> dates) => dates
        .where((date) => !date.toLocal().isBefore(weekStart))
        .length;
    final weeklyMood = mood.weeklyMoodAverage;
    final gratitudeThisWeek =
        since(garden.entries.map((entry) => entry.createdAt));
    final journalThisWeek =
        since(journal.entries.map((entry) => entry.createdAt));
    final milestones = _buildMilestones(
      language: language,
      journalDates: journal.entries.map((entry) => entry.createdAt),
      gratitudeDates: garden.entries.map((entry) => entry.createdAt),
      moodDates: mood.logs.map((entry) => entry.createdAt),
    );

    return Scaffold(
      appBar: AppBar(title: Text(copy('Your Journey', 'Iyong paglalakbay'))),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: CozyFeatureBanner(
                  eyebrow: copy('Gentle progress', 'Banayad na progreso'),
                  title: copy(
                      'Notice how you are growing', 'Pansinin ang paglago mo'),
                  subtitle: copy(
                    'Every check-in, reflection, and grateful moment belongs here.',
                    'Kasama rito ang bawat pag-check-in, pagninilay, at pasasalamat.',
                  ),
                  placeholderLabel: 'wellness-journey',
                  placeholderIcon: Icons.route_rounded,
                  accent: AppColors.honeyAmber,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeading(
                  eyebrow: copy('At a glance', 'Sa isang tingin'),
                  title: copy('Your gentle rhythm', 'Iyong banayad na ritmo'),
                  subtitle: longestStreak > 1
                      ? copy(
                          'No pressure—these reflect the care you made time '
                              'for. Your longest run so far is $longestStreak '
                              'days, and it survived every gap before it.',
                          'Walang pressure—ipinapakita lang nito ang oras na '
                              'inilaan mo sa sarili. Ang pinakamahaba mong '
                              'sunod-sunod ay $longestStreak araw, at '
                              'nalampasan nito ang bawat pagitan.',
                        )
                      : copy(
                          'No pressure—these numbers simply reflect the care you made time for.',
                          'Walang pressure—ipinapakita lang nito ang oras na inilaan mo sa sarili.',
                        ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    final tileWidth = compact
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;
                    final metrics = [
                      _MetricData(
                        label: copy('Current rhythm', 'Kasalukuyang ritmo'),
                        value: streak == 0
                            ? copy('Start today', 'Magsimula ngayon')
                            : copy('$streak day${streak == 1 ? '' : 's'}',
                                '$streak araw'),
                        // A streak number on its own invites a person to
                        // read a missed day as a failure. The caption says
                        // what it would actually take to keep it.
                        caption: streak == 0
                            ? copy('One saved moment starts it again',
                                'Isang tala at magsisimula muli')
                            : loggedToday
                                ? copy('Today is already in',
                                    'Kasama na ang ngayon')
                                : copy('Anything today keeps it',
                                    'Kahit ano ngayon, tuloy ito'),
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.honeyAmber,
                      ),
                      _MetricData(
                        label: copy('Garden blooms', 'Mga bulaklak'),
                        value: '${garden.flowerCount}',
                        caption: gratitudeThisWeek == 0
                            ? copy('none planted in the last 7 days',
                                'wala sa huling 7 araw')
                            : copy(
                                '$gratitudeThisWeek in the last 7 days',
                                '$gratitudeThisWeek sa huling 7 araw'),
                        icon: Icons.local_florist_rounded,
                        color: AppColors.softOlive,
                      ),
                      _MetricData(
                        label: copy('Reflections', 'Mga pagninilay'),
                        value: '${journal.entries.length}',
                        caption: journalThisWeek == 0
                            ? copy('none written in the last 7 days',
                                'wala sa huling 7 araw')
                            : copy(
                                '$journalThisWeek in the last 7 days',
                                '$journalThisWeek sa huling 7 araw'),
                        icon: Icons.auto_stories_rounded,
                        color: AppColors.sageGreen,
                      ),
                      _MetricData(
                        label: copy('Average mood', 'Karaniwang mood'),
                        // A week with no check-ins has no average. Showing
                        // 0.0 would draw an empty week as the worst one.
                        value: weeklyMood == null
                            ? '—'
                            : '${weeklyMood.toStringAsFixed(1)} / 5',
                        caption: weeklyMood == null
                            ? (mood.logs.isEmpty
                                ? copy('no check-ins yet',
                                    'wala pang check-in')
                                : copy('none in the last 7 days',
                                    'wala sa huling 7 araw'))
                            : PlainLanguageInsights.moodWord(
                                    weeklyMood, language)
                                .toLowerCase(),
                        icon: Icons.wb_sunny_rounded,
                        color: AppColors.honeyGold,
                      ),
                    ];
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                        metrics.length,
                        (index) => SizedBox(
                          width: tileWidth,
                          child: CozyEntrance(
                            delay: Duration(milliseconds: 60 * index),
                            child: _MetricCard(
                              data: metrics[index],
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _SectionHeading(
                  eyebrow: copy('Your story', 'Iyong kuwento'),
                  title: copy(
                      'Milestones worth noticing', 'Mga hakbang na mahalaga'),
                  subtitle: copy(
                    'A quiet timeline built only from moments you actually recorded.',
                    'Isang tahimik na timeline mula lamang sa mga naitala mo.',
                  ),
                ),
              ),
            ),
            if (milestones.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: _JourneyEmptyState(
                    isDark: isDark,
                    title: copy(
                      'Your first moment starts here',
                      'Dito magsisimula ang unang sandali mo',
                    ),
                    subtitle: copy(
                      'Write a reflection, log a mood, or plant one gratitude to begin your timeline.',
                      'Magsulat, mag-log ng mood, o magtanim ng isang pasasalamat upang magsimula.',
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                sliver: SliverList.separated(
                  itemCount: milestones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => CozyEntrance(
                    delay: Duration(milliseconds: 70 * index),
                    child: _MilestoneTile(
                      milestone: milestones[index],
                      isDark: isDark,
                      isLast: index == milestones.length - 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static int _currentStreak(Iterable<DateTime> dates) {
    final unique =
        dates.map((date) => DateTime(date.year, date.month, date.day)).toSet();
    if (unique.isEmpty) return 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!unique.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!unique.contains(cursor)) return 0;
    }
    var count = 0;
    while (unique.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  static List<_MilestoneData> _buildMilestones({
    required String language,
    required Iterable<DateTime> journalDates,
    required Iterable<DateTime> gratitudeDates,
    required Iterable<DateTime> moodDates,
  }) {
    String copy(String english, String filipino) => LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
        );
    final milestones = <_MilestoneData>[];
    void addFirst(
      Iterable<DateTime> dates,
      String title,
      String description,
      IconData icon,
      Color color,
    ) {
      if (dates.isEmpty) return;
      final first = dates.reduce((a, b) => a.isBefore(b) ? a : b);
      milestones.add(_MilestoneData(
        title: title,
        description: description,
        date: first,
        icon: icon,
        color: color,
      ));
    }

    addFirst(
      moodDates,
      copy('First mood check-in', 'Unang mood check-in'),
      copy('You paused long enough to name how you felt.',
          'Huminto ka upang kilalanin ang nararamdaman mo.'),
      Icons.wb_sunny_rounded,
      AppColors.honeyGold,
    );
    addFirst(
      journalDates,
      copy('First journal reflection', 'Unang pagninilay'),
      copy('You made room for an honest thought.',
          'Naglaan ka ng espasyo para sa isang tapat na kaisipan.'),
      Icons.auto_stories_rounded,
      AppColors.sageGreen,
    );
    addFirst(
      gratitudeDates,
      copy('First gratitude planted', 'Unang pasasalamat na itinanim'),
      copy('One meaningful moment became part of your garden.',
          'Isang makabuluhang sandali ang naging bahagi ng hardin mo.'),
      Icons.local_florist_rounded,
      AppColors.softOlive,
    );
    milestones.sort((a, b) => a.date.compareTo(b.date));
    return milestones;
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.honeyAmber,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _MetricData {
  final String label;
  final String value;

  /// The sentence that makes the figure mean something. Without it a tile
  /// reports a number and leaves the reader to decide whether it is good.
  final String caption;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;
  final bool isDark;

  const _MetricCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : data.color.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: isDark ? 0.06 : 0.1),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color, size: 19),
          ),
          const SizedBox(height: 14),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: data.color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 5),
          Text(
            data.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneData {
  final String title;
  final String description;
  final DateTime date;
  final IconData icon;
  final Color color;

  const _MilestoneData({
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.color,
  });
}

class _MilestoneTile extends StatelessWidget {
  final _MilestoneData milestone;
  final bool isDark;
  final bool isLast;

  const _MilestoneTile({
    required this.milestone,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: milestone.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: milestone.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(milestone.icon, color: milestone.color, size: 19),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.honeyBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkCardBorder : AppColors.honeyBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d').format(milestone.date),
                        style: TextStyle(
                          color: milestone.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    milestone.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyEmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _JourneyEmptyState({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return CozyEntrance(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkHoneySurface : AppColors.honeyLight,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark ? AppColors.darkHoneyBorder : AppColors.honeyBorder,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.route_rounded,
                color: AppColors.honeyAmber, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
