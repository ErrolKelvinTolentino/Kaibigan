import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_state_view.dart';
import '../../core/widgets/kaibigan_surface.dart';
import '../../core/widgets/mobile_layout.dart';
import '../../core/services/ui_sound_service.dart';
import '../../core/widgets/kaibigan_sound_scope.dart';
import '../settings/user_provider.dart';
import 'learning_ask_kai_sheet.dart';
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
  final _readerKey = GlobalKey();
  bool _reflecting = false;
  bool _completed = false;
  Set<String> _completedLessonIds = {};
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
      _completedLessonIds = results[0] as Set<String>;
      _completed = _completedLessonIds.contains(widget.lesson.id);
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
    final completedIds =
        await _progressStore.setCompleted(widget.lesson.id, next);
    if (!mounted) return;
    setState(() {
      _completed = next;
      _completedLessonIds = completedIds;
      _saving = false;
    });
    if (next) {
      HapticFeedback.mediumImpact();
      // A lesson is a real piece of work, so it gets the fuller cue.
      KaibiganSoundScope.play(context, UiSound.complete);
    }
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
    setState(() => _reflecting = false);
    final target = index.clamp(0, widget.lesson.sections.length - 1);
    _onIdeaChanged(target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _readerKey.currentContext == null) return;
      Scrollable.ensureVisible(_readerKey.currentContext!,
          duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
              ? Duration.zero
              : KaibiganMotion.standard,
          curve: KaibiganMotion.enter,
          alignment: 0);
    });
  }

  bool get _canComplete => widget.lesson.sections
      .asMap()
      .entries
      .where((entry) => entry.value.essential)
      .every((entry) => _viewedIdeas.contains(entry.key));

  /// Where to go after this lesson, and why.
  ///
  /// The previous version returned the first related lesson whether or not it
  /// had already been finished, so completing a lesson could hand you back
  /// something you had read weeks ago. Completed lessons are now skipped at
  /// every stage, and the reason for the suggestion is shown with it.
  ({LearningLesson lesson, LearningNextReason reason})? get _nextStep {
    bool unread(LearningLesson lesson) =>
        lesson.id != widget.lesson.id &&
        !_completedLessonIds.contains(lesson.id);

    for (final id in widget.lesson.relatedLessonIds) {
      final lesson = LearningCatalog.byId(id);
      if (lesson.id == id && unread(lesson)) {
        return (lesson: lesson, reason: LearningNextReason.related);
      }
    }

    // A path the current lesson belongs to is the strongest signal of order.
    for (final path in LearningCatalog.paths) {
      if (!path.lessonIds.contains(widget.lesson.id)) continue;
      for (final id in path.lessonIds) {
        final lesson = LearningCatalog.byId(id);
        if (lesson.id == id && unread(lesson)) {
          return (lesson: lesson, reason: LearningNextReason.path);
        }
      }
    }

    for (final lesson in LearningCatalog.lessons) {
      if (lesson.category == widget.lesson.category && unread(lesson)) {
        return (lesson: lesson, reason: LearningNextReason.category);
      }
    }

    for (final lesson in LearningCatalog.lessons) {
      if (unread(lesson)) {
        return (lesson: lesson, reason: LearningNextReason.anything);
      }
    }
    return null;
  }

  Future<void> _toggleIdeaHelpful(int index) async {
    final next = !_helpfulIdeas.contains(index);
    HapticFeedback.lightImpact();
    if (next) KaibiganSoundScope.play(context, UiSound.select);
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
    setState(() => _reflecting = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final target = _reflectionKey.currentContext;
    if (target == null || !target.mounted) return;
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
    final nextStep = _nextStep;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(LanguageHelper.pick(language,
            english: 'Learn', filipino: 'Matuto')),
        centerTitle: true,
        actions: [
          IconButton(
            key: const ValueKey('learning-lesson-outline'),
            tooltip: LanguageHelper.pick(language,
                english: 'Lesson overview', filipino: 'Buod ng aralin'),
            onPressed: () => _showOutline(language),
            icon: const Icon(Icons.format_list_bulleted_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: _lessonNavigation(language),
      body: SafeArea(
        top: false,
        bottom: false,
        child: MobileContent(
          child: SingleChildScrollView(
            key: const ValueKey('learning-lesson-scroll-view'),
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(padding, 8, padding, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                key: const ValueKey('learning-lesson-hero'),
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.category.label(language),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: palette.accentStrong)),
                    const SizedBox(height: 6),
                    Semantics(
                      headingLevel: 1,
                      child: Text(lesson.title.resolve(language),
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _LessonMeta(
                          icon: Icons.schedule_rounded,
                          label: LanguageHelper.pick(language,
                              english: '${lesson.readMinutes} minute read',
                              filipino:
                                  '${lesson.readMinutes} minutong pagbasa'),
                        ),
                        _LessonMeta(
                          icon: Icons.view_agenda_outlined,
                          label: LanguageHelper.pick(language,
                              english: '${lesson.sections.length} key ideas',
                              filipino:
                                  '${lesson.sections.length} mahahalagang ideya'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (lesson.sensitivityNotice != null) ...[
                KaibiganSurface(
                  key: const ValueKey('learning-sensitivity-notice'),
                  tone: KaibiganSurfaceTone.accent,
                  padding: const EdgeInsets.all(14),
                  child: Text(lesson.sensitivityNotice!.resolve(language),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary, height: 1.5)),
                ),
                const SizedBox(height: 16),
              ],
              if (!_reflecting) Container(
                key: _readerKey,
                child: _buildIdeaReader(context, language, lesson),
              ),
              if (_reflecting) KaibiganSurface(
                key: _reflectionKey,
                tone: KaibiganSurfaceTone.accent,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: palette.accent),
                    const SizedBox(height: 10),
                    Semantics(
                      headingLevel: 2,
                      child: Text(
                          LanguageHelper.pick(language,
                              english: 'Pause and reflect',
                              filipino: 'Huminto at magnilay'),
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 10),
                    Text(lesson.reflection.resolve(language),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: palette.textSecondary, height: 1.6)),
                    const SizedBox(height: 12),
                    Text(
                        LanguageHelper.pick(language,
                            english:
                                'No right answer. Take what feels useful and leave the rest.',
                            filipino:
                                'Walang tamang sagot. Baunin ang kapaki-pakinabang sa iyo.'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary, height: 1.5)),
                  ],
                ),
              ),
              if (_completed) ...[
                const SizedBox(height: 16),
                KaibiganSurface(
                  key: const ValueKey('lesson-complete-celebration'),
                  tone: KaibiganSurfaceTone.botanical,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: palette.botanical),
                      const SizedBox(height: 10),
                      Text(
                          LanguageHelper.pick(language,
                              english:
                                  'A little more understanding, at your own pace.',
                              filipino:
                                  'Mas malalim na pag-unawa, sa sarili mong bilis.'),
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(
                          LanguageHelper.pick(language,
                              english:
                                  'Your lesson is complete. You can stop here or explore another idea.',
                              filipino:
                                  'Tapos na ang aralin. Maaari kang magpahinga o tumuklas pa.'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: palette.textSecondary, height: 1.5)),
                      if (nextStep != null) ...[
                        const SizedBox(height: KaibiganSpace.md),
                        Text(
                          nextStep.reason.label(language),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: palette.textMuted,
                                letterSpacing: 0.6,
                              ),
                        ),
                        const SizedBox(height: KaibiganSpace.xs),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey('open-next-lesson'),
                            onPressed: () => Navigator.of(context)
                                .pushReplacement<void, void>(MaterialPageRoute(
                              builder: (_) =>
                                  LearningLessonScreen(lesson: nextStep.lesson),
                            )),
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: Text(
                              nextStep.lesson.title.resolve(language),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: KaibiganSpace.sm,
                                vertical: KaibiganSpace.xs,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: KaibiganSpace.sm),
                        Text(
                          LanguageHelper.pick(
                            language,
                            english:
                                'That is every lesson in the library read. '
                                'Revisit any of them whenever it would help.',
                            filipino:
                                'Nabasa mo na ang lahat ng aralin. Balikan '
                                'ang alinman kapag makakatulong ito.',
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                key: const ValueKey('finish-learning-later'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                    LanguageHelper.pick(language,
                        english: 'Save my place and leave',
                        filipino: 'Itabi ang progreso at bumalik'),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              Text(
                  LanguageHelper.pick(language,
                      english:
                          'For learning and support. This is not a diagnosis or a substitute for professional care.',
                      filipino:
                          'Para sa pagkatuto at suporta. Hindi ito pagsusuri ng karamdaman o kapalit ng propesyonal na pangangalaga.'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.textMuted, height: 1.5)),
              const SizedBox(height: 16),
              KaibiganSurface(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  key: const ValueKey('learning-sources-expansion'),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: Icon(Icons.verified_outlined, color: palette.accent),
                  title: Text(LanguageHelper.pick(language,
                      english: 'Sources & further reading',
                      filipino: 'Mga sanggunian at babasahin')),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [_sourceSection(language)],
                ),
              ),
              if (lesson.category == LearningCategory.conditions ||
                  lesson.id == 'asking-for-help' ||
                  lesson.id == 'supporting-someone' ||
                  lesson.id == 'suicide-safety' ||
                  lesson.id == 'philippines-support-contacts') ...[
                const SizedBox(height: 16),
                _philippineSupportCard(language),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOutline(String language) async {
    final lesson = widget.lesson;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => MobileSheetBody(
        topMargin: 16,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  LanguageHelper.pick(language,
                      english: 'Your lesson, at your pace',
                      filipino: 'Ang aralin, sa sarili mong bilis'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(lesson.summary.resolve(language)),
              if (lesson.outcomes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                    LanguageHelper.pick(language,
                        english: 'What you will take away',
                        filipino: 'Mga matututunan mo'),
                    style: Theme.of(context).textTheme.titleSmall),
                ...lesson.outcomes.map((outcome) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('• ${outcome.resolve(language)}'),
                    )),
              ],
              const SizedBox(height: 16),
              ...lesson.sections.asMap().entries.map((entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_viewedIdeas.contains(entry.key)
                        ? Icons.check_circle_outline_rounded
                        : Icons.circle_outlined),
                    title: Text(entry.value.heading.resolve(language)),
                    selected: entry.key == _currentIdea,
                    subtitle: Text(LanguageHelper.pick(language,
                        english: 'Idea ${entry.key + 1}',
                        filipino: 'Ideya ${entry.key + 1}')),
                    onTap: () => Navigator.of(context).pop(entry.key),
                  )),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) _goToIdea(selected);
  }

  Widget _lessonNavigation(String language) {
    final palette = context.kaibigan;
    final isLast = _currentIdea == widget.lesson.sections.length - 1;
    final primaryLabel = _reflecting
        ? LanguageHelper.pick(language,
            english: _completed
                ? 'Back to lessons'
                : _canComplete
                    ? 'Complete lesson'
                    : 'Continue reading',
            filipino: _completed
                ? 'Bumalik sa mga aralin'
                : _canComplete
                    ? 'Tapusin ang aralin'
                    : 'Magpatuloy sa pagbasa')
        : LanguageHelper.pick(language,
            english: isLast ? 'Reflect' : 'Next idea',
            filipino: isLast ? 'Magnilay' : 'Susunod na ideya');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: MobileLayout.maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MobileLayout.horizontalPadding(context),
                  vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: OutlinedButton(
                      key: const ValueKey('previous-learning-idea'),
                      onPressed: _currentIdea == 0 && !_reflecting
                          ? null
                          : () => _goToIdea(
                              _reflecting ? _currentIdea : _currentIdea - 1),
                      style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 48)),
                      child: Icon(Icons.arrow_back_rounded,
                          semanticLabel: LanguageHelper.pick(language,
                              english: 'Previous idea',
                              filipino: 'Nakaraang ideya')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: ValueKey(_reflecting
                          ? 'toggle-lesson-completion'
                          : 'next-learning-idea'),
                      onPressed: _saving
                          ? null
                          : () {
                              if (_reflecting) {
                                if (_completed) {
                                  Navigator.of(context).maybePop();
                                } else if (_canComplete) {
                                  _toggleCompletion();
                                } else {
                                  final unread = widget.lesson.sections
                                      .asMap()
                                      .entries
                                      .firstWhere((entry) =>
                                          entry.value.essential &&
                                          !_viewedIdeas.contains(entry.key));
                                  _goToIdea(unread.key);
                                }
                              } else if (isLast) {
                                _showReflection();
                              } else {
                                _goToIdea(_currentIdea + 1);
                              }
                            },
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12)),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(primaryLabel, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            Flexible(
                child: Text(
              sectionType.label(language),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.accentStrong,
                    fontWeight: FontWeight.w700,
                  ),
            )),
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
                      colors: [palette.accent, palette.accentStrong],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            children: [
              Icon(
                Icons.swipe_rounded,
                size: 14,
                color: palette.textMuted,
              ),
              Text(
                LanguageHelper.pick(
                  language,
                  english: 'Swipe to explore ideas',
                  filipino: 'Mag-swipe para sa mga ideya',
                  taglish: 'Swipe to explore ideas',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const ValueKey('ask-kai-about-learning-idea'),
            onPressed: () {
              HapticFeedback.selectionClick();
              LearningAskKaiSheet.show(
                context,
                lesson: lesson,
                currentSection: section,
                language: language,
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              alignment: Alignment.centerLeft,
              side: BorderSide(color: palette.border, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius:
                        BorderRadius.circular(KaibiganRadius.control),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: palette.onAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageHelper.pick(
                          language,
                          english: 'Ask Kai about this idea',
                          filipino: 'Tanungin si Kai tungkol dito',
                          taglish: 'Ask Kai about this idea',
                        ),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LanguageHelper.pick(
                          language,
                          english:
                              'A simpler explanation or one practical step',
                          filipino:
                              'Mas malinaw na paliwanag o praktikal na hakbang',
                          taglish: 'Simpler explanation o isang practical step',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: palette.accent),
              ],
            ),
          ),
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
          SizedBox.shrink(
            key: ValueKey('helpful-learning-idea-$index'),
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
        Flexible(
            child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: palette.textMuted),
        )),
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
