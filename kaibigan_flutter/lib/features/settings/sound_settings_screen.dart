import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/ui_sound_service.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_sound_scope.dart';
import '../../core/widgets/kaibigan_surface.dart';
import '../../core/widgets/mobile_layout.dart';
import 'user_provider.dart';

/// Controls for the app's interface sound.
///
/// Sound is the kind of thing people want to change the moment it annoys them,
/// so every option previews itself the instant it is chosen — nobody should
/// have to leave this screen and tap around to hear what they picked.
class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key, required this.language});

  final String language;

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  UiSoundController? _sound;

  String _copy(String english, String filipino) => LanguageHelper.pick(
        widget.language,
        english: english,
        filipino: filipino,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sound = KaibiganSoundScope.maybeOf(context);
  }

  Future<void> _setLevel(UiSoundLevel level) async {
    final sound = _sound;
    if (sound == null) return;
    await sound.setLevel(level);
    if (!mounted) return;
    try {
      final user = Provider.of<UserProvider>(context, listen: false);
      await user.setUiSoundLevel(level, soundController: sound);
    } catch (_) {}
    if (!mounted) return;
    setState(() {});
    // The chosen level plays itself, so the choice is audible immediately.
    sound.play(UiSound.select);
  }

  String _levelLabel(UiSoundLevel level) => switch (level) {
        UiSoundLevel.off => _copy('Off', 'Naka-off'),
        UiSoundLevel.soft => _copy('Soft', 'Mahina'),
        UiSoundLevel.balanced => _copy('Balanced', 'Katamtaman'),
        UiSoundLevel.full => _copy('Full', 'Malakas'),
      };

  String _levelDescription(UiSoundLevel level) => switch (level) {
        UiSoundLevel.off =>
          _copy('No interface sound at all.', 'Walang tunog ang interface.'),
        UiSoundLevel.soft => _copy(
            'Barely there. Easy to miss in a quiet room.',
            'Halos hindi marinig. Mahina sa tahimik na kwarto.',
          ),
        UiSoundLevel.balanced => _copy(
            'Clear without being loud. A good default.',
            'Malinaw pero hindi maingay. Magandang default.',
          ),
        UiSoundLevel.full => _copy(
            'Loudest. Useful with the phone at arm\'s length.',
            'Pinakamalakas. Bagay kung malayo ang telepono.',
          ),
      };

  String _cueLabel(UiSound sound) => switch (sound) {
        UiSound.tap => _copy('Tap', 'Pag-tap'),
        UiSound.select => _copy('Choosing', 'Pagpili'),
        UiSound.open => _copy('Opening', 'Pagbukas'),
        UiSound.success => _copy('Saved', 'Na-save'),
        UiSound.complete => _copy('Finished', 'Tapos'),
        UiSound.gentle => _copy('Needs attention', 'May kailangang tingnan'),
      };

  String _cueDescription(UiSound sound) => switch (sound) {
        UiSound.tap =>
          _copy('Any ordinary press.', 'Anumang karaniwang pindot.'),
        UiSound.select => _copy(
            'Picking an option, a mood, a flower.',
            'Pagpili ng opsyon, mood, o bulaklak.',
          ),
        UiSound.open => _copy(
            'A sheet or screen arriving.',
            'Pagdating ng sheet o screen.',
          ),
        UiSound.success => _copy(
            'An entry, a log or a check-in saved.',
            'Na-save na tala, log, o check-in.',
          ),
        UiSound.complete => _copy(
            'A lesson, routine or session finished.',
            'Natapos na aralin, routine, o session.',
          ),
        UiSound.gentle => _copy(
            'Something needs a second look. Never a buzz.',
            'May dapat tingnan muli. Hindi kailanman matalas.',
          ),
      };

  IconData _cueIcon(UiSound sound) => switch (sound) {
        UiSound.tap => Icons.touch_app_outlined,
        UiSound.select => Icons.check_circle_outline_rounded,
        UiSound.open => Icons.web_asset_rounded,
        UiSound.success => Icons.bookmark_added_outlined,
        UiSound.complete => Icons.celebration_outlined,
        UiSound.gentle => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final sound = _sound;
    final level = sound?.level ?? UiSoundLevel.off;
    final silent = sound == null || level.isSilent;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(_copy('Sound', 'Tunog')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: MobileContent(
          child: ListView(
            padding: MobileLayout.pageInsets(context, top: 8, bottom: 32),
            children: [
              Text(
                _copy(
                  'Kaibigan can answer your taps with a quiet sound. Every cue '
                  'is soft, low and short — the kind you stop noticing but '
                  'would miss.',
                  'Maaaring sagutin ng Kaibigan ang mga pindot mo ng banayad '
                  'na tunog. Mahina, mababa, at maikli ang bawat isa.',
                ),
                style: text.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: KaibiganSpace.lg),
              Text(
                _copy('VOLUME', 'LAKAS'),
                style: text.labelSmall?.copyWith(
                  color: palette.textMuted,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: KaibiganSpace.xs),
              ...UiSoundLevel.values.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: KaibiganSpace.xs),
                  child: KaibiganSurface(
                    key: ValueKey('ui-sound-level-${option.name}'),
                    onTap: sound == null ? null : () => _setLevel(option),
                    tone: option == level
                        ? KaibiganSurfaceTone.accent
                        : KaibiganSurfaceTone.elevated,
                    padding: const EdgeInsets.all(KaibiganSpace.sm),
                    semanticLabel: _levelLabel(option),
                    child: Row(
                      children: [
                        Icon(
                          option == level
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: option == level
                              ? palette.accent
                              : palette.textMuted,
                          size: 21,
                        ),
                        const SizedBox(width: KaibiganSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _levelLabel(option),
                                style: text.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _levelDescription(option),
                                style: text.bodySmall?.copyWith(
                                  color: palette.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: KaibiganSpace.lg),
              Text(
                _copy('WHAT EACH SOUND MEANS', 'ANO ANG IBIG SABIHIN'),
                style: text.labelSmall?.copyWith(
                  color: palette.textMuted,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: KaibiganSpace.xs),
              Text(
                silent
                    ? _copy(
                        'Turn sound on above to hear these.',
                        'I-on ang tunog sa itaas para marinig ang mga ito.',
                      )
                    : _copy(
                        'Tap any row to hear it.',
                        'I-tap ang alinman para marinig.',
                      ),
                style: text.bodySmall?.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: KaibiganSpace.xs),
              ...UiSound.values.map(
                (cue) => Padding(
                  padding: const EdgeInsets.only(bottom: KaibiganSpace.xs),
                  child: Opacity(
                    opacity: silent ? 0.5 : 1,
                    child: KaibiganSurface(
                      key: ValueKey('ui-sound-preview-${cue.name}'),
                      onTap: silent ? null : () => sound.play(cue),
                      padding: const EdgeInsets.all(KaibiganSpace.sm),
                      semanticLabel: _cueLabel(cue),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: palette.accentSubtle,
                              borderRadius:
                                  BorderRadius.circular(KaibiganRadius.control),
                            ),
                            child: Icon(
                              _cueIcon(cue),
                              size: 18,
                              color: palette.accentStrong,
                            ),
                          ),
                          const SizedBox(width: KaibiganSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_cueLabel(cue), style: text.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  _cueDescription(cue),
                                  style: text.bodySmall?.copyWith(
                                    color: palette.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!silent)
                            Icon(
                              Icons.play_arrow_rounded,
                              color: palette.textMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: KaibiganSpace.md),
              Text(
                _copy(
                  'Interface sound follows your phone\'s media volume and its '
                  'silent switch. It is separate from the background sound in '
                  'breathing sessions.',
                  'Sumusunod ang tunog ng interface sa media volume at silent '
                  'switch ng telepono mo. Hiwalay ito sa background sound ng '
                  'breathing.',
                ),
                style: text.bodySmall?.copyWith(
                  color: palette.textMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
