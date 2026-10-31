import 'package:flutter/material.dart';

import '../../core/utils/language_helper.dart';

@immutable
class LearningCopy {
  const LearningCopy({
    required this.english,
    required this.filipino,
    this.taglish,
  });

  final String english;
  final String filipino;
  final String? taglish;

  String resolve(String language) => LanguageHelper.pick(
        language,
        english: english,
        filipino: filipino,
        taglish: taglish,
      );
}

@immutable
class LearningSection {
  const LearningSection({
    required this.heading,
    required this.body,
    this.type = LearningSectionType.explanation,
    this.prompt,
    this.essential = true,
  });

  final LearningCopy heading;
  final LearningCopy body;
  final LearningSectionType type;
  final LearningCopy? prompt;
  final bool essential;
}

enum LearningSectionType {
  explanation,
  example,
  signs,
  mythFact,
  practice,
  support,
  seekHelp,
  recap,
}

extension LearningSectionTypeStyle on LearningSectionType {
  IconData get icon => switch (this) {
        LearningSectionType.explanation => Icons.menu_book_outlined,
        LearningSectionType.example => Icons.chat_bubble_outline_rounded,
        LearningSectionType.signs => Icons.visibility_outlined,
        LearningSectionType.mythFact => Icons.fact_check_outlined,
        LearningSectionType.practice => Icons.bolt_rounded,
        LearningSectionType.support => Icons.people_alt_outlined,
        LearningSectionType.seekHelp => Icons.health_and_safety_outlined,
        LearningSectionType.recap => Icons.auto_awesome_outlined,
      };

  String label(String language) => switch (this) {
        LearningSectionType.explanation => LanguageHelper.pick(
            language,
            english: 'Understand',
            filipino: 'Unawain',
          ),
        LearningSectionType.example => LanguageHelper.pick(
            language,
            english: 'In real life',
            filipino: 'Sa tunay na buhay',
          ),
        LearningSectionType.signs => LanguageHelper.pick(
            language,
            english: 'Notice',
            filipino: 'Pansinin',
          ),
        LearningSectionType.mythFact => LanguageHelper.pick(
            language,
            english: 'Myth & fact',
            filipino: 'Myth at fact',
          ),
        LearningSectionType.practice => LanguageHelper.pick(
            language,
            english: 'Try it',
            filipino: 'Subukan',
          ),
        LearningSectionType.support => LanguageHelper.pick(
            language,
            english: 'Support',
            filipino: 'Suporta',
          ),
        LearningSectionType.seekHelp => LanguageHelper.pick(
            language,
            english: 'Get help',
            filipino: 'Humingi ng tulong',
          ),
        LearningSectionType.recap => LanguageHelper.pick(
            language,
            english: 'Takeaway',
            filipino: 'Baunin',
          ),
      };
}

enum LearningCategory { foundations, conditions, emotions, coping, support }

extension LearningCategoryCopy on LearningCategory {
  IconData get icon => switch (this) {
        LearningCategory.foundations => Icons.psychology_alt_rounded,
        LearningCategory.conditions => Icons.health_and_safety_outlined,
        LearningCategory.emotions => Icons.favorite_outline_rounded,
        LearningCategory.coping => Icons.spa_rounded,
        LearningCategory.support => Icons.people_alt_outlined,
      };

  String label(String language) => switch (this) {
        LearningCategory.foundations => LanguageHelper.pick(
            language,
            english: 'Foundations',
            filipino: 'Mga batayan',
          ),
        LearningCategory.conditions => LanguageHelper.pick(
            language,
            english: 'Conditions',
            filipino: 'Mga kondisyon',
          ),
        LearningCategory.emotions => LanguageHelper.pick(
            language,
            english: 'Emotions',
            filipino: 'Damdamin',
          ),
        LearningCategory.coping => LanguageHelper.pick(
            language,
            english: 'Coping skills',
            filipino: 'Mga paraan ng pagharap',
          ),
        LearningCategory.support => LanguageHelper.pick(
            language,
            english: 'Getting support',
            filipino: 'Paghingi ng suporta',
          ),
      };
}

@immutable
class LearningLesson {
  const LearningLesson({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.readMinutes,
    required this.icon,
    required this.sections,
    required this.reflection,
    required this.medlinePlusQuery,
    required this.sourceUrl,
    required this.sourceLabel,
    this.outcomes = const [],
    this.searchTerms = const [],
    this.sensitivityNotice,
    this.reviewedLabel = 'August 2026',
    this.contentVersion = '1.0',
    this.relatedLessonIds = const [],
  });

  final String id;
  final LearningCategory category;
  final LearningCopy title;
  final LearningCopy summary;
  final int readMinutes;
  final IconData icon;
  final List<LearningSection> sections;
  final LearningCopy reflection;
  final String medlinePlusQuery;
  final Uri sourceUrl;
  final String sourceLabel;
  final List<LearningCopy> outcomes;
  final List<String> searchTerms;
  final LearningCopy? sensitivityNotice;
  final String reviewedLabel;
  final String contentVersion;
  final List<String> relatedLessonIds;
}

extension LearningLessonStructure on LearningLesson {
  LearningSectionType effectiveTypeAt(int index) {
    final declared = sections[index].type;
    if (declared != LearningSectionType.explanation || index == 0) {
      return declared;
    }
    if (index == sections.length - 1) return LearningSectionType.recap;
    if (index == 1) return LearningSectionType.signs;
    if (index == sections.length - 2) return LearningSectionType.practice;
    return LearningSectionType.example;
  }
}

@immutable
class LearningPath {
  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.lessonIds,
  });

  final String id;
  final LearningCopy title;
  final LearningCopy description;
  final IconData icon;
  final List<String> lessonIds;
}

@immutable
class TrustedArticle {
  const TrustedArticle({
    required this.title,
    required this.summary,
    required this.url,
  });

  final String title;
  final String summary;
  final Uri url;

  static bool isMedlineUrl(Uri url) => url.scheme == 'https' &&
      const {'medlineplus.gov', 'www.medlineplus.gov'}.contains(url.host) &&
      url.userInfo.isEmpty;

  Map<String, Object?> toJson() => {
        'title': title,
        'summary': summary,
        'url': url.toString(),
      };

  static TrustedArticle? fromJson(Map<String, Object?> json) {
    final title = json['title'] as String?;
    final summary = json['summary'] as String?;
    final url = Uri.tryParse(json['url'] as String? ?? '');
    if (title == null || title.trim().isEmpty || summary == null || url == null || !isMedlineUrl(url)) {
      return null;
    }
    return TrustedArticle(title: title, summary: summary, url: url);
  }
}

/// Why a particular lesson is being suggested next. Showing the reason turns
/// a bare link into a choice the reader can judge.
enum LearningNextReason { related, path, category, anything }

extension LearningNextReasonCopy on LearningNextReason {
  String label(String language) => switch (this) {
        LearningNextReason.related => LanguageHelper.pick(
            language,
            english: 'CONTINUES THIS TOPIC',
            filipino: 'PAGPAPATULOY NG PAKSANG ITO',
          ),
        LearningNextReason.path => LanguageHelper.pick(
            language,
            english: 'NEXT IN THIS PATH',
            filipino: 'SUSUNOD SA LANDAS NA ITO',
          ),
        LearningNextReason.category => LanguageHelper.pick(
            language,
            english: 'MORE ON THIS SUBJECT',
            filipino: 'IBA PA SA PAKSANG ITO',
          ),
        LearningNextReason.anything => LanguageHelper.pick(
            language,
            english: 'SOMEWHERE ELSE TO START',
            filipino: 'IBANG PWEDENG SIMULAN',
          ),
      };
}
