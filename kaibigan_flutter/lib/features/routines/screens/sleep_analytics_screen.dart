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
import '../../insights/wellness_analytics.dart';
import '../../insights/wellness_insights_panel.dart';
import '../../settings/user_provider.dart';
import '../routine_model.dart';
import '../routines_provider.dart';
import '../sleep_insights.dart';
import 'sleep_energy_curve.dart';
import 'sleep_feedback_card.dart';
import 'sleep_log_flow_screen.dart';
import 'sleep_status_card.dart';

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
  final double? hours;
  final DateTime completedAt;
  final String description;

  static ParsedSleepLog? tryParse(RoutineLog log) {
    final text = log.focusOrHighlight ?? '';
    if (routineActivity(log) != 'sleep') return null;
    final hours = loggedSleepHours(log);
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
                    language: user.language,
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
    required this.language,
  });

  final List<ParsedSleepLog> logs;
  final MascotInfo mascot;
  final Color Function(SleepFeeling) colorForFeeling;
  final String Function(String, String) copy;
  final VoidCallback onLogSleep;
  final String language;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _EmptySleepState(
        mascot: mascot,
        copy: copy,
        onLogSleep: onLogSleep,
      );
    }
    final lastSeven = _lastSevenDays(logs);
    final recent =
        lastSeven.map((day) => day.log).whereType<ParsedSleepLog>().toList();
    final snapshot = WellnessAnalytics.build(
      now: DateTime.now(),
      routines: logs.map((log) => log.rawLog),
    );
    final insights = SleepInsights.build(
      logs.map((log) => log.rawLog).toList(),
      language: language,
    );
    return MobileContent(
      child: SingleChildScrollView(
        padding: MobileLayout.pageInsets(context, top: 10, bottom: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The verdict comes before the figures: a person who is short on
            // sleep should not have to work that out from three durations.
            SleepStatusCard(insights: insights, language: language),
            const SizedBox(height: 16),
            SleepMetricsRow(insights: insights, language: language),
            const SizedBox(height: 16),
            SleepTipsCard(insights: insights, language: language),
            const SizedBox(height: 16),
            if (insights.hasEnergyCurve) ...[
              SleepEnergyCurveCard(insights: insights),
              const SizedBox(height: 16),
            ],
            SleepFeedbackCard(insights: insights, language: language),
            const SizedBox(height: 16),
            if (insights.lastNight?.wakeTime != null) ...[
              _BedtimeCalculatorCard(
                wakeTime: insights.lastNight!.wakeTime!,
                copy: copy,
              ),
              const SizedBox(height: 16),
            ],
            _WeeklyRhythmCard(
              days: lastSeven,
              copy: copy,
            ),
            const SizedBox(height: 20),
            _QualityDistribution(
              logs: recent
                  .where((log) => log.rawLog.sleepFeeling != null)
                  .toList(),
              colorForFeeling: colorForFeeling,
              copy: copy,
            ),
            const SizedBox(height: 20),
            WellnessInsightsPanel(
              snapshot: snapshot,
              language: language,
              feature: 'sleep',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Works backwards from the wake time this person actually uses, so the
/// suggested bedtimes are about their morning, not a generic one.
class _BedtimeCalculatorCard extends StatelessWidget {
  const _BedtimeCalculatorCard({
    required this.wakeTime,
    required this.copy,
  });

  final TimeOfDay wakeTime;
  final String Function(String, String) copy;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final options = SleepCycleCalculator.bedtimesFor(wakeTime);

    return KaibiganSurface(
      key: const ValueKey('sleep-bedtime-calculator'),
      tone: KaibiganSurfaceTone.elevated,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 18,
                color: palette.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy('Bedtime calculator', 'Kalkulador ng oras ng tulog'),
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            copy(
              'To wake at ${SleepInsights.formatTime(wakeTime)} at the end of '
                  'a sleep cycle rather than the middle of one.',
              'Para magising nang ${SleepInsights.formatTime(wakeTime)} sa '
                  'dulo ng sleep cycle, hindi sa gitna nito.',
            ),
            style: text.bodySmall?.copyWith(
              color: palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: option.cycles == 5
                          ? palette.accentSubtle
                          : palette.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: option.cycles == 5
                            ? palette.accent
                            : palette.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          SleepInsights.formatTime(option.bedtime),
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${option.cycles} × 90m · '
                          '${SleepInsights.formatHours(option.hours)}',
                          style: text.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
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
    final date = DateTime(today.year, today.month, today.day - 6 + index);
    ParsedSleepLog? match;
    for (final log in logs) {
      if (!log.completedAt.isAfter(now) && DateUtils.isSameDay(log.completedAt, date)) {
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
                        'Each row shows your latest sleep entry that day. Missing hours stay blank.',
                        'Pinakahuling tala ng tulog sa bawat araw. Blangko ang oras na hindi naitala.',
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
              final status = copy('Logged', 'Naitala');
              final statusColor = palette.textSecondary;              return Container(
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
                                  _sleepDurationLabel(log, copy),
                                  style: text.bodyMedium?.copyWith(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$status · ${_sleepFeelingLabel(log, copy)}',
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
              copy: copy,
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
    required this.copy,
    required this.deleteLabel,
    required this.onDelete,
  });
  final ParsedSleepLog entry;
  final Color color;
  final String Function(String, String) copy;
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
                      label: _sleepFeelingLabel(entry, copy),
                      color: color,
                    ),
                    _HistoryPill(
                      label: _sleepDurationLabel(entry, copy),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16, color: palette.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      copy('Takes about 20 seconds', 'Mga 20 segundo lamang'),
                      style: text.bodySmall?.copyWith(color: palette.textMuted),
                    ),
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

String _sleepDurationLabel(ParsedSleepLog log, String Function(String, String) copy) {
  if (log.hours != null) return copy('${log.hours!.toStringAsFixed(1)} hours', '${log.hours!.toStringAsFixed(1)} oras');
  final content = log.description.toLowerCase();
  if (content.startsWith('slept less than 1')) return copy('Less than 1 hour', 'Wala pang 1 oras');
  if (content.startsWith('slept 10+')) return copy('10+ hours', '10+ oras');
  return copy('Duration not logged', 'Hindi naitala ang tagal');
}

String _sleepFeelingLabel(ParsedSleepLog log, String Function(String, String) copy) {
  if (log.rawLog.sleepFeeling == null) return copy('Quality not logged', 'Hindi naitala ang kalidad');
  return switch (log.feeling) {
    SleepFeeling.restless => copy('Restless', 'Hindi mapakali'),
    SleepFeeling.groggy => copy('A bit groggy', 'Medyo antok'),
    SleepFeeling.moderate => copy('Okay', 'Katamtaman'),
    SleepFeeling.wellRested => copy('Well rested', 'Nakapagpahinga'),
    SleepFeeling.energized => copy('Energized', 'Masigla'),
  };
}