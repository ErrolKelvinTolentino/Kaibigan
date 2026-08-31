import 'package:flutter/material.dart';

/// Semantic Kaibigan colors.
///
/// Feature widgets should prefer these roles over choosing raw colors. This
/// keeps light and night themes emotionally consistent without simply
/// inverting one palette into the other.
@immutable
class KaibiganPalette extends ThemeExtension<KaibiganPalette> {
  const KaibiganPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentStrong,
    required this.accentSubtle,
    required this.botanical,
    required this.botanicalSubtle,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
    required this.scrim,
  });

  static const light = KaibiganPalette(
    background: Color(0xFFFAF8F3),
    surface: Color(0xFFFFFDF9),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF4F0E8),
    textPrimary: Color(0xFF26231F),
    textSecondary: Color(0xFF625D54),
    textMuted: Color(0xFF8A8378),
    accent: Color(0xFFA86118),
    onAccent: Color(0xFFFFFFFF),
    accentStrong: Color(0xFF84480D),
    accentSubtle: Color(0xFFFFF0D3),
    botanical: Color(0xFF647E68),
    botanicalSubtle: Color(0xFFEAF0E9),
    border: Color(0xFFE8E1D6),
    success: Color(0xFF52745A),
    warning: Color(0xFFAA7021),
    danger: Color(0xFFB85858),
    shadow: Color(0x1A493317),
    scrim: Color(0x70302B24),
  );

  static const dark = KaibiganPalette(
    background: Color(0xFF171A18),
    surface: Color(0xFF202521),
    surfaceElevated: Color(0xFF272D28),
    surfaceSubtle: Color(0xFF1C211D),
    textPrimary: Color(0xFFF2F0EA),
    textSecondary: Color(0xFFB4B8B2),
    textMuted: Color(0xFF858C86),
    accent: Color(0xFFE3B15D),
    onAccent: Color(0xFF2E2315),
    accentStrong: Color(0xFFF1C773),
    accentSubtle: Color(0xFF3A3020),
    botanical: Color(0xFF9BB09B),
    botanicalSubtle: Color(0xFF263229),
    border: Color(0xFF384139),
    success: Color(0xFF8EAD91),
    warning: Color(0xFFE0B56D),
    danger: Color(0xFFE09292),
    shadow: Color(0x66000000),
    scrim: Color(0xB3000000),
  );

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color accentStrong;
  final Color accentSubtle;
  final Color botanical;
  final Color botanicalSubtle;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shadow;
  final Color scrim;

  @override
  KaibiganPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? accentStrong,
    Color? accentSubtle,
    Color? botanical,
    Color? botanicalSubtle,
    Color? border,
    Color? success,
    Color? warning,
    Color? danger,
    Color? shadow,
    Color? scrim,
  }) {
    return KaibiganPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      botanical: botanical ?? this.botanical,
      botanicalSubtle: botanicalSubtle ?? this.botanicalSubtle,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  KaibiganPalette lerp(ThemeExtension<KaibiganPalette>? other, double t) {
    if (other is! KaibiganPalette) return this;
    return KaibiganPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      botanical: Color.lerp(botanical, other.botanical, t)!,
      botanicalSubtle: Color.lerp(botanicalSubtle, other.botanicalSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension KaibiganThemeContext on BuildContext {
  KaibiganPalette get kaibigan =>
      Theme.of(this).extension<KaibiganPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? KaibiganPalette.dark
          : KaibiganPalette.light);
}

abstract final class KaibiganSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;
}

abstract final class KaibiganRadius {
  static const double control = 16;
  static const double card = 22;
  static const double feature = 28;
  static const double sheet = 30;
}

abstract final class KaibiganMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration reveal = Duration(milliseconds: 380);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}
