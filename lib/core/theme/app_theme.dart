import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgBase,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.bgBase,
          primary: AppColors.accent,
          onPrimary: Colors.white,
          secondary: AppColors.accentTint,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(
          color: AppColors.surface1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: AppColors.borderHairline),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface1,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderHairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderHairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface1,
          selectedColor: AppColors.accentTint,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          side: const BorderSide(color: AppColors.borderHairline),
          shape: const StadiumBorder(),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderHairline,
          thickness: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgBaseLight,
        colorScheme: const ColorScheme.light(
          surface: AppColors.bgBaseLight,
          primary: AppColors.accentLight,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimaryLight,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        cardTheme: const CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: AppColors.borderLight),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accentLight, width: 1.5),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.accentLight.withOpacity(0.14),
          labelStyle: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12),
          side: const BorderSide(color: AppColors.borderLight),
          shape: const StadiumBorder(),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentLight,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      );
}
