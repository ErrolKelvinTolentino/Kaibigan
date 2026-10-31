import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../../../core/widgets/mobile_layout.dart';
import '../../settings/user_provider.dart';
import 'friend_support_model.dart';
import 'friend_support_quiz_screen.dart';
import 'friend_support_safety_sheet.dart';
import 'friend_support_practice_model.dart';
import 'friend_support_practice_screen.dart';

class FriendSupportLessonScreen extends StatelessWidget {
  const FriendSupportLessonScreen({
    super.key,
    required this.lesson,
  });

  final FriendSupportLesson lesson;

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
            english: 'Lesson ${lesson.order}',
            filipino: 'Aralin ${lesson.order}',
          ),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            key: const ValueKey('friend-support-lesson-need-help'),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MobileLayout.horizontalPadding(context),
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lesson Hero Header Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? const [Color(0xFF382C1B), Color(0xFF242017)]
                          : const [Color(0xFFFFF1D0), Color(0xFFFFFAEF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.honeyAmber.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.35
                            : 0.45,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.honeyAmber.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.honeyAmber,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              LanguageHelper.pick(
                                language,
                                english: 'Lesson ${lesson.order} of 3',
                                filipino: 'Aralin ${lesson.order} sa 3',
                              ),
                              style: const TextStyle(
                                color: AppColors.onHoney,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.12
                                    : 0.85,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              lesson.order == 1
                                  ? Icons.hearing_rounded
                                  : lesson.order == 2
                                      ? Icons.health_and_safety_rounded
                                      : Icons.handshake_outlined,
                              color: AppColors.honeyAmber,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        lesson.title.resolve(language),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 21,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lesson.subtitle.resolve(language),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.textSecondary,
                              height: 1.45,
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // What You'll Learn Section
                KaibiganSurface(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: palette.accentSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: palette.accentStrong,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              LanguageHelper.pick(
                                language,
                                english: 'What You\'ll Learn',
                                filipino: 'Ano ang Matututunan Mo',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lesson.whatYoullLearn.resolve(language),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.textPrimary,
                              height: 1.55,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Helpful Points Section (Calming Mint / Green Accent)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF19271E)
                        : const Color(0xFFF1F8F4),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF81C784).withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.30
                            : 0.55,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF81C784)
                                  .withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lesson.pointsHeader.resolve(language),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...lesson.points.map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  point.resolve(language),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        height: 1.48,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Avoid Points Section (if any, Warm Rose Accent)
                if (lesson.avoidHeader != null &&
                    lesson.avoidPoints.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A1B1C)
                          : const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE57373).withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.30
                              : 0.50,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE57373)
                                    .withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.remove_circle_outline_rounded,
                                color: Color(0xFFC62828),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lesson.avoidHeader!.resolve(language),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...lesson.avoidPoints.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFC62828),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    point.resolve(language),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          height: 1.48,
                                          fontWeight: FontWeight.w500,
                                        ),
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

                const SizedBox(height: 24),
                for (final scenario in PracticeScenarios.all
                    .where((item) => item.lessonId == lesson.id)) ...[
                  OutlinedButton.icon(
                    key: ValueKey('lesson-practice-${scenario.id}'),
                    onPressed: () =>
                        Navigator.of(context).push<void>(MaterialPageRoute(
                      builder: (_) =>
                          FriendSupportPracticeScreen(scenario: scenario),
                    )),
                    icon: const Icon(Icons.forum_outlined),
                    label: Text(LanguageHelper.pick(
                      language,
                      english:
                          'Practise a conversation with ${scenario.friendName}',
                      filipino:
                          'Praktisin ang usapan kay ${scenario.friendName}',
                    )),
                  ),
                  const SizedBox(height: 8),
                ],
                // Practice Quiz CTA
                ElevatedButton(
                  key: const ValueKey('start-friend-quiz-btn'),
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => FriendSupportQuizScreen(lesson: lesson),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.honeyAmber,
                    foregroundColor: AppColors.onHoney,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.quiz_outlined, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          LanguageHelper.pick(
                            language,
                            english:
                                'Start Practice Quiz (${lesson.questions.length} questions)',
                            filipino:
                                'Simulan ang Quiz (${lesson.questions.length} tanong)',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
