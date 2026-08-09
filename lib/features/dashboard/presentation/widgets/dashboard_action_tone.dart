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
          ? (const Color(0xFF142419), const Color(0xFF09120C))
          : (const Color(0xFFF0F7F2), const Color(0xFFE2EFE5)),
      DashboardActionTone.neutral => dark
          ? (const Color(0xFF181C19), const Color(0xFF0C0F0D))
          : (const Color(0xFFF5F7F5), const Color(0xFFE7EAE7)),
      DashboardActionTone.personnel => dark
          ? (const Color(0xFF12202C), const Color(0xFF091119))
          : (const Color(0xFFEFF5FA), const Color(0xFFDFECF6)),
      DashboardActionTone.import => dark
          ? (const Color(0xFF102133), const Color(0xFF08121D))
          : (const Color(0xFFEEF5FF), const Color(0xFFDCEDFF)),
      DashboardActionTone.pending => dark
          ? (const Color(0xFF261F10), const Color(0xFF140F06))
          : (const Color(0xFFFFFDF0), const Color(0xFFFFF6D4)),
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
        accent.withValues(alpha: dark ? 0.75 : 0.65),
        accent.withValues(alpha: dark ? 0.35 : 0.30),
        dark
            ? Colors.white.withValues(alpha: 0.25)
            : accent.withValues(alpha: 0.15),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final iconGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent.withValues(alpha: dark ? 0.38 : 0.24),
        accent.withValues(alpha: dark ? 0.18 : 0.10),
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
