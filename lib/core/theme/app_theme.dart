import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'app_colors.dart';
import 'app_custom_colors.dart';

export 'app_colors.dart';
export 'app_custom_colors.dart';
export 'theme_context.dart';

class AppTheme {
  static ThemeData get militaryTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.militaryOlive,
        primary: AppColors.militaryOlive,
        onPrimary: Colors.white,
        secondary: const Color(0xFF334155),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainer: Colors.white,
        surfaceContainerHighest: const Color(0xFFE2E8F0),
        onSurfaceVariant: AppColors.textSecondaryLight,
        outlineVariant: const Color(0xFFDCE3EA),
      ),
      extensions: const [AppCustomColors.light],
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.militaryOlive,
        foregroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Color(0xFFDCE3EA),
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightOlive.withValues(alpha: 0.72),
        selectedColor: AppColors.militaryOlive,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(
          color: AppColors.darkOlive,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.militaryOlive,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.militaryOlive,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.militaryOlive,
            width: 2,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkMilitaryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      dividerColor: const Color(0xFF263449),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.militaryOlive,
        brightness: Brightness.dark,
        primary: const Color(0xFF5EEAD4),
        onPrimary: const Color(0xFF042F2E),
        secondary: AppColors.accentKhaki,
        onSecondary: const Color(0xFF0F172A),
        surface: const Color(0xFF111827),
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerLow: const Color(0xFF131C2B),
        surfaceContainer: AppColors.cardDark,
        surfaceContainerHigh: const Color(0xFF1E293B),
        surfaceContainerHighest: const Color(0xFF263449),
        onSurfaceVariant: AppColors.textSecondaryDark,
        outlineVariant: const Color(0xFF334155),
      ),
      extensions: const [AppCustomColors.dark],
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 2,
        shadowColor: const Color(0x66000000),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF2B3A50)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2B3A50)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF111827),
        modalBackgroundColor: Color(0xFF111827),
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
        fillColor: const Color(0xFF131C2B),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2B3A50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2B3A50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentKhaki, width: 2),
        ),
      ),
    );
  }
}
