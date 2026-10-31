import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ai_service.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_logo.dart';
import '../companion/companion_model.dart';
import '../comfort_corner/comfort_corner_screen.dart';
import '../mood_tracking/mood_tracker_screen.dart';
import '../routines/screens/gratitude_planting_screen.dart';
import '../routines/screens/grounding_session_screen.dart';
import '../routines/screens/mindfulness_meditation_screen.dart';
import '../routines/screens/sleep_log_flow_screen.dart';
import 'journal_model.dart';
import 'journal_reflection_insights.dart';

typedef JournalSummaryLoader = Future<AIJournalSaveSummary> Function();

class JournalSaveReflectionScreen extends StatefulWidget {
  final JournalEntry entry;
  final String language;
  final String companionId;
  final JournalSummaryLoader? summaryLoader;

  /// Called once the look-back is ready, so the caller can keep it with the
  /// saved record. Omitted in tests, where nothing is persisted.
  final Future<bool> Function(AIJournalSaveSummary)? onSummaryReady;

  /// The entries already saved, used to say what keeps coming back. Reading
  /// one entry alone throws away the thing journalling is best at showing.
  final List<JournalEntry> previousEntries;

  /// Optional override for suggested activities. By default they open from
  /// this screen, including when the insight is revisited from Records.
  final ValueChanged<JournalFollowUpKind>? onFollowUp;

  /// Aggregate figures from the last seven days, so the recap's suggestion
  /// can be grounded in the week rather than the entry alone. Empty when the
  /// person has switched the context off.
  final String wellbeingContext;

  const JournalSaveReflectionScreen({
    super.key,
    required this.entry,
    required this.language,
    required this.companionId,
    this.summaryLoader,
    this.onSummaryReady,
    this.previousEntries = const [],
    this.onFollowUp,
    this.wellbeingContext = '',
  });

  @override
  State<JournalSaveReflectionScreen> createState() =>
      _JournalSaveReflectionScreenState();
}

class _JournalSaveReflectionScreenState
    extends State<JournalSaveReflectionScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  AIJournalSaveSummary? _summary;
  JournalContextReading? _context;
  bool _loading = true;
  int _page = 0;
  bool _saving = false;
  bool _saveFailed = false;

  String _copy(String english, String filipino) => LanguageHelper.pick(
        widget.language,
        english: english,
        filipino: filipino,
      );

  @override
  void initState() {
    super.initState();
    // The look-back across earlier entries is arithmetic on what is already
    // saved, so it is ready before the network answers — and stays useful
    // when the network never does.
    _context = JournalReflectionInsights.read(
      entry: widget.entry,
      previousEntries: widget.previousEntries,
      language: widget.language,
    );
    if (widget.entry.summary != null) {
      _summary = widget.entry.summary;
      _loading = false;
      _context = JournalReflectionInsights.read(
        entry: widget.entry,
        previousEntries: widget.previousEntries,
        language: widget.language,
        summary: _summary,
      );
      return;
    }
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await (widget.summaryLoader?.call() ??
          AIService.generateJournalSaveSummary(
            userText: widget.entry.content,
            companionId: widget.companionId,
            language: widget.language,
            wellbeingContext: widget.wellbeingContext,
          ));
      if (mounted) {
        setState(() {
          _summary = summary;
          // Recomputed with the emotions the companion recognised, which is
          // what makes a repeated feeling visible across entries.
          _context = JournalReflectionInsights.read(
            entry: widget.entry,
            previousEntries: widget.previousEntries,
            language: widget.language,
            summary: summary,
          );
        });
      }
      await _persistSummary(summary);
    } catch (_) {
      // The intentionally simple fallback below is the complete failure state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persistSummary(AIJournalSaveSummary summary) async {
    final save = widget.onSummaryReady;
    if (save == null) return;
    if (mounted) setState(() => _saving = true);
    var saved = false;
    try {
      saved = await save(summary);
    } catch (_) {
      // Keep the reflection visible and offer a retry when persistence fails.
    }
    if (mounted) {
      setState(() {
        _saving = false;
        _saveFailed = !saved;
      });
    }
  }

  void _openFollowUp(JournalFollowUpKind kind) {
    if (widget.onFollowUp != null) {
      widget.onFollowUp!(kind);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => switch (kind) {
              JournalFollowUpKind.breathing =>
                const MindfulnessMeditationScreen(),
              JournalFollowUpKind.grounding => const GroundingSessionScreen(),
              JournalFollowUpKind.gratitude => const GratitudePlantingScreen(),
              JournalFollowUpKind.moodCheckIn => const MoodTrackerScreen(),
              JournalFollowUpKind.sleepLog => const SleepLogFlowScreen(),
              JournalFollowUpKind.comfortCorner => const ComfortCornerScreen(),
            }));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KaibiganLogo(size: 31),
            SizedBox(width: 9),
            Text('Kaibigan'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _copy('Close', 'Isara'),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          child: _loading
              ? _loadingView(isDark)
              : _summary == null
                  ? _fallbackView(isDark)
                  : _summaryView(_summary!, isDark),
        ),
      ),
    );
  }

  Widget _loadingView(bool isDark) {
    final mascot = MascotInfo.getById(widget.companionId);
    return Center(
      key: const ValueKey('journal-summary-loading'),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Text(
              _copy('Holding this moment with you…',
                  'Inaalagaan ang sandaling ito kasama mo…'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 9),
            Text(
              _copy(
                'Your entry is already saved. ${mascot.name} is gathering a gentle look back.',
                'Naka-save na ang iyong tala. Gumagawa si ${mascot.name} ng banayad na paglingon.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackView(bool isDark) {
    return Center(
      key: const ValueKey('journal-summary-fallback'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 24, 30, 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 178,
                  height: 178,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.honeyGold.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  left: 13,
                  top: 35,
                  child: Icon(Icons.hexagon_outlined,
                      color: AppColors.honeyGold.withValues(alpha: 0.28),
                      size: 30),
                ),
                Positioned(
                  right: 14,
                  bottom: 28,
                  child: Icon(Icons.eco_outlined,
                      color: AppColors.sageGreen.withValues(alpha: 0.35),
                      size: 34),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              _copy('Your moment is safely kept',
                  'Ligtas na naingatan ang iyong sandali'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              _copy(
                'A reflection could not be prepared right now, but your words still matter. You can return to them whenever you need.',
                'Hindi nakagawa ng pagninilay ngayon, pero mahalaga pa rin ang iyong mga salita. Maaari mong balikan ang mga ito anumang oras.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            // A failed model call should not empty the page. Everything
            // below is computed on the device, so it survives the failure.
            if (_context?.hasContext ?? false) ...[
              const SizedBox(height: 22),
              _FallbackNote(
                key: const ValueKey('journal-summary-fallback-context'),
                text: [
                  if (_context!.recurrenceNote != null)
                    _context!.recurrenceNote!,
                  if (_context!.continuityNote != null)
                    _context!.continuityNote!,
                ].join('\n\n'),
                isDark: isDark,
              ),
            ],
            if (_context?.followUps.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              for (final followUp in _context!.followUps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FollowUpTile(
                    followUp: followUp,
                    isDark: isDark,
                    accent: AppColors.sageGreen,
                    onTap: () => _openFollowUp(followUp.kind),
                  ),
                ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_copy('Return to journal', 'Bumalik sa journal')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryView(AIJournalSaveSummary summary, bool isDark) {
    final reading = _context!;
    final slides = <Widget>[
      _reflectionCard(
        eyebrow: _copy('A GENTLE LOOK BACK', 'BANAYAD NA PAGLINGON'),
        title: widget.entry.displayTitle(widget.language),
        body: summary.summary,
        emotions: summary.emotions,
        icon: Icons.auto_awesome_rounded,
        isDark: isDark,
      ),
      ...summary.moments.map(
        (moment) => _reflectionCard(
          eyebrow: _copy('A MOMENT THAT STOOD OUT', 'SANDALING NAMUKOD-TANGI'),
          title: moment.title,
          body: moment.reflection,
          emotions: moment.emotions,
          icon: Icons.bookmark_rounded,
          isDark: isDark,
        ),
      ),
      // A question sits between describing and advising: it keeps the entry
      // open without telling the person what to do with it.
      if (summary.hasQuestion)
        _reflectionCard(
          key: const ValueKey('journal-summary-question-card'),
          eyebrow: _copy('A QUESTION TO SIT WITH', 'TANONG NA PAG-ISIPAN'),
          title:
              _copy('No answer needed today', 'Walang kailangang sagot ngayon'),
          body: summary.question,
          emotions: const [],
          icon: Icons.help_outline_rounded,
          isDark: isDark,
          accent: AppColors.skyBlue,
          footnote: _copy(
            'Only you can answer this one. It is fine to leave it open.',
            'Ikaw lang ang makakasagot nito. Ayos lang kung iiwan mong bukas.',
          ),
        ),
      // What this entry shares with the ones before it. Computed on the
      // device from saved entries, so it is the one card that is never a
      // guess — and it is the only place a repeated feeling becomes visible.
      if (reading.hasContext) _contextCard(reading, isDark),
      // The advice comes last and in a different colour: it is the one card
      // that asks something of the reader instead of describing what they
      // already wrote.
      if (summary.hasAdvice)
        _reflectionCard(
          key: const ValueKey('journal-summary-advice-card'),
          eyebrow: _copy('SOMETHING YOU COULD TRY', 'MAAARI MONG SUBUKAN'),
          title: _copy('One small thing', 'Isang munting hakbang'),
          body: summary.advice,
          emotions: const [],
          icon: Icons.tips_and_updates_rounded,
          isDark: isDark,
          accent: AppColors.sageGreen,
          footnote: _copy(
            'An option, not an instruction. Leave it if it does not fit.',
            'Mungkahi lamang, hindi utos. Iwan ito kung hindi bagay.',
          ),
        ),
      // Reflection that ends at the last word of a card leaves the person
      // exactly where they started. This one hands them somewhere to go.
      if (reading.followUps.isNotEmpty) _followUpCard(reading, isDark),
    ];
    final isLast = _page == slides.length - 1;
    return Column(
      key: const ValueKey('journal-summary-success'),
      children: [
        if (_saveFailed)
          MaterialBanner(
            content: Text(_copy(
              'Your entry is saved, but these insights could not be kept yet.',
              'Naka-save ang tala, pero hindi pa naingatan ang mga insight.',
            )),
            actions: [
              TextButton(
                onPressed: _saving ? null : () => _persistSummary(summary),
                child: Text(_copy('Retry', 'Subukan muli')),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Column(
            children: [
              Text(
                _copy('A little space for what mattered',
                    'Munting espasyo para sa mga mahalaga'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                _copy('Not a verdict—just a gentle reflection of your words.',
                    'Hindi ito hatol—banayad na pagninilay lamang sa iyong mga salita.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: slides[index],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: index == _page ? 22 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == _page
                    ? AppColors.honeyAmber
                    : AppColors.honeyGold.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                if (isLast) {
                  Navigator.pop(context);
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              icon: Icon(
                  isLast ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(isLast
                  ? _copy('Done', 'Tapos na')
                  : _copy('Continue', 'Magpatuloy')),
            ),
          ),
        ),
      ],
    );
  }

  /// Where this entry sits among the others: how often you have been
  /// writing, and which feeling keeps returning.
  Widget _contextCard(JournalContextReading reading, bool isDark) {
    final lines = [
      if (reading.recurrenceNote != null) reading.recurrenceNote!,
      if (reading.continuityNote != null) reading.continuityNote!,
    ];
    return _reflectionCard(
      key: const ValueKey('journal-summary-context-card'),
      eyebrow: _copy('ACROSS YOUR ENTRIES', 'SA MGA TALA MO'),
      title: reading.recurringEmotions.isEmpty
          ? _copy('Your writing rhythm', 'Ang ritmo ng pagsulat mo')
          : _copy('This keeps coming back', 'Paulit-ulit itong bumabalik'),
      body: lines.join('\n\n'),
      emotions: reading.recurringEmotions,
      icon: Icons.history_rounded,
      isDark: isDark,
      accent: AppColors.periwinkle,
      footnote: _copy(
        'Counted from your saved entries on this device — no AI involved.',
        'Bilang mula sa mga naka-save mong tala sa device na ito — walang AI.',
      ),
    );
  }

  /// The suggestions that turn a reflection into something with a next step,
  /// each carrying the reason it was offered so it can be declined on
  /// grounds rather than out of vagueness.
  Widget _followUpCard(JournalContextReading reading, bool isDark) {
    final accent = AppColors.sageGreen;
    return Container(
      key: const ValueKey('journal-summary-followup-card'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.16), AppColors.darkCard)
            : Color.alphaBlend(accent.withValues(alpha: 0.10), Colors.white),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.explore_outlined, color: accent, size: 20),
            ),
            const SizedBox(height: 18),
            Text(
              _copy('WHERE YOU COULD GO NEXT', 'SAAN KA MAAARING TUMULOY'),
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _copy('Carry it forward', 'Dalhin ito pasulong'),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...reading.followUps.map(
              (followUp) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FollowUpTile(
                  followUp: followUp,
                  isDark: isDark,
                  accent: accent,
                  onTap: () => _openFollowUp(followUp.kind),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _copy(
                'None of these are required. Closing this page is a complete ending too.',
                'Wala sa mga ito ang sapilitan. Kumpletong pagtatapos na rin ang pagsara ng pahinang ito.',
              ),
              style: TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reflectionCard({
    Key? key,
    required String eyebrow,
    required String title,
    required String body,
    required List<String> emotions,
    required IconData icon,
    required bool isDark,
    Color accent = AppColors.honeyAmber,
    String? footnote,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.16),
                    AppColors.darkCard,
                  ),
                  AppColors.darkCard,
                ]
              : [
                  Colors.white,
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.13),
                    Colors.white,
                  ),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.16 : 0.13),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // spaceBetween rather than a Spacer: this card lives inside a
              // scroll view, and the screen's tests guard against Spacer for
              // exactly that reason.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.2 : 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              eyebrow,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (emotions.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emotions
                    .map((emotion) => _emotionChip(emotion, isDark))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    footnote ??
                        _copy(
                          '✦ AI-generated reflection · for personal insight, not medical advice',
                          '✦ Binuo ng AI na pagninilay · para sa pansariling pananaw, hindi medikal na payo',
                        ),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emotionChip(String emotion, bool isDark) {
    final color = _emotionColor(emotion);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        _emotionLabel(emotion),
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  String _emotionLabel(String emotion) {
    final english = emotion[0].toUpperCase() + emotion.substring(1);
    final filipino = switch (emotion) {
      'happy' => 'Masaya',
      'anxious' => 'Balisa',
      'tired' => 'Pagod',
      'grateful' => 'Mapagpasalamat',
      'excited' => 'Sabik',
      'sad' => 'Malungkot',
      'overwhelmed' => 'Nabibigatan',
      'calm' => 'Kalmado',
      'hopeful' => 'Umaasa',
      'frustrated' => 'Naiinis',
      'relieved' => 'Gumaan',
      'lonely' => 'Nag-iisa',
      'proud' => 'Proud',
      'uncertain' => 'Hindi tiyak',
      'peaceful' => 'Payapa',
      'nostalgic' => 'Nananabik sa nakaraan',
      _ => english,
    };
    return _copy(english, filipino);
  }

  Color _emotionColor(String emotion) {
    switch (emotion) {
      case 'happy':
      case 'grateful':
      case 'excited':
      case 'proud':
        return AppColors.honeyAmber;
      case 'calm':
      case 'hopeful':
      case 'peaceful':
      case 'relieved':
        return AppColors.sageGreen;
      case 'anxious':
      case 'overwhelmed':
      case 'uncertain':
        return AppColors.periwinkle;
      case 'sad':
      case 'lonely':
      case 'tired':
        return AppColors.skyBlue;
      default:
        return AppColors.softRose;
    }
  }
}

/// One suggested next move. Tappable when the caller can route to it, plain
/// text when it cannot — the reason for the suggestion is the useful part
/// either way.
class _FollowUpTile extends StatelessWidget {
  const _FollowUpTile({
    required this.followUp,
    required this.isDark,
    required this.accent,
    this.onTap,
  });

  final JournalFollowUp followUp;
  final bool isDark;
  final Color accent;
  final VoidCallback? onTap;

  IconData get _icon => switch (followUp.kind) {
        JournalFollowUpKind.breathing => Icons.air_rounded,
        JournalFollowUpKind.grounding => Icons.spa_outlined,
        JournalFollowUpKind.gratitude => Icons.local_florist_outlined,
        JournalFollowUpKind.moodCheckIn =>
          Icons.sentiment_satisfied_alt_rounded,
        JournalFollowUpKind.sleepLog => Icons.bedtime_outlined,
        JournalFollowUpKind.comfortCorner => Icons.favorite_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_icon, size: 18, color: accent),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  followUp.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  followUp.rationale,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: accent.withValues(alpha: 0.8)),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// The on-device look-back shown when the model could not be reached.
class _FallbackNote extends StatelessWidget {
  const _FallbackNote({super.key, required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.periwinkle.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.periwinkle.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.55,
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
