import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ai_service.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_logo.dart';
import '../companion/companion_model.dart';
import 'journal_model.dart';

typedef JournalSummaryLoader = Future<AIJournalSaveSummary> Function();

class JournalSaveReflectionScreen extends StatefulWidget {
  final JournalEntry entry;
  final String language;
  final String companionId;
  final JournalSummaryLoader? summaryLoader;

  const JournalSaveReflectionScreen({
    super.key,
    required this.entry,
    required this.language,
    required this.companionId,
    this.summaryLoader,
  });

  @override
  State<JournalSaveReflectionScreen> createState() =>
      _JournalSaveReflectionScreenState();
}

class _JournalSaveReflectionScreenState
    extends State<JournalSaveReflectionScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  AIJournalSaveSummary? _summary;
  bool _loading = true;
  int _page = 0;

  String _copy(String english, String filipino) => LanguageHelper.pick(
        widget.language,
        english: english,
        filipino: filipino,
      );

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await (widget.summaryLoader?.call() ??
          AIService.generateJournalSaveSummary(
            userText: widget.entry.content,
            companionId: widget.companionId,
            language: widget.language,
          ));
      if (mounted) setState(() => _summary = summary);
    } catch (_) {
      // The intentionally simple fallback below is the complete failure state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          duration: const Duration(milliseconds: 320),
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
            _mascotOrb(mascot, 78),
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
    final mascot = MascotInfo.getById(widget.companionId);
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
                _mascotOrb(mascot, 92),
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
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _summaryView(AIJournalSaveSummary summary, bool isDark) {
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
    ];
    final isLast = _page == slides.length - 1;
    return Column(
      key: const ValueKey('journal-summary-success'),
      children: [
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
                  ? _copy('Keep this moment', 'Ingatan ang sandaling ito')
                  : _copy('Continue', 'Magpatuloy')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reflectionCard({
    required String eyebrow,
    required String title,
    required String body,
    required List<String> emotions,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkHoneySurface, AppColors.darkCard]
              : [Colors.white, AppColors.honeyLight],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.honeyGold.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.honeyGold.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.honeyAmber, size: 20),
            ),
            const SizedBox(height: 18),
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.honeyAmber,
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
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04);
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

  Widget _mascotOrb(MascotInfo mascot, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: mascot.primaryColor.withValues(alpha: 0.14),
          border:
              Border.all(color: mascot.primaryColor.withValues(alpha: 0.22)),
        ),
        child: Icon(mascot.materialIcon,
            color: mascot.primaryColor, size: size * 0.43),
      );
}
