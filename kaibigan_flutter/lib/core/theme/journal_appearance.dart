import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum JournalPaperStyle { ruled, clean, dotted, botanical }

/// Writing and reading size for journal entries. Stored as a preference rather
/// than per entry, because it is about the reader's comfort, not the text.
enum JournalTextSize { small, normal, large }

enum JournalAccent { honey, sage, rose, lavender, sky }

extension JournalPaperStyleX on JournalPaperStyle {
  static JournalPaperStyle fromStorage(String? value) {
    return JournalPaperStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => JournalPaperStyle.ruled,
    );
  }
}

extension JournalTextSizeX on JournalTextSize {
  /// Multiplier applied to the editor and reader body sizes.
  double get scale => switch (this) {
        JournalTextSize.small => 0.88,
        JournalTextSize.normal => 1.0,
        JournalTextSize.large => 1.18,
      };

  /// Line spacing in logical pixels, kept in step with the size so ruled paper
  /// can draw its lines exactly under the text.
  double get lineHeight => switch (this) {
        JournalTextSize.small => 25.0,
        JournalTextSize.normal => 28.0,
        JournalTextSize.large => 33.0,
      };

  String get label => switch (this) {
        JournalTextSize.small => 'Small',
        JournalTextSize.normal => 'Normal',
        JournalTextSize.large => 'Large',
      };

  static JournalTextSize fromStorage(String? value) {
    return JournalTextSize.values.firstWhere(
      (size) => size.name == value,
      orElse: () => JournalTextSize.normal,
    );
  }
}

extension JournalAccentX on JournalAccent {
  Color get color => switch (this) {
        JournalAccent.honey => AppColors.honeyAmber,
        JournalAccent.sage => AppColors.sageGreen,
        JournalAccent.rose => AppColors.softRose,
        JournalAccent.lavender => AppColors.lavenderMist,
        JournalAccent.sky => AppColors.skyBlue,
      };

  static JournalAccent fromStorage(String? value) {
    return JournalAccent.values.firstWhere(
      (accent) => accent.name == value,
      orElse: () => JournalAccent.honey,
    );
  }
}
