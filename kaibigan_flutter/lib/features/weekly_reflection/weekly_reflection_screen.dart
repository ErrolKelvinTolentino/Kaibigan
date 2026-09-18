import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';

import '../../core/services/ai_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_feature_banner.dart';
import '../home/activity_feedback_store.dart';
import '../insights/wellness_insights_panel.dart';
import '../insights/wellness_insights_button.dart';
import '../companion/companion_model.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../journaling/journal_provider.dart';
import '../mood_tracking/mood_provider.dart';
import '../mood_tracking/mood_model.dart';
import '../routines/routines_provider.dart';
import '../routines/screens/sleep_analytics_screen.dart';
import '../settings/user_provider.dart';
import 'weekly_reflection_service.dart';

class WeeklyReflectionScreen extends StatefulWidget {
  const WeeklyReflectionScreen({super.key});

  @override
  State<WeeklyReflectionScreen> createState() => _WeeklyReflectionScreenState();
}

class _WeeklyReflectionScreenState extends State<WeeklyReflectionScreen> {
  List<ActivityFeedbackRecord> _feedback = const [];
  @override
  void initState() {
    super.initState();
    ActivityFeedbackStore.load().then((value) {
      if (mounted) setState(() => _feedback = value);
    });
  }

  bool _isLoadingSavedReflection = true;
  bool _isGenerating = false;
  String? _aiReflection;
  WeeklyReflectionNarrative? _narrative;
  String? _generationError;
  DateTime? _savedAt;
  bool _createdOnDevice = false;
  bool _hasNewDataSinceSave = false;
  bool _isSavingToJournal = false;
  bool _savedToJournal = false;
  String? _loadedStorageKey;
  String? _scheduledStorageKey;

  String _copy(String language, String english, String filipino) =>
      LanguageHelper.pick(language, english: english, filipino: filipino);

  String _storageKey(WeeklyReflectionSnapshot snapshot, {String language = 'english'}) {
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id ?? 'local'
        : 'local';
    final locale = LanguageHelper.normalize(language);
    final suffix = locale == 'english' ? '' : '_$locale';
    return 'weekly_reflection_v4_${userId}_${DateFormat('yyyyMMdd').format(snapshot.start)}$suffix';
  }

  Future<void> _loadSavedReflection(
    WeeklyReflectionSnapshot snapshot,
    String storageKey,
    String storageIdentity,
    String language,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id ?? 'local'
        : 'local';
    final locale = LanguageHelper.normalize(language);
    final suffix = locale == 'english' ? '' : '_$locale';

    // 1. Check exact date/locale key
    String? rawJson = preferences.getString(storageKey);

    // 2. Fall back to latest reflection key for this user & locale
    if (rawJson == null || rawJson.trim().isEmpty) {
      rawJson = preferences.getString('weekly_reflection_latest_$userId$suffix');
    }

    // 3. Fall back to latest reflection key for this user (any locale)
    if (rawJson == null || rawJson.trim().isEmpty) {
      rawJson = preferences.getString('weekly_reflection_latest_$userId');
    }

    // 4. Fall back to rolling past 7 days keys
    if (rawJson == null || rawJson.trim().isEmpty) {
      for (var i = 0; i <= 7; i++) {
        final pastStart = snapshot.start.subtract(Duration(days: i));
        final pastKey =
            'weekly_reflection_v4_${userId}_${DateFormat('yyyyMMdd').format(pastStart)}$suffix';
        final candidate = preferences.getString(pastKey);
        if (candidate != null && candidate.trim().isNotEmpty) {
          rawJson = candidate;
          break;
        }
      }
    }

    // 5. If logged in, also check local fallback
    if ((rawJson == null || rawJson.trim().isEmpty) && userId != 'local') {
      rawJson = preferences.getString('weekly_reflection_latest_local$suffix') ??
          preferences.getString('weekly_reflection_latest_local');
    }

    String? reflection;
    DateTime? savedAt;
    var createdOnDevice = false;
    WeeklyReflectionNarrative? parsedNarrative;
    var hasNewData = false;
    Map<String, dynamic>? savedPayload;

    if (rawJson != null && rawJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          savedPayload = decoded;
          reflection = decoded['text']?.toString();
          savedAt = DateTime.tryParse(decoded['savedAt']?.toString() ?? '');
          createdOnDevice = decoded['origin'] == 'device';

          final savedEvidence = decoded['evidence']?.toString();
          final savedPattern = decoded['pattern']?.toString();
          final savedExperiment = decoded['experiment']?.toString();
          if (savedEvidence != null &&
              savedPattern != null &&
              savedExperiment != null &&
              savedEvidence.isNotEmpty &&
              savedPattern.isNotEmpty &&
              savedExperiment.isNotEmpty) {
            parsedNarrative = WeeklyReflectionNarrative(
              evidence: savedEvidence,
              pattern: savedPattern,
              experiment: savedExperiment,
            );
          }

          final savedSignature = decoded['snapshotSignature']?.toString();
          if (savedSignature != null &&
              savedSignature != snapshot.dataSignature) {
            hasNewData = true;
          }
        }
      } catch (_) {
        // Version 1 stored the reflection as a plain string.
        reflection = rawJson;
      }

      parsedNarrative ??= reflection == null
          ? null
          : WeeklyReflectionNarrative.tryParse(reflection);

      // Invalidate if older than 7 days
      if (savedAt != null && DateTime.now().difference(savedAt).inDays > 7) {
        reflection = null;
        parsedNarrative = null;
        savedAt = null;
      }

      if (reflection == null || parsedNarrative == null) {
        // Earlier builds persisted the generic companion fallback. It is not
        // a weekly analysis, so quietly migrate it out instead of showing it.
        await preferences.remove(storageKey);
        reflection = null;
        parsedNarrative = null;
        savedAt = null;
      } else if (savedPayload != null &&
          savedPayload['snapshotSignature'] == null) {
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

    if (!mounted || _scheduledStorageKey != storageIdentity) return;
    setState(() {
      _aiReflection = reflection;
      _narrative = parsedNarrative;
      _savedAt = savedAt;
      _createdOnDevice = createdOnDevice;
      _hasNewDataSinceSave = hasNewData;
      _loadedStorageKey = storageIdentity;
      _scheduledStorageKey = null;
      _isLoadingSavedReflection = false;
    });
  }

  Future<void> _generate(WeeklyReflectionSnapshot snapshot) async {
    final user = context.read<UserProvider>();
    final language = user.language;
    final storageKey = _storageKey(snapshot, language: language);
    final previousReflection = _aiReflection?.trim();
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });
    var createdOnDevice = false;
    String reflection;
    WeeklyReflectionNarrative? parsedNarrative;
    try {
      final reply = await AIService.generateCompanionReply(
        userText: snapshot.toCompactPrompt(language: language),
        companionId: user.selectedCompanion,
        language: language,
        mode: CompanionMode.weeklyReflection,
        useReasoning: true,
        adjustment: previousReflection == null
            ? null
            : AIResponseAdjustment.lessRepetitive,
        previousResponse: previousReflection,
      );
      if (reply.isOffline) throw const _WeeklyReflectionOfflineException();
      reflection = reply.text.trim();
      parsedNarrative = WeeklyReflectionNarrative.tryParse(reflection);
      if (parsedNarrative == null) {
        throw const FormatException('Incomplete weekly reflection response.');
      }
    } catch (_) {
      parsedNarrative = WeeklyReflectionService.buildLocalNarrative(
        snapshot,
        language: language,
      );
      reflection = parsedNarrative.toMarkdown();
      createdOnDevice = true;
    }

    try {
      final savedAt = DateTime.now();
      final preferences = await SharedPreferences.getInstance();
      final userId = SupabaseService.isInitialized
          ? SupabaseService.client.auth.currentUser?.id ?? 'local'
          : 'local';
      final locale = LanguageHelper.normalize(language);
      final suffix = locale == 'english' ? '' : '_$locale';

      final payload = jsonEncode({
        'version': 4,
        'text': reflection,
        'evidence': parsedNarrative.evidence,
        'pattern': parsedNarrative.pattern,
        'experiment': parsedNarrative.experiment,
        'savedAt': savedAt.toIso8601String(),
        'origin': createdOnDevice ? 'device' : 'companion',
        'snapshotSignature': snapshot.dataSignature,
        'startDate': snapshot.start.toIso8601String(),
        'endDate': snapshot.endExclusive.toIso8601String(),
      });

      await preferences.setString(storageKey, payload);
      await preferences.setString('weekly_reflection_latest_$userId$suffix', payload);
      await preferences.setString('weekly_reflection_latest_$userId', payload);
      if (userId != 'local') {
        await preferences.setString('weekly_reflection_latest_local$suffix', payload);
        await preferences.setString('weekly_reflection_latest_local', payload);
      }

      if (mounted) {
        setState(() {
          _aiReflection = reflection;
          _narrative = parsedNarrative;
          _savedAt = savedAt;
          _createdOnDevice = createdOnDevice;
          _hasNewDataSinceSave = false;
          _savedToJournal = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _copy(
                      language,
                      'Weekly reflection saved to your device for this week!',
                      'Na-save ang lingguhang pagninilay sa iyong device para sa linggong ito!',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
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
    final user = context.read<UserProvider>();
    final language = user.language;
    final storageKey = _storageKey(snapshot, language: language);
    final preferences = await SharedPreferences.getInstance();
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id ?? 'local'
        : 'local';
    final locale = LanguageHelper.normalize(language);
    final suffix = locale == 'english' ? '' : '_$locale';

    await preferences.remove(storageKey);
    await preferences.remove('weekly_reflection_latest_$userId$suffix');
    await preferences.remove('weekly_reflection_latest_$userId');
    await preferences.remove('weekly_reflection_latest_local$suffix');
    await preferences.remove('weekly_reflection_latest_local');

    if (mounted) {
      setState(() {
        _aiReflection = null;
        _narrative = null;
        _savedAt = null;
        _createdOnDevice = false;
        _generationError = null;
        _hasNewDataSinceSave = false;
        _savedToJournal = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(language, 'Reflection deleted.', 'Nabura ang pagninilay.'),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveToJournal(WeeklyReflectionSnapshot snapshot) async {
    final narrative = _narrative ??
        (_aiReflection != null
            ? WeeklyReflectionNarrative.tryParse(_aiReflection!)
            : null);
    if (narrative == null) return;
    final user = context.read<UserProvider>();
    final language = user.language;

    setState(() => _isSavingToJournal = true);
    try {
      final dateRange =
          '${DateFormat('MMM d').format(snapshot.start)} – ${DateFormat('MMM d').format(snapshot.endExclusive.subtract(const Duration(days: 1)))}';
      final title = _copy(
        language,
        'Weekly Reflection ($dateRange)',
        'Lingguhang Pagninilay ($dateRange)',
      );
      final content = '''
### ${_copy(language, 'What you shared', 'Ang ibinahagi mo')}
${narrative.evidence}

### ${_copy(language, 'What may connect', 'Posibleng ugnayan')}
${narrative.pattern}

### ${_copy(language, 'Try this next', 'Subukan ito')}
${narrative.experiment}
''';

      await context.read<JournalProvider>().addJournalEntry(
        title: title,
        content: content,
        companionId: user.selectedCompanion,
        mood: 'reflective',
        tags: ['weekly-reflection'],
      );

      if (mounted) {
        setState(() {
          _isSavingToJournal = false;
          _savedToJournal = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _copy(
                      language,
                      'Saved to your journal entries!',
                      'Na-save sa iyong mga journal entry!',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSavingToJournal = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _copy(
                language,
                'Could not save to journal. Please try again.',
                'Hindi ma-save sa journal. Subukan muli.',
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _copyReflection() async {
    final narrative = _narrative ??
        (_aiReflection != null
            ? WeeklyReflectionNarrative.tryParse(_aiReflection!)
            : null);
    if (narrative == null) return;
    final user = context.read<UserProvider>();
    final language = user.language;
    await Clipboard.setData(ClipboardData(text: narrative.toMarkdown()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              language,
              'Copied reflection to clipboard.',
              'Na-kopya ang pagninilay sa clipboard.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
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
      feedback: _feedback,
      moods: context.watch<MoodProvider>().logs,
      journals: context.watch<JournalProvider>().allEntries,
      gratitudes: context.watch<GratitudeProvider>().entries,
      routines: context.watch<RoutinesProvider>().logs,
    );
    final storageKey = _storageKey(snapshot, language: language);
    final storageIdentity = storageKey;
    if (_loadedStorageKey != storageIdentity &&
        _scheduledStorageKey != storageIdentity) {
      _scheduledStorageKey = storageIdentity;
      if (_aiReflection == null) {
        _isLoadingSavedReflection = true;
      }
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadSavedReflection(snapshot, storageKey, storageIdentity, language),
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

                  WellnessInsightsPanel(
                    snapshot: snapshot.wellness,
                    language: language,
                    onFeatureTap: (id) => showWellnessDetails(
                        context, snapshot.wellness, language, id),
                  ),
                if (snapshot.sleepDebtHours >= 4 &&
                    snapshot.sleepDebtNights >= 2) ...[
                  const SizedBox(height: 16),
                  _sleepDebtCallout(snapshot, language, isDark),
                ],
                const SizedBox(height: 16),
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

  /// Sleep debt is the one figure in this screen with a repayment attached
  /// to it, so it gets its own callout and a way through to the detail
  /// rather than sitting inside a grid of tiles.
  Widget _sleepDebtCallout(
    WeeklyReflectionSnapshot snapshot,
    String language,
    bool isDark,
  ) {
    final hours = snapshot.sleepDebtHours.toStringAsFixed(1);
    return Material(
      key: const ValueKey('weekly-sleep-debt-callout'),
      color: AppColors.periwinkle.withValues(alpha: isDark ? 0.16 : 0.10),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SleepAnalyticsScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bedtime_outlined,
                  color: AppColors.periwinkle, size: 21),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.sleepStatusTitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _copy(
                        language,
                        '$hours hours of sleep missed across '
                            '${snapshot.sleepDebtNights} logged nights. '
                            '${snapshot.sleepRecoveryAction}',
                        '$hours oras ng tulog ang kulang sa '
                            '${snapshot.sleepDebtNights} gabing may tala. '
                            '${snapshot.sleepRecoveryAction}',
                      ),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: isDark ? Colors.white70 : AppColors.beeDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.periwinkle, size: 20),
            ],
          ),
        ),
      ),
    );
  }

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
    final narrative = _narrative ??
        (_aiReflection == null
            ? null
            : WeeklyReflectionNarrative.tryParse(_aiReflection!));
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: secondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _copy(
                        language,
                        '✦ AI-generated reflection · for personal insight, not medical advice',
                        '✦ Binuo ng AI na pagninilay · para sa pansariling pananaw, hindi medikal na payo',
                      ),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              if (_hasNewDataSinceSave) ...[
                const SizedBox(height: 12),
                Container(
                  key: const ValueKey('weekly-reflection-new-data-notice'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.honeyAmber.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.honeyAmber.withValues(alpha: isDark ? 0.28 : 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.honeyAmber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _copy(
                            language,
                            'New check-ins were logged since this reflection. Your saved reflection is kept above, or tap "Reflect again" to update.',
                            'May mga bagong check-in mula nang ma-save ito. Naka-save pa rin ang pagninilay sa itaas, o pindutin ang "Magnilay muli" para i-update.',
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: secondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
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
                  narrative == null ? 'Create reflection' : 'Reflect again',
                  narrative == null ? 'Gumawa ng pagninilay' : 'Magnilay muli',
                ),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (narrative != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('weekly-reflection-save-journal'),
                      onPressed: _isSavingToJournal
                          ? null
                          : () => _saveToJournal(snapshot),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        _savedToJournal
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_add_outlined,
                        size: 17,
                        color: _savedToJournal ? AppColors.honeyAmber : null,
                      ),
                      label: Text(
                        _savedToJournal
                            ? _copy(language, 'In Journal', 'Nasa Journal')
                            : _copy(language, 'Save to Journal', 'I-save sa Journal'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('weekly-reflection-copy'),
                    onPressed: _copyReflection,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(
                      _copy(language, 'Copy', 'Kopyahin'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('weekly-reflection-delete'),
                    onPressed:
                        _isGenerating ? null : () => _deleteSaved(snapshot),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    label: Text(
                      _copy(language, 'Delete', 'Burahin'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
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

class _WeeklyReflectionOfflineException implements Exception {
  const _WeeklyReflectionOfflineException();
}
