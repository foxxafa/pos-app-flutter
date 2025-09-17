import 'package:flutter/material.dart';

class AppTheme {
  // --- AÇIK TEMA RENKLERİ (DIAPALET ile aynı) ---
  static const Color lightPrimaryColor = Color(0xFF0D47A1);
  static const Color lightSecondaryColor = Color(0xFF1976D2);
  static const Color lightBackgroundColor = Color(0xFFF0F4F8);
  static const Color lightSurfaceColor = Colors.white;

  // --- ORTAK RENKLER ---
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFFA000);

  // --- AÇIK TEMA TANIMI ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: lightPrimaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,

    colorScheme: ColorScheme.fromSeed(
      seedColor: lightPrimaryColor,
      primary: lightPrimaryColor,
      secondary: lightSecondaryColor,
      surface: lightBackgroundColor,
      error: errorColor,
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: lightPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 1.0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 19.0,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      color: lightSurfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightPrimaryColor, width: 2.0),
      ),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: lightSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: lightSecondaryColor,
      foregroundColor: Colors.white,
    ),
  );
}