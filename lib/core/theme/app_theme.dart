import 'package:flutter/material.dart';

class AppColors {
  // Askeri Haki / Zeytin Yeşili Paleti
  static const Color militaryOlive = Color(0xFF4A5D36); // Primary Olive Green
  static const Color darkOlive = Color(0xFF2E3B21); // Dark Accent
  static const Color lightOlive = Color(0xFFE8EFE0); // Container Background
  static const Color accentKhaki = Color(0xFF8B9467);

  // Genel Arka Plan ve Yüzey Renkleri
  static const Color backgroundLight = Color(0xFFF8F9F5);
  static const Color backgroundSecondaryLight = Color(0xFFF4F6F0);
  static const Color backgroundDark = Color(0xFF0F1410);
  static const Color cardDark = Color(0xFF1F291D);

  // Metin Renkleri (Light / Dark)
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textMutedLight = Color(0xFF9E9E9E);

  static const Color textPrimaryDark = Color(0xFFEEEEEE);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);
  static const Color textMutedDark = Color(0xFF78909C);

  // Durum Renkleri
  static const Color approvedGreen = Color(0xFF2E7D32);
  static const Color pendingYellow = Color(0xFFF57F17);
  static const Color rejectedRed = Color(0xFFC62828);
  static const Color leaveGrey = Color(0xFF616161);

  // Uyarı & Bildirim Arka Planları
  static const Color warningBackgroundLight = Color(0xFFFFEBEE);
  static const Color warningBorderLight = Color(0xFFEF5350);
  static const Color warningBackgroundDark = Color(0xFF3B1E1E);
  static const Color warningBorderDark = Color(0xFFD32F2F);

  // Kart Aksan Renkleri
  static const Color cardBlueGrey = Color(0xFF37474F);
  static const Color cardTeal = Color(0xFF00695C);
  static const Color cardBrown = Color(0xFF4E342E);

  // Nöbet / Görev Hücre Renkleri (Matris İçin)
  static const Color statusDutyLight = Color(0xFFE8F5E9);
  static const Color statusDutyTextLight = Color(0xFF2E7D32);
  static const Color statusDutyDark = Color(0xFF1B4D24);
  static const Color statusDutyTextDark = Color(0xFF81C784);

  static const Color statusLeaveLight = Color(0xFFE0E0E0);
  static const Color statusLeaveTextLight = Color(0xFF212121);
  static const Color statusLeaveDark = Color(0xFF2C3942);
  static const Color statusLeaveTextDark = Color(0xFFCFD8DC);

  static const Color statusReportLight = Color(0xFFFFEBEE);
  static const Color statusReportTextLight = Color(0xFFC62828);
  static const Color statusReportDark = Color(0xFF4A1919);
  static const Color statusReportTextDark = Color(0xFFE57373);

  static const Color statusPendingLight = Color(0xFFFFF8E1);
  static const Color statusPendingTextLight = Color(0xFFE65100);
  static const Color statusPendingDark = Color(0xFF4A3710);
  static const Color statusPendingTextDark = Color(0xFFFFD54F);
}

extension ThemeContext on BuildContext {
  /// Theme Data
  ThemeData get theme => Theme.of(this);

  /// Color Scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// True if dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Primary text color based on active theme
  Color get textPrimary => isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  /// Secondary text color based on active theme
  Color get textSecondary => isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  /// Muted / Hint text color based on active theme
  Color get textMuted => isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight;

  /// Subtitle style with theme secondary text color
  TextStyle get textStyleSecondary => TextStyle(color: textSecondary);

  /// Muted text style
  TextStyle get textStyleMuted => TextStyle(color: textMuted);

  /// Accent Khaki in dark mode, Military Olive in light mode for legible primary text/icons
  Color get accentOrOlive => isDarkMode ? AppColors.accentKhaki : AppColors.militaryOlive;

  /// Badge container background color (surfaceContainerHighest in dark, lightOlive in light)
  Color get squadBadgeBg => isDarkMode ? colorScheme.surfaceContainerHighest : AppColors.lightOlive;

  /// Badge container text color (accentKhaki in dark, darkOlive in light)
  Color get squadBadgeText => isDarkMode ? AppColors.accentKhaki : AppColors.darkOlive;

  /// Card border side color (dividerColor in dark, lightOlive in light)
  Color get cardBorderColor => isDarkMode ? theme.dividerColor : AppColors.lightOlive;

  /// Text/Icon contrast color on accentOrOlive containers
  Color get onAccentOrOlive => isDarkMode ? const Color(0xFF141B13) : Colors.white;

  /// Rejection / Warning text & icon color for dark and light modes
  Color get rejectedColor => isDarkMode ? AppColors.warningBorderLight : AppColors.rejectedRed;

  /// Rejection / Warning container background color
  Color get rejectedBgColor => isDarkMode ? AppColors.warningBackgroundDark : AppColors.warningBackgroundLight;

  /// Rejection / Warning container border color
  Color get rejectedBorderColor => isDarkMode ? AppColors.warningBorderDark : AppColors.rejectedRed;

  /// Dynamic shadow color
  Color get shadowColor => isDarkMode ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.12);

  /// Primary header background color (darkOlive in dark mode, militaryOlive in light mode)
  Color get headerBg => isDarkMode ? AppColors.darkOlive : AppColors.militaryOlive;

  /// Secondary header background for gradients (dark green in dark mode, darkOlive in light mode)
  Color get headerBgSecondary => isDarkMode ? const Color(0xFF1F291D) : AppColors.darkOlive;

  /// PDF export button background color
  Color get pdfButtonBg => isDarkMode ? const Color(0xFF2C4C7E) : const Color(0xFF1B365D);

  /// Day grid header background (pendingYellow for today, darkOlive/cardDark for standard days)
  Color dayHeaderBg({required bool isToday}) =>
      isToday ? AppColors.pendingYellow : (isDarkMode ? AppColors.cardDark : AppColors.darkOlive);

  /// Day grid header text color
  Color dayHeaderTextColor({required bool isToday}) =>
      isToday ? AppColors.textPrimaryLight : Colors.white;

  /// Cell border color for matrix/tables
  Color cellBorderColor({required bool isToday}) =>
      isToday ? accentOrOlive : cardBorderColor;

  /// Subtle container background for chips/containers (0.08 alpha)
  Color get accentSubtleBg => isDarkMode
      ? Colors.white.withValues(alpha: 0.08)
      : AppColors.militaryOlive.withValues(alpha: 0.08);

  /// Approved status color for light and dark modes
  Color get approvedColor => isDarkMode ? const Color(0xFF81C784) : AppColors.approvedGreen;

  /// Pending status color for light and dark modes
  Color get pendingColor => isDarkMode ? const Color(0xFFFFD54F) : AppColors.pendingYellow;

  /// Slate / Blue Grey accent color
  Color get blueGreyColor => isDarkMode ? const Color(0xFF90A4AE) : AppColors.cardBlueGrey;

  /// Teal accent color
  Color get tealColor => isDarkMode ? const Color(0xFF4DB6AC) : AppColors.cardTeal;

  /// Brown accent color
  Color get brownColor => isDarkMode ? const Color(0xFFFFB74D) : AppColors.cardBrown;

  /// Matrix Duty/Leave status background color
  Color getStatusBgColor(String status) {
    if (status.contains('GÖREV') || status.contains('NÖBET')) {
      return isDarkMode ? AppColors.statusDutyDark : AppColors.statusDutyLight;
    } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
      return isDarkMode ? AppColors.statusLeaveDark : AppColors.statusLeaveLight;
    } else if (status.contains('RAPOR') || status.contains('SEVK')) {
      return isDarkMode ? AppColors.statusReportDark : AppColors.statusReportLight;
    } else if (status.contains('beklemede')) {
      return isDarkMode ? AppColors.statusPendingDark : AppColors.statusPendingLight;
    }
    return isDarkMode ? AppColors.cardDark : Colors.transparent;
  }

  /// Matrix Duty/Leave status text color
  Color getStatusTextColor(String status) {
    if (status.contains('GÖREV') || status.contains('NÖBET')) {
      return isDarkMode ? AppColors.statusDutyTextDark : AppColors.statusDutyTextLight;
    } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
      return isDarkMode ? AppColors.statusLeaveTextDark : AppColors.statusLeaveTextLight;
    } else if (status.contains('RAPOR') || status.contains('SEVK')) {
      return isDarkMode ? AppColors.statusReportTextDark : AppColors.statusReportTextLight;
    } else if (status.contains('beklemede')) {
      return isDarkMode ? AppColors.statusPendingTextDark : AppColors.statusPendingTextLight;
    }
    return textMuted;
  }
}

class AppTheme {
  static ThemeData get militaryTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.militaryOlive,
        primary: AppColors.militaryOlive,
        secondary: AppColors.darkOlive,
        surface: AppColors.backgroundLight,
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
      scaffoldBackgroundColor: AppColors.backgroundDark,
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
        color: AppColors.cardDark,
        elevation: 3,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF2C3B29)),
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
