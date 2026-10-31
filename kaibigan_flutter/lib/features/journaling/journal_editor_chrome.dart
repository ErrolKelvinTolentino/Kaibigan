import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../companion/companion_model.dart';

/// Journal layout changes are immediate so keyboard resizing and typing do
/// not compete with animated relayout of the conversation.
class JournalAnimatedSize extends StatelessWidget {
  const JournalAnimatedSize(
      {super.key, required this.child, this.alignment = Alignment.topLeft});

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => child;
}

class JournalCompanionHeader extends StatelessWidget {
  const JournalCompanionHeader(
      {super.key,
      required this.mascot,
      required this.language,
      this.compact = false});

  final MascotInfo mascot;
  final String language;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    String copy(String en, String fil) =>
        LanguageHelper.pick(language, english: en, filipino: fil);
    return JournalAnimatedSize(
      alignment: Alignment.topLeft,
      child: Padding(
        key: const ValueKey('journal-companion-header'),
        padding:
            EdgeInsets.only(top: compact ? 0 : 4, bottom: compact ? 8 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      copy('WITH ${mascot.name.toUpperCase()}',
                          'KASAMA SI ${mascot.name.toUpperCase()}'),
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          color: palette.accentStrong)),
                  const SizedBox(height: 7),
                  Text(copy('Write it as it comes', 'Isulat nang malaya'),
                      style: GoogleFonts.lora(
                          fontSize: compact ? 18 : 24,
                          height: 1.22,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary)),
                  if (!compact) ...[
                    const SizedBox(height: 7),
                    Text(
                        copy('Your words. Your pace.',
                            'Mga salita mo. Sa sarili mong ritmo.'),
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: palette.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalPromptCard extends StatelessWidget {
  const JournalPromptCard(
      {super.key,
      required this.text,
      required this.onShuffle,
      required this.shuffleLabel});

  final String text;
  final VoidCallback onShuffle;
  final String shuffleLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return Container(
      key: const ValueKey('journal-writing-prompt'),
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
          color: palette.accentSubtle,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.accent.withValues(alpha: 0.18))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.lightbulb_outline_rounded,
                size: 18, color: palette.accentStrong)),
        const SizedBox(width: 9),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(text,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: palette.textPrimary)))),
        IconButton(
            tooltip: shuffleLabel,
            onPressed: onShuffle,
            icon: const Icon(Icons.refresh_rounded, size: 18)),
      ]),
    );
  }
}
