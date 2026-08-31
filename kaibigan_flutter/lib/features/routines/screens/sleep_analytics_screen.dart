import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/cozy_confirm_sheet.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../companion/companion_model.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';
import 'sleep_log_flow_screen.dart';

/// Parsed sleep log data object for analytics and timeline rendering.
class ParsedSleepLog {
  final RoutineLog rawLog;
  final SleepFeeling feeling;
  final double hours;
  final DateTime completedAt;
  final String description;

  const ParsedSleepLog({
    required this.rawLog,
    required this.feeling,
    required this.hours,
    required this.completedAt,
    required this.description,
  });

  static ParsedSleepLog? tryParse(RoutineLog log) {
    // Check if this log relates to sleep tracking
    final hasFeeling = log.sleepFeeling != null;
    final isSleepId = log.routineId.startsWith('sleep_') || log.routineId == 'sleep';
    final hasSleptText = log.focusOrHighlight != null &&
        (log.focusOrHighlight!.toLowerCase().contains('slept') ||
            log.focusOrHighlight!.toLowerCase().contains('sleep'));

    if (!hasFeeling && !isSleepId && !hasSleptText) {
      return null;
    }

    final feeling = log.sleepFeeling ?? SleepFeeling.moderate;
    final text = log.focusOrHighlight ?? '';

    // Extract hours from focusOrHighlight
    double hours = 7.0;
    final regex = RegExp(
      r'Slept\s+([0-9\.\+\<\s\w]+?)\s*(?:hrs|hours)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      final valStr = match.group(1)?.trim() ?? '';
      if (valStr.toLowerCase().contains('less than 1')) {
        hours = 0.5;
      } else if (valStr.contains('10+')) {
        hours = 10.0;
      } else {
        final parsed = double.tryParse(valStr);
        if (parsed != null) {
          hours = parsed;
        }
      }
    }

    return ParsedSleepLog(
      rawLog: log,
      feeling: feeling,
      hours: hours,
      completedAt: log.completedAt,
      description: text,
    );
  }
}

class SleepAnalyticsScreen extends StatefulWidget {
  const SleepAnalyticsScreen({super.key});

  @override
  State<SleepAnalyticsScreen> createState() => _SleepAnalyticsScreenState();
}

class _SleepAnalyticsScreenState extends State<SleepAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedChartDayIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _copy(String english, String filipino) {
    final language = context.read<UserProvider>().preferredLanguage;
    return LanguageHelper.pick(language, english: english, filipino: filipino);
  }

  Color _colorForFeeling(SleepFeeling feeling) {
    switch (feeling) {
      case SleepFeeling.energized:
        return AppColors.honeyGold;
      case SleepFeeling.wellRested:
        return AppColors.sageGreen;
      case SleepFeeling.moderate:
        return AppColors.honeyAmber;
      case SleepFeeling.groggy:
        return const Color(0xFFE07A5F);
      case SleepFeeling.restless:
        return const Color(0xFF8D5B4C);
    }
  }

  List<ParsedSleepLog> _extractSleepLogs(List<RoutineLog> logs) {
    final list = <ParsedSleepLog>[];
    for (final log in logs) {
      final parsed = ParsedSleepLog.tryParse(log);
      if (parsed != null) {
        list.add(parsed);
      }
    }
    list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return list;
  }

  Future<void> _openSleepLogger() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SleepLogFlowScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmDeleteLog(ParsedSleepLog entry) async {
    final shouldDelete = await CozyConfirmSheet.show(
      context,
      title: _copy('Delete sleep log?', 'Burahin ang tala ng tulog?'),
      message: _copy(
        'This sleep entry will be removed from your logs and analytics.',
        'Matatanggal ang talang ito sa iyong kasaysayan at pagsusuri ng tulog.',
      ),
      confirmLabel: _copy('Delete', 'Burahin'),
      cancelLabel: _copy('Keep', 'Panatilihin'),
      isDestructive: true,
    );

    if (shouldDelete == true && mounted) {
      final provider = context.read<RoutinesProvider>();
      await provider.deleteLog(entry.rawLog.id);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final mascot = MascotInfo.getById(userProvider.selectedCompanion);
    final routinesProvider = Provider.of<RoutinesProvider>(context);
    final allSleepLogs = _extractSleepLogs(routinesProvider.logs);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _copy('Sleep Analytics', 'Pagsusuri ng Tulog'),
          style: AppTypography.heading3(context, isDark: isDark),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _copy('Log sleep', 'Magtala ng tulog'),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.honeyAmber, size: 26),
            onPressed: _openSleepLogger,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.honeyGold.withValues(alpha: isDark ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.honeyGold.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: isDark ? AppColors.honeyGold : AppColors.honeyAmber,
              unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              tabs: [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics_outlined, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _copy('Analytics', 'Pagsusuri'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _copy('History', 'Kasaysayan'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (allSleepLogs.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.honeyGold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${allSleepLogs.length}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSleepLogger,
        backgroundColor: AppColors.honeyGold,
        foregroundColor: AppColors.onHoney,
        elevation: 3,
        icon: const Icon(Icons.bedtime_rounded, size: 20),
        label: Text(
          _copy('Log Sleep', 'Magtala ng Tulog'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (routinesProvider.isLoading)
              const LinearProgressIndicator(minHeight: 2, color: AppColors.honeyAmber),
            if (routinesProvider.errorMessage != null)
              SyncStatusBanner(
                message: routinesProvider.errorMessage!,
                onRetry: routinesProvider.fetchRoutineLogs,
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAnalyticsTab(context, isDark, mascot, allSleepLogs),
                  _buildHistoryTab(context, isDark, mascot, allSleepLogs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ANALYTICS TAB
  // ===========================================================================
  Widget _buildAnalyticsTab(
    BuildContext context,
    bool isDark,
    MascotInfo mascot,
    List<ParsedSleepLog> logs,
  ) {
    if (logs.isEmpty) {
      return _buildEmptyState(context, isDark, mascot);
    }

    // Compute statistics
    final totalHours = logs.fold<double>(0.0, (sum, item) => sum + item.hours);
    final avgHours = totalHours / logs.length;

    final feelingCounts = <SleepFeeling, int>{};
    for (final log in logs) {
      feelingCounts[log.feeling] = (feelingCounts[log.feeling] ?? 0) + 1;
    }

    SleepFeeling primaryFeeling = SleepFeeling.moderate;
    int maxFeelingCount = 0;
    for (final entry in feelingCounts.entries) {
      if (entry.value > maxFeelingCount) {
        maxFeelingCount = entry.value;
        primaryFeeling = entry.key;
      }
    }

    final totalScore = logs.fold<int>(0, (sum, item) => sum + item.feeling.score);
    final avgScore = totalScore / logs.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mascot sleep insight banner
          _buildMascotInsightCard(context, isDark, mascot, avgHours, primaryFeeling, logs.length)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05),

          const SizedBox(height: 16),

          // Overview 4-metric grid
          _buildOverviewGrid(context, isDark, avgHours, primaryFeeling, logs.length, avgScore)
              .animate()
              .fadeIn(duration: 350.ms, delay: 50.ms),

          const SizedBox(height: 20),

          // 7-day sleep trend chart
          _buildWeeklyTrendChart(context, isDark, logs)
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 20),

          // Sleep feeling distribution breakdown
          _buildFeelingDistribution(context, isDark, feelingCounts, logs.length)
              .animate()
              .fadeIn(duration: 450.ms, delay: 150.ms),

          const SizedBox(height: 20),

          // Rest rituals & gentle tips
          _buildRestRitualsCard(context, isDark, mascot)
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildMascotInsightCard(
    BuildContext context,
    bool isDark,
    MascotInfo mascot,
    double avgHours,
    SleepFeeling primaryFeeling,
    int count,
  ) {
    String insightText;
    if (avgHours >= 7.0 && (primaryFeeling == SleepFeeling.wellRested || primaryFeeling == SleepFeeling.energized)) {
      insightText = _copy(
        "You've maintained deeply nourishing rest! Consistent sleep creates a peaceful cushion for your daily thoughts.",
        'Napakaganda ng iyong pahinga! Ang tuloy-tuloy na tulog ay nagbibigay ng payapang lakas sa iyong buong araw.',
      );
    } else if (avgHours < 6.0 || primaryFeeling == SleepFeeling.groggy || primaryFeeling == SleepFeeling.restless) {
      insightText = _copy(
        "Sleep has felt a bit limited lately. Take things gently today—short breathing pauses can offer a low-effort reset.",
        'Medyo kapos ang pahinga kamakailan. Magdahan-dahan muna ngayong araw—makakatulong ang sandaling paghinga.',
      );
    } else {
      insightText = _copy(
        "Tracking your nightly rhythms helps build steady daily energy. Remember: rest is about kindness, not perfection.",
        'Ang pagsubaybay sa iyong tulog ay nagpapatibay ng lakas. Tandaan: ang pahinga ay pag-aalaga, hindi pagsusulit.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: mascot.primaryColor.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: mascot.primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(mascot.materialIcon, color: mascot.primaryColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy('${mascot.name}\'s Sleep Check', 'Puna ni ${mascot.name} sa Tulog'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insightText,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(
    BuildContext context,
    bool isDark,
    double avgHours,
    SleepFeeling primaryFeeling,
    int count,
    double avgScore,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricTile(
              context,
              isDark,
              width: itemWidth,
              icon: Icons.access_time_filled_rounded,
              iconColor: AppColors.honeyAmber,
              title: _copy('Average Rest', 'Karaniwang Oras'),
              value: '${avgHours.toStringAsFixed(1)} hrs',
              subtitle: avgHours >= 7.0 && avgHours <= 9.0
                  ? _copy('Optimal Range', 'Tamang Saklaw')
                  : (avgHours < 7.0 ? _copy('Under 7 hrs', 'Mababa sa 7h') : _copy('Long rest', 'Mahabang tulog')),
            ),
            _buildMetricTile(
              context,
              isDark,
              width: itemWidth,
              icon: Icons.sentiment_satisfied_alt_rounded,
              iconColor: _colorForFeeling(primaryFeeling),
              title: _copy('Top Feeling', 'Pangunahing Pakiramdam'),
              value: primaryFeeling.label,
              subtitle: _copy('Most recorded', 'Pinakamadalas'),
            ),
            _buildMetricTile(
              context,
              isDark,
              width: itemWidth,
              icon: Icons.nights_stay_rounded,
              iconColor: AppColors.sageGreen,
              title: _copy('Nights Logged', 'Naitatalang Gabi'),
              value: '$count',
              subtitle: _copy('Total check-ins', 'Kabuuang tala'),
            ),
            _buildMetricTile(
              context,
              isDark,
              width: itemWidth,
              icon: Icons.star_rounded,
              iconColor: AppColors.honeyGold,
              title: _copy('Rest Index', 'Puntos ng Pahinga'),
              value: '${avgScore.toStringAsFixed(1)} / 5',
              subtitle: avgScore >= 4.0
                  ? _copy('Very Restorative', 'Napakahimbing')
                  : (avgScore >= 3.0 ? _copy('Moderate Care', 'Katamtaman') : _copy('Needs Gentle Rest', 'Kailangan ng kalinga')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    bool isDark, {
    required double width,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7-DAY SLEEP TRENDS CHART
  // ===========================================================================
  Widget _buildWeeklyTrendChart(
    BuildContext context,
    bool isDark,
    List<ParsedSleepLog> logs,
  ) {
    // Generate the last 7 days (including today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });

    // Find the latest log for each day
    final dayData = days.map((day) {
      final matching = logs.where((l) {
        final logDate = DateTime(l.completedAt.year, l.completedAt.month, l.completedAt.day);
        return logDate == day;
      }).toList();
      return matching.isNotEmpty ? matching.first : null;
    }).toList();

    ParsedSleepLog? selectedLog;
    if (_selectedChartDayIndex >= 0 && _selectedChartDayIndex < dayData.length) {
      selectedLog = dayData[_selectedChartDayIndex];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _copy('7-Day Sleep Rhythm', '7-Araw na Ritmo ng Tulog'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _copy('Tap a day to inspect hours & feeling', 'Pindutin ang araw para sa detalye'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.honeyGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _copy('Past 7 Days', 'Huling 7 Araw'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.honeyAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Bars
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final day = days[index];
                final log = dayData[index];
                final isToday = day == today;
                final isSelected = _selectedChartDayIndex == index;
                final hours = log?.hours ?? 0.0;
                // Max scale 12 hours
                final barRatio = (hours / 12.0).clamp(0.06, 1.0);
                final barColor = log != null ? _colorForFeeling(log.feeling) : (isDark ? Colors.white12 : Colors.black12);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedChartDayIndex = _selectedChartDayIndex == index ? -1 : index;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Hours label on top
                        if (log != null)
                          Text(
                            '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}h',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? barColor
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          )
                        else
                          const Text(
                            '—',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        const SizedBox(height: 6),

                        // The Bar
                        Container(
                          width: 22,
                          height: 90 * barRatio,
                          decoration: BoxDecoration(
                            color: isSelected ? barColor : barColor.withValues(alpha: log != null ? 0.75 : 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: isSelected ? 2 : 0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: barColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Day label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.honeyGold.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('E').format(day).substring(0, 1),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isToday
                                  ? AppColors.honeyAmber
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Selected day preview strip
          if (selectedLog != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    selectedLog.feeling.assetPath,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Icon(selectedLog!.feeling.icon, size: 28, color: AppColors.honeyAmber),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('EEEE, MMM d').format(selectedLog.completedAt)} • ${selectedLog.hours} hrs',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedLog.feeling.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _colorForFeeling(selectedLog.feeling),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // SLEEP QUALITY DISTRIBUTION
  // ===========================================================================
  Widget _buildFeelingDistribution(
    BuildContext context,
    bool isDark,
    Map<SleepFeeling, int> feelingCounts,
    int totalCount,
  ) {
    const options = [
      SleepFeeling.energized,
      SleepFeeling.wellRested,
      SleepFeeling.moderate,
      SleepFeeling.groggy,
      SleepFeeling.restless,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy('Sleep Quality Distribution', 'Distribusyon ng Kalidad ng Tulog'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _copy('How often each beemoji state occurred', 'Dalas ng bawat pakiramdam ng tulog'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 18),
          ...options.map((feeling) {
            final count = feelingCounts[feeling] ?? 0;
            final pct = totalCount > 0 ? (count / totalCount) : 0.0;
            final color = _colorForFeeling(feeling);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      feeling.assetPath,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(feeling.icon, size: 20, color: color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 82,
                    child: Text(
                      feeling.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 54,
                    child: Text(
                      '${(pct * 100).toInt()}% ($count)',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // REST RITUALS CARD
  // ===========================================================================
  Widget _buildRestRitualsCard(BuildContext context, bool isDark, MascotInfo mascot) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_rounded, color: AppColors.sageGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _copy('Sleep Hygiene Principles', 'Mga Gabay sa Mahimbing na Tulog'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRitualBullet(
            isDark,
            icon: Icons.wb_sunny_outlined,
            title: _copy('Consistent Wake Time', 'Pare-parehong Oras ng Gising'),
            description: _copy(
              'A stable morning wake time sets your internal clock better than forcing early sleep.',
              'Ang maayos na wake time ay nagtatakda ng rhythm ng katawan kaysa sa pilit na pagtulog nang maaga.',
            ),
          ),
          const SizedBox(height: 10),
          _buildRitualBullet(
            isDark,
            icon: Icons.phonelink_erase_rounded,
            title: _copy('Screen Wind-down', 'Pagbawas ng Screen Bago Matulog'),
            description: _copy(
              'Dimming bright devices 30 minutes before bed lets your natural melatonin rise comfortably.',
              'Ang pagpatay sa maliwanag na screen 30 minuto bago matulog ay nagpapadali sa pagkaantok.',
            ),
          ),
          const SizedBox(height: 10),
          _buildRitualBullet(
            isDark,
            icon: Icons.air_rounded,
            title: _copy('Low Pressure Rest', 'Pahingang Walang Pressure'),
            description: _copy(
              'Rest is not only sleep. Lying quietly with slow breathing restores the mind even on awake nights.',
              'Ang pahinga ay hindi lang tulog. Ang paghiga nang payapa ay nakakatulong din sa katawan.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRitualBullet(
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.honeyAmber),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HISTORY TAB
  // ===========================================================================
  Widget _buildHistoryTab(
    BuildContext context,
    bool isDark,
    MascotInfo mascot,
    List<ParsedSleepLog> logs,
  ) {
    if (logs.isEmpty) {
      return _buildEmptyState(context, isDark, mascot);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 84),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final entry = logs[index];
        final color = _colorForFeeling(entry.feeling);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  entry.feeling.assetPath,
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Icon(entry.feeling.icon, size: 40, color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('EEE, MMM d').format(entry.completedAt),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(entry.completedAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.feeling.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.hours} hrs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (entry.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
                onPressed: () => _confirmDeleteLog(entry),
                tooltip: _copy('Delete log', 'Burahin'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================
  Widget _buildEmptyState(BuildContext context, bool isDark, MascotInfo mascot) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: mascot.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bedtime_outlined,
                size: 54,
                color: mascot.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _copy('No sleep logs yet', 'Wala pang tala ng tulog'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _copy(
                'Tracking your nightly rest helps ${mascot.name} uncover patterns and suggest gentle daily paces.',
                'Ang pagtatala ng tulog ay tumutulong kay ${mascot.name} na magrekomenda ng tamang gabay sa araw.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openSleepLogger,
              icon: const Icon(Icons.add_rounded),
              label: Text(_copy('Log Your First Sleep', 'Itala ang Unang Tulog')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.honeyGold,
                foregroundColor: AppColors.onHoney,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
