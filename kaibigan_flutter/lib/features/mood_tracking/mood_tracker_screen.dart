import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'mood_provider.dart';
import 'mood_model.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  int _selectedScore = 4;
  String _selectedLabel = 'Good';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodProvider = Provider.of<MoodProvider>(context);
    final logs = moodProvider.logs;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mood & Emotional Insights',
          style: AppTypography.titleLarge(context, isDark: isDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emotional Check-in Logger Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamusta ang pakiramdam mo ngayon?',
                      style: AppTypography.titleMedium(context, isDark: isDark),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        final score = index + 1;
                        final isSelected = _selectedScore == score;
                        final emoji = MoodLog.getMoodEmoji(score);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedScore = score;
                              switch (score) {
                                case 1:
                                  _selectedLabel = 'Struggling';
                                  break;
                                case 2:
                                  _selectedLabel = 'Low';
                                  break;
                                case 3:
                                  _selectedLabel = 'Okay';
                                  break;
                                case 4:
                                  _selectedLabel = 'Good';
                                  break;
                                case 5:
                                  _selectedLabel = 'Awesome';
                                  break;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MoodLog.getMoodColor(score)
                                      .withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? MoodLog.getMoodColor(score)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              emoji,
                              style: TextStyle(fontSize: isSelected ? 32 : 26),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _selectedLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MoodLog.getMoodColor(_selectedScore),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Add a brief note (optional)...',
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.warmCream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sageGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          moodProvider.logMood(
                            score: _selectedScore,
                            label: _selectedLabel,
                            note: _noteController.text.isEmpty
                                ? null
                                : _noteController.text,
                          );
                          _noteController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Mood check-in recorded! ✨')),
                          );
                        },
                        child: const Text('Save Mood Check-In',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 7-Day Emotional Trends Chart
              Text(
                'Weekly Emotional Trends',
                style: AppTypography.titleMedium(context, isDark: isDark),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.only(
                    right: 20, left: 10, top: 20, bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 1,
                    maxY: 5,
                    lineBarsData: [
                      LineChartBarData(
                        spots: logs
                            .take(7)
                            .toList()
                            .asMap()
                            .entries
                            .map((e) {
                              return FlSpot(e.key.toDouble(),
                                  e.value.moodScore.toDouble());
                            })
                            .toList()
                            .reversed
                            .toList(),
                        isCurved: true,
                        color: AppColors.sageGreen,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.sageGreen.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
