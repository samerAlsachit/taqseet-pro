import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Tajawal',
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.electric,
      secondary: AppColors.navy,
      surface: AppColors.cardLight,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.electric,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.navy),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electric, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(fontFamily: 'Tajawal', color: AppColors.textSecondaryLight),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1, space: 1),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'Tajawal',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.electric,
      secondary: AppColors.navy,
      surface: AppColors.cardDark,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.electric,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.electric,
        side: const BorderSide(color: AppColors.electric),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electric, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(fontFamily: 'Tajawal', color: AppColors.textSecondaryDark),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderDark, thickness: 1, space: 1),
  );
}
