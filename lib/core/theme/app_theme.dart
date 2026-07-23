import 'package:flutter/material.dart';

class AppColors {
  // Askeri Haki / Zeytin Yeşili Paleti
  static const Color militaryOlive = Color(0xFF4A5D36); // Primary Olive Green
  static const Color darkOlive = Color(0xFF2E3B21); // Dark Accent
  static const Color lightOlive = Color(0xFFE8EFE0); // Container Background
  static const Color accentKhaki = Color(0xFF8B9467);

  // Durum Renkleri
  static const Color approvedGreen = Color(0xFF2E7D32);
  static const Color pendingYellow = Color(0xFFF57F17);
  static const Color rejectedRed = Color(0xFFC62828);
  static const Color leaveGrey = Color(0xFF616161);

  // Nöbet / Görev Hücre Renkleri (Matris İçin)
  static const Color statusDuty = Color(0xFF2E7D32);
  static const Color statusLeave = Color(0xFF424242);
  static const Color statusReport = Color(0xFFC62828);
  static const Color statusPending = Color(0xFFF57F17);
}

class AppTheme {
  static ThemeData get militaryTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.militaryOlive,
        primary: AppColors.militaryOlive,
        secondary: AppColors.darkOlive,
        surface: const Color(0xFFF8F9F5),
        surfaceContainerHighest: AppColors.lightOlive,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.militaryOlive,
        foregroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.militaryOlive,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.militaryOlive,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.militaryOlive, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkMilitaryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1410), // Deep Tactical Obsidian
      dividerColor: const Color(0xFF2C3B29),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.militaryOlive,
        brightness: Brightness.dark,
        primary: const Color(0xFF768D5D),
        secondary: AppColors.accentKhaki,
        surface: const Color(0xFF192117),
        surfaceContainerHighest: const Color(0xFF243021),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF161D15),
        foregroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1F291D),
        elevation: 3,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF2C3B29), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF192117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C3B29)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF192117),
        modalBackgroundColor: Color(0xFF192117),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.militaryOlive,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.militaryOlive,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF141B13),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2C3B29)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2C3B29)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentKhaki, width: 2),
        ),
      ),
    );
  }
}
