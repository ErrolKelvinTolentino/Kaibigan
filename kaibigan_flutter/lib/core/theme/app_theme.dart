import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.quicksand().fontFamily,
    scaffoldBackgroundColor: AppColors.warmCream,
    colorScheme: const ColorScheme.light(
      primary: AppColors.sageGreen,
      secondary: AppColors.softRose,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: AppColors.textPrimaryLight,
      onSurface: AppColors.textPrimaryLight,
    ),
    textTheme: GoogleFonts.quicksandTextTheme().copyWith(
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimaryLight,
        height: 1.1,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryLight,
        height: 1.25,
      ),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
        height: 1.3,
      ),
      titleSmall: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimaryLight,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryLight,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
      ),
      labelLarge: GoogleFonts.quicksand(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.warmCream,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      titleTextStyle: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryLight,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.quicksand().fontFamily,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.softOlive,
      secondary: AppColors.lavenderMist,
      surface: AppColors.darkCard,
      onPrimary: AppColors.darkBackground,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
    ),
    textTheme: GoogleFonts.quicksandTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimaryDark,
        height: 1.1,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryDark,
        height: 1.25,
      ),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
        height: 1.3,
      ),
      titleSmall: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimaryDark,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryDark,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryDark,
      ),
      labelLarge: GoogleFonts.quicksand(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: const BorderSide(color: AppColors.darkCardBorder, width: 1.5),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      titleTextStyle: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryDark,
      ),
    ),
  );
}
