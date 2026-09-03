import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/cozy_confirm_sheet.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../../../core/widgets/mobile_layout.dart';
import '../../../core/widgets/sync_status_banner.dart';
import '../../companion/companion_model.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';
import 'sleep_log_flow_screen.dart';

/// Stable adapter for legacy and current sleep-log storage formats.
class ParsedSleepLog {
  const ParsedSleepLog({
    required this.rawLog,
    required this.feeling,
    required this.hours,
    required this.completedAt,
    required this.description,
  });

  final RoutineLog rawLog;
  final SleepFeeling feeling;
  final double hours;
  final DateTime completedAt;
  final String description;

  static ParsedSleepLog? tryParse(RoutineLog log) {
    final text = log.focusOrHighlight ?? '';
    final isSleepLog = log.sleepFeeling != null ||
        log.routineId == 'sleep' ||
        log.routineId.startsWith('sleep_') ||
        text.toLowerCase().contains('slept') ||
        text.toLowerCase().contains('sleep');
    if (!isSleepLog) return null;

    var hours = 7.0;
    final match = RegExp(
      r'Slept\s+(.+?)\s*(?:hrs|hours)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final value = match.group(1)?.trim().toLowerCase() ?? '';
      if (value.contains('less than 1') || value.contains('under 1')) {
        hours = .5;
      } else if (value.contains('10+')) {
        hours = 10;
      } else {
        hours = double.tryParse(value) ?? hours;
      }
    }

    return ParsedSleepLog(
      rawLog: log,
      feeling: log.sleepFeeling ?? SleepFeeling.moderate,
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
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _copy(String english, String filipino) => LanguageHelper.pick(
        context.read<UserProvider>().preferredLanguage,
        english: english,
        filipino: filipino,
      );

  List<ParsedSleepLog> _sleepLogs(List<RoutineLog> logs) {
    final result = logs.map(ParsedSleepLog.tryParse).whereType<ParsedSleepLog>()
      ..toList();
    final sorted = result.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted;
  }

  Future<void> _openLogger() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SleepLogFlowScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(ParsedSleepLog entry) async {
    final approved = await CozyConfirmSheet.show(
      context,
      title: _copy('Delete sleep log?', 'Burahin ang tala ng tulog?'),
      message: _copy(
        'This entry will be removed from your history and insights.',
        'Matatanggal ang talang ito sa iyong kasaysayan at mga insight.',
      ),
      confirmLabel: _copy('Delete', 'Burahin'),
      cancelLabel: _copy('Keep', 'Panatilihin'),
      isDestructive: true,
    );
    if (approved == true && mounted) {
      await context.read<RoutinesProvider>().deleteLog(entry.rawLog.id);
    }
  }

  Color _feelingColor(SleepFeeling feeling, KaibiganPalette palette) {
    return switch (feeling) {
      SleepFeeling.energized => AppColors.honeyGold,
      SleepFeeling.wellRested => palette.botanical,
      SleepFeeling.moderate => palette.warning,
      SleepFeeling.groggy => const Color(0xFFD97862),
      SleepFeeling.restless => const Color(0xFF9A6D82),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final provider = context.watch<RoutinesProvider>();
    final user = context.watch<UserProvider>();
    final mascot = MascotInfo.getById(user.selectedCompanion);
    final logs = _sleepLogs(provider.logs);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: _copy('Back', 'Bumalik'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _copy('Sleep Analytics', 'Pagsusuri ng Tulog'),
          style: AppTypography.heading3(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _copy('Log sleep', 'Magtala ng tulog'),
            onPressed: _openLogger,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('sleep-log-button'),
        onPressed: _openLogger,
        backgroundColor: AppColors.honeyGold,
        foregroundColor: AppColors.onHoney,
        icon: const Icon(Icons.nightlight_round),
        label: Text(_copy('Log Sleep', 'Magtala ng Tulog')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (provider.isLoading) const LinearProgressIndicator(minHeight: 2),
            if (provider.errorMessage != null)
              SyncStatusBanner(
                message: provider.errorMessage!,
                onRetry: provider.fetchRoutineLogs,
              ),
            MobileContent(
              padding: EdgeInsets.fromLTRB(
                MobileLayout.horizontalPadding(context),
                6,
                MobileLayout.horizontalPadding(context),
                8,
              ),
              child: _SegmentedTabs(
                controller: _tabs,
                historyCount: logs.length,
                analyticsLabel: _copy('Insights', 'Mga Insight'),
                historyLabel: _copy('History', 'Kasaysayan'),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _AnalyticsTab(
                    logs: logs,
                    mascot: mascot,
                    colorForFeeling: (value) => _feelingColor(value, palette),
                    copy: _copy,
                    onLogSleep: _openLogger,
                  ),
                  _HistoryTab(
                    logs: logs,
                    mascot: mascot,
                    colorForFeeling: (value) => _feelingColor(value, palette),
                    copy: _copy,
                    onDelete: _delete,
                    onLogSleep: _openLogger,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.controller,
    required this.historyCount,
    required this.analyticsLabel,
    required this.historyLabel,
  });

  final TabController controller;
  final int historyCount;
  final String analyticsLabel;
  final String historyLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: TabBar(
        controller: controller,
        labelPadding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insights_rounded, size: 17),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    analyticsLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_rounded, size: 17),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    historyLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (historyCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: palette.accentSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$historyCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({
    required this.logs,
    required this.mascot,
    required this.colorForFeeling,
    required this.copy,
    required this.onLogSleep,
  });

  final List<ParsedSleepLog> logs;
  final MascotInfo mascot;
  final Color Function(SleepFeeling) colorForFeeling;
  final String Function(String, String) copy;
  final VoidCallback onLogSleep;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _EmptySleepState(
        mascot: mascot,
        copy: copy,
        onLogSleep: onLogSleep,
      );
    }
    final average =
        logs.fold<double>(0, (sum, log) => sum + log.hours) / logs.length;
    final commonFeeling = _mostCommonFeeling(logs);
    final lastSeven = _lastSevenDays(logs);
    final recentCount = lastSeven.where((day) => day.log != null).length;

    return MobileContent(
      child: SingleChildScrollView(
        padding: MobileLayout.pageInsets(context, top: 10, bottom: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InsightHero(
              mascot: mascot,
              average: average,
              feeling: commonFeeling,
              count: logs.length,
              copy: copy,
            ),
            const SizedBox(height: 14),
            _OverviewMetrics(
              average: average,
              commonFeeling: commonFeeling,
              recentCount: recentCount,
              colorForFeeling: colorForFeeling,
              copy: copy,
            ),
            const SizedBox(height: 20),
            _WeeklyRhythmCard(
              days: lastSeven,
              copy: copy,
            ),
            const SizedBox(height: 20),
            _QualityDistribution(
              logs: logs,
              colorForFeeling: colorForFeeling,
              copy: copy,
            ),
            const SizedBox(height: 20),
            _SleepPrinciples(copy: copy),
          ],
        ),
      ),
    );
  }

  SleepFeeling _mostCommonFeeling(List<ParsedSleepLog> values) {
    final counts = <SleepFeeling, int>{};
    for (final log in values) {
      counts[log.feeling] = (counts[log.feeling] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class _InsightHero extends StatelessWidget {
  const _InsightHero({
    required this.mascot,
    required this.average,
    required this.feeling,
    required this.count,
    required this.copy,
  });

  final MascotInfo mascot;
  final double average;
  final SleepFeeling feeling;
  final int count;
  final String Function(String, String) copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final message = average >= 7 && feeling.score >= 4
        ? copy(
            'Your recent rest looks nourishing. Protect the routines that are helping this rhythm feel steady.',
            'Mukhang nakapagpapalakas ang iyong pahinga. Panatilihin ang mga rutinang tumutulong sa rhythm na ito.',
          )
        : average < 6 || feeling.score <= 2
            ? copy(
                'Rest has felt limited lately. A gentler pace and one small wind-down cue may help tonight.',
                'Medyo kapos ang pahinga kamakailan. Makakatulong ang mas banayad na araw at simpleng wind-down cue.',
              )
            : copy(
                'Your sleep rhythm is taking shape. Keep checking in—patterns become more useful with consistency.',
                'Unti-unting lumilinaw ang ritmo ng iyong tulog. Magpatuloy sa pagtatala para mas makita ang pattern.',
              );

    return Semantics(
      container: true,
      label: '${mascot.name} sleep insight. $message',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.accentSubtle, palette.botanicalSubtle],
          ),
          borderRadius: BorderRadius.circular(KaibiganRadius.feature),
          border: Border.all(color: palette.accent.withValues(alpha: .22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: palette.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    mascot.materialIcon,
                    color: mascot.primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${mascot.name}'s Sleep Check",
                        style: text.titleMedium,
                      ),
                      Text(
                        copy(
                          'Based on $count ${count == 1 ? 'check-in' : 'check-ins'}',
                          'Batay sa $count ${count == 1 ? 'tala' : 'mga tala'}',
                        ),
                        style: text.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.auto_awesome_rounded, color: palette.accent),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: text.bodyMedium?.copyWith(
                color: palette.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetrics extends StatelessWidget {
  const _OverviewMetrics({
    required this.average,
    required this.commonFeeling,
    required this.recentCount,
    required this.colorForFeeling,
    required this.copy,
  });

  final double average;
  final SleepFeeling commonFeeling;
  final int recentCount;
  final Color Function(SleepFeeling) colorForFeeling;
  final String Function(String, String) copy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.bedtime_outlined,
            label: copy('Average Rest', 'Karaniwang Pahinga'),
            value: '${average.toStringAsFixed(1)} hrs',
            supporting: copy('Across all logs', 'Sa lahat ng tala'),
            accent: context.kaibigan.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: commonFeeling.icon,
            label: copy('Usual Feeling', 'Madalas na Pakiramdam'),
            value: commonFeeling.label,
            supporting: copy('$recentCount of 7 days logged',
                '$recentCount sa 7 araw ang may tala'),
            accent: colorForFeeling(commonFeeling),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.supporting,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String supporting;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return KaibiganSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: text.labelMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            supporting,
            maxLines: 2,
            style: text.bodySmall?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SleepDay {
  const _SleepDay(this.date, this.log);
  final DateTime date;
  final ParsedSleepLog? log;
}

List<_SleepDay> _lastSevenDays(List<ParsedSleepLog> logs) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(7, (index) {
    final date = today.subtract(Duration(days: 6 - index));
    ParsedSleepLog? match;
    for (final log in logs) {
      if (DateUtils.isSameDay(log.completedAt, date)) {
        match = log;
        break;
      }
    }
    return _SleepDay(date, match);
  });
}

class _WeeklyRhythmCard extends StatelessWidget {
  const _WeeklyRhythmCard({
    required this.days,
    required this.copy,
  });

  final List<_SleepDay> days;
  final String Function(String, String) copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final loggedCount = days.where((day) => day.log != null).length;
    return KaibiganSurface(
      key: const ValueKey('sleep-rhythm-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy('Your last 7 nights', 'Huling 7 gabi mo'),
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      copy(
                        'Each row shows what you logged and how it compares with your 7–9 hour guide.',
                        'Makikita sa bawat hanay ang tala mo at paghahambing nito sa 7–9 oras na gabay.',
                      ),
                      style: text.bodySmall?.copyWith(color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.botanicalSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  copy('$loggedCount of 7 logged',
                      '$loggedCount sa 7 ang may tala'),
                  style: text.labelSmall?.copyWith(
                    color: palette.accentStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            key: const ValueKey('sleep-rhythm-list'),
            children: List.generate(days.length, (index) {
              final day = days[index];
              final log = day.log;
              final isToday = DateUtils.isSameDay(day.date, DateTime.now());
              final status = log == null
                  ? null
                  : log.hours < 7
                      ? copy('Below guide', 'Kulang sa gabay')
                      : log.hours <= 9
                          ? copy('Within guide', 'Pasok sa gabay')
                          : copy('Above guide', 'Higit sa gabay');
              final statusColor = log == null
                  ? palette.textMuted
                  : log.hours >= 7 && log.hours <= 9
                      ? palette.success
                      : palette.warning;
              return Container(
                key: ValueKey('sleep-rhythm-day-$index'),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: index == days.length - 1
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: palette.border.withValues(alpha: .72),
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday
                                ? copy('Today', 'Ngayon')
                                : DateFormat('EEE').format(day.date),
                            style: text.bodyMedium?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d').format(day.date),
                            style: text.bodySmall?.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: log == null
                          ? Text(
                              copy('No entry', 'Walang tala'),
                              textAlign: TextAlign.end,
                              style: text.bodyMedium?.copyWith(
                                color: palette.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${log.hours.toStringAsFixed(1)} hours',
                                  style: text.bodyMedium?.copyWith(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$status · ${log.feeling.label}',
                                  textAlign: TextAlign.end,
                                  style: text.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _QualityDistribution extends StatelessWidget {
  const _QualityDistribution({
    required this.logs,
    required this.colorForFeeling,
    required this.copy,
  });

  final List<ParsedSleepLog> logs;
  final Color Function(SleepFeeling) colorForFeeling;
  final String Function(String, String) copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final counts = <SleepFeeling, int>{};
    for (final log in logs) {
      counts[log.feeling] = (counts[log.feeling] ?? 0) + 1;
    }
    return KaibiganSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy('Sleep Quality Distribution',
                'Distribusyon ng Kalidad ng Tulog'),
            style: text.titleMedium,
          ),
          const SizedBox(height: 3),
          Text(
            copy('How your mornings have felt',
                'Kung ano ang pakiramdam ng iyong mga umaga'),
            style: text.bodySmall?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: 18),
          for (final feeling in SleepFeeling.values.reversed) ...[
            _DistributionRow(
              feeling: feeling,
              count: counts[feeling] ?? 0,
              total: logs.length,
              color: colorForFeeling(feeling),
            ),
            if (feeling != SleepFeeling.restless) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.feeling,
    required this.count,
    required this.total,
    required this.color,
  });

  final SleepFeeling feeling;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final ratio = total == 0 ? 0.0 : count / total;
    return Semantics(
      label: '${feeling.label}, ${(ratio * 100).round()} percent, $count logs',
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(feeling.icon, size: 15, color: color),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 82,
            child: Text(
              feeling.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 9,
                backgroundColor: palette.surfaceSubtle,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 36,
            child: Text(
              '${(ratio * 100).round()}%',
              textAlign: TextAlign.end,
              style: text.labelSmall?.copyWith(color: palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepPrinciples extends StatelessWidget {
  const _SleepPrinciples({required this.copy});
  final String Function(String, String) copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return KaibiganSurface(
      key: const ValueKey('sleep-principles-card'),
      tone: KaibiganSurfaceTone.accent,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.pollenGlow.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: AppColors.onHoney,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  copy('Sleep Hygiene Principles',
                      'Mga Gabay sa Mahimbing na Tulog'),
                  style: text.titleMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _Principle(
            icon: Icons.wb_sunny_outlined,
            title:
                copy('Anchor your wake time', 'Panatilihin ang oras ng gising'),
            body: copy(
              'A steady morning cue can support your body clock—even after a rough night.',
              'Ang pare-parehong oras ng gising ay tumutulong sa body clock kahit hindi maganda ang tulog.',
            ),
          ),
          const SizedBox(height: 13),
          _Principle(
            icon: Icons.brightness_4_outlined,
            title:
                copy('Lower the evening signal', 'Bawasan ang liwanag sa gabi'),
            body: copy(
              'Dim light and quiet screens before bed to make winding down easier.',
              'Bawasan ang liwanag at screen bago matulog para mas madaling magpahinga.',
            ),
          ),
          const SizedBox(height: 13),
          _Principle(
            icon: Icons.self_improvement_rounded,
            title: copy('Release the pressure', 'Bawasan ang pressure'),
            body: copy(
              'Quiet rest still counts. Your log is a guide, never a grade.',
              'Mahalaga rin ang tahimik na pahinga. Gabay ang tala, hindi marka.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Principle extends StatelessWidget {
  const _Principle({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 19, color: AppColors.honeyAmber),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.labelLarge?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.logs,
    required this.mascot,
    required this.colorForFeeling,
    required this.copy,
    required this.onDelete,
    required this.onLogSleep,
  });

  final List<ParsedSleepLog> logs;
  final MascotInfo mascot;
  final Color Function(SleepFeeling) colorForFeeling;
  final String Function(String, String) copy;
  final ValueChanged<ParsedSleepLog> onDelete;
  final VoidCallback onLogSleep;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _EmptySleepState(
        mascot: mascot,
        copy: copy,
        onLogSleep: onLogSleep,
      );
    }
    return MobileContent(
      child: ListView.builder(
        padding: MobileLayout.pageInsets(context, top: 12, bottom: 104),
        itemCount: logs.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: KaibiganSectionHeader(
                title: copy('Your sleep story', 'Iyong kuwento ng tulog'),
                description: copy(
                  '${logs.length} ${logs.length == 1 ? 'check-in' : 'check-ins'}, newest first',
                  '${logs.length} ${logs.length == 1 ? 'tala' : 'mga tala'}, pinakabago muna',
                ),
              ),
            );
          }
          final entry = logs[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HistoryEntry(
              entry: entry,
              color: colorForFeeling(entry.feeling),
              deleteLabel: copy('Delete log', 'Burahin ang tala'),
              onDelete: () => onDelete(entry),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({
    required this.entry,
    required this.color,
    required this.deleteLabel,
    required this.onDelete,
  });
  final ParsedSleepLog entry;
  final Color color;
  final String deleteLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return KaibiganSurface(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(
              entry.feeling.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                entry.feeling.icon,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(entry.completedAt),
                  style: text.titleSmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HistoryPill(
                      label: entry.feeling.label,
                      color: color,
                    ),
                    _HistoryPill(
                      label: '${entry.hours.toStringAsFixed(1)} hrs',
                      color: palette.textSecondary,
                    ),
                    _HistoryPill(
                      label: DateFormat('h:mm a').format(entry.completedAt),
                      color: palette.textMuted,
                    ),
                  ],
                ),
                if (entry.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: palette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: deleteLabel,
            onPressed: onDelete,
            icon: Icon(
              Icons.more_horiz_rounded,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _EmptySleepState extends StatelessWidget {
  const _EmptySleepState({
    required this.mascot,
    required this.copy,
    required this.onLogSleep,
  });
  final MascotInfo mascot;
  final String Function(String, String) copy;
  final VoidCallback onLogSleep;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return MobileContent(
      child: Center(
        child: SingleChildScrollView(
          padding: MobileLayout.pageInsets(context, top: 28, bottom: 100),
          child: Column(
            children: [
              Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.accentSubtle, palette.botanicalSubtle],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 54,
                      color: palette.accent,
                    ),
                    Positioned(
                      right: 19,
                      top: 18,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: palette.botanical,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                copy('No sleep logs yet', 'Wala pang tala ng tulog'),
                style: text.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                copy(
                  'Your first check-in gives ${mascot.name} a starting point. A simple estimate is enough.',
                  'Ang unang tala ay magiging simula para kay ${mascot.name}. Sapat na ang simpleng pagtatantiya.',
                ),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onLogSleep,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  copy('Log Your First Sleep', 'Itala ang Unang Tulog'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16, color: palette.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    copy('Takes about 20 seconds', 'Mga 20 segundo lamang'),
                    style: text.bodySmall?.copyWith(color: palette.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
