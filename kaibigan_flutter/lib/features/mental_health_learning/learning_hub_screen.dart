import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_state_view.dart';
import '../../core/widgets/kaibigan_surface.dart';
import '../../core/widgets/mobile_layout.dart';
import '../settings/user_provider.dart';
import '../mood_tracking/mood_model.dart';
import 'learning_catalog.dart';
import 'learning_lesson_screen.dart';
import 'learning_model.dart';
import 'learning_progress_store.dart';
import 'learning_toolkit_screen.dart';
import 'friend_support/friend_support_hub_screen.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  final _searchController = TextEditingController();
  final _progressStore = LearningProgressStore();
  Set<String> _completed = {};
  LearningCategory? _category;
  LearningPath? _path;
  String? _lastLessonId;
  int _lastIdeaIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await _progressStore.loadCompleted();
    final lastLessonId = await _progressStore.loadLastLessonId();
    final resumeLesson = _lessonForId(lastLessonId);
    final lastIdeaIndex = resumeLesson == null
        ? 0
        : await _progressStore.loadIdeaIndex(
            resumeLesson.id,
            max: resumeLesson.sections.length,
          );
    if (!mounted) return;
    setState(() {
      _completed = completed.where((id) => _lessonForId(id) != null).toSet();
      _lastLessonId = lastLessonId;
      _lastIdeaIndex = lastIdeaIndex;
    });
  }

  LearningLesson? _lessonForId(String? id) {
    if (id == null) return null;
    for (final lesson in LearningCatalog.lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openLesson(LearningLesson lesson) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: KaibiganMotion.reveal,
        reverseTransitionDuration: KaibiganMotion.standard,
        pageBuilder: (_, __, ___) => LearningLessonScreen(lesson: lesson),
        transitionsBuilder: (context, animation, _, child) {
          if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
            return child;
          }
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: KaibiganMotion.enter,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: KaibiganMotion.enter,
              )),
              child: child,
            ),
          );
        },
      ),
    );
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserProvider>().language;
    final palette = context.kaibigan;
    final query = _searchController.text.trim().toLowerCase();
    final showSafetyResult = _isSafetySearch(query);
    final lessons = LearningCatalog.lessons.where((lesson) {
      final inCategory = _category == null || lesson.category == _category;
      final inPath = _path == null || _path!.lessonIds.contains(lesson.id);
      final searchable = [
        lesson.title.resolve(language),
        lesson.summary.resolve(language),
        lesson.category.label(language),
        lesson.title.english,
        lesson.title.filipino,
        lesson.summary.english,
        lesson.summary.filipino,
        ...lesson.searchTerms,
        ...lesson.sections.expand(
          (section) => [
            section.heading.english,
            section.heading.filipino,
            section.body.english,
            section.body.filipino,
          ],
        ),
      ].join(' ').toLowerCase();
      return inCategory &&
          inPath &&
          (query.isEmpty || searchable.contains(query));
    }).toList()
      ..sort((a, b) {
        if (_path != null) {
          return _path!.lessonIds
              .indexOf(a.id)
              .compareTo(_path!.lessonIds.indexOf(b.id));
        }
        if (_category != null) {
          return LearningCatalog.lessons
              .indexOf(a)
              .compareTo(LearningCatalog.lessons.indexOf(b));
        }
        int rank(LearningCategory category) => switch (category) {
              LearningCategory.foundations => 0,
              LearningCategory.conditions => 1,
              LearningCategory.coping => 2,
              LearningCategory.emotions => 3,
              LearningCategory.support => 4,
            };
        final byCategory = rank(a.category).compareTo(rank(b.category));
        return byCategory != 0
            ? byCategory
            : LearningCatalog.lessons
                .indexOf(a)
                .compareTo(LearningCatalog.lessons.indexOf(b));
      });
    final resumeLesson = _lessonForId(_lastLessonId);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          LanguageHelper.pick(
            language,
            english: 'Learn',
            filipino: 'Matuto',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            key: const ValueKey('open-learning-toolkit'),
            tooltip: LanguageHelper.pick(
              language,
              english: 'Saved ideas',
              filipino: 'Mga itinabing ideya',
            ),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const LearningToolkitScreen()),
            ),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: MobileContent(
            child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          key: const ValueKey('learning-hub-scroll-view'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                MobileLayout.horizontalPadding(context),
                12,
                MobileLayout.horizontalPadding(context),
                16,
              ),
              sliver: SliverList.list(
                children: [
                  Container(
                    key: const ValueKey('learning-intro-card'),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.accentSubtle,
                          Theme.of(context).brightness == Brightness.dark
                              ? palette.surfaceElevated
                              : AppColors.pollenGlow.withValues(alpha: 0.72),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.shadow,
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          key: const ValueKey('learning-hub-art'),
                          width: 54,
                          height: 54,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: palette.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Image.asset(
                            FeatureIconHelper.learn,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.local_library_outlined,
                              color: palette.accent,
                              size: 29,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageHelper.pick(
                                  language,
                                  english: 'A little understanding helps',
                                  filipino: 'Unti-unting unawain ang sarili',
                                ),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                LanguageHelper.pick(
                                  language,
                                  english:
                                      'Small, practical lessons for everyday life.',
                                  filipino:
                                      'Maiikli at praktikal na aralin para sa araw-araw.',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: palette.textSecondary),
                              ),
                              if (_completed.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                    LanguageHelper.pick(language,
                                        english:
                                            '${_completed.length} lessons explored · at your pace',
                                        filipino:
                                            '${_completed.length} araling natapos · sa sarili mong bilis'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: palette.accentStrong)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (resumeLesson != null) ...[
                    const SizedBox(height: 12),
                    _ContinueLearningCard(
                      lesson: resumeLesson,
                      language: language,
                      ideaIndex: _lastIdeaIndex,
                      completed: _completed.contains(resumeLesson.id),
                      onTap: () => _openLesson(resumeLesson),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    key: const ValueKey('learning-search-field'),
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: LanguageHelper.pick(
                        language,
                        english: 'Search a topic',
                        filipino: 'Maghanap ng paksa',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: LanguageHelper.pick(
                                language,
                                english: 'Clear search',
                                filipino: 'Burahin ang hinanap',
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  if (query.isEmpty) ...[
                    const SizedBox(height: 14),
                    _FriendSupportEntryCard(
                      language: language,
                      onTap: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            settings: const RouteSettings(name: 'friend_support_hub'),
                            builder: (_) => const FriendSupportHubScreen(),
                          ),
                        );
                        await _loadProgress();
                      },
                    ),
                    const SizedBox(height: 22),
                    Semantics(
                      headingLevel: 2,
                      child: Text(
                        LanguageHelper.pick(
                          language,
                          english: 'What would help right now?',
                          filipino: 'Ano ang makakatulong ngayon?',
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      LanguageHelper.pick(
                        language,
                        english: 'Choose a topic that fits your day.',
                        filipino: 'Pumili ng paksang angkop sa araw mo.',
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.textMuted),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      key: const ValueKey('learning-paths-list'),
                      scrollDirection: Axis.horizontal,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: LearningCatalog.paths
                              .map((path) => Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: _LearningPathCard(
                                      path: path,
                                      language: language,
                                      selected: _path?.id == path.id,
                                      completedCount: path.lessonIds
                                          .where(_completed.contains)
                                          .length,
                                      onTap: () => setState(() {
                                        _path =
                                            _path?.id == path.id ? null : path;
                                        _category = null;
                                      }),
                                    ),
                                  ))
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                  if (showSafetyResult) ...[
                    const SizedBox(height: 12),
                    _SearchSafetyCard(
                      language: language,
                      onTap: () => _openLesson(
                        LearningCatalog.byId('suicide-safety'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _categoryChip(
                          language: language,
                          label: LanguageHelper.pick(
                            language,
                            english: 'All topics',
                            filipino: 'Lahat',
                          ),
                          category: null,
                        ),
                        ...LearningCategory.values.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _categoryChip(
                              language: language,
                              label: category.label(language),
                              category: category,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Semantics(
                    headingLevel: 2,
                    child: Text(
                      _path?.title.resolve(language) ??
                          LanguageHelper.pick(
                            language,
                            english: 'All lessons',
                            filipino: 'Lahat ng aralin',
                          ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    LanguageHelper.pick(
                      language,
                      english: '${lessons.length} available offline',
                      filipino:
                          '${lessons.length} aralin kahit walang internet',
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.textMuted),
                  ),
                ],
              ),
            ),
            if (lessons.isEmpty)
              SliverToBoxAdapter(
                child: KaibiganStateView(
                  compact: true,
                  icon: Icons.search_off_rounded,
                  title: LanguageHelper.pick(
                    language,
                    english: 'No lessons found',
                    filipino: 'Walang nahanap na aralin',
                  ),
                  message: LanguageHelper.pick(
                    language,
                    english: 'Try another word or choose all topics.',
                    filipino: 'Subukan ang ibang salita o piliin ang lahat.',
                  ),
                  actionLabel: LanguageHelper.pick(
                    language,
                    english: 'Reset search',
                    filipino: 'I-reset',
                  ),
                  onAction: () {
                    _searchController.clear();
                    setState(() => _category = null);
                  },
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  MobileLayout.horizontalPadding(context),
                  0,
                  MobileLayout.horizontalPadding(context),
                  28,
                ),
                sliver: SliverList.separated(
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final card = _LessonCard(
                      lesson: lessons[index],
                      language: language,
                      completed: _completed.contains(lessons[index].id),
                      onTap: () => _openLesson(lessons[index]),
                    );
                    if (MediaQuery.maybeOf(context)?.disableAnimations ??
                        false) {
                      return card;
                    }
                    return card
                        .animate(
                          key: ValueKey('lesson-reveal-${lessons[index].id}'),
                          delay: Duration(
                            milliseconds: 35 * (index > 6 ? 6 : index),
                          ),
                        )
                        .fadeIn(duration: KaibiganMotion.reveal)
                        .slideY(
                          begin: 0.035,
                          end: 0,
                          duration: KaibiganMotion.reveal,
                          curve: KaibiganMotion.enter,
                        );
                  },
                ),
              ),
          ],
        )),
      ),
    );
  }

  Widget _categoryChip({
    required String language,
    required String label,
    required LearningCategory? category,
  }) {
    final selected = _category == category;
    final palette = context.kaibigan;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      avatar: category == null ? null : Icon(category.icon, size: 18),
      onSelected: (_) => setState(() {
        _category = category;
        _path = null;
      }),
      selectedColor: palette.accentSubtle,
      checkmarkColor: palette.accentStrong,
      side: BorderSide(
        color:
            selected ? palette.accent.withValues(alpha: 0.52) : palette.border,
      ),
    );
  }

  bool _isSafetySearch(String query) {
    if (query.isEmpty) return false;
    const safetyTerms = [
      'suicide',
      'suicidal',
      'self harm',
      'self-harm',
      'want to die',
      'unsafe',
      'ayoko na',
      'magpakamatay',
      'saktan ang sarili',
    ];
    return safetyTerms.any(query.contains);
  }
}

class _LearningPathCard extends StatelessWidget {
  const _LearningPathCard({
    required this.path,
    required this.language,
    required this.selected,
    required this.completedCount,
    required this.onTap,
  });

  final LearningPath path;
  final String language;
  final bool selected;
  final int completedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return SizedBox(
      width: 214,
      child: KaibiganSurface(
        key: ValueKey('learning-path-${path.id}'),
        tone: selected
            ? KaibiganSurfaceTone.accent
            : KaibiganSurfaceTone.elevated,
        onTap: onTap,
        padding: const EdgeInsets.all(15),
        semanticLabel: path.title.resolve(language),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.accentSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(path.icon, size: 20, color: palette.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                  LanguageHelper.pick(language,
                      english: '${path.lessonIds.length} lessons',
                      filipino: '${path.lessonIds.length} aralin'),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.accentStrong,
                        fontWeight: FontWeight.w800,
                      ),
                )),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              path.title.resolve(language),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              path.description.resolve(language),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: palette.textSecondary, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSafetyCard extends StatelessWidget {
  const _SearchSafetyCard({required this.language, required this.onTap});

  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return KaibiganSurface(
      key: const ValueKey('learning-safety-search-result'),
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.danger.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.health_and_safety_outlined, color: palette.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageHelper.pick(
                    language,
                    english: 'Immediate support is available',
                    filipino: 'May agarang tulong na makukuha',
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  LanguageHelper.pick(
                    language,
                    english:
                        'Open safety steps and Philippine crisis contacts. Call 911 if danger is immediate.',
                    filipino:
                        'Tingnan ang mga hakbang sa kaligtasan at maaaring tawagan sa Pilipinas. Tumawag sa 911 kung may agarang panganib.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: palette.danger),
        ],
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.lesson,
    required this.language,
    required this.ideaIndex,
    required this.completed,
    required this.onTap,
  });

  final LearningLesson lesson;
  final String language;
  final int ideaIndex;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final total = lesson.sections.length;
    return KaibiganSurface(
      key: const ValueKey('continue-learning-card'),
      tone: KaibiganSurfaceTone.accent,
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      semanticLabel: LanguageHelper.pick(language,
          english:
              '${completed ? 'Review' : 'Continue'} ${lesson.title.resolve(language)}',
          filipino:
              '${completed ? 'Balikan' : 'Ipagpatuloy'} ang ${lesson.title.resolve(language)}'),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              completed ? Icons.replay_rounded : Icons.play_arrow_rounded,
              color: palette.onAccent,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageHelper.pick(
                    language,
                    english: completed
                        ? 'Review your last lesson'
                        : 'Continue learning',
                    filipino: completed
                        ? 'Balikan ang huling aralin'
                        : 'Ipagpatuloy ang pag-aaral',
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.accentStrong,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.title.resolve(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  LanguageHelper.pick(
                    language,
                    english: 'Idea ${ideaIndex + 1} of $total',
                    filipino: 'Ideya ${ideaIndex + 1} sa $total',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: palette.accent),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.language,
    required this.completed,
    required this.onTap,
  });

  final LearningLesson lesson;
  final String language;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return KaibiganSurface(
      key: ValueKey('learning-lesson-${lesson.id}'),
      onTap: onTap,
      semanticLabel: lesson.title.resolve(language),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 64,
            decoration: BoxDecoration(
              color: palette.accentSubtle,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(lesson.icon, color: palette.accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.title.resolve(language),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (completed)
                      Icon(
                        Icons.check_circle_rounded,
                        color: palette.accent,
                        size: 20,
                        semanticLabel: LanguageHelper.pick(
                          language,
                          english: 'Completed',
                          filipino: 'Tapos na',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  lesson.summary.resolve(language),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 9),
                Text(
                  LanguageHelper.pick(
                    language,
                    english:
                        '${lesson.readMinutes} min · ${lesson.category.label(language)}',
                    filipino:
                        '${lesson.readMinutes} min · ${lesson.category.label(language)}',
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Icon(Icons.chevron_right_rounded, color: palette.textMuted),
        ],
      ),
    );
  }
}

class _FriendSupportEntryCard extends StatelessWidget {
  const _FriendSupportEntryCard({
    required this.language,
    required this.onTap,
  });

  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;

    return KaibiganSurface(
      key: const ValueKey('friend-support-entry-card'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.accentSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.25),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('💛', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.accentSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        LanguageHelper.pick(
                          language,
                          english: '3 Interactive Lessons & Quizzes',
                          filipino: '3 Aralin at Pagsasanay',
                        ),
                        style: TextStyle(
                          color: palette.accentStrong,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      LanguageHelper.pick(
                        language,
                        english: 'Friend Support Lessons',
                        filipino: 'Aralin sa Pagsuporta sa Kaibigan',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      LanguageHelper.pick(
                        language,
                        english: 'Learn how to listen and respond with empathy.',
                        filipino: 'Matutong makinig at sumuporta nang may malasakit.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: palette.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
