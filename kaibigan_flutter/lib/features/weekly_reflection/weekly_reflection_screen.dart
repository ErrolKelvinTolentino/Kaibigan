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
import '../mood_tracking/mood_model.dart';
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
    return 'weekly_reflection_v4_${userId}_${DateFormat('yyyyMMdd').format(snapshot.start)}';
  }

  Future<void> _loadSavedReflection(
    WeeklyReflectionSnapshot snapshot,
    String storageKey,
    String storageIdentity,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(storageKey);
    String? reflection;
    DateTime? savedAt;
    var createdOnDevice = false;
    Map<String, dynamic>? savedPayload;

    if (saved != null && saved.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(saved);
        if (decoded is Map<String, dynamic>) {
          savedPayload = decoded;
          reflection = decoded['text']?.toString();
          savedAt = DateTime.tryParse(decoded['savedAt']?.toString() ?? '');
          createdOnDevice = decoded['origin'] == 'device';
          final savedSignature = decoded['snapshotSignature']?.toString();
          if (savedSignature != null &&
              savedSignature != snapshot.dataSignature) {
            reflection = null;
            savedAt = null;
            await preferences.remove(storageKey);
          }
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
      } else if (savedPayload != null &&
          savedPayload['snapshotSignature'] == null) {
        // Upgrade older valid reflections so later check-ins can invalidate
        // them instead of leaving a stale analysis on screen.
        await preferences.setString(
          storageKey,
          jsonEncode({
            ...savedPayload,
            'version': 4,
            'snapshotSignature': snapshot.dataSignature,
          }),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _aiReflection = reflection;
      _savedAt = savedAt;
      _createdOnDevice = createdOnDevice;
      _loadedStorageKey = storageIdentity;
      _scheduledStorageKey = null;
      _isLoadingSavedReflection = false;
    });
  }

  Future<void> _generate(WeeklyReflectionSnapshot snapshot) async {
    final user = context.read<UserProvider>();
    final previousReflection = _aiReflection?.trim();
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
        adjustment: previousReflection == null
            ? null
            : AIResponseAdjustment.lessRepetitive,
        previousResponse: previousReflection,
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
          'version': 4,
          'text': reflection,
          'savedAt': savedAt.toIso8601String(),
          'origin': createdOnDevice ? 'device' : 'companion',
          'snapshotSignature': snapshot.dataSignature,
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
    final storageIdentity = '$storageKey:${snapshot.dataSignature}';
    if (_loadedStorageKey != storageIdentity &&
        _scheduledStorageKey != storageIdentity) {
      _scheduledStorageKey = storageIdentity;
      _isLoadingSavedReflection = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadSavedReflection(snapshot, storageKey, storageIdentity),
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
                assetPath: FeatureIconHelper.weeklyInsights,
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
                      _copy(language, 'See check-in details',
                          'Tingnan ang check-in details'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _copy(
                        language,
                        'Scores are translated into plain language',
                        'Ipinaliliwanag ang scores sa simpleng salita',
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
                                _plainLevel(snapshot.averageMood, language),
                                _copy(language, 'Average mood',
                                    'Karaniwang mood'),
                                AppColors.honeyAmber,
                                isDark),
                            _metricCard(
                                width,
                                Icons.bedtime_rounded,
                                _plainLevel(snapshot.averageSleep, language),
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

  String _plainLevel(
    double? value,
    String language, {
    bool highIsHard = false,
  }) {
    if (value == null) return _copy(language, 'Not logged', 'Hindi na-log');
    if (value >= 4.5) {
      return highIsHard
          ? _copy(language, 'Very high', 'Napakataas')
          : _copy(language, 'Very good', 'Napakaganda');
    }
    if (value >= 3.5) {
      return highIsHard
          ? _copy(language, 'High', 'Mataas')
          : _copy(language, 'Good', 'Maganda');
    }
    if (value >= 2.5) return _copy(language, 'In the middle', 'Nasa gitna');
    if (value >= 1.5) return _copy(language, 'Low', 'Mababa');
    return _copy(language, 'Very low', 'Napakababa');
  }

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
      final energy = _plainLevel(snapshot.averageEnergy, language);
      final stress = _plainLevel(
        snapshot.averageStress,
        language,
        highIsHard: true,
      );
      items.add(_Observation(
        Icons.balance_rounded,
        _copy(language, 'Energy and demand', 'Lakas at bigat'),
        _copy(
          language,
          'Your check-ins describe your energy as $energy and stress as $stress. These are broad descriptions of how the week felt, not grades.',
          'Inilalarawan ng check-ins ang energy mo bilang $energy at stress bilang $stress. Pangkalahatang paglalarawan ito ng linggo, hindi grado.',
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
              ? 'Your later mood check-ins felt better than your earlier ones. The direction is encouraging, though one week cannot explain what caused it.'
              : 'Your later mood check-ins felt heavier than your earlier ones. That shift is worth noticing, but one week cannot explain what caused it.',
          rising
              ? 'Mas magaan ang mga huling mood check-in kaysa sa mga nauna. Magandang direksyon ito, pero hindi pa masasabi ng isang linggo ang sanhi.'
              : 'Mas mabigat ang mga huling mood check-in kaysa sa mga nauna. Mahalagang pansinin ito, pero hindi pa masasabi ng isang linggo ang sanhi.',
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
              ? 'Mood tended to feel better on the days when sleep felt better. This is something to notice again, not proof that sleep caused the change.'
              : 'Mood tended to feel lower even on the days when sleep felt better. That unexpected connection is worth noticing again before drawing a conclusion.',
          positive
              ? 'Mas maganda ang mood sa mga araw na mas maganda rin ang tulog. Dapat itong pansinin muli, hindi ituring na patunay na tulog ang sanhi.'
              : 'Mas mababa ang mood kahit sa mga araw na mas maganda ang tulog. Hindi ito inaasahang ugnayan, kaya mas mabuting pansinin muli bago magkonklusyon.',
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
              ? 'Mood tended to feel better on routine days. This may be a useful signal, but it does not prove that the routine caused the change.'
              : 'Mood tended to feel lower on routine days. You may use routines on harder days, so this should not be treated as an effect of the routine.',
          positive
              ? 'Mas maganda ang mood sa routine days. Posibleng signal ito, pero hindi nito pinatutunayan ang sanhi.'
              : 'Mas mababa ang mood sa routine days. Maaaring mas ginagamit ang routine sa mahihirap na araw, kaya huwag muna itong ituring na epekto ng routine.',
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
                'Nothing is shared until you tap Reflect. Then Kai uses only your entries, gratitude notes, and check-ins from these seven days—not Kai’s previous replies.',
                'Walang ibinabahagi hanggang pindutin mo ang Reflect. Pagkatapos, ang entries, gratitude notes, at check-ins mo lamang mula sa pitong araw na ito ang gagamitin ni Kai—hindi ang mga dating sagot ni Kai.'),
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
                              'A reflection grounded in what you wrote this week.',
                              'Pagninilay batay sa mga isinulat mo ngayong linggo.',
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
                            'Created on this device from your own words and check-ins.',
                            'Ginawa sa device na ito mula sa sarili mong mga salita at check-ins.',
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
                label: _copy(language, 'What you shared', 'Ang ibinahagi mo'),
                markdown: narrative.evidence,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _narrativeBlock(
                icon: Icons.insights_rounded,
                label: _copy(language, 'What may connect', 'Posibleng ugnayan'),
                markdown: narrative.pattern,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _narrativeBlock(
                icon: Icons.science_outlined,
                label: _copy(language, 'Try this next', 'Subukan ito'),
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
