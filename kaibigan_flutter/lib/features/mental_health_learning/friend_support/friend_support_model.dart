import 'package:flutter/material.dart';

import '../learning_model.dart';

@immutable
class FriendSupportOption {
  const FriendSupportOption({
    required this.id,
    required this.text,
    required this.explanation,
  });

  /// Identifier like 'A', 'B', 'C', or 'D'
  final String id;

  /// Option text in English and Filipino/Taglish
  final LearningCopy text;

  /// Educational explanation of why this option is correct, less helpful, or harmful
  final LearningCopy explanation;
}

@immutable
class FriendSupportQuestion {
  const FriendSupportQuestion({
    required this.id,
    this.contextQuote,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.hint,
    required this.correctExplanation,
  });

  final String id;

  /// Friend's statement or scenario quote (if any)
  final LearningCopy? contextQuote;

  /// The question prompt (e.g. "What would be the most supportive response?")
  final LearningCopy prompt;

  /// Exactly 4 options
  final List<FriendSupportOption> options;

  /// 0-based index of the correct option
  final int correctIndex;

  /// Hint shown when tapping "💡 Help"
  final LearningCopy hint;

  /// Educational explanation for why the correct option is best
  final LearningCopy correctExplanation;

  FriendSupportOption get correctOption => options[correctIndex];
}

@immutable
class FriendSupportLesson {
  const FriendSupportLesson({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.whatYoullLearn,
    required this.pointsHeader,
    required this.points,
    this.avoidHeader,
    this.avoidPoints = const [],
    required this.questions,
  });

  final String id;
  final int order;
  final LearningCopy title;
  final LearningCopy subtitle;
  final LearningCopy whatYoullLearn;
  final LearningCopy pointsHeader;
  final List<LearningCopy> points;
  final LearningCopy? avoidHeader;
  final List<LearningCopy> avoidPoints;
  final List<FriendSupportQuestion> questions;
}
