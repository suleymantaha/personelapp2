import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_custom_colors.dart';

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

  /// Warning text and surfaces stay readable in both themes.
  Color get warningColor => customColors.statusPendingText;
  Color get warningBgColor => customColors.statusPendingBg;

  /// Select a readable foreground for a solid status-colored control.
  Color onStatusColor(Color background) {
    const light = Colors.white;
    const dark = AppColors.textPrimaryLight;
    final luminance = background.computeLuminance();
    final darkLuminance = dark.computeLuminance();
    final lightContrast = 1.05 / (luminance + 0.05);
    final darkContrast = luminance > darkLuminance
        ? (luminance + 0.05) / (darkLuminance + 0.05)
        : (darkLuminance + 0.05) / (luminance + 0.05);
    return lightContrast >= darkContrast ? light : dark;
  }

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
