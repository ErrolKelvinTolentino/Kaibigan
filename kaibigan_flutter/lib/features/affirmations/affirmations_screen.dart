import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_state_view.dart';
import '../settings/user_provider.dart';
import 'affirmation_model.dart';
import 'affirmations_provider.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  String? _preparedCategoryId;
  String? _preparedLanguage;
  List<String> _feed = const [];
  bool _choosingCategory = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AffirmationsProvider>();
    final language = context.watch<UserProvider>().language;
    final category = provider.selectedCategory;
    if (category != null &&
        (category.id != _preparedCategoryId || language != _preparedLanguage)) {
      _prepareFeed(category, provider, language);
    }
  }

  void _prepareFeed(
    AffirmationCategory category,
    AffirmationsProvider provider,
    String language,
  ) {
    final today = provider.affirmationForDay(
      DateTime.now(),
      language: language,
    );
    final shuffled = List<String>.of(category.affirmationsFor(language))
      ..shuffle(Random());
    if (today != null) {
      shuffled.remove(today);
      shuffled.insert(0, today);
    }
    _preparedCategoryId = category.id;
    _preparedLanguage = language;
    _feed = shuffled;
  }

  void _reshuffle() {
    final provider = context.read<AffirmationsProvider>();
    final category = provider.selectedCategory;
    if (category == null) return;
    final language = context.read<UserProvider>().language;
    setState(() {
      _preparedCategoryId = null;
      _preparedLanguage = null;
      _prepareFeed(category, provider, language);
    });
  }

  Future<void> _selectCategory(String id) async {
    await context.read<AffirmationsProvider>().selectCategory(id);
    if (!mounted) return;
    setState(() {
      _choosingCategory = false;
      _preparedCategoryId = null;
      _preparedLanguage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AffirmationsProvider>();
    final language = context.watch<UserProvider>().language;
    final category = provider.selectedCategory;
    final showChooser = _choosingCategory || category == null;
    String copy(String english, String filipino, [String? taglish]) =>
        LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
          taglish: taglish,
        );

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.warmCream,
      appBar: AppBar(
        title: Text(
          showChooser
              ? copy('Choose your focus', 'Piliin ang iyong pokus',
                  'Choose your focus')
              : copy('Affirmations', 'Mga paalala', 'Affirmations'),
        ),
        actions: [
          if (!showChooser) ...[
            IconButton(
              tooltip: copy('Change focus', 'Baguhin ang pokus'),
              onPressed: () => setState(() => _choosingCategory = true),
              icon: const Icon(Icons.tune_rounded),
            ),
            IconButton(
              tooltip: copy('Reshuffle', 'Ihalo muli'),
              onPressed: _reshuffle,
              icon: const Icon(Icons.shuffle_rounded),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: !provider.isLoaded
            ? Center(
                child: KaibiganStateView(
                  loading: true,
                  title: copy(
                    'Finding a gentle reminder',
                    'Naghahanap ng banayad na paalala',
                  ),
                  message: copy(
                    'A few supportive words are almost ready.',
                    'Malapit nang maging handa ang ilang salitang makakatulong.',
                  ),
                  compact: true,
                ),
              )
            : showChooser
                ? _CategoryChooser(
                    language: language,
                    selectedId: category?.id,
                    onSelected: _selectCategory,
                  )
                : _AffirmationFeed(
                    key: ValueKey('affirmation-feed-${category.id}'),
                    category: category,
                    affirmations: _feed,
                    language: language,
                  ),
      ),
    );
  }
}

class _CategoryChooser extends StatelessWidget {
  final String language;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _CategoryChooser({
    required this.language,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String copy(String english, String filipino, [String? taglish]) =>
        LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
          taglish: taglish,
        );

    return CustomScrollView(
      key: const ValueKey('affirmation-category-chooser'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy(
                    'What kind of reminder would feel supportive?',
                    'Anong uri ng paalala ang makatutulong?',
                    'Anong reminder ang makakatulong today?',
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  copy(
                    'There is no right choice. You can change your focus whenever you need.',
                    'Walang maling pili. Maaari mong baguhin ang pokus anumang oras.',
                    'Walang wrong choice. You can change your focus anytime.',
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          sliver: SliverList.separated(
            itemCount: AffirmationCatalog.categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 11),
            itemBuilder: (context, index) {
              final category = AffirmationCatalog.categories[index];
              final visual = _CategoryVisual.forId(category.id);
              final localized = _localizedCategory(category, language);
              final selected = selectedId == category.id;
              return Semantics(
                button: true,
                selected: selected,
                child: InkWell(
                  key: ValueKey('affirmation-category-${category.id}'),
                  onTap: () => onSelected(category.id),
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected
                            ? visual.color
                            : isDark
                                ? AppColors.darkCardBorder
                                : const Color(0xFFEDE8DE),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: visual.color.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(visual.icon, color: visual.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localized.title,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                localized.subtitle,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color: visual.color,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AffirmationFeed extends StatefulWidget {
  final AffirmationCategory category;
  final List<String> affirmations;
  final String language;

  const _AffirmationFeed({
    super.key,
    required this.category,
    required this.affirmations,
    required this.language,
  });

  @override
  State<_AffirmationFeed> createState() => _AffirmationFeedState();
}

class _AffirmationFeedState extends State<_AffirmationFeed> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _CategoryVisual.forId(widget.category.id);
    final localized = _localizedCategory(widget.category, widget.language);
    String copy(String english, String filipino, [String? taglish]) =>
        LanguageHelper.pick(
          widget.language,
          english: english,
          filipino: filipino,
          taglish: taglish,
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(visual.icon, size: 14, color: visual.color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          localized.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: visual.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_page + 1} / ${widget.affirmations.length}',
                key: const ValueKey('affirmation-progress'),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            key: const ValueKey('affirmation-vertical-feed'),
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.affirmations.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            visual.color.withValues(alpha: 0.22),
                            AppColors.darkCard,
                          ]
                        : [
                            visual.color.withValues(alpha: 0.19),
                            Colors.white,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: visual.color.withValues(alpha: 0.25),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: visual.color.withValues(alpha: 0.7),
                      size: 34,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.affirmations[index],
                      key: ValueKey('affirmation-$index'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 26,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      copy(
                        'Keep what feels honest. Skip what does not.',
                        'Piliin ang tapat sa iyo. Laktawan ang hindi.',
                        'Keep what feels honest. Skip what does not.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (index < widget.affirmations.length - 1)
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Icon(Icons.keyboard_arrow_up_rounded,
                              size: 18, color: visual.color),
                          Text(
                            copy('Swipe for another', 'Mag-swipe para sa iba',
                                'Swipe for another'),
                            style: TextStyle(
                              color: visual.color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        copy(
                          'You reached all 30. Reshuffle whenever you want.',
                          'Nakita mo na ang 30. Ihalo muli anumang oras.',
                          'You reached all 30. Reshuffle anytime.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: visual.color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
  }
}

({String title, String subtitle}) _localizedCategory(
  AffirmationCategory category,
  String language,
) {
  return (
    title: category.titleFor(language),
    subtitle: category.subtitleFor(language),
  );
}

class _CategoryVisual {
  final IconData icon;
  final Color color;

  const _CategoryVisual(this.icon, this.color);

  static _CategoryVisual forId(String id) => switch (id) {
        'self_worth' => const _CategoryVisual(
            Icons.favorite_outline_rounded, AppColors.honeyAmber),
        'quiet_confidence' =>
          const _CategoryVisual(Icons.wb_sunny_outlined, AppColors.honeyGold),
        'self_compassion' => const _CategoryVisual(
            Icons.volunteer_activism_outlined, AppColors.warmHoney),
        'calm_grounding' =>
          const _CategoryVisual(Icons.spa_outlined, AppColors.honeyAmber),
        'resilience_growth' =>
          const _CategoryVisual(Icons.eco_outlined, AppColors.honeyGold),
        _ => const _CategoryVisual(
            Icons.people_outline_rounded, AppColors.warmHoney),
      };
}
