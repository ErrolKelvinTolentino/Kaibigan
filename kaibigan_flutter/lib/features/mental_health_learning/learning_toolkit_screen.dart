import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../../core/widgets/kaibigan_state_view.dart';
import '../../core/widgets/kaibigan_surface.dart';
import '../../core/widgets/mobile_layout.dart';
import '../settings/user_provider.dart';
import 'learning_catalog.dart';
import 'learning_lesson_screen.dart';
import 'learning_model.dart';
import 'learning_progress_store.dart';

class LearningToolkitScreen extends StatefulWidget {
  const LearningToolkitScreen({super.key});

  @override
  State<LearningToolkitScreen> createState() => _LearningToolkitScreenState();
}

class _LearningToolkitScreenState extends State<LearningToolkitScreen> {
  final _store = LearningProgressStore();
  late Future<List<_SavedIdea>> _savedIdeas;

  @override
  void initState() {
    super.initState();
    _savedIdeas = _loadSavedIdeas();
  }

  Future<List<_SavedIdea>> _loadSavedIdeas() async {
    final refs = await _store.loadAllHelpfulIdeaRefs();
    final ideas = <_SavedIdea>[];
    for (final ref in refs) {
      final separator = ref.lastIndexOf(':');
      if (separator <= 0) continue;
      final lessonId = ref.substring(0, separator);
      final index = int.tryParse(ref.substring(separator + 1));
      if (index == null || index < 0) continue;
      final lesson = LearningCatalog.byId(lessonId);
      if (lesson.id != lessonId || index >= lesson.sections.length) continue;
      ideas.add(_SavedIdea(lesson: lesson, index: index));
    }
    ideas.sort(
        (a, b) => a.lesson.title.english.compareTo(b.lesson.title.english));
    return ideas;
  }

  Future<void> _openIdea(_SavedIdea idea) async {
    await _store.rememberPosition(idea.lesson.id, idea.index);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LearningLessonScreen(lesson: idea.lesson),
      ),
    );
    if (!mounted) return;
    setState(() => _savedIdeas = _loadSavedIdeas());
  }

  Future<void> _removeIdea(_SavedIdea idea, String language) async {
    await _store.setIdeaHelpful(idea.lesson.id, idea.index, false);
    if (!mounted) return;
    setState(() => _savedIdeas = _loadSavedIdeas());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(LanguageHelper.pick(language,
          english: 'Idea removed from saved ideas.',
          filipino: 'Inalis sa mga itinabing ideya.')),
      action: SnackBarAction(
        label: LanguageHelper.pick(language, english: 'Undo', filipino: 'Ibalik'),
        onPressed: () async {
          await _store.setIdeaHelpful(idea.lesson.id, idea.index, true);
          if (mounted) setState(() => _savedIdeas = _loadSavedIdeas());
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserProvider>().language;
    final palette = context.kaibigan;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          LanguageHelper.pick(
            language,
            english: 'Saved ideas',
            filipino: 'Mga itinabing ideya',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(top: false, child: MobileContent(child: FutureBuilder<List<_SavedIdea>>(
        future: _savedIdeas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return KaibiganStateView(
              loading: true,
              title: LanguageHelper.pick(
                language,
                english: 'Gathering your ideas',
                filipino: 'Inihahanda ang mga ideya mo',
              ),
              message: LanguageHelper.pick(
                language,
                english: 'Your personal learning toolkit is almost ready.',
                filipino: 'Inihahanda ang mga ideyang maaari mong balikan.',
              ),
            );
          }
          if (snapshot.hasError) {
            return KaibiganStateView(
              icon: Icons.refresh_rounded,
              title: LanguageHelper.pick(language,
                  english: 'Let’s try that again', filipino: 'Subukan nating muli'),
              message: LanguageHelper.pick(language,
                  english: 'Your saved ideas could not load just now.',
                  filipino: 'Hindi mabuksan ang mga itinabing ideya ngayon.'),
              actionLabel: LanguageHelper.pick(language,
                  english: 'Try again', filipino: 'Subukan muli'),
              onAction: () => setState(() => _savedIdeas = _loadSavedIdeas()),
            );
          }
          final ideas = snapshot.data ?? const <_SavedIdea>[];
          if (ideas.isEmpty) {
            return KaibiganStateView(
              icon: Icons.bookmark_add_outlined,
              title: LanguageHelper.pick(
                language,
                english: 'Save ideas you want to remember',
                filipino: 'Itabi ang mga ideyang nais mong tandaan',
              ),
              message: LanguageHelper.pick(
                language,
                english:
                    'Tap Save idea in a lesson. Come back whenever you need a gentle reminder.',
                filipino:
                    'Piliin ang Itabi ang ideya sa isang aralin. Balikan ito kapag kailangan mo ng paalala.',
              ),
            );
          }
          return ListView.separated(
            key: const ValueKey('saved-learning-ideas-list'),
            padding: EdgeInsets.fromLTRB(
              MobileLayout.horizontalPadding(context),
              12,
              MobileLayout.horizontalPadding(context),
              32,
            ),
            itemCount: ideas.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 11),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(LanguageHelper.pick(language,
                      english: 'Keep what helps. Revisit an idea or make room for something new.',
                      filipino: 'Itabi ang nakakatulong. Balikan ang isang ideya o maglaan ng puwang para sa bago.'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary, height: 1.5)),
                );
              }
              final idea = ideas[index - 1];
              final section = idea.lesson.sections[idea.index];
              return KaibiganSurface(
                key: ValueKey('saved-idea-${idea.lesson.id}-${idea.index}'),
                onTap: () => _openIdea(idea),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.accentSubtle,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        idea.lesson.effectiveTypeAt(idea.index).icon,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            idea.lesson.title.resolve(language),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: palette.accentStrong),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            section.heading.resolve(language),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            section.body.resolve(language),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: palette.textSecondary,
                                      height: 1.4,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      key: ValueKey('remove-saved-idea-${idea.lesson.id}-${idea.index}'),
                      tooltip: LanguageHelper.pick(language,
                          english: 'Remove saved idea', filipino: 'Alisin ang itinabing ideya'),
                      onPressed: () => _removeIdea(idea, language),
                      icon: Icon(Icons.bookmark_remove_outlined,
                          color: palette.textMuted),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ))),
    );
  }
}

class _SavedIdea {
  const _SavedIdea({required this.lesson, required this.index});

  final LearningLesson lesson;
  final int index;
}
