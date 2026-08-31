import 'package:flutter/material.dart';

class AppColors {
  // Cozy Pastel Nature & Bee Palette
  static const Color honeyGold = Color(0xFFE5A93C);
  static const Color honeyAmber = Color(0xFFD48B28);
  static const Color honeyLight = Color(0xFFFDF7EB);
  static const Color warmHoney = Color(0xFFF3C06B);
  static const Color pollenGlow = Color(0xFFFFE7A3);
  static const Color honeySurface = Color(0xFFFFFCF5);
  static const Color honeyBorder = Color(0xFFF0DFC0);

  /// Accessible foreground for honey and pollen controls in both themes.
  static const Color onHoney = Color(0xFF2E2315);

  /// Chooses the higher-contrast Kaibigan foreground for custom accent fills.
  static Color readableOn(Color background) {
    final backgroundLuminance = background.computeLuminance();
    final darkLuminance = onHoney.computeLuminance();
    final whiteContrast = 1.05 / (backgroundLuminance + 0.05);
    final lighter = backgroundLuminance > darkLuminance
        ? backgroundLuminance
        : darkLuminance;
    final darker = backgroundLuminance > darkLuminance
        ? darkLuminance
        : backgroundLuminance;
    final darkContrast = (lighter + 0.05) / (darker + 0.05);
    return darkContrast >= whiteContrast ? onHoney : Colors.white;
  }

  static const Color sageGreen = Color(0xFF52745A);
  static const Color softOlive = Color(0xFF8CA58A);
  static const Color warmCream = Color(0xFFFBF9F4);
  static const Color softIvory = Color(0xFFFFFFFF);

  // Accent & Emotion Colors
  static const Color softRose = Color(0xFFE28490);
  static const Color warmPeach = Color(0xFFF29E85);
  static const Color lavenderMist = Color(0xFFB5A4DB);
  static const Color periwinkle = Color(0xFF9EA9E2);
  static const Color skyBlue = Color(0xFF7FAEC9);
  static const Color softYellow = Color(0xFFF5C76D);

  // Dark Mode Palette (Cozy Forest Night)
  static const Color darkBackground = Color(0xFF171A18);
  static const Color darkCard = Color(0xFF272D28);
  static const Color darkCardBorder = Color(0xFF384139);
  static const Color darkHoneySurface = Color(0xFF3A3020);
  static const Color darkHoneyBorder = Color(0xFF5A4930);

  // Text Colors (High Contrast)
  static const Color textPrimaryLight = Color(0xFF1E1E1E);
  static const Color textSecondaryLight = Color(0xFF555555);
  static const Color textPrimaryDark = Color(0xFFF2F0EA);
  static const Color textSecondaryDark = Color(0xFFB4B8B2);

  // Mascot Personas (Bee Themed Outfits)
  // Kai (Male Bee Companion / Calm Honey & Amber)
  static const Color kaiPrimary = Color(0xFFD9822B);
  static const Color kaiLight = Color(0xFFFDF3E7);
  static const Color kaiDark = Color(0xFF6E3B09);

  // Ann (Female Bee Companion / Warm Blossom & Peach Honey)
  static const Color annPrimary = Color(0xFFE26D5C);
  static const Color annLight = Color(0xFFFDF0ED);
  static const Color annDark = Color(0xFF6E2317);

  // Bee Secondary
  static const Color beePrimary = Color(0xFFE5A93C);
  static const Color beeLight = Color(0xFFFDF7EB);
  static const Color beeDark = Color(0xFF7A4E08);

  // Mood Tracker Colors (1 - 5)
  // These mirror the illustrated backgrounds used by the five bee moods and
  // also serve as the compact, non-pictorial calendar legend.
  static const Color moodAwful = Color(0xFF9AA9BC); // 1 - Struggling
  static const Color moodLow = Color(0xFF91B9AA); // 2 - Low
  static const Color moodOkay = Color(0xFFB9CE95); // 3 - Okay
  static const Color moodGood = Color(0xFFF0A57D); // 4 - Good
  static const Color moodAwesome = Color(0xFFF2C75C); // 5 - Great

  // Flower Growth Colors
  static const Color gardenGrass = Color(0xFFD3E0D5);
  static const Color gardenGrassDark = Color(0xFF27382B);
}
