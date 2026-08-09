import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/spacing.dart';

class AppColors {
  // Askeri Haki / Zeytin Yeşili Paleti
  static const Color militaryOlive = Color(0xFF4A5D36); // Primary Olive Green
  static const Color darkOlive = Color(0xFF2E3B21); // Dark Accent
  static const Color lightOlive = Color(0xFFE8EFE0); // Container Background
  static const Color accentKhaki = Color(0xFF8B9467);

  // Genel Arka Plan ve Yüzey Renkleri
  static const Color backgroundLight = Color(0xFFF6F8F5);
  static const Color backgroundSecondaryLight = Color(0xFFEFF3EB);
  static const Color backgroundDark = Color(0xFF111613);
  static const Color cardDark = Color(0xFF1E281F);

  // Metin Renkleri (Light / Dark)
  static const Color textPrimaryLight = Color(0xFF1C221A);
  static const Color textSecondaryLight = Color(0xFF5A6255);
  static const Color textMutedLight = Color(0xFF8B9485);

  static const Color textPrimaryDark = Color(0xFFE6EBE4);
  static const Color textSecondaryDark = Color(0xFFA5B2A0);
  static const Color textMutedDark = Color(0xFF748270);

  // Durum Renkleri
  static const Color approvedGreen = Color(0xFF2E7D32);
  static const Color pendingYellow = Color(0xFFF57F17);
  static const Color rejectedRed = Color(0xFFC62828);
  static const Color leaveGrey = Color(0xFF616161);

  // Uyarı & Bildirim Arka Planları
  static const Color warningBackgroundLight = Color(0xFFFFEBEE);
  static const Color warningBorderLight = Color(0xFFEF5350);
  static const Color warningBackgroundDark = Color(0xFF381B1B);
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

  static const Color statusLeaveLight = Color(0xFFECEFF1);
  static const Color statusLeaveTextLight = Color(0xFF37474F);
  static const Color statusLeaveDark = Color(0xFF263238);
  static const Color statusLeaveTextDark = Color(0xFFECEFF1);

  static const Color statusReportLight = Color(0xFFFFEBEE);
  static const Color statusReportTextLight = Color(0xFFC62828);
  static const Color statusReportDark = Color(0xFF4A1919);
  static const Color statusReportTextDark = Color(0xFFEF9A9A);

  static const Color statusPendingLight = Color(0xFFFFF8E1);
  static const Color statusPendingTextLight = Color(0xFFE65100);
  static const Color statusPendingDark = Color(0xFF4A3710);
  static const Color statusPendingTextDark = Color(0xFFFFD54F);
}

@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color accentOrOlive;
  final Color onAccentOrOlive;
  final Color squadBadgeBg;
  final Color squadBadgeText;
  final Color cardBorderColor;
  final Color rejectedColor;
  final Color rejectedBgColor;
  final Color rejectedBorderColor;
  final Color shadowColor;
  final Color headerBg;
  final Color headerBgSecondary;
  final Color pdfButtonBg;
  final Color accentSubtleBg;
  final Color approvedColor;
  final Color pendingColor;
  final Color blueGreyColor;
  final Color tealColor;
  final Color brownColor;
  final Color statusDutyBg;
  final Color statusDutyText;
  final Color statusLeaveBg;
  final Color statusLeaveText;
  final Color statusReportBg;
  final Color statusReportText;
  final Color statusPendingBg;
  final Color statusPendingText;

  const AppCustomColors({
    required this.accentOrOlive,
    required this.onAccentOrOlive,
    required this.squadBadgeBg,
    required this.squadBadgeText,
    required this.cardBorderColor,
    required this.rejectedColor,
    required this.rejectedBgColor,
    required this.rejectedBorderColor,
    required this.shadowColor,
    required this.headerBg,
    required this.headerBgSecondary,
    required this.pdfButtonBg,
    required this.accentSubtleBg,
    required this.approvedColor,
    required this.pendingColor,
    required this.blueGreyColor,
    required this.tealColor,
    required this.brownColor,
    required this.statusDutyBg,
    required this.statusDutyText,
    required this.statusLeaveBg,
    required this.statusLeaveText,
    required this.statusReportBg,
    required this.statusReportText,
    required this.statusPendingBg,
    required this.statusPendingText,
  });

  static const light = AppCustomColors(
    accentOrOlive: AppColors.militaryOlive,
    onAccentOrOlive: Colors.white,
    squadBadgeBg: AppColors.lightOlive,
    squadBadgeText: AppColors.darkOlive,
    cardBorderColor: Color(0xFFD6DEC9),
    rejectedColor: AppColors.rejectedRed,
    rejectedBgColor: AppColors.warningBackgroundLight,
    rejectedBorderColor: AppColors.rejectedRed,
    shadowColor: Color(0x14000000),
    headerBg: AppColors.militaryOlive,
    headerBgSecondary: AppColors.darkOlive,
    pdfButtonBg: Color(0xFF1B365D),
    accentSubtleBg: Color(0x144A5D36),
    approvedColor: AppColors.approvedGreen,
    pendingColor: AppColors.pendingYellow,
    blueGreyColor: AppColors.cardBlueGrey,
    tealColor: AppColors.cardTeal,
    brownColor: AppColors.cardBrown,
    statusDutyBg: AppColors.statusDutyLight,
    statusDutyText: AppColors.statusDutyTextLight,
    statusLeaveBg: AppColors.statusLeaveLight,
    statusLeaveText: AppColors.statusLeaveTextLight,
    statusReportBg: AppColors.statusReportLight,
    statusReportText: AppColors.statusReportTextLight,
    statusPendingBg: AppColors.statusPendingLight,
    statusPendingText: AppColors.statusPendingTextLight,
  );

  static const dark = AppCustomColors(
    accentOrOlive: AppColors.accentKhaki,
    onAccentOrOlive: Color(0xFF141B13),
    squadBadgeBg: Color(0xFF263326),
    squadBadgeText: AppColors.accentKhaki,
    cardBorderColor: Color(0xFF2A3626),
    rejectedColor: AppColors.warningBorderLight,
    rejectedBgColor: AppColors.warningBackgroundDark,
    rejectedBorderColor: AppColors.warningBorderDark,
    shadowColor: Color(0x66000000),
    headerBg: AppColors.darkOlive,
    headerBgSecondary: Color(0xFF1F291D),
    pdfButtonBg: Color(0xFF2C4C7E),
    accentSubtleBg: Color(0x1AFFFFFF),
    approvedColor: Color(0xFF81C784),
    pendingColor: Color(0xFFFFD54F),
    blueGreyColor: Color(0xFF90A4AE),
    tealColor: Color(0xFF4DB6AC),
    brownColor: Color(0xFFFFB74D),
    statusDutyBg: AppColors.statusDutyDark,
    statusDutyText: AppColors.statusDutyTextDark,
    statusLeaveBg: AppColors.statusLeaveDark,
    statusLeaveText: AppColors.statusLeaveTextDark,
    statusReportBg: AppColors.statusReportDark,
    statusReportText: AppColors.statusReportTextDark,
    statusPendingBg: AppColors.statusPendingDark,
    statusPendingText: AppColors.statusPendingTextDark,
  );

  @override
  AppCustomColors copyWith({
    Color? accentOrOlive,
    Color? onAccentOrOlive,
    Color? squadBadgeBg,
    Color? squadBadgeText,
    Color? cardBorderColor,
    Color? rejectedColor,
    Color? rejectedBgColor,
    Color? rejectedBorderColor,
    Color? shadowColor,
    Color? headerBg,
    Color? headerBgSecondary,
    Color? pdfButtonBg,
    Color? accentSubtleBg,
    Color? approvedColor,
    Color? pendingColor,
    Color? blueGreyColor,
    Color? tealColor,
    Color? brownColor,
    Color? statusDutyBg,
    Color? statusDutyText,
    Color? statusLeaveBg,
    Color? statusLeaveText,
    Color? statusReportBg,
    Color? statusReportText,
    Color? statusPendingBg,
    Color? statusPendingText,
  }) {
    return AppCustomColors(
      accentOrOlive: accentOrOlive ?? this.accentOrOlive,
      onAccentOrOlive: onAccentOrOlive ?? this.onAccentOrOlive,
      squadBadgeBg: squadBadgeBg ?? this.squadBadgeBg,
      squadBadgeText: squadBadgeText ?? this.squadBadgeText,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      rejectedColor: rejectedColor ?? this.rejectedColor,
      rejectedBgColor: rejectedBgColor ?? this.rejectedBgColor,
      rejectedBorderColor: rejectedBorderColor ?? this.rejectedBorderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      headerBg: headerBg ?? this.headerBg,
      headerBgSecondary: headerBgSecondary ?? this.headerBgSecondary,
      pdfButtonBg: pdfButtonBg ?? this.pdfButtonBg,
      accentSubtleBg: accentSubtleBg ?? this.accentSubtleBg,
      approvedColor: approvedColor ?? this.approvedColor,
      pendingColor: pendingColor ?? this.pendingColor,
      blueGreyColor: blueGreyColor ?? this.blueGreyColor,
      tealColor: tealColor ?? this.tealColor,
      brownColor: brownColor ?? this.brownColor,
      statusDutyBg: statusDutyBg ?? this.statusDutyBg,
      statusDutyText: statusDutyText ?? this.statusDutyText,
      statusLeaveBg: statusLeaveBg ?? this.statusLeaveBg,
      statusLeaveText: statusLeaveText ?? this.statusLeaveText,
      statusReportBg: statusReportBg ?? this.statusReportBg,
      statusReportText: statusReportText ?? this.statusReportText,
      statusPendingBg: statusPendingBg ?? this.statusPendingBg,
      statusPendingText: statusPendingText ?? this.statusPendingText,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      accentOrOlive: Color.lerp(accentOrOlive, other.accentOrOlive, t)!,
      onAccentOrOlive: Color.lerp(onAccentOrOlive, other.onAccentOrOlive, t)!,
      squadBadgeBg: Color.lerp(squadBadgeBg, other.squadBadgeBg, t)!,
      squadBadgeText: Color.lerp(squadBadgeText, other.squadBadgeText, t)!,
      cardBorderColor: Color.lerp(cardBorderColor, other.cardBorderColor, t)!,
      rejectedColor: Color.lerp(rejectedColor, other.rejectedColor, t)!,
      rejectedBgColor: Color.lerp(rejectedBgColor, other.rejectedBgColor, t)!,
      rejectedBorderColor:
          Color.lerp(rejectedBorderColor, other.rejectedBorderColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      headerBg: Color.lerp(headerBg, other.headerBg, t)!,
      headerBgSecondary:
          Color.lerp(headerBgSecondary, other.headerBgSecondary, t)!,
      pdfButtonBg: Color.lerp(pdfButtonBg, other.pdfButtonBg, t)!,
      accentSubtleBg: Color.lerp(accentSubtleBg, other.accentSubtleBg, t)!,
      approvedColor: Color.lerp(approvedColor, other.approvedColor, t)!,
      pendingColor: Color.lerp(pendingColor, other.pendingColor, t)!,
      blueGreyColor: Color.lerp(blueGreyColor, other.blueGreyColor, t)!,
      tealColor: Color.lerp(tealColor, other.tealColor, t)!,
      brownColor: Color.lerp(brownColor, other.brownColor, t)!,
      statusDutyBg: Color.lerp(statusDutyBg, other.statusDutyBg, t)!,
      statusDutyText: Color.lerp(statusDutyText, other.statusDutyText, t)!,
      statusLeaveBg: Color.lerp(statusLeaveBg, other.statusLeaveBg, t)!,
      statusLeaveText: Color.lerp(statusLeaveText, other.statusLeaveText, t)!,
      statusReportBg: Color.lerp(statusReportBg, other.statusReportBg, t)!,
      statusReportText:
          Color.lerp(statusReportText, other.statusReportText, t)!,
      statusPendingBg: Color.lerp(statusPendingBg, other.statusPendingBg, t)!,
      statusPendingText:
          Color.lerp(statusPendingText, other.statusPendingText, t)!,
    );
  }
}

extension ThemeContext on BuildContext {
  /// Theme Data
  ThemeData get theme => Theme.of(this);

  /// Color Scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Custom Theme Extensions
  AppCustomColors get customColors =>
      theme.extension<AppCustomColors>() ??
      (isDarkMode ? AppCustomColors.dark : AppCustomColors.light);

  /// True if dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Primary text color based on active theme
  Color get textPrimary =>
      isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  /// Secondary text color based on active theme
  Color get textSecondary =>
      isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  /// Muted / Hint text color based on active theme
  Color get textMuted =>
      isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight;

  /// Subtitle style with theme secondary text color
  TextStyle get textStyleSecondary => TextStyle(color: textSecondary);

  /// Muted text style
  TextStyle get textStyleMuted => TextStyle(color: textMuted);

  /// Accent Khaki in dark mode, Military Olive in light mode for legible primary text/icons
  Color get accentOrOlive => customColors.accentOrOlive;

  /// Badge container background color
  Color get squadBadgeBg => customColors.squadBadgeBg;

  /// Badge container text color
  Color get squadBadgeText => customColors.squadBadgeText;

  /// Card border side color
  Color get cardBorderColor => customColors.cardBorderColor;

  /// Text/Icon contrast color on accentOrOlive containers
  Color get onAccentOrOlive => customColors.onAccentOrOlive;

  /// Rejection / Warning text & icon color for dark and light modes
  Color get rejectedColor => customColors.rejectedColor;

  /// Rejection / Warning container background color
  Color get rejectedBgColor => customColors.rejectedBgColor;

  /// Rejection / Warning container border color
  Color get rejectedBorderColor => customColors.rejectedBorderColor;

  /// Dynamic shadow color
  Color get shadowColor => customColors.shadowColor;

  /// Primary header background color
  Color get headerBg => customColors.headerBg;

  /// Secondary header background for gradients
  Color get headerBgSecondary => customColors.headerBgSecondary;

  /// PDF export button background color
  Color get pdfButtonBg => customColors.pdfButtonBg;

  /// Day grid header background
  Color dayHeaderBg({required bool isToday}) => isToday
      ? customColors.pendingColor
      : (isDarkMode ? AppColors.cardDark : AppColors.darkOlive);

  /// Day grid header text color
  Color dayHeaderTextColor({required bool isToday}) =>
      isToday ? AppColors.textPrimaryLight : Colors.white;

  /// Cell border color for matrix/tables
  Color cellBorderColor({required bool isToday}) =>
      isToday ? accentOrOlive : cardBorderColor;

  /// Subtle container background for chips/containers
  Color get accentSubtleBg => customColors.accentSubtleBg;

  /// Approved status color for light and dark modes
  Color get approvedColor => customColors.approvedColor;

  /// Pending status color for light and dark modes
  Color get pendingColor => customColors.pendingColor;

  /// Slate / Blue Grey accent color
  Color get blueGreyColor => customColors.blueGreyColor;

  /// Teal accent color
  Color get tealColor => customColors.tealColor;

  /// Brown accent color
  Color get brownColor => customColors.brownColor;

  /// Matrix Duty/Leave status background color
  Color getStatusBgColor(String status) {
    if (status.contains('beklemede')) {
      return customColors.statusPendingBg;
    } else if (status.contains('GÖREV') || status.contains('NÖBET')) {
      return customColors.statusDutyBg;
    } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
      return customColors.statusLeaveBg;
    } else if (status.contains('RAPOR') || status.contains('SEVK')) {
      return customColors.statusReportBg;
    }
    return isDarkMode ? AppColors.cardDark : Colors.transparent;
  }

  /// Matrix Duty/Leave status text color
  Color getStatusTextColor(String status) {
    if (status.contains('beklemede')) {
      return customColors.statusPendingText;
    } else if (status.contains('GÖREV') || status.contains('NÖBET')) {
      return customColors.statusDutyText;
    } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
      return customColors.statusLeaveText;
    } else if (status.contains('RAPOR') || status.contains('SEVK')) {
      return customColors.statusReportText;
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
        onPrimary: Colors.white,
        secondary: AppColors.darkOlive,
        onSecondary: Colors.white,
        surface: const Color(0xFFF8F9FA),
        onSurface: AppColors.textPrimaryLight,
        surfaceContainer: Colors.white,
        surfaceContainerHighest: AppColors.lightOlive,
        onSurfaceVariant: AppColors.textSecondaryLight,
        outlineVariant: const Color(0xFFD6DEC9),
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
            color: Color(0xFFD6DEC9),
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
          borderSide: const BorderSide(color: Color(0xFFD6DEC9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide: const BorderSide(color: Color(0xFFD6DEC9)),
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
      dividerColor: const Color(0xFF2A3626),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.militaryOlive,
        brightness: Brightness.dark,
        primary: const Color(0xFF819D65),
        onPrimary: const Color(0xFF141D0E),
        secondary: AppColors.accentKhaki,
        onSecondary: const Color(0xFF141B13),
        surface: const Color(0xFF171E18),
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerLow: const Color(0xFF1A221B),
        surfaceContainer: AppColors.cardDark,
        surfaceContainerHigh: const Color(0xFF263326),
        surfaceContainerHighest: const Color(0xFF2D3C2D),
        onSurfaceVariant: AppColors.textSecondaryDark,
        outlineVariant: const Color(0xFF384937),
      ),
      extensions: const [AppCustomColors.dark],
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF161D15),
        foregroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 2,
        shadowColor: const Color(0x66000000),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF2A3626)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF171E18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A3626)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF171E18),
        modalBackgroundColor: Color(0xFF171E18),
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
          borderSide: const BorderSide(color: Color(0xFF2A3626)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2A3626)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentKhaki, width: 2),
        ),
      ),
    );
  }
}

