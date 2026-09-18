import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/journal_appearance.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/journal_paper_surface.dart';
import 'user_provider.dart';

class JournalAppearanceScreen extends StatelessWidget {
  const JournalAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>();
    final accent = user.journalAccent.color;
    String copy(String english, String filipino) => LanguageHelper.pick(
          user.language,
          english: english,
          filipino: filipino,
        );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(copy('Journal appearance', 'Itsura ng talaarawan')),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: copy('Restore defaults', 'Ibalik sa default'),
            onPressed: user.resetJournalAppearance,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            Text(
              copy(
                'Make your quiet space feel like yours.',
                'Gawing tunay na iyo ang tahimik mong espasyo.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              child: JournalPaperSurface(
                key: ValueKey(
                  '${user.journalPaperStyle.name}-${accent.toARGB32()}'
                  '-${user.journalTextSize.name}',
                ),
                style: user.journalPaperStyle,
                accentColor: accent,
                lineHeight: user.journalTextSize.lineHeight,
                firstLineOffset: 29 + 31 + user.journalTextSize.lineHeight,
                padding: const EdgeInsets.fromLTRB(22, 29, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy('A small good thing', 'Isang munting saya'),
                      style: GoogleFonts.lora(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      copy(
                        'Today felt lighter when I gave myself a moment to breathe.',
                        'Gumaan ang araw nang binigyan ko ang sarili ko ng sandaling huminga.',
                      ),
                      style: GoogleFonts.lora(
                        fontSize: 14 * user.journalTextSize.scale,
                        height: user.journalTextSize.lineHeight /
                            (14 * user.journalTextSize.scale),
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.eco_rounded, size: 15, color: accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            copy('Your journal, your rhythm',
                                'Iyong tala, iyong ritmo'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04),
            const SizedBox(height: 30),
            _SectionLabel(
              title: copy('Paper', 'Papel'),
              subtitle: copy(
                'Used in AI Journal and Daily Reflection',
                'Gagamitin sa AI Journal at Daily Reflection',
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: JournalPaperStyle.values.map((style) {
                    return SizedBox(
                      width: width,
                      child: _PaperChoice(
                        style: style,
                        selected: user.journalPaperStyle == style,
                        accent: accent,
                        isDark: isDark,
                        label: _paperLabel(style, copy),
                        onTap: () => user.setJournalPaperStyle(style),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            _SectionLabel(
              title: copy('Text size', 'Laki ng teksto'),
              subtitle: copy(
                'Applies while you write and when you read entries back',
                'Gagamitin sa pagsulat at sa pagbabalik-basa ng mga tala',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: JournalTextSize.values.map((choice) {
                final selected = user.journalTextSize == choice;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: choice == JournalTextSize.large ? 0 : 10,
                    ),
                    child: Semantics(
                      button: true,
                      selected: selected,
                      child: Material(
                        color: selected
                            ? accent.withValues(alpha: isDark ? 0.22 : 0.13)
                            : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          key: ValueKey('journal-size-${choice.name}'),
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => user.setJournalTextSize(choice),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? accent
                                    : (isDark
                                        ? AppColors.darkCardBorder
                                        : Colors.black
                                            .withValues(alpha: 0.055)),
                                width: selected ? 1.8 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Aa',
                                  style: GoogleFonts.lora(
                                    fontSize: 15 * choice.scale,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  choice.label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? accent
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            _SectionLabel(
              title: copy('Accent color', 'Kulay ng detalye'),
              subtitle: copy(
                'A gentle touch—not a full theme overhaul',
                'Banayad na detalye, hindi sobrang pagbabago',
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : Colors.black.withValues(alpha: 0.055),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: JournalAccent.values.map((choice) {
                  final selected = user.journalAccent == choice;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: _accentLabel(choice, copy),
                    child: Tooltip(
                      message: _accentLabel(choice, copy),
                      child: InkResponse(
                        radius: 28,
                        onTap: () => user.setJournalAccent(choice),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  selected ? choice.color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: choice.color,
                            ),
                            child: selected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 19)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paperLabel(
    JournalPaperStyle style,
    String Function(String, String) copy,
  ) {
    return switch (style) {
      JournalPaperStyle.ruled => copy('Ruled', 'May guhit'),
      JournalPaperStyle.clean => copy('Clean', 'Malinis'),
      JournalPaperStyle.dotted => copy('Dotted', 'May tuldok'),
      JournalPaperStyle.botanical => copy('Botanical', 'May halaman'),
    };
  }

  String _accentLabel(
    JournalAccent accent,
    String Function(String, String) copy,
  ) {
    return switch (accent) {
      JournalAccent.honey => copy('Honey', 'Pulot'),
      JournalAccent.sage => copy('Sage', 'Sage'),
      JournalAccent.rose => copy('Rose', 'Rosas'),
      JournalAccent.lavender => copy('Lavender', 'Lavender'),
      JournalAccent.sky => copy('Sky', 'Langit'),
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _PaperChoice extends StatelessWidget {
  const _PaperChoice({
    required this.style,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  final JournalPaperStyle style;
  final bool selected;
  final Color accent;
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (style) {
      JournalPaperStyle.ruled => Icons.format_align_left_rounded,
      JournalPaperStyle.clean => Icons.crop_portrait_rounded,
      JournalPaperStyle.dotted => Icons.grid_on_rounded,
      JournalPaperStyle.botanical => Icons.eco_outlined,
    };
    return Material(
      color: selected
          ? accent.withValues(alpha: isDark ? 0.16 : 0.09)
          : (isDark ? AppColors.darkCard : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected
              ? accent
              : (isDark ? AppColors.darkCardBorder : Colors.black12),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? accent : null),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
