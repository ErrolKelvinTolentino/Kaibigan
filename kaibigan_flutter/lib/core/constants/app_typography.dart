import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Hero Stacked Header Typography (e.g. MY favorites)
  static TextStyle heroHeader(BuildContext context, {bool isDark = false, Color? color}) => GoogleFonts.quicksand(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: color ?? (isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C)),
        height: 1.0,
        letterSpacing: 0.5,
      );

  // Screen Title Typography (24px, w800)
  static TextStyle titleLarge(BuildContext context, {bool isDark = false, Color? color}) => GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: color ?? (isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C)),
        height: 1.25,
      );

  // Section Header Typography (20px, w700)
  static TextStyle titleMedium(BuildContext context, {bool isDark = false, Color? color}) => GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color ?? (isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C)),
        height: 1.3,
      );

  // Card Header / Sub-Section Typography (16px, w700)
  static TextStyle titleSmall(BuildContext context, {bool isDark = false, Color? color}) => GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color ?? (isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C)),
      );

  // Main Content / Body Large (16px, w500)
  static TextStyle bodyLarge(BuildContext context, {bool isDark = false, Color? color}) => GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color ?? (isDark ? AppColors.textPrimaryDark : const Color(0xFF2C2C2C)),
        height: 1.5,
      );

  // Subtitle / Body Medium (14px, w500)
  static TextStyle bodyMedium(BuildContext context, {bool isDark = false, Color? color}) => GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        height: 1.4,
      );

  // Micro-copy / Badges / Dates (12px, w600)
  static TextStyle bodySmall(BuildContext context, {bool isDark = false, Color? color}) => GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      );

  // Button Label (15px, w700)
  static TextStyle labelButton(BuildContext context, {Color? color}) => GoogleFonts.quicksand(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color ?? Colors.white,
      );

  // Companion Reflection Typography: Italic Serif (Lora)
  static TextStyle companionInlineResponse({Color? color, double fontSize = 15}) => GoogleFonts.lora(
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.sageGreen,
        height: 1.6,
      );
}
