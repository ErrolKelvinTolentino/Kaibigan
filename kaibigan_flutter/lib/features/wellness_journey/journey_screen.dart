import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../journaling/journal_provider.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../mood_tracking/mood_provider.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final journalProvider = Provider.of<JournalProvider>(context);
    final gardenProvider = Provider.of<GratitudeProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wellness Journey 📈',
          style: AppTypography.titleLarge(context, isDark: isDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Emotional Progress & Milestones',
                style: AppTypography.bodyMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 20),

              // Overview Milestone Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Current Streak',
                      value: '7 Days 🔥',
                      color: AppColors.moodLow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Flowers Bloomed',
                      value: '${gardenProvider.flowerCount} 🌸',
                      color: AppColors.softRose,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Reflections',
                      value: '${journalProvider.entries.length} ✍️',
                      color: AppColors.sageGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Avg Mood',
                      value: '${moodProvider.averageWeeklyScore.toStringAsFixed(1)} / 5.0 ✨',
                      color: AppColors.beePrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Visual Milestone Timeline
              Text(
                'Milestone Timeline',
                style: AppTypography.titleMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 16),
              _buildTimelineTile(
                context,
                title: 'Started Kaibigan Journey',
                desc: 'Chose Kai as companion & completed initial wellness check-in.',
                icon: '🌱',
                isFirst: true,
              ),
              _buildTimelineTile(
                context,
                title: 'First Flower Bloomed',
                desc: 'Planted a gratitude sunflower in the virtual garden.',
                icon: '🌻',
              ),
              _buildTimelineTile(
                context,
                title: 'Butterflies Unlocked!',
                desc: 'Reached 3 blooming flowers in Gratitude Garden.',
                icon: '🦋',
              ),
              _buildTimelineTile(
                context,
                title: '7-Day Reflection Streak',
                desc: 'Maintained daily mental self-care consistency.',
                icon: '🏆',
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(BuildContext context, {required String title, required String desc, required String icon, bool isFirst = false, bool isLast = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: AppColors.warmCream, shape: BoxShape.circle),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: AppColors.sageGreen.withOpacity(0.4)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
