import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

enum DashboardActionTone { primary, neutral, personnel, import, pending }

class DashboardActionPalette {
  const DashboardActionPalette({
    required this.surface,
    required this.border,
    required this.iconSurface,
    required this.content,
    required this.surfaceGradient,
    required this.borderGradient,
    required this.iconGradient,
    required this.glowColor,
  });

  final Color surface;
  final Color border;
  final Color iconSurface;
  final Color content;
  final LinearGradient surfaceGradient;
  final LinearGradient borderGradient;
  final LinearGradient iconGradient;
  final Color glowColor;
}

extension DashboardActionTonePalette on DashboardActionTone {
  DashboardActionPalette resolve(BuildContext context) {
    final dark = context.isDarkMode;
    final accent = switch (this) {
      DashboardActionTone.primary ||
      DashboardActionTone.neutral =>
        context.accentOrOlive,
      DashboardActionTone.personnel => context.blueGreyColor,
      DashboardActionTone.import =>
        dark ? const Color(0xFF64B5F6) : Colors.blue.shade700,
      DashboardActionTone.pending => context.pendingColor,
    };
    final alpha = this == DashboardActionTone.primary ? 0.14 : 0.08;

    final (Color startColor, Color endColor) = switch (this) {
      DashboardActionTone.primary => dark
          ? (const Color(0xFF1E2E23), const Color(0xFF0F1812))
          : (const Color(0xFFF2FAF4), const Color(0xFFE4F2E7)),
      DashboardActionTone.neutral => dark
          ? (const Color(0xFF222623), const Color(0xFF121513))
          : (const Color(0xFFF7F8F6), const Color(0xFFEAEDE8)),
      DashboardActionTone.personnel => dark
          ? (const Color(0xFF192530), const Color(0xFF0E161E))
          : (const Color(0xFFF1F6FB), const Color(0xFFE2EDF7)),
      DashboardActionTone.import => dark
          ? (const Color(0xFF172636), const Color(0xFF0D1622))
          : (const Color(0xFFF0F6FF), const Color(0xFFE0ECFD)),
      DashboardActionTone.pending => dark
          ? (const Color(0xFF2A2315), const Color(0xFF18130B))
          : (const Color(0xFFFFFDF2), const Color(0xFFFFF7DB)),
    };

    final surfaceGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [startColor, endColor],
    );

    final borderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        dark
            ? Colors.white.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.90),
        accent.withValues(alpha: dark ? 0.55 : 0.45),
        accent.withValues(alpha: dark ? 0.20 : 0.25),
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    final iconGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent.withValues(alpha: dark ? 0.35 : 0.22),
        accent.withValues(alpha: dark ? 0.15 : 0.08),
      ],
    );

    return DashboardActionPalette(
      surface: accent.withValues(alpha: dark ? alpha + 0.04 : alpha),
      border: accent.withValues(
        alpha: this == DashboardActionTone.primary ? 0.85 : 0.32,
      ),
      iconSurface: accent.withValues(alpha: dark ? 0.22 : 0.10),
      content: accent,
      surfaceGradient: surfaceGradient,
      borderGradient: borderGradient,
      iconGradient: iconGradient,
      glowColor: accent,
    );
  }
}
