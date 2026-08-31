import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_state_view.dart';
import '../../core/widgets/kaibigan_surface.dart';
import '../../core/widgets/mobile_layout.dart';
import '../settings/user_provider.dart';
import 'learning_catalog.dart';
import 'learning_model.dart';
import 'learning_progress_store.dart';
import 'medline_plus_service.dart';

class LearningLessonScreen extends StatefulWidget {
  const LearningLessonScreen({super.key, required this.lesson});

  final LearningLesson lesson;

  @override
  State<LearningLessonScreen> createState() => _LearningLessonScreenState();
}

class _LearningLessonScreenState extends State<LearningLessonScreen> {
  final _progressStore = LearningProgressStore();
  final _medlinePlus = MedlinePlusService();
  final _scrollController = ScrollController();
  final _reflectionKey = GlobalKey();
  bool _completed = false;
  bool _saving = false;
  int _currentIdea = 0;
  int _navigationDirection = 1;
  double _horizontalDragDistance = 0;
  Set<int> _helpfulIdeas = {};
  Set<int> _viewedIdeas = {};
  Future<List<TrustedArticle>>? _trustedReading;

  @override
  void initState() {
    super.initState();
    _loadCompletion();
  }

  Future<void> _loadCompletion() async {
    final results = await Future.wait<Object>([
      _progressStore.loadCompleted(),
      _progressStore.loadHelpfulIdeas(widget.lesson.id),
      _progressStore.loadViewedIdeas(widget.lesson.id),
      _progressStore.loadIdeaIndex(
        widget.lesson.id,
        max: widget.lesson.sections.length,
      ),
    ]);
    if (!mounted) return;
    final savedIdea = results[3] as int;
    final viewed = Set<int>.from(results[2] as Set<int>)..add(savedIdea);
    setState(() {
      _completed = (results[0] as Set<String>).contains(widget.lesson.id);
      _helpfulIdeas = results[1] as Set<int>;
      _viewedIdeas = viewed;
      _currentIdea = savedIdea;
    });
    unawaited(_progressStore.rememberPosition(widget.lesson.id, savedIdea));
    unawaited(_progressStore.markIdeaViewed(widget.lesson.id, savedIdea));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleCompletion() async {
    if (_saving) return;
    setState(() => _saving = true);
    final next = !_completed;
    await _progressStore.setCompleted(widget.lesson.id, next);
    if (!mounted) return;
    setState(() {
      _completed = next;
      _saving = false;
    });
    if (next) HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next
              ? LanguageHelper.pick(
                  context.read<UserProvider>().language,
                  english: 'Lesson marked complete.',
                  filipino: 'Minarkahang tapos ang lesson.',
                )
              : LanguageHelper.pick(
                  context.read<UserProvider>().language,
                  english: 'Lesson moved back to your list.',
                  filipino: 'Ibinalik ang lesson sa listahan.',
                ),
        ),
      ),
    );
  }

  Future<void> _openLink(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  void _loadTrustedReading() {
    setState(() {
      _trustedReading = _medlinePlus.search(widget.lesson.medlinePlusQuery);
    });
  }

  void _onIdeaChanged(int index) {
    if (_currentIdea == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _navigationDirection = index > _currentIdea ? 1 : -1;
      _currentIdea = index;
      _viewedIdeas.add(index);
    });
    unawaited(_progressStore.rememberPosition(widget.lesson.id, index));
    unawaited(_progressStore.markIdeaViewed(widget.lesson.id, index));
  }

  void _goToIdea(int index) {
    final target = index.clamp(0, widget.lesson.sections.length - 1);
    _onIdeaChanged(target);
  }

  bool get _canComplete => widget.lesson.sections
      .asMap()
      .entries
      .where((entry) => entry.value.essential)
      .every((entry) => _viewedIdeas.contains(entry.key));

  LearningLesson? get _nextLesson {
    for (final id in widget.lesson.relatedLessonIds) {
      final lesson = LearningCatalog.byId(id);
      if (lesson.id == id) return lesson;
    }
    final current = LearningCatalog.lessons.indexOf(widget.lesson);
    if (current >= 0 && current + 1 < LearningCatalog.lessons.length) {
      return LearningCatalog.lessons[current + 1];
    }
    return null;
  }

  Future<void> _toggleIdeaHelpful(int index) async {
    final next = !_helpfulIdeas.contains(index);
    HapticFeedback.lightImpact();
    setState(() {
      if (next) {
        _helpfulIdeas.add(index);
      } else {
        _helpfulIdeas.remove(index);
      }
    });
    await _progressStore.setIdeaHelpful(widget.lesson.id, index, next);
  }

  Future<void> _showReflection() async {
    HapticFeedback.mediumImpact();
    final target = _reflectionKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
          ? Duration.zero
          : KaibiganMotion.reveal,
      curve: KaibiganMotion.enter,
      alignment: 0.14,
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserProvider>().language;
    final palette = context.kaibigan;
    final lesson = widget.lesson;
    final padding = MobileLayout.horizontalPadding(context);
    final remainingIdeas = lesson.sections
        .asMap()
        .entries
        .where((entry) => entry.value.essential)
        .where((entry) => !_viewedIdeas.contains(entry.key))
        .length;
    final nextLesson = _nextLesson;

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
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('learning-lesson-scroll-view'),
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 32),
          children: [
            KaibiganSurface(
              key: const ValueKey('learning-lesson-hero'),
              tone: KaibiganSurfaceTone.accent,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: palette.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(lesson.icon, color: palette.accent, size: 30),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    lesson.category.label(language).toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.accentStrong,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.title.resolve(language),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.summary.resolve(language),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: palette.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 7,
                    children: [
                      _LessonMeta(
                        icon: Icons.schedule_rounded,
                        label: LanguageHelper.pick(
                          language,
                          english: '${lesson.readMinutes} minute read',
                          filipino: '${lesson.readMinutes} minutong pagbasa',
                        ),
                      ),
                      _LessonMeta(
                        icon: Icons.view_agenda_outlined,
                        label: LanguageHelper.pick(
                          language,
                          english: '${lesson.sections.length} key ideas',
                          filipino:
                              '${lesson.sections.length} pangunahing idea',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (lesson.outcomes.isNotEmpty) ...[
              const SizedBox(height: 14),
              KaibiganSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      headingLevel: 2,
                      child: Text(
                        LanguageHelper.pick(
                          language,
                          english: 'What you will take away',
                          filipino: 'Ano ang matututunan mo',
                        ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...lesson.outcomes.map(
                      (outcome) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.hexagon_rounded,
                              size: 11,
                              color: palette.accent,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                outcome.resolve(language),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            KaibiganSurface(
              tone: KaibiganSurfaceTone.subtle,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: palette.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      LanguageHelper.pick(
                        language,
                        english:
                            'For education, not diagnosis or a substitute for professional care.',
                        filipino:
                            'Para sa kaalaman, hindi diagnosis o kapalit ng propesyonal na pangangalaga.',
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            if (lesson.sensitivityNotice != null) ...[
              const SizedBox(height: 10),
              KaibiganSurface(
                key: const ValueKey('learning-sensitivity-notice'),
                tone: KaibiganSurfaceTone.accent,
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: palette.accentStrong,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lesson.sensitivityNotice!.resolve(language),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textSecondary,
                              height: 1.45,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            _buildIdeaReader(context, language, lesson),
            const SizedBox(height: 30),
            KaibiganSurface(
              key: _reflectionKey,
              tone: KaibiganSurfaceTone.accent,
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: palette.accent),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          LanguageHelper.pick(
                            language,
                            english: 'Pause and reflect',
                            filipino: 'Huminto at magmuni',
                          ),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    lesson.reflection.resolve(language),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: palette.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _sourceSection(language),
            const SizedBox(height: 20),
            if (lesson.category == LearningCategory.conditions ||
                lesson.id == 'asking-for-help' ||
                lesson.id == 'supporting-someone' ||
                lesson.id == 'suicide-safety' ||
                lesson.id == 'philippines-support-contacts') ...[
              _philippineSupportCard(language),
              const SizedBox(height: 20),
            ],
            AnimatedSwitcher(
              duration: KaibiganMotion.standard,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
              child: _completed
                  ? Padding(
                      key: const ValueKey('lesson-complete-celebration'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: KaibiganSurface(
                        tone: KaibiganSurfaceTone.accent,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: palette.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: palette.onAccent,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    LanguageHelper.pick(
                                      language,
                                      english:
                                          'Lesson complete. Take one useful idea with you.',
                                      filipino:
                                          'Tapos na ang lesson. Magbaon ng isang useful na idea.',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: palette.textSecondary,
                                          height: 1.4,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            if (nextLesson != null) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                key: const ValueKey('open-next-lesson'),
                                onPressed: () => Navigator.of(context)
                                    .pushReplacement<void, void>(
                                  MaterialPageRoute(
                                    builder: (_) => LearningLessonScreen(
                                      lesson: nextLesson,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Flexible(
                                  child: Text(
                                    LanguageHelper.pick(
                                      language,
                                      english:
                                          'Next: ${nextLesson.title.resolve(language)}',
                                      filipino:
                                          'Susunod: ${nextLesson.title.resolve(language)}',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('toggle-lesson-completion'),
                onPressed: _saving || (!_completed && !_canComplete)
                    ? null
                    : _toggleCompletion,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.onAccent,
                        ),
                      )
                    : Icon(
                        _completed
                            ? Icons.check_circle_rounded
                            : Icons.check_rounded,
                      ),
                label: Text(
                  _completed
                      ? LanguageHelper.pick(
                          language,
                          english: 'Completed',
                          filipino: 'Tapos na',
                        )
                      : !_canComplete
                          ? LanguageHelper.pick(
                              language,
                              english:
                                  'Read $remainingIdeas more ${remainingIdeas == 1 ? 'idea' : 'ideas'}',
                              filipino:
                                  'Basahin pa ang $remainingIdeas ${remainingIdeas == 1 ? 'idea' : 'ideas'}',
                            )
                          : LanguageHelper.pick(
                              language,
                              english: 'Complete lesson',
                              filipino: 'Tapusin ang lesson',
                            ),
                ),
              ),
            ),
            if (!_completed) ...[
              const SizedBox(height: 6),
              TextButton(
                key: const ValueKey('finish-learning-later'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  LanguageHelper.pick(
                    language,
                    english: 'Finish for now — progress is saved',
                    filipino: 'Tama na muna — naka-save ang progress',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaReader(
    BuildContext context,
    String language,
    LearningLesson lesson,
  ) {
    final palette = context.kaibigan;
    final total = lesson.sections.length;
    final progress = (_currentIdea + 1) / total;
    final isLast = _currentIdea == total - 1;
    final section = lesson.sections[_currentIdea];
    final sectionType = lesson.effectiveTypeAt(_currentIdea);
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Column(
      key: const ValueKey('learning-idea-reader'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: LanguageHelper.pick(
                  language,
                  english: 'Idea ${_currentIdea + 1} of $total',
                  filipino: 'Idea ${_currentIdea + 1} sa $total',
                ),
                child: AnimatedSwitcher(
                  duration:
                      reducedMotion ? Duration.zero : KaibiganMotion.quick,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.18),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    LanguageHelper.pick(
                      language,
                      english: 'Idea ${_currentIdea + 1} of $total',
                      filipino: 'Idea ${_currentIdea + 1} sa $total',
                    ),
                    key: ValueKey(_currentIdea),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            Icon(sectionType.icon, size: 17, color: palette.accent),
            const SizedBox(width: 6),
            Text(
              sectionType.label(language),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.accentStrong,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            key: const ValueKey('learning-idea-progress'),
            height: 8,
            color: palette.surfaceSubtle,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: KaibiganMotion.standard,
              curve: KaibiganMotion.enter,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [palette.accent, palette.accentStrong]
                          : [AppColors.honeyGold, AppColors.honeyAmber],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          key: const ValueKey('learning-idea-page-view'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _horizontalDragDistance = 0,
          onHorizontalDragUpdate: (details) {
            _horizontalDragDistance += details.primaryDelta ?? 0;
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if ((velocity < -180 || _horizontalDragDistance < -48) && !isLast) {
              _goToIdea(_currentIdea + 1);
            } else if ((velocity > 180 || _horizontalDragDistance > 48) &&
                _currentIdea > 0) {
              _goToIdea(_currentIdea - 1);
            }
          },
          child: AnimatedSize(
            duration: reducedMotion ? Duration.zero : KaibiganMotion.standard,
            curve: KaibiganMotion.enter,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: reducedMotion ? Duration.zero : KaibiganMotion.standard,
              switchInCurve: KaibiganMotion.enter,
              switchOutCurve: KaibiganMotion.exit,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0.055 * _navigationDirection, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _LearningIdeaCard(
                key: ValueKey('learning-idea-card-$_currentIdea'),
                index: _currentIdea,
                section: section,
                type: sectionType,
                language: language,
                helpful: _helpfulIdeas.contains(_currentIdea),
                onHelpful: () => _toggleIdeaHelpful(_currentIdea),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            total,
            (index) => Semantics(
              button: true,
              selected: index == _currentIdea,
              label: LanguageHelper.pick(
                language,
                english: 'Go to idea ${index + 1}',
                filipino: 'Pumunta sa idea ${index + 1}',
              ),
              child: InkResponse(
                key: ValueKey('learning-idea-dot-$index'),
                onTap: () => _goToIdea(index),
                radius: 20,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: KaibiganMotion.quick,
                      curve: KaibiganMotion.enter,
                      width: index == _currentIdea ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentIdea
                            ? palette.accent
                            : palette.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            AnimatedOpacity(
              duration: KaibiganMotion.quick,
              opacity: _currentIdea == 0 ? 0.45 : 1,
              child: Tooltip(
                message: LanguageHelper.pick(
                  language,
                  english: 'Previous idea',
                  filipino: 'Nakaraang idea',
                ),
                child: SizedBox(
                  width: 52,
                  child: OutlinedButton(
                    key: const ValueKey('previous-learning-idea'),
                    onPressed: _currentIdea == 0
                        ? null
                        : () => _goToIdea(_currentIdea - 1),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 19),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('next-learning-idea'),
                onPressed: isLast
                    ? _showReflection
                    : () => _goToIdea(_currentIdea + 1),
                icon: AnimatedSwitcher(
                  duration: KaibiganMotion.quick,
                  child: Icon(
                    isLast
                        ? Icons.lightbulb_outline_rounded
                        : Icons.arrow_forward_rounded,
                    key: ValueKey(isLast),
                    size: 19,
                  ),
                ),
                label: AnimatedSwitcher(
                  duration: KaibiganMotion.quick,
                  child: Text(
                    isLast
                        ? LanguageHelper.pick(
                            language,
                            english: 'Reflect',
                            filipino: 'Magnilay',
                          )
                        : LanguageHelper.pick(
                            language,
                            english: 'Next idea',
                            filipino: 'Susunod na idea',
                          ),
                    key: ValueKey(isLast),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sourceSection(String language) {
    final palette = context.kaibigan;
    final trustedReading = _trustedReading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageHelper.pick(
            language,
            english: 'Sources and trusted reading',
            filipino: 'Sources at mapagkakatiwalaang babasahin',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(
          LanguageHelper.pick(
            language,
            english:
                'Reviewed ${widget.lesson.reviewedLabel} · Version ${widget.lesson.contentVersion} · Tap a source to continue reading.',
            filipino:
                'Ni-review ${widget.lesson.reviewedLabel} · Version ${widget.lesson.contentVersion} · I-tap ang source para magbasa pa.',
          ),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        KaibiganSurface(
          onTap: () => _openLink(widget.lesson.sourceUrl),
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(Icons.verified_outlined, color: palette.accent),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.lesson.sourceLabel,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      LanguageHelper.pick(
                        language,
                        english: 'Primary reference',
                        filipino: 'Pangunahing reference',
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  color: palette.textMuted, size: 19),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (trustedReading == null)
          OutlinedButton(
            key: const ValueKey('load-medline-plus'),
            onPressed: _loadTrustedReading,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_rounded),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    LanguageHelper.pick(
                      language,
                      english: 'Find related official articles',
                      filipino: 'Maghanap ng kaugnay na official articles',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          )
        else
          FutureBuilder<List<TrustedArticle>>(
            future: trustedReading,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return KaibiganStateView(
                  compact: true,
                  loading: true,
                  title: LanguageHelper.pick(
                    language,
                    english: 'Finding trusted reading',
                    filipino: 'Naghahanap ng mapagkakatiwalaang babasahin',
                  ),
                  message: LanguageHelper.pick(
                    language,
                    english: 'Checking MedlinePlus…',
                    filipino: 'Tinitingnan ang MedlinePlus…',
                  ),
                );
              }
              if (snapshot.hasError) {
                return KaibiganStateView(
                  compact: true,
                  tone: KaibiganStateTone.error,
                  icon: Icons.cloud_off_rounded,
                  title: LanguageHelper.pick(
                    language,
                    english: 'Still available offline',
                    filipino: 'Available pa rin offline',
                  ),
                  message: LanguageHelper.pick(
                    language,
                    english:
                        'Official articles could not load. This lesson is unaffected.',
                    filipino:
                        'Hindi ma-load ang official articles. Available pa rin ang lesson.',
                  ),
                  actionLabel: LanguageHelper.pick(
                    language,
                    english: 'Try again',
                    filipino: 'Subukan muli',
                  ),
                  onAction: _loadTrustedReading,
                );
              }
              final articles = snapshot.data ?? const [];
              if (articles.isEmpty) {
                return KaibiganStateView(
                  compact: true,
                  icon: Icons.menu_book_outlined,
                  title: LanguageHelper.pick(
                    language,
                    english: 'No related articles found',
                    filipino: 'Walang kaugnay na article',
                  ),
                  message: LanguageHelper.pick(
                    language,
                    english: 'You can use the primary source above.',
                    filipino: 'Maaari mong gamitin ang source sa itaas.',
                  ),
                );
              }
              return Column(
                children: [
                  ...articles.map(
                    (article) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: KaibiganSurface(
                        onTap: () => _openLink(article.url),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(article.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                  if (article.summary.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      article.summary,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: palette.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.open_in_new_rounded,
                                color: palette.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'From MedlinePlus.gov',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _philippineSupportCard(String language) {
    final palette = context.kaibigan;
    return KaibiganSurface(
      key: const ValueKey('philippines-support-contacts-card'),
      tone: KaibiganSurfaceTone.accent,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent_rounded, color: palette.danger),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  LanguageHelper.pick(
                    language,
                    english: 'Support in the Philippines',
                    filipino: 'Suporta sa Pilipinas',
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            LanguageHelper.pick(
              language,
              english:
                  'Choose the contact that matches what is happening. If you cannot connect and danger is immediate, go to the nearest emergency department or ask someone nearby to call.',
              filipino:
                  'Piliin ang contact na tugma sa nangyayari. Kung hindi makakonekta at immediate ang danger, pumunta sa nearest emergency department o magpatulong tumawag.',
            ),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: palette.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 15),
          _SupportContactRow(
            icon: Icons.emergency_rounded,
            title: LanguageHelper.pick(
              language,
              english: 'Immediate emergency',
              filipino: 'Immediate emergency',
            ),
            detail: LanguageHelper.pick(
              language,
              english: 'Unified nationwide emergency hotline',
              filipino: 'Unified nationwide emergency hotline',
            ),
            number: '911',
            color: palette.danger,
            onTap: () => _openLink(Uri.parse('tel:911')),
          ),
          const SizedBox(height: 9),
          _SupportContactRow(
            icon: Icons.support_agent_rounded,
            title: LanguageHelper.pick(
              language,
              english: 'Mental health crisis',
              filipino: 'Mental health crisis',
            ),
            detail: LanguageHelper.pick(
              language,
              english: 'NCMH Crisis Hotline',
              filipino: 'NCMH Crisis Hotline',
            ),
            number: '1553',
            color: palette.accentStrong,
            onTap: () => _openLink(Uri.parse('tel:1553')),
          ),
          const SizedBox(height: 9),
          _SupportContactRow(
            icon: Icons.phone_android_rounded,
            title: LanguageHelper.pick(
              language,
              english: 'NCMH mobile line',
              filipino: 'NCMH mobile line',
            ),
            detail: LanguageHelper.pick(
              language,
              english: 'Save as a backup crisis contact',
              filipino: 'I-save bilang backup crisis contact',
            ),
            number: '0917 899 8727',
            color: palette.accent,
            onTap: () => _openLink(Uri.parse('tel:+639178998727')),
          ),
          const SizedBox(height: 11),
          Text(
            LanguageHelper.pick(
              language,
              english:
                  'Hotline availability and network access can change. Save a trusted person and nearby hospital as backups.',
              filipino:
                  'Maaaring magbago ang hotline availability at network access. Mag-save rin ng trusted person at nearby hospital.',
            ),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: palette.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LearningIdeaCard extends StatelessWidget {
  const _LearningIdeaCard({
    super.key,
    required this.index,
    required this.section,
    required this.type,
    required this.language,
    required this.helpful,
    required this.onHelpful,
  });

  final int index;
  final LearningSection section;
  final LearningSectionType type;
  final String language;
  final bool helpful;
  final VoidCallback onHelpful;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final ideaNumber = index + 1;
    return KaibiganSurface(
      key: ValueKey('learning-idea-$ideaNumber'),
      padding: const EdgeInsets.fromLTRB(19, 17, 19, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: index.isEven
                      ? palette.accentSubtle
                      : palette.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type.icon,
                  size: 18,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  type.label(language).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        letterSpacing: 0.85,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Icon(Icons.hexagon_rounded,
                  size: 13, color: palette.accent.withValues(alpha: 0.55)),
            ],
          ),
          const SizedBox(height: 18),
          Semantics(
            headingLevel: 3,
            child: Text(
              section.heading.resolve(language),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            section.body.resolve(language),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: palette.textSecondary,
                  height: 1.68,
                ),
          ),
          if (section.prompt != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.accentSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note_rounded,
                      size: 20, color: palette.accent),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      section.prompt!.resolve(language),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: palette.textSecondary,
                            height: 1.45,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              selected: helpful,
              label: LanguageHelper.pick(
                language,
                english: 'Mark this idea as helpful',
                filipino: 'Markahan ang idea bilang helpful',
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('helpful-learning-idea-$index'),
                  onTap: onHelpful,
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: KaibiganMotion.standard,
                    curve: KaibiganMotion.enter,
                    constraints: const BoxConstraints(minHeight: 48),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: helpful
                          ? palette.accentSubtle
                          : palette.surfaceSubtle,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: helpful ? palette.accent : palette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: KaibiganMotion.quick,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            helpful
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(helpful),
                            size: 18,
                            color: helpful ? palette.accent : palette.textMuted,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          helpful
                              ? LanguageHelper.pick(
                                  language,
                                  english: 'Saved',
                                  filipino: 'Naka-save',
                                )
                              : LanguageHelper.pick(
                                  language,
                                  english: 'Helpful',
                                  filipino: 'Helpful',
                                ),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: helpful
                                        ? palette.accent
                                        : palette.textSecondary,
                                    fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _LessonMeta extends StatelessWidget {
  const _LessonMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: palette.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _SupportContactRow extends StatelessWidget {
  const _SupportContactRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.number,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String number;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final identity = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                detail,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
    Widget callAction({required bool expanded}) => Container(
          width: expanded ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call_rounded, size: 17, color: color),
              const SizedBox(width: 6),
              if (expanded)
                Expanded(
                  child: Text(
                    number,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                )
              else
                Text(
                  number,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
            ],
          ),
        );
    return Material(
      color: palette.surface.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: 10),
                    callAction(expanded: true),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 10),
                  callAction(expanded: false),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
