import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_logo.dart';
import '../settings/user_provider.dart';

class KaiValueDemoScreen extends StatefulWidget {
  const KaiValueDemoScreen({
    super.key,
    required this.onContinue,
  });

  /// `true` opens registration; `false` opens sign in.
  final ValueChanged<bool> onContinue;

  @override
  State<KaiValueDemoScreen> createState() => _KaiValueDemoScreenState();
}

class _KaiValueDemoScreenState extends State<KaiValueDemoScreen> {
  String? _selectedFeeling;

  static const _feelings = <String>['overwhelmed', 'drained', 'hopeful'];

  String _copy(
    String language, {
    required String english,
    required String filipino,
    String? taglish,
  }) =>
      LanguageHelper.pick(
        language,
        english: english,
        filipino: filipino,
        taglish: taglish,
      );

  Future<void> _setLanguage(String language) async {
    HapticFeedback.selectionClick();
    await context.read<UserProvider>().setLanguage(language);
  }

  void _selectFeeling(String feeling) {
    HapticFeedback.selectionClick();
    setState(() => _selectedFeeling = feeling);
  }

  String _feelingLabel(String feeling, String language) => switch (feeling) {
        'overwhelmed' => _copy(
            language,
            english: 'Overwhelmed',
            filipino: 'Nabibigatan',
            taglish: 'Overwhelmed',
          ),
        'drained' => _copy(
            language,
            english: 'Drained',
            filipino: 'Ubos ang lakas',
            taglish: 'Drained',
          ),
        _ => _copy(
            language,
            english: 'A little hopeful',
            filipino: 'May kaunting pag-asa',
            taglish: 'Medyo hopeful',
          ),
      };

  String _sampleMessage(String feeling, String language) => switch (feeling) {
        'overwhelmed' => _copy(
            language,
            english:
                'Everything feels urgent and I do not know where to start.',
            filipino:
                'Parang sabay-sabay ang lahat at hindi ko alam kung saan magsisimula.',
            taglish:
                'Parang urgent lahat at hindi ko alam kung saan magsisimula.',
          ),
        'drained' => _copy(
            language,
            english: 'I made it through today, but I have almost nothing left.',
            filipino:
                'Nalampasan ko ang araw, pero halos ubos na ang lakas ko.',
            taglish:
                'Kinaya ko today, pero parang wala nang natitirang energy.',
          ),
        _ => _copy(
            language,
            english: 'Today was not easy, but one small thing went right.',
            filipino:
                'Hindi madali ang araw, pero may isang munting bagay na naging maayos.',
            taglish:
                'Hindi easy ang today, pero may isang small thing na naging okay.',
          ),
      };

  String _kaiResponse(String feeling, String language) => switch (feeling) {
        'overwhelmed' => _copy(
            language,
            english:
                'That sounds like too much to hold at once. We do not need to solve the whole day. Want to name the one thing that needs your attention first?',
            filipino:
                'Mukhang napakarami mong pasan nang sabay-sabay. Hindi kailangang ayusin ang buong araw ngayon. Maaari ba nating tukuyin ang isang bagay na kailangan munang harapin?',
            taglish:
                'Ang dami mong hawak sabay-sabay. Hindi natin kailangang ayusin ang buong araw ngayon. Piliin natin ang isang bagay na kailangan munang harapin?',
          ),
        'drained' => _copy(
            language,
            english:
                'You have already spent a lot of yourself today. Before asking for more, let us make the next minute softer. Would rest, water, or quiet feel most possible?',
            filipino:
                'Marami ka nang naibigay ngayong araw. Bago humingi pa sa sarili, gawin nating mas magaan ang susunod na minuto. Pahinga, tubig, o katahimikan—alin ang kaya ngayon?',
            taglish:
                'Ang dami mo nang naibigay today. Bago humingi pa sa sarili, gawin muna nating softer ang next minute. Rest, water, or quiet—ano ang pinaka-kaya?',
          ),
        _ => _copy(
            language,
            english:
                'That small thing matters. It does not erase the hard parts, but it gives us something real to keep. What helped that moment happen?',
            filipino:
                'Mahalaga ang munting bagay na iyon. Hindi nito binubura ang hirap, pero may tunay kang sandaling maaaring panghawakan. Ano ang nakatulong upang mangyari iyon?',
            taglish:
                'Mahalaga iyong small win. Hindi nito binubura ang hard parts, pero may tunay kang moment na puwedeng panghawakan. Ano ang nakatulong doon?',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = context.watch<UserProvider>().language;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      key: const ValueKey('kai-value-demo-screen'),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.warmCream,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF25261F), Color(0xFF191C1A)]
                : const [Color(0xFFFFFCF5), Color(0xFFFFF2CF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.clamp(0, 720).toDouble();
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Center(
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const KaibiganWordmark(fontSize: 24),
                            const Spacer(),
                            _LanguageMenu(
                              language: language,
                              isDark: isDark,
                              onSelected: _setLanguage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.honeyAmber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _copy(
                              language,
                              english: 'MEET KAI — NO ACCOUNT NEEDED',
                              filipino:
                                  'KILALANIN SI KAI — WALANG ACCOUNT MUNA',
                              taglish: 'MEET KAI — NO ACCOUNT MUNA',
                            ),
                            style: const TextStyle(
                              color: AppColors.honeyAmber,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.75,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _copy(
                            language,
                            english:
                                'A companion for the moment you are actually in.',
                            filipino:
                                'Isang kasama para sa sandaling tunay mong nararanasan.',
                            taglish:
                                'A companion for the moment you are actually in.',
                          ),
                          style: TextStyle(
                            color: primary,
                            fontSize: constraints.maxWidth < 380 ? 30 : 36,
                            height: 1.08,
                            letterSpacing: -1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _copy(
                            language,
                            english:
                                'Try one private sample. Nothing here is saved or sent.',
                            filipino:
                                'Subukan ang isang pribadong halimbawa. Walang isi-save o ipapadala.',
                            taglish:
                                'Try one private sample. Walang ise-save o ipapadala.',
                          ),
                          style: TextStyle(
                            color: secondary,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _copy(
                            language,
                            english: 'What feels closest to today?',
                            filipino:
                                'Ano ang pinakamalapit sa nararamdaman mo?',
                            taglish:
                                'Ano ang closest sa nararamdaman mo today?',
                          ),
                          style: TextStyle(
                            color: primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: _feelings.map((feeling) {
                            final selected = _selectedFeeling == feeling;
                            return ChoiceChip(
                              key: ValueKey('demo-feeling-$feeling'),
                              selected: selected,
                              onSelected: (_) => _selectFeeling(feeling),
                              showCheckmark: false,
                              avatar: Icon(
                                switch (feeling) {
                                  'overwhelmed' => Icons.waves_rounded,
                                  'drained' => Icons.battery_1_bar_rounded,
                                  _ => Icons.wb_sunny_outlined,
                                },
                                size: 17,
                                color: selected
                                    ? AppColors.onHoney
                                    : AppColors.honeyAmber,
                              ),
                              label: Text(_feelingLabel(feeling, language)),
                              selectedColor: AppColors.honeyAmber,
                              backgroundColor:
                                  isDark ? AppColors.darkCard : Colors.white,
                              labelStyle: TextStyle(
                                color: selected ? AppColors.onHoney : primary,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.honeyAmber
                                    : AppColors.honeyBorder,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            );
                          }).toList(growable: false),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: _selectedFeeling == null
                              ? _EmptyDemoCard(
                                  key: const ValueKey('demo-empty-state'),
                                  language: language,
                                  isDark: isDark,
                                )
                              : _ConversationDemoCard(
                                  key: ValueKey(
                                    'demo-response-${_selectedFeeling!}',
                                  ),
                                  message: _sampleMessage(
                                    _selectedFeeling!,
                                    language,
                                  ),
                                  response: _kaiResponse(
                                    _selectedFeeling!,
                                    language,
                                  ),
                                  isDark: isDark,
                                ),
                        ),
                        const SizedBox(height: 22),
                        _LoopPreview(language: language, isDark: isDark),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const ValueKey('demo-create-account'),
                            onPressed: _selectedFeeling == null
                                ? null
                                : () => widget.onContinue(true),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: AppColors.honeyAmber,
                              foregroundColor: AppColors.onHoney,
                            ),
                            child: Text(
                              _copy(
                                language,
                                english: 'Create my private space',
                                filipino: 'Gawin ang pribadong espasyo ko',
                                taglish: 'Create my private space',
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            key: const ValueKey('demo-sign-in'),
                            onPressed: () => widget.onContinue(false),
                            child: Text(
                              _copy(
                                language,
                                english: 'I already have an account',
                                filipino: 'May account na ako',
                                taglish: 'May account na ako',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConversationDemoCard extends StatelessWidget {
  const _ConversationDemoCard({
    super.key,
    required this.message,
    required this.response,
    required this.isDark,
  });

  final String message;
  final String response;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.honeyBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 470),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.honeyAmber.withValues(alpha: 0.14),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(color: primary, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.honeyAmber,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: AppColors.onHoney,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KAI',
                      style: TextStyle(
                        color: AppColors.honeyAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      response,
                      key: const ValueKey('demo-kai-response'),
                      style: TextStyle(
                        color: primary,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDemoCard extends StatelessWidget {
  const _EmptyDemoCard({
    super.key,
    required this.language,
    required this.isDark,
  });

  final String language;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCard : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.honeyBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.honeyAmber, size: 28),
          const SizedBox(height: 10),
          Text(
            LanguageHelper.pick(
              language,
              english: 'Choose a feeling to see how Kai responds.',
              filipino: 'Pumili ng pakiramdam upang makita ang tugon ni Kai.',
              taglish:
                  'Choose a feeling para makita kung paano sasagot si Kai.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoopPreview extends StatelessWidget {
  const _LoopPreview({required this.language, required this.isDark});

  final String language;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final labels = language == 'filipino'
        ? const [
            'Mag-check in',
            'Makinig si Kai',
            'Gumawa ng hakbang',
            'Makakita ng pattern'
          ]
        : const ['Check in', 'Kai listens', 'Take one step', 'Notice patterns'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageHelper.pick(
            language,
            english: 'More than a chat. A gentle loop that learns with you.',
            filipino:
                'Higit sa usapan. Banayad na prosesong natututo kasama mo.',
            taglish: 'More than a chat. A gentle loop that learns with you.',
          ),
          style: TextStyle(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: index == 1
                                ? AppColors.honeyAmber
                                : AppColors.honeyAmber.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            [
                              Icons.favorite_outline_rounded,
                              Icons.chat_bubble_outline_rounded,
                              Icons.spa_outlined,
                              Icons.insights_outlined,
                            ][index],
                            size: 15,
                            color: index == 1
                                ? AppColors.onHoney
                                : AppColors.honeyAmber,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[index],
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 9.5,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < labels.length - 1)
                    Container(
                      width: 8,
                      height: 1,
                      color: AppColors.honeyBorder,
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({
    required this.language,
    required this.isDark,
    required this.onSelected,
  });

  final String language;
  final bool isDark;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const ValueKey('demo-language-menu'),
      initialValue: language,
      onSelected: onSelected,
      tooltip: 'Choose language',
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'taglish', child: Text('Taglish')),
        PopupMenuItem(value: 'filipino', child: Text('Filipino')),
        PopupMenuItem(value: 'english', child: Text('English')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.honeyBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
                size: 16, color: AppColors.honeyAmber),
            const SizedBox(width: 6),
            Text(
              language == 'filipino'
                  ? 'Filipino'
                  : language == 'english'
                      ? 'English'
                      : 'Taglish',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
