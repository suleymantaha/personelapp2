import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

enum DashboardActionTone { primary, neutral, personnel, import, pending }

class DashboardActionPalette {
  const DashboardActionPalette({
    required this.surface,
    required this.border,
    required this.iconSurface,
    required this.content,
  });

  final Color surface;
  final Color border;
  final Color iconSurface;
  final Color content;
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
    return DashboardActionPalette(
      surface: accent.withValues(alpha: dark ? alpha + 0.04 : alpha),
      border: accent.withValues(
        alpha: this == DashboardActionTone.primary ? 0.85 : 0.32,
      ),
      iconSurface: accent.withValues(alpha: dark ? 0.22 : 0.10),
      content: accent,
    );
  }
}
