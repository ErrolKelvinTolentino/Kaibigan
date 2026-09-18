import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../../../core/widgets/mobile_layout.dart';
import '../../settings/user_provider.dart';
import '../learning_progress_store.dart';
import 'friend_support_catalog.dart';
import 'friend_support_lesson_screen.dart';
import 'friend_support_model.dart';
import 'friend_support_practice_model.dart';
import 'friend_support_practice_screen.dart';
import 'friend_support_safety_sheet.dart';

class FriendSupportHubScreen extends StatefulWidget {
  const FriendSupportHubScreen({
    super.key,
    this.progressStore,
  });

  final LearningProgressStore? progressStore;

  @override
  State<FriendSupportHubScreen> createState() => _FriendSupportHubScreenState();
}

class _FriendSupportHubScreenState extends State<FriendSupportHubScreen> {
  late final LearningProgressStore _progressStore;
  Set<String> _completedIds = {};
  final Map<String, ({int score, int total})> _quizScores = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _progressStore = widget.progressStore ?? LearningProgressStore();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await _progressStore.loadCompleted();
    final scores = <String, ({int score, int total})>{};
    for (final lesson in FriendSupportCatalog.lessons) {
      final scoreData = await _progressStore.loadQuizScore(lesson.id);
      if (scoreData != null) {
        scores[lesson.id] = scoreData;
      }
    }

    if (!mounted) return;
    setState(() {
      _completedIds = completed;
      _quizScores.clear();
      _quizScores.addAll(scores);
      _isLoading = false;
    });
  }

  Future<void> _openLesson(FriendSupportLesson lesson) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FriendSupportLessonScreen(lesson: lesson),
      ),
    );
    await _loadProgress();
  }

  Future<void> _openPractice(PracticeScenario scenario) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FriendSupportPracticeScreen(scenario: scenario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<UserProvider>().language;
    final palette = context.kaibigan;
    final completedCount = FriendSupportCatalog.lessons
        .where((l) => _completedIds.contains(l.id))
        .length;
    final totalCount = FriendSupportCatalog.lessons.length;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          LanguageHelper.pick(
            language,
            english: 'Friend Support Lessons',
            filipino: 'Aralin sa Pagsuporta',
          ),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            key: const ValueKey('friend-support-hub-need-help'),
            onPressed: () => FriendSupportSafetySheet.show(
              context,
              language: language,
            ),
            icon: Icon(
              Icons.health_and_safety_outlined,
              color: palette.danger,
              size: 18,
            ),
            label: Text(
              LanguageHelper.pick(
                language,
                english: 'Need Help?',
                filipino: 'Tulong?',
              ),
              style: TextStyle(
                color: palette.danger,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: MobileContent(
          child: RefreshIndicator(
            onRefresh: _loadProgress,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: MobileLayout.horizontalPadding(context),
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Introduction Card
                  Container(
                    key: const ValueKey('friend-support-hub-hero'),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      colors: [
                          palette.surface,
                          Theme.of(context).brightness == Brightness.dark
                              ? palette.surfaceElevated
                              : palette.accentSubtle,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.accent.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: palette.accent.withValues(alpha: 0.24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.accent.withValues(alpha: 0.10),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.handshake_rounded,
                                  color: palette.accentStrong,
                                  size: 29,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LanguageHelper.pick(
                                      language,
                                      english: 'How to be there for a friend',
                                      filipino: 'Paano sumuporta sa kaibigan',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    LanguageHelper.pick(
                                      language,
                                      english: 'A practical guide for caring conversations',
                                      filipino: 'Praktikal na gabay para sa maingat na pag-uusap',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: palette.accentStrong,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    LanguageHelper.pick(
                                      language,
                                      english:
                                          'Learn how to listen without judging, recognize crisis situations, and know when to involve help.',
                                      filipino:
                                          'Matutong makinig nang walang panghuhusga, makilala ang delikadong sitwasyon, at malaman kung kailan hihingi ng tulong.',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: palette.textSecondary,
                                          height: 1.42,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: palette.border.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      LanguageHelper.pick(
                                        language,
                                        english:
                                            '$completedCount of $totalCount lessons completed',
                                        filipino:
                                            '$completedCount sa $totalCount aralin ang natapos',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: palette.accentStrong,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${totalCount == 0 ? 0 : ((completedCount / totalCount) * 100).toInt()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: palette.accentStrong,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: totalCount == 0
                                      ? 0
                                      : completedCount / totalCount,
                                  minHeight: 7,
                                  backgroundColor: palette.surfaceSubtle,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    palette.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Live practice: reading about a good reply and typing one
                  // are different skills, so this sits above the lessons.
                  Text(
                    LanguageHelper.pick(
                      language,
                      english: 'Practise a real conversation',
                      filipino: 'Magpraktis ng tunay na usapan',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LanguageHelper.pick(
                      language,
                      english:
                          'Kaibigan plays a friend who is struggling. You reply '
                          'in the chat box, and every reply comes back with '
                          'feedback.',
                      filipino:
                          'Gaganap ang Kaibigan bilang kaibigang nahihirapan. '
                          'Sumagot ka sa chat box, at may feedback sa bawat '
                          'sagot mo.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          height: 1.42,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    key: const ValueKey('friend-support-practice-rail'),
                    height: 156,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: PracticeScenarios.all.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final scenario = PracticeScenarios.all[index];
                        return _PracticeCard(
                          scenario: scenario,
                          language: language,
                          onTap: () => _openPractice(scenario),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  Text(
                    LanguageHelper.pick(
                      language,
                      english: 'Lessons & Practice Quizzes',
                      filipino: 'Mga Aralin at Pagsasanay',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Lesson Cards
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    ...FriendSupportCatalog.lessons.map((lesson) {
                      final isCompleted = _completedIds.contains(lesson.id);
                      final scoreData = _quizScores[lesson.id];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: KaibiganSurface(
                          key: ValueKey('friend-lesson-card-${lesson.id}'),
                          child: InkWell(
                            onTap: () => _openLesson(lesson),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? palette.accentSubtle
                                              : palette.surfaceSubtle,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              LanguageHelper.pick(
                                                language,
                                                english: 'Lesson ${lesson.order}',
                                                filipino: 'Aralin ${lesson.order}',
                                              ),
                                              style: TextStyle(
                                                color: isCompleted
                                                    ? palette.accentStrong
                                                    : palette.textSecondary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.accentSubtle,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            border: Border.all(
                                              color: palette.accent.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: palette.accentStrong,
                                                size: 13,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                LanguageHelper.pick(
                                                  language,
                                                  english: 'Completed',
                                                  filipino: 'Tapos na',
                                                ),
                                                style: TextStyle(
                                                  color: palette.accentStrong,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    lesson.title.resolve(language),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    lesson.subtitle.resolve(language),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: palette.textSecondary,
                                          height: 1.42,
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.quiz_outlined,
                                            size: 15,
                                            color: palette.textMuted,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              LanguageHelper.pick(
                                                language,
                                                english:
                                                    '${lesson.questions.length} questions',
                                                filipino:
                                                    '${lesson.questions.length} tanong',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: palette.textMuted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (scoreData != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.accentSubtle,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.emoji_events_rounded,
                                                size: 14,
                                                color: palette.accentStrong,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                LanguageHelper.pick(
                                                  language,
                                                  english:
                                                      'Best: ${scoreData.score}/${scoreData.total}',
                                                  filipino:
                                                      'Iskor: ${scoreData.score}/${scoreData.total}',
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color:
                                                          palette.accentStrong,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One scenario the user can rehearse, shown in the practice rail.
class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.scenario,
    required this.language,
    required this.onTap,
  });

  final PracticeScenario scenario;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 232,
      child: Material(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(KaibiganRadius.card),
        child: InkWell(
          key: ValueKey('practice-card-${scenario.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(KaibiganRadius.card),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KaibiganRadius.card),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: scenario.isSensitive
                            ? palette.danger.withValues(alpha: 0.13)
                            : palette.accentSubtle,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        scenario.isSensitive
                            ? Icons.health_and_safety_outlined
                            : Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: scenario.isSensitive
                            ? palette.danger
                            : palette.accentStrong,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        scenario.friendName,
                        style: text.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    scenario.situation.resolve(language),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: palette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        LanguageHelper.pick(
                          language,
                          english: 'Start practice',
                          filipino: 'Simulan',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(
                          color: palette.accentStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: palette.accentStrong,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
