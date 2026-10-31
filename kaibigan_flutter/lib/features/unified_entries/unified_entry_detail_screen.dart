import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/journal_appearance.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../companion/companion_model.dart';
import '../gratitude_garden/garden_layout.dart';
import '../gratitude_garden/gratitude_model.dart';
import '../gratitude_garden/gratitude_provider.dart';
import '../gratitude_garden/polished_flower_asset.dart';
import '../journaling/journal_editor_screen.dart';
import '../journaling/journal_model.dart';
import '../journaling/journal_provider.dart';
import '../journaling/journal_save_reflection_screen.dart';
import '../mood_tracking/mood_model.dart';
import '../mood_tracking/mood_provider.dart';
import '../routines/routine_model.dart';
import '../routines/routines_provider.dart';
import '../settings/user_provider.dart';
import 'unified_feed_item.dart';

class UnifiedEntryDetailScreen extends StatefulWidget {
  const UnifiedEntryDetailScreen({
    super.key,
    required this.item,
  });

  final UnifiedFeedItem item;

  @override
  State<UnifiedEntryDetailScreen> createState() =>
      _UnifiedEntryDetailScreenState();
}

class _UnifiedEntryDetailScreenState extends State<UnifiedEntryDetailScreen> {
  late Object? _rawData = widget.item.rawData;
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _paletteFor(widget.item.category, isDark);
    final rawData = _currentRawData(context);

    return Scaffold(
      key: ValueKey('entry-detail-${widget.item.category.name}'),
      backgroundColor: palette.page,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 310,
            foregroundColor: Colors.white,
            backgroundColor: palette.heroEnd,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: 'Back to all entries',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            title: Text(
              widget.item.categoryTag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _buildHero(rawData, palette),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rawData is JournalEntry) ...[
                    OutlinedButton.icon(
                      key: const ValueKey('record-view-insights'),
                      onPressed: rawData.content.trim().isEmpty
                          ? null
                          : () => _openInsights(rawData),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text(LanguageHelper.pick(
                        context.watch<UserProvider>().language,
                        english: 'Insights',
                        filipino: 'Mga insight',
                      )),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _buildFeatureBody(rawData, palette, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActions(rawData, palette, isDark),
    );
  }

  Object? _currentRawData(BuildContext context) {
    final raw = _rawData;
    if (raw is GratitudeEntry) {
      final entries = context.watch<GratitudeProvider>().entries;
      return entries.cast<GratitudeEntry?>().firstWhere(
                (entry) => entry?.id == raw.id,
                orElse: () => raw,
              ) ??
          raw;
    }
    if (raw is JournalEntry) {
      final entries = context.watch<JournalProvider>().allEntries;
      return entries.cast<JournalEntry?>().firstWhere(
                (entry) => entry?.id == raw.id,
                orElse: () => raw,
              ) ??
          raw;
    }
    return raw;
  }

  Future<void> _openInsights(JournalEntry entry) async {
    final user = context.read<UserProvider>();
    final journals = context.read<JournalProvider>();
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => JournalSaveReflectionScreen(
        entry: entry,
        language: user.language,
        companionId: entry.companionId,
        previousEntries:
            journals.allEntries.where((item) => item.id != entry.id).toList(),
        onSummaryReady: (summary) => journals.saveSummary(entry.id, summary,
            expectedContent: entry.content),
      ),
    ));
  }

  Widget _buildHero(Object? rawData, _DetailPalette palette) {
    return switch (widget.item.category) {
      EntryCategory.gratitude => _GratitudeHero(
          entry: rawData as GratitudeEntry,
          timestamp: widget.item.timestamp,
        ),
      EntryCategory.mood => _MoodHero(
          log: rawData as MoodLog,
          palette: palette,
        ),
      EntryCategory.sleep => _SleepHero(
          log: rawData as RoutineLog,
          palette: palette,
        ),
      EntryCategory.focus => _IntentHero(
          title: 'A direction for the day',
          icon: Icons.near_me_outlined,
          palette: palette,
          timestamp: widget.item.timestamp,
        ),
      EntryCategory.breathing || EntryCategory.grounding => _IntentHero(
          title: widget.item.category == EntryCategory.breathing
              ? 'A moment to breathe'
              : 'Back to the present',
          icon: widget.item.category == EntryCategory.breathing
              ? Icons.air_rounded
              : Icons.spa_outlined,
          palette: palette,
          timestamp: widget.item.timestamp,
        ),
      EntryCategory.highlight => _IntentHero(
          title: 'A moment worth keeping',
          icon: Icons.auto_awesome_rounded,
          palette: palette,
          timestamp: widget.item.timestamp,
        ),
      EntryCategory.reflection => _JournalHero(
          entry: rawData as JournalEntry,
          palette: palette,
          reflection: true,
        ),
      EntryCategory.journal => _JournalHero(
          entry: rawData as JournalEntry,
          palette: palette,
          reflection: false,
        ),
      EntryCategory.all => _IntentHero(
          title: widget.item.title,
          icon: Icons.auto_stories_outlined,
          palette: palette,
          timestamp: widget.item.timestamp,
        ),
    };
  }

  Widget _buildFeatureBody(
    Object? rawData,
    _DetailPalette palette,
    bool isDark,
  ) {
    return switch (widget.item.category) {
      EntryCategory.journal => _JournalEntryBody(
          entry: rawData as JournalEntry,
          palette: palette,
          isDark: isDark,
        ),
      EntryCategory.reflection => _ReflectionEntryBody(
          entry: rawData as JournalEntry,
          palette: palette,
          isDark: isDark,
        ),
      EntryCategory.gratitude => _GratitudeEntryBody(
          entry: rawData as GratitudeEntry,
          palette: palette,
          isDark: isDark,
        ),
      EntryCategory.mood => _MoodEntryBody(
          log: rawData as MoodLog,
          palette: palette,
          isDark: isDark,
        ),
      EntryCategory.sleep => _SleepEntryBody(
          log: rawData as RoutineLog,
          palette: palette,
          isDark: isDark,
        ),
      EntryCategory.focus ||
      EntryCategory.highlight ||
      EntryCategory.breathing ||
      EntryCategory.grounding =>
        _IntentEntryBody(
          item: widget.item,
          log: rawData as RoutineLog,
          palette: palette,
          isDark: isDark,
        ),
      EntryCategory.all => _IntentEntryBody(
          item: widget.item,
          log: rawData as RoutineLog,
          palette: palette,
          isDark: isDark,
        ),
    };
  }

  Widget _buildActions(
    Object? rawData,
    _DetailPalette palette,
    bool isDark,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            top: BorderSide(
              color:
                  isDark ? AppColors.darkCardBorder : const Color(0xFFE8E3DA),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (rawData is JournalEntry) ...[
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('entry-detail-edit'),
                  onPressed: _isWorking ? null : () => _editJournal(rawData),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.accent,
                    side: BorderSide(color: palette.accent),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('entry-detail-delete'),
                onPressed: _isWorking ? null : () => _deleteEntry(rawData),
                icon: _isWorking
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Let go'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editJournal(JournalEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => JournalEditorScreen(entry: entry)),
    );
    if (!mounted) return;
    final entries = context.read<JournalProvider>().entries;
    final updated = entries.where((candidate) => candidate.id == entry.id);
    if (updated.isNotEmpty) setState(() => _rawData = updated.first);
  }

  Future<void> _deleteEntry(Object? rawData) async {
    final language = context.read<UserProvider>().language;
    final confirmed = await CozyConfirmSheet.show(
      context,
      title: LanguageHelper.pick(
        language,
        english: 'Let go of this entry?',
        filipino: 'Bitawan ang talang ito?',
      ),
      message: LanguageHelper.pick(
        language,
        english: '“${widget.item.title}” will be permanently removed.',
        filipino: 'Permanenteng buburahin ang “${widget.item.title}”.',
      ),
      confirmLabel: LanguageHelper.pick(
        language,
        english: 'Delete',
        filipino: 'Burahin',
      ),
      cancelLabel: LanguageHelper.pick(
        language,
        english: 'Keep entry',
        filipino: 'Panatilihin',
      ),
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isWorking = true);

    var deleted = false;
    String? error;
    if (rawData is JournalEntry) {
      final provider = context.read<JournalProvider>();
      deleted = await provider.deleteJournalEntry(rawData.id);
      error = provider.errorMessage;
    } else if (rawData is GratitudeEntry) {
      final provider = context.read<GratitudeProvider>();
      deleted = await provider.deleteGratitudeEntry(rawData.id);
      error = provider.errorMessage;
    } else if (rawData is MoodLog) {
      final provider = context.read<MoodProvider>();
      deleted = await provider.deleteMoodLog(rawData.id);
      error = provider.errorMessage;
    } else if (rawData is RoutineLog) {
      final provider = context.read<RoutinesProvider>();
      deleted = await provider.deleteLog(rawData.id);
      error = provider.errorMessage;
    }
    if (!mounted) return;
    setState(() => _isWorking = false);
    if (deleted) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'The entry was not removed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _GratitudeHero extends StatelessWidget {
  const _GratitudeHero({required this.entry, required this.timestamp});

  final GratitudeEntry entry;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final background = GardenLayout.backgroundAssetFor(timestamp);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(background, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black45, Colors.transparent, Colors.black38],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.45),
          child: PolishedFlowerAsset(
            flowerType: entry.flowerType,
            width: 260,
            height: 225,
            glowOpacity: 0.2,
            glowBlur: 10,
            cacheWidth: 420,
            cacheHeight: 770,
          ),
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 16,
          child: Text(
            '${GratitudeEntry.getFlowerName(entry.flowerType)} • Garden ${entry.gardenIndex + 1}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoodHero extends StatelessWidget {
  const _MoodHero({required this.log, required this.palette});

  final MoodLog log;
  final _DetailPalette palette;

  @override
  Widget build(BuildContext context) {
    return _GradientHero(
      palette: palette,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            MoodLog.getMoodAssetPath(log.moodScore),
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 18),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.moodLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${log.moodScore} of 5',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepHero extends StatelessWidget {
  const _SleepHero({required this.log, required this.palette});

  final RoutineLog log;
  final _DetailPalette palette;

  @override
  Widget build(BuildContext context) {
    final sleep = log.sleepFeeling ?? SleepFeeling.moderate;
    return _GradientHero(
      palette: palette,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(sleep.assetPath, width: 160, height: 145),
          const SizedBox(height: 4),
          Text(
            sleep.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Sleep check-in',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _JournalHero extends StatelessWidget {
  const _JournalHero({
    required this.entry,
    required this.palette,
    required this.reflection,
  });

  final JournalEntry entry;
  final _DetailPalette palette;
  final bool reflection;

  @override
  Widget build(BuildContext context) {
    return _GradientHero(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 74, 28, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              reflection
                  ? Icons.nights_stay_outlined
                  : Icons.auto_stories_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              entry.title.isEmpty
                  ? JournalEntry.warmUntitledTitle
                  : entry.title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(
                color: Colors.white,
                fontSize: 25,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              DateFormat('EEEE, MMMM d • h:mm a').format(entry.createdAt),
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentHero extends StatelessWidget {
  const _IntentHero({
    required this.title,
    required this.icon,
    required this.palette,
    required this.timestamp,
  });

  final String title;
  final IconData icon;
  final _DetailPalette palette;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return _GradientHero(
      palette: palette,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30),
            ),
            child: Icon(icon, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            DateFormat('EEEE, MMMM d').format(timestamp),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _GradientHero extends StatelessWidget {
  const _GradientHero({required this.palette, required this.child});

  final _DetailPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.heroStart, palette.heroEnd],
        ),
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}

class _JournalEntryBody extends StatelessWidget {
  const _JournalEntryBody({
    required this.entry,
    required this.palette,
    required this.isDark,
  });

  final JournalEntry entry;
  final _DetailPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final turns = entry.turnsForDisplay;
    final mascot = MascotInfo.getById(entry.companionId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow('THE JOURNAL', palette.accent),
        const SizedBox(height: 12),
        for (var index = 0; index < turns.length; index++) ...[
          _ConversationCard(
            label: index == 0 ? 'You wrote' : 'You continued',
            icon: Icons.edit_note_rounded,
            color: palette.accent,
            surface: palette.surface,
            isDark: isDark,
            markdown: turns[index].userText,
          ),
          if (turns[index].aiResponse?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _ConversationCard(
              label: '${mascot.name} reflected',
              icon: mascot.materialIcon,
              color: mascot.primaryColor,
              surface:
                  mascot.primaryColor.withValues(alpha: isDark ? 0.13 : 0.08),
              isDark: isDark,
              markdown: turns[index].aiResponse!,
            ),
          ],
          if (index < turns.length - 1) const SizedBox(height: 18),
        ],
        if (entry.tags.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: entry.tags
                .map((tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ReflectionEntryBody extends StatelessWidget {
  const _ReflectionEntryBody({
    required this.entry,
    required this.palette,
    required this.isDark,
  });

  final JournalEntry entry;
  final _DetailPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mascot = MascotInfo.getById(entry.companionId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow('YOUR REFLECTION', palette.accent),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.accent.withValues(alpha: 0.2)),
          ),
          child: _MarkdownText(data: entry.content, isDark: isDark, size: 16),
        ),
        if (entry.aiResponse?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 18),
          _ConversationCard(
            label: '${mascot.name} noticed',
            icon: mascot.materialIcon,
            color: mascot.primaryColor,
            surface:
                mascot.primaryColor.withValues(alpha: isDark ? 0.14 : 0.09),
            isDark: isDark,
            markdown: entry.aiResponse!,
          ),
        ],
      ],
    );
  }
}

class _GratitudeEntryBody extends StatelessWidget {
  const _GratitudeEntryBody({
    required this.entry,
    required this.palette,
    required this.isDark,
  });

  final GratitudeEntry entry;
  final _DetailPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Eyebrow('A MEMORY IN BLOOM', palette.accent),
        const SizedBox(height: 13),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(23, 28, 23, 28),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.accent.withValues(alpha: 0.2)),
          ),
          child: Text(
            '“${entry.content}”',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 21,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _InfoTile(
            icon: Icons.local_florist_outlined,
            label: GratitudeEntry.getFlowerMeaning(entry.flowerType),
            color: palette.accent,
            surface: palette.surface,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _MoodEntryBody extends StatelessWidget {
  const _MoodEntryBody({
    required this.log,
    required this.palette,
    required this.isDark,
  });

  final MoodLog log;
  final _DetailPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow('CHECK-IN DETAILS', palette.accent),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.55,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _MetricCard('Stress', log.stressLevel, Icons.bolt_outlined,
                AppColors.softRose, palette.surface, isDark),
            _MetricCard('Energy', log.energyLevel, Icons.battery_charging_full,
                AppColors.honeyAmber, palette.surface, isDark),
            _MetricCard('Sleep', log.sleepQuality, Icons.bedtime_outlined,
                AppColors.skyBlue, palette.surface, isDark),
            _MetricCard('Anxiety', log.anxietyLevel, Icons.waves_rounded,
                AppColors.lavenderMist, palette.surface, isDark),
          ],
        ),
        const SizedBox(height: 20),
        _Eyebrow('WHAT YOU NOTED', palette.accent),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            log.note?.trim().isNotEmpty == true
                ? log.note!
                : 'No note was added to this check-in.',
            style: TextStyle(
              color: log.note?.trim().isNotEmpty == true
                  ? (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight)
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              fontSize: 15,
              height: 1.5,
              fontStyle: log.note?.trim().isNotEmpty == true
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _SleepEntryBody extends StatelessWidget {
  const _SleepEntryBody({
    required this.log,
    required this.palette,
    required this.isDark,
  });

  final RoutineLog log;
  final _DetailPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final sleep = log.sleepFeeling ?? SleepFeeling.moderate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow('REST & ENERGY', palette.accent),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Container(
                    width: 32,
                    height: 9,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index < sleep.score
                          ? palette.accent
                          : palette.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                sleep.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: 17,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        if (log.focusOrHighlight?.trim().isNotEmpty == true &&
            (log.routineId == 'sleep' ||
                log.routineId.startsWith('sleep_') ||
                log.focusOrHighlight!.startsWith('Slept '))) ...[
          Text(log.focusOrHighlight!,
              style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontSize: 16,
                  height: 1.5)),
          const SizedBox(height: 15),
        ],
        _InfoTile(
          icon: Icons.schedule_rounded,
          label: DateFormat('h:mm a • EEEE, MMMM d').format(log.completedAt),
          color: palette.accent,
          surface: palette.surface,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _IntentEntryBody extends StatelessWidget {
  const _IntentEntryBody({
    required this.item,
    required this.log,
    required this.palette,
    required this.isDark,
  });

  final UnifiedFeedItem item;
  final RoutineLog log;
  final _DetailPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isHighlight = item.category == EntryCategory.highlight;
    final isPractice = item.category == EntryCategory.breathing ||
        item.category == EntryCategory.grounding;
    return Column(
      children: [
        _Eyebrow(
          switch (item.category) {
            EntryCategory.breathing => 'BREATHING SESSION',
            EntryCategory.grounding => 'GROUNDING SESSION',
            _ =>
              isHighlight ? 'THE MOMENT YOU KEPT' : 'THE DIRECTION YOU CHOSE',
          },
          palette.accent,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 210),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(29),
            border: Border.all(color: palette.accent.withValues(alpha: 0.22)),
          ),
          child: Center(
            child: Text(
              '“${item.content}”',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 23,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _InfoTile(
          icon: isPractice
              ? Icons.schedule_rounded
              : isHighlight
                  ? Icons.nights_stay_outlined
                  : Icons.wb_sunny_outlined,
          label: isPractice
              ? DateFormat('h:mm a • EEEE, MMMM d').format(log.completedAt)
              : isHighlight
                  ? 'Saved during your evening routine'
                  : 'Chosen during your ${log.routineType.name} routine',
          color: palette.accent,
          surface: palette.surface,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.surface,
    required this.isDark,
    required this.markdown,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color surface;
  final bool isDark;
  final String markdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MarkdownText(data: markdown, isDark: isDark, size: 15),
        ],
      ),
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({
    required this.data,
    required this.isDark,
    required this.size,
  });

  final String data;
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Reading follows the same size the entry was written at, so the person's
    // choice in the editor carries through to every place they read it back.
    final scale = context.watch<UserProvider>().journalTextSize.scale;
    final body = TextStyle(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      fontSize: size * scale,
      height: 1.52,
    );
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: body,
        em: GoogleFonts.lora(
          fontStyle: FontStyle.italic,
          color: isDark ? AppColors.honeyGold : AppColors.honeyAmber,
        ),
        strong: TextStyle(
          fontWeight: FontWeight.w800,
          color: body.color,
        ),
        listBullet: body,
        listIndent: 20 * scale,
        blockSpacing: 10 * scale,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.surface,
    this.isDark,
  );

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color surface;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value / 5',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.surface,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color surface;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.05,
        ),
      ),
    );
  }
}

class _DetailPalette {
  const _DetailPalette({
    required this.accent,
    required this.page,
    required this.surface,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color accent;
  final Color page;
  final Color surface;
  final Color heroStart;
  final Color heroEnd;
}

_DetailPalette _paletteFor(EntryCategory category, bool isDark) {
  final page = isDark ? AppColors.darkBackground : AppColors.warmCream;
  final surface = isDark ? AppColors.darkCard : Colors.white;
  return switch (category) {
    EntryCategory.journal => _DetailPalette(
        accent: AppColors.sageGreen,
        page: page,
        surface: surface,
        heroStart: const Color(0xFF76927B),
        heroEnd: const Color(0xFF405F4C),
      ),
    EntryCategory.reflection => _DetailPalette(
        accent: AppColors.lavenderMist,
        page: page,
        surface: surface,
        heroStart: const Color(0xFF8C83B4),
        heroEnd: const Color(0xFF4C456F),
      ),
    EntryCategory.gratitude => _DetailPalette(
        accent: AppColors.sageGreen,
        page: page,
        surface: surface,
        heroStart: const Color(0xFF79A889),
        heroEnd: const Color(0xFF315C52),
      ),
    EntryCategory.mood => _DetailPalette(
        accent: AppColors.skyBlue,
        page: page,
        surface: surface,
        heroStart: const Color(0xFF87BBD5),
        heroEnd: const Color(0xFF4B759D),
      ),
    EntryCategory.sleep || EntryCategory.breathing => _DetailPalette(
        accent: AppColors.skyBlue,
        page: page,
        surface: surface,
        heroStart: const Color(0xFF596E9D),
        heroEnd: const Color(0xFF273657),
      ),
    EntryCategory.focus || EntryCategory.grounding => _DetailPalette(
        accent: AppColors.sageGreen,
        page: page,
        surface: surface,
        heroStart: const Color(0xFF91AE7B),
        heroEnd: const Color(0xFF4F754F),
      ),
    EntryCategory.highlight => _DetailPalette(
        accent: AppColors.honeyAmber,
        page: page,
        surface: surface,
        heroStart: const Color(0xFFE2A55B),
        heroEnd: const Color(0xFF9B5E62),
      ),
    EntryCategory.all => _DetailPalette(
        accent: AppColors.honeyAmber,
        page: page,
        surface: surface,
        heroStart: AppColors.honeyAmber,
        heroEnd: AppColors.sageGreen,
      ),
  };
}
