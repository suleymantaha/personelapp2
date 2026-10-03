import 'package:flutter/material.dart';
import 'app_colors.dart';

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
    cardBorderColor: Color(0xFFDCE3EA),
    rejectedColor: AppColors.rejectedRed,
    rejectedBgColor: AppColors.warningBackgroundLight,
    rejectedBorderColor: AppColors.rejectedRed,
    shadowColor: Color(0x120F172A),
    headerBg: AppColors.militaryOlive,
    headerBgSecondary: AppColors.darkOlive,
    pdfButtonBg: Color(0xFF1B365D),
    accentSubtleBg: Color(0x140F766E),
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
    onAccentOrOlive: Color(0xFF042F2E),
    squadBadgeBg: Color(0xFF173B3A),
    squadBadgeText: AppColors.accentKhaki,
    cardBorderColor: Color(0xFF2B3A50),
    rejectedColor: AppColors.warningBorderLight,
    rejectedBgColor: AppColors.warningBackgroundDark,
    rejectedBorderColor: AppColors.warningBorderDark,
    shadowColor: Color(0x66000000),
    headerBg: Color(0xFF0F172A),
    headerBgSecondary: Color(0xFF172033),
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
