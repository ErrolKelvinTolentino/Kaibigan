import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_feature_banner.dart';
import '../../core/widgets/cozy_motion.dart';
import '../companion/companion_model.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../journaling/journal_provider.dart';
import '../mood_tracking/mood_provider.dart';
import '../routines/routines_provider.dart';
import '../settings/user_provider.dart';
import 'weekly_reflection_service.dart';

class WeeklyReflectionScreen extends StatefulWidget {
  const WeeklyReflectionScreen({super.key});

  @override
  State<WeeklyReflectionScreen> createState() => _WeeklyReflectionScreenState();
}

class _WeeklyReflectionScreenState extends State<WeeklyReflectionScreen> {
  bool _isLoadingSavedReflection = true;
  bool _isGenerating = false;
  String? _aiReflection;
  String? _generationError;
  DateTime? _savedAt;
  bool _createdOnDevice = false;
  String? _loadedStorageKey;
  String? _scheduledStorageKey;

  String _copy(String language, String english, String filipino) =>
      LanguageHelper.pick(language, english: english, filipino: filipino);

  String _storageKey(WeeklyReflectionSnapshot snapshot) {
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id ?? 'local'
        : 'local';
    return 'weekly_reflection_${userId}_${DateFormat('yyyyMMdd').format(snapshot.start)}';
  }

  Future<void> _loadSavedReflection(
    WeeklyReflectionSnapshot snapshot,
    String storageKey,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(storageKey);
    String? reflection;
    DateTime? savedAt;
    var createdOnDevice = false;

    if (saved != null && saved.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(saved);
        if (decoded is Map<String, dynamic>) {
          reflection = decoded['text']?.toString();
          savedAt = DateTime.tryParse(decoded['savedAt']?.toString() ?? '');
          createdOnDevice = decoded['origin'] == 'device';
        }
      } catch (_) {
        // Version 1 stored the reflection as a plain string.
        reflection = saved;
      }

      if (reflection == null ||
          WeeklyReflectionNarrative.tryParse(reflection) == null) {
        // Earlier builds persisted the generic companion fallback. It is not
        // a weekly analysis, so quietly migrate it out instead of showing it.
        await preferences.remove(storageKey);
        reflection = null;
        savedAt = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _aiReflection = reflection;
      _savedAt = savedAt;
      _createdOnDevice = createdOnDevice;
      _loadedStorageKey = storageKey;
      _scheduledStorageKey = null;
      _isLoadingSavedReflection = false;
    });
  }

  Future<void> _generate(WeeklyReflectionSnapshot snapshot) async {
    final user = context.read<UserProvider>();
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });
    var createdOnDevice = false;
    String reflection;
    try {
      final reply = await AIService.generateCompanionReply(
        userText: snapshot.toCompactPrompt(language: user.language),
        companionId: user.selectedCompanion,
        language: user.language,
        mode: CompanionMode.weeklyReflection,
        useReasoning: true,
      );
      if (reply.isOffline) throw const _WeeklyReflectionOfflineException();
      reflection = reply.text.trim();
      if (WeeklyReflectionNarrative.tryParse(reflection) == null) {
        throw const FormatException('Incomplete weekly reflection response.');
      }
    } catch (_) {
      reflection = WeeklyReflectionService.buildLocalNarrative(
        snapshot,
        language: user.language,
      ).toMarkdown();
      createdOnDevice = true;
    }

    try {
      final savedAt = DateTime.now();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey(snapshot),
        jsonEncode({
          'version': 2,
          'text': reflection,
          'savedAt': savedAt.toIso8601String(),
          'origin': createdOnDevice ? 'device' : 'companion',
        }),
      );
      if (mounted) {
        setState(() {
          _aiReflection = reflection;
          _savedAt = savedAt;
          _createdOnDevice = createdOnDevice;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _generationError = _copy(
            user.language,
            'The reflection was created, but it could not be saved. Please try again.',
            'Nagawa ang pagninilay, pero hindi ito ma-save. Subukan muli.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _deleteSaved(WeeklyReflectionSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey(snapshot));
    if (mounted) {
      setState(() {
        _aiReflection = null;
        _savedAt = null;
        _createdOnDevice = false;
        _generationError = null;
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<MoodProvider>().fetchMoodLogs(),
      context.read<JournalProvider>().fetchJournalEntries(),
      context.read<GratitudeProvider>().fetchGratitudeEntries(),
      context.read<RoutinesProvider>().fetchRoutineLogs(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>();
    final language = user.language;
    final snapshot = WeeklyReflectionService.build(
      now: DateTime.now(),
      moods: context.watch<MoodProvider>().logs,
      journals: context.watch<JournalProvider>().allEntries,
      gratitudes: context.watch<GratitudeProvider>().entries,
      routines: context.watch<RoutinesProvider>().logs,
    );
    final storageKey = _storageKey(snapshot);
    if (_loadedStorageKey != storageKey && _scheduledStorageKey != storageKey) {
      _scheduledStorageKey = storageKey;
      _isLoadingSavedReflection = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadSavedReflection(snapshot, storageKey),
      );
    }

    final dateRange =
        '${DateFormat('MMM d').format(snapshot.start)} – ${DateFormat('MMM d').format(snapshot.endExclusive.subtract(const Duration(days: 1)))}';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        title:
            Text(_copy(language, 'Weekly reflection', 'Lingguhang pagninilay')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.honeyAmber,
          onRefresh: _refreshData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              CozyFeatureBanner(
                eyebrow: dateRange,
                title: _copy(language, 'Your week, gently connected',
                    'Ang iyong linggo, maingat na pinag-ugnay'),
                subtitle: _copy(
                  language,
                  'See patterns across mood, rest, routines, gratitude, and reflection.',
                  'Tingnan ang banayad na ugnayan ng damdamin, pahinga, routine, pasasalamat, at pagninilay.',
                ),
                placeholderLabel: 'weekly-reflection',
                placeholderIcon: Icons.auto_graph_rounded,
                accent: AppColors.honeyAmber,
              ),
              const SizedBox(height: 22),
              if (!snapshot.hasData)
                _emptyState(language, isDark)
              else ...[
                Text(
                  _copy(language, 'What this week suggests',
                      'Ipinapahiwatig ng linggo'),
                  style: AppTypography.titleMedium(context, isDark: isDark),
                ),
                const SizedBox(height: 10),
                ..._observations(snapshot, language).asMap().entries.map(
                      (entry) => CozyEntrance(
                        delay: Duration(milliseconds: 50 * entry.key),
                        child: _observationCard(entry.value, isDark),
                      ),
                    ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    childrenPadding: const EdgeInsets.only(top: 4, bottom: 12),
                    leading: const Icon(Icons.insights_outlined),
                    title: Text(
                      _copy(language, 'See the numbers',
                          'Tingnan ang mga bilang'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _copy(
                        language,
                        'Optional context behind these observations',
                        'Opsyonal na konteksto ng mga obserbasyon',
                      ),
                    ),
                    children: [
                      LayoutBuilder(builder: (context, constraints) {
                        final width = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _metricCard(
                                width,
                                Icons.sentiment_satisfied_alt_rounded,
                                _score(snapshot.averageMood),
                                _copy(language, 'Average mood',
                                    'Karaniwang mood'),
                                AppColors.honeyAmber,
                                isDark),
                            _metricCard(
                                width,
                                Icons.bedtime_rounded,
                                _score(snapshot.averageSleep),
                                _copy(language, 'Rest quality',
                                    'Kalidad ng pahinga'),
                                AppColors.honeyGold,
                                isDark),
                            _metricCard(
                                width,
                                Icons.menu_book_rounded,
                                '${snapshot.journalEntries}',
                                _copy(language, 'Journal entries', 'Mga tala'),
                                AppColors.honeyAmber,
                                isDark),
                            _metricCard(
                                width,
                                Icons.check_circle_rounded,
                                '${snapshot.completedRoutines}',
                                _copy(language, 'Routines completed',
                                    'Natapos na routine'),
                                AppColors.warmHoney,
                                isDark),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _privacyNote(language, isDark),
                const SizedBox(height: 18),
                _aiSection(snapshot, user, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _score(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)}/5';

  Widget _metricCard(double width, IconData icon, String value, String label,
      Color accent, bool isDark) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: accent, size: 22),
        const SizedBox(height: 12),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.textPrimaryLight)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight)),
      ]),
    );
  }

  List<_Observation> _observations(
      WeeklyReflectionSnapshot snapshot, String language) {
    final items = <_Observation>[];
    items.add(_Observation(
      Icons.fact_check_outlined,
      _copy(language, 'How much this week can tell us',
          'Gaano karami ang masasabi ng linggong ito'),
      _copy(
        language,
        snapshot.activeDays >= 5
            ? '${snapshot.activeDays} of 7 days contain a log, so repeated patterns are more useful than a single check-in.'
            : 'Only ${snapshot.activeDays} of 7 days contain a log. Treat the observations below as leads to test—not conclusions.',
        '${snapshot.activeDays} sa 7 araw ang may tala. Ituring ang mga obserbasyon bilang susubukan, hindi konklusyon.',
      ),
    ));
    if (snapshot.averageEnergy != null || snapshot.averageStress != null) {
      final energy = snapshot.averageEnergy?.toStringAsFixed(1) ?? '—';
      final stress = snapshot.averageStress?.toStringAsFixed(1) ?? '—';
      items.add(_Observation(
        Icons.balance_rounded,
        _copy(language, 'Energy and demand', 'Lakas at bigat'),
        _copy(
          language,
          'Logged energy averaged $energy/5 while stress averaged $stress/5. Next week, log one check-in before and after your busiest period to see whether that gap repeats.',
          'Ang karaniwang energy ay $energy/5 at stress ay $stress/5. Sa susunod na linggo, mag-log bago at pagkatapos ng pinakaabalang oras upang makita kung mauulit ang agwat.',
        ),
      ));
    }
    if (snapshot.moodTrend != null && snapshot.moodTrend!.abs() >= 0.25) {
      final rising = snapshot.moodTrend! > 0;
      items.add(_Observation(
        Icons.trending_up_rounded,
        _copy(
            language,
            rising ? 'A gentler finish' : 'A heavier finish',
            rising
                ? 'Mas magaan ang pagtatapos'
                : 'Mas mabigat ang pagtatapos'),
        _copy(
          language,
          rising
              ? 'Your later mood check-ins were a little higher than your earlier ones.'
              : 'Your later mood check-ins were a little lower than your earlier ones. Extra rest may be worth protecting.',
          rising
              ? 'Bahagyang mas mataas ang mga huling mood check-in kaysa sa mga nauna.'
              : 'Bahagyang mas mababa ang mga huling mood check-in. Maaaring makatulong ang pagprotekta sa pahinga.',
        ),
      ));
    }
    if (snapshot.pairedSleepMoodDays >= 3 &&
        snapshot.sleepMoodDelta != null &&
        snapshot.sleepMoodDelta!.abs() >= 0.25) {
      final positive = snapshot.sleepMoodDelta! > 0;
      items.add(_Observation(
        Icons.nights_stay_rounded,
        _copy(language, 'Rest and mood', 'Pahinga at mood'),
        _copy(
          language,
          positive
              ? 'On days with better logged sleep, your logged mood was also a little higher.'
              : 'Your sleep and mood logs did not move together this week—and that is useful to notice too.',
          positive
              ? 'Sa mga araw na mas maayos ang naitalang tulog, bahagyang mas mataas din ang naitalang mood.'
              : 'Hindi magkasabay ang galaw ng tulog at mood logs ngayong linggo—mahalaga ring mapansin iyon.',
        ),
      ));
    }
    if (snapshot.pairedRoutineMoodDays >= 3 &&
        snapshot.routineMoodDelta != null &&
        snapshot.routineMoodDelta!.abs() >= 0.25) {
      final positive = snapshot.routineMoodDelta! > 0;
      items.add(_Observation(
        Icons.hive_rounded,
        _copy(language, 'Daily anchors', 'Araw-araw na sandigan'),
        _copy(
          language,
          positive
              ? 'Your logged mood was a little higher on routine days. This is an observation, not a conclusion.'
              : 'Routine days looked a little heavier in your mood logs. The routine may be supporting you on the days you need it most.',
          positive
              ? 'Bahagyang mas mataas ang mood logs sa mga araw na may routine. Obserbasyon ito, hindi konklusyon.'
              : 'Mas mabigat nang kaunti ang mood logs sa routine days. Maaaring ginagamit mo ang routine sa mga araw na mas kailangan mo ito.',
        ),
      ));
    }
    items.add(_Observation(
      Icons.eco_rounded,
      _copy(language, 'Moments you tended', 'Mga sandaling inalagaan mo'),
      _copy(
        language,
        'You checked in on ${snapshot.activeDays} of 7 days, with ${snapshot.gratitudeEntries} gratitude note${snapshot.gratitudeEntries == 1 ? '' : 's'} and ${snapshot.journalEntries} journal entr${snapshot.journalEntries == 1 ? 'y' : 'ies'}.',
        'Nag-check in ka sa ${snapshot.activeDays} sa 7 araw, na may ${snapshot.gratitudeEntries} tala ng pasasalamat at ${snapshot.journalEntries} journal entry.',
      ),
    ));
    return items;
  }

  Widget _observationCard(_Observation observation, bool isDark) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.honeyBorder
                  .withValues(alpha: isDark ? 0.16 : 0.65)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: AppColors.honeyGold.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13)),
            child:
                Icon(observation.icon, color: AppColors.honeyAmber, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(observation.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(observation.body,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
              ])),
        ]),
      );

  Widget _privacyNote(String language, bool isDark) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.honeyAmber.withValues(alpha: isDark ? 0.10 : 0.07),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.honeyAmber, size: 19),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
            _copy(
                language,
                'These observations are calculated on-device. AI receives only the totals above when you ask it to reflect—never your raw entries.',
                'Kinakalkula sa device ang mga obserbasyong ito. Mga kabuuang bilang lamang ang matatanggap ng AI kapag humingi ka ng pagninilay—hindi ang mismong mga tala.'),
            style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: isDark ? Colors.white70 : AppColors.beeDark),
          )),
        ]),
      );

  Widget _aiSection(
      WeeklyReflectionSnapshot snapshot, UserProvider user, bool isDark) {
    final language = user.language;
    final companion = MascotInfo.getById(user.selectedCompanion);
    final narrative = _aiReflection == null
        ? null
        : WeeklyReflectionNarrative.tryParse(_aiReflection!);
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Container(
      key: const ValueKey('weekly-companion-reflection'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.honeyAmber.withValues(alpha: isDark ? 0.32 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.honeyAmber.withValues(
              alpha: isDark ? 0.05 : 0.07,
            ),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE7B1), Color(0xFFE8B35E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  companion.avatarIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _copy(
                        language,
                        'Reflect with ${companion.name}',
                        'Magnilay kasama si ${companion.name}',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      narrative == null || _savedAt == null
                          ? _copy(
                              language,
                              'Optional analysis using only this week’s totals.',
                              'Opsyonal na pagsusuri gamit lamang ang kabuuan ng linggong ito.',
                            )
                          : _copy(
                              language,
                              'Saved ${DateFormat('MMM d, h:mm a').format(_savedAt!)} · only for this week',
                              'Na-save ${DateFormat('MMM d, h:mm a').format(_savedAt!)} · para lamang sa linggong ito',
                            ),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (narrative != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.honeyAmber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: AppColors.honeyAmber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'SAVED',
                        style: TextStyle(
                          color: AppColors.honeyAmber,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isLoadingSavedReflection) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(
                minHeight: 4,
                color: AppColors.honeyAmber,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _copy(language, 'Checking this week’s saved reflection…',
                  'Tinitingnan ang naka-save na pagninilay…'),
              style: TextStyle(fontSize: 11.5, color: secondary),
            ),
          ] else ...[
            if (narrative == null && _generationError == null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkHoneySurface
                      : AppColors.honeyLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.honeyAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _copy(
                          language,
                          'Get one evidence-based pattern and a measurable experiment for the next seven days.',
                          'Kumuha ng isang pattern mula sa datos at nasusukat na eksperimento para sa susunod na pitong araw.',
                        ),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isGenerating) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.honeyAmber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.honeyAmber,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        _copy(
                          language,
                          'Connecting this week’s signals…',
                          'Pinag-uugnay ang mga signal ng linggong ito…',
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_generationError != null) ...[
              const SizedBox(height: 16),
              Container(
                key: const ValueKey('weekly-reflection-error'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF342B21)
                      : const Color(0xFFFFF3DF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.honeyAmber.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.honeyAmber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _copy(language, 'Couldn’t reach your companion',
                                'Hindi makonekta ang companion'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _generationError!,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (narrative != null) ...[
              const SizedBox(height: 18),
              if (_createdOnDevice) ...[
                Container(
                  key: const ValueKey('weekly-reflection-device-note'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.honeyAmber.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.offline_bolt_outlined,
                        color: AppColors.honeyAmber,
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _copy(
                            language,
                            'Created privately on this device from your weekly totals.',
                            'Pribadong ginawa sa device na ito mula sa weekly totals mo.',
                          ),
                          style: TextStyle(
                            color: secondary,
                            fontSize: 11.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _narrativeBlock(
                icon: Icons.fact_check_outlined,
                label: _copy(language, 'Evidence', 'Ebidensya'),
                markdown: narrative.evidence,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _narrativeBlock(
                icon: Icons.insights_rounded,
                label: _copy(language, 'Pattern', 'Pattern'),
                markdown: narrative.pattern,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _narrativeBlock(
                icon: Icons.science_outlined,
                label: _copy(language, 'One experiment', 'Isang eksperimento'),
                markdown: narrative.experiment,
                isDark: isDark,
                emphasized: true,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('weekly-reflection-generate'),
                    onPressed: _isGenerating ? null : () => _generate(snapshot),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppColors.honeyAmber,
                      foregroundColor: AppColors.onHoney,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(narrative == null
                        ? Icons.auto_awesome_rounded
                        : Icons.refresh_rounded),
                    label: Text(
                      _copy(
                        language,
                        narrative == null
                            ? 'Create reflection'
                            : 'Reflect again',
                        narrative == null
                            ? 'Gumawa ng pagninilay'
                            : 'Magnilay muli',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                if (narrative != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _isGenerating ? null : () => _deleteSaved(snapshot),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(_copy(language, 'Delete', 'Burahin')),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _narrativeBlock({
    required IconData icon,
    required String label,
    required String markdown,
    required bool isDark,
    bool emphasized = false,
  }) {
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.honeyAmber.withValues(alpha: isDark ? 0.12 : 0.08)
            : (isDark ? AppColors.darkBackground : const Color(0xFFFAF8F3)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasized
              ? AppColors.honeyAmber.withValues(alpha: 0.25)
              : (isDark ? AppColors.darkCardBorder : const Color(0xFFECE5D9)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.honeyAmber),
              const SizedBox(width: 7),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.honeyAmber,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: markdown,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: primary,
              ),
              strong: const TextStyle(fontWeight: FontWeight.w800),
              listBullet: TextStyle(color: primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String language, bool isDark) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          const Icon(Icons.calendar_today_rounded,
              size: 34, color: AppColors.honeyAmber),
          const SizedBox(height: 12),
          Text(
              _copy(language, 'Your week is ready to be noticed',
                  'Handa nang mapansin ang iyong linggo'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Text(
              _copy(
                  language,
                  'A mood check-in, journal entry, gratitude note, or completed routine will begin your honest weekly overview.',
                  'Magsisimula ang tapat na lingguhang buod kapag may mood check-in, journal entry, gratitude note, o natapos na routine.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
        ]),
      );
}

class _Observation {
  final IconData icon;
  final String title;
  final String body;
  const _Observation(this.icon, this.title, this.body);
}

class _WeeklyReflectionOfflineException implements Exception {
  const _WeeklyReflectionOfflineException();
}
