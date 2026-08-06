import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';

class DashboardMenuCard extends StatelessWidget {
  const DashboardMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 145;
        final hideSubtitle = constraints.maxHeight < 125;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Card(
            margin: EdgeInsets.zero,
            color: color.withValues(alpha: context.isDarkMode ? 0.18 : 0.1),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: color.withValues(
                  alpha: context.isDarkMode ? 0.4 : 0.3,
                ),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: compact ? 24 : 28, color: color),
                  SizedBox(height: compact ? AppSpacing.xs : AppSpacing.rowGap),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: compact ? 13 : null,
                    ),
                  ),
                  if (!hideSubtitle) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
