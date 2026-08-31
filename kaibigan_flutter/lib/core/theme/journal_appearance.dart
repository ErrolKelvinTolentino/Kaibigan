import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum JournalPaperStyle { ruled, clean, dotted, botanical }

enum JournalAccent { honey, sage, rose, lavender, sky }

extension JournalPaperStyleX on JournalPaperStyle {
  static JournalPaperStyle fromStorage(String? value) {
    return JournalPaperStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => JournalPaperStyle.ruled,
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
