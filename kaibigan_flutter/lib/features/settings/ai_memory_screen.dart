import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ai_memory_service.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/cozy_confirm_sheet.dart';
import '../../core/widgets/cozy_feature_banner.dart';
import '../../core/widgets/kaibigan_state_view.dart';

class AiMemoryScreen extends StatefulWidget {
  final String language;
  const AiMemoryScreen({super.key, required this.language});

  @override
  State<AiMemoryScreen> createState() => _AiMemoryScreenState();
}

class _AiMemoryScreenState extends State<AiMemoryScreen> {
  bool _loading = true;
  bool _enabled = true;

  String _copy(String english, String filipino) => LanguageHelper.pick(
        widget.language,
        english: english,
        filipino: filipino,
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AIMemoryService.loadPreference();
    await AIMemoryService.fetchMemories();
    if (!mounted) return;
    setState(() {
      _enabled = AIMemoryService.isEnabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await AIMemoryService.setEnabled(value);
  }

  Future<void> _delete(UserMemory memory) async {
    final confirmed = await CozyConfirmSheet.show(
      context,
      title: _copy('Forget this memory?', 'Kalimutan ang memory na ito?'),
      message: _copy(
        'Kaibigan will stop using this detail in future reflections.',
        'Hindi na gagamitin ng Kaibigan ang detalyeng ito sa mga susunod na pagninilay.',
      ),
      confirmLabel: _copy('Forget', 'Kalimutan'),
      cancelLabel: _copy('Keep', 'Panatilihin'),
    );
    if (!confirmed) return;
    final success = await AIMemoryService.deleteMemory(memory.id);
    if (mounted) {
      setState(() {});
      if (!success) _showError();
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await CozyConfirmSheet.show(
      context,
      title: _copy('Forget everything?', 'Kalimutan ang lahat?'),
      message: _copy(
        'All learned themes and coping preferences will be permanently removed.',
        'Permanenteng aalisin ang lahat ng natutuhang tema at coping preferences.',
      ),
      confirmLabel: _copy('Clear memories', 'Burahin lahat'),
      cancelLabel: _copy('Keep them', 'Panatilihin'),
    );
    if (!confirmed) return;
    final success = await AIMemoryService.clearMemories();
    if (mounted) {
      setState(() {});
      if (!success) _showError();
    }
  }

  void _showError() => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_copy(
            'That change could not be synced. Nothing was removed.',
            'Hindi na-sync ang pagbabagong iyon. Walang inalis.',
          )),
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final memories = AIMemoryService.memories;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      appBar: AppBar(
          title: Text(_copy('AI memory & privacy', 'AI memory at privacy'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            CozyFeatureBanner(
              eyebrow: _copy('YOU ARE IN CONTROL', 'IKAW ANG MAY KONTROL'),
              title:
                  _copy('What Kaibigan remembers', 'Ang naaalala ng Kaibigan'),
              subtitle: _copy(
                'Review, pause, or remove the broad themes used for personalization.',
                'Suriin, ihinto, o alisin ang malawak na temang ginagamit sa personalization.',
              ),
              placeholderLabel: 'ai-memory',
              placeholderIcon: Icons.psychology_alt_rounded,
              accent: AppColors.sageGreen,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: AppColors.honeyGold.withValues(alpha: 0.17)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.honeyGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.honeyAmber),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          _copy('Personalized reflections',
                              'Personalized na pagninilay'),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(
                          _enabled
                              ? _copy(
                                  'Use relevant memories when they clearly help',
                                  'Gamitin ang relevant na memory kapag talagang makakatulong')
                              : _copy('Memory use and learning are paused',
                                  'Naka-pause ang paggamit at pagkatuto ng memory'),
                          style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)),
                    ])),
                Switch(
                    value: _enabled,
                    activeThumbColor: AppColors.honeyGold,
                    onChanged: _toggle),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: Text(_copy('Remembered themes', 'Mga naaalalang tema'),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900))),
              if (memories.isNotEmpty)
                TextButton(
                    onPressed: _clearAll,
                    child: Text(_copy('Clear all', 'Burahin lahat'))),
            ]),
            const SizedBox(height: 8),
            if (_loading)
              KaibiganStateView(
                loading: true,
                compact: true,
                title:
                    _copy('Gathering your memories', 'Kinukuha ang memories'),
                message: _copy(
                  'Kaibigan is checking only the themes you chose to keep.',
                  'Sinusuri lamang ng Kaibigan ang mga temang pinili mong itabi.',
                ),
              )
            else if (memories.isEmpty)
              KaibiganStateView(
                icon: Icons.hive_outlined,
                title: _copy('Nothing remembered yet', 'Wala pang naaalala'),
                message: _copy(
                  'Kaibigan keeps only a few broad themes from entries you choose to save.',
                  'Ilang malawak na tema lamang mula sa mga talang pinili mong i-save ang itinatabi ng Kaibigan.',
                ),
                tone: KaibiganStateTone.warm,
                compact: true,
              )
            else
              ...memories.asMap().entries.map((entry) {
                final memory = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.honeyBorder),
                  ),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                              color: _categoryColor(memory.category)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(_categoryLabel(memory.category),
                              style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: _categoryColor(memory.category))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(memory.summary,
                                style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600))),
                        IconButton(
                            onPressed: () => _delete(memory),
                            tooltip: _copy('Forget', 'Kalimutan'),
                            icon: const Icon(Icons.close_rounded, size: 18)),
                      ]),
                )
                    .animate(delay: Duration(milliseconds: 45 * entry.key))
                    .fadeIn()
                    .slideY(begin: 0.04);
              }),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppColors.sageGreen),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(
                      _copy(
                        'Memory stores short summaries—not full journal entries—and only sends up to two relevant themes with an AI request.',
                        'Maiikling buod lamang ang sine-save—hindi buong journal entry—at hanggang dalawang relevant na tema lang ang kasama sa AI request.',
                      ),
                      style: TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight))),
            ]),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'coping_strategy':
        return _copy('COPING', 'PAGHARAP');
      case 'milestone':
        return _copy('MILESTONE', 'TAGUMPAY');
      case 'trigger':
        return _copy('CONTEXT', 'KONTEKSTO');
      default:
        return _copy('THEME', 'TEMA');
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'coping_strategy':
        return AppColors.sageGreen;
      case 'milestone':
        return AppColors.softRose;
      case 'trigger':
        return AppColors.periwinkle;
      default:
        return AppColors.honeyAmber;
    }
  }
}
