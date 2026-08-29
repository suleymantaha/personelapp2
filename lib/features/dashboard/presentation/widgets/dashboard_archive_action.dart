import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/tactical_hud_painter.dart';

class DashboardArchiveAction extends StatelessWidget {
  const DashboardArchiveAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.animationIndex = 6,
    this.height,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int animationIndex;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardActionTone.neutral.resolve(context);
    final dark = context.isDarkMode;

    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height ?? 56),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: palette.borderGradient,
              boxShadow: [
                BoxShadow(
                  color:
                      palette.glowColor.withValues(alpha: dark ? 0.24 : 0.14),
                  blurRadius: 14,
                  spreadRadius: -2,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.40 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: palette.surfaceGradient,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TacticalHudPainter(
                        isDarkMode: dark,
                        accentColor: palette.content,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.content,
                        boxShadow: [
                          BoxShadow(
                            color: palette.content.withValues(
                              alpha: dark ? 0.90 : 0.70,
                            ),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      splashColor: palette.content.withValues(alpha: 0.18),
                      highlightColor: palette.content.withValues(alpha: 0.09),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                gradient: palette.iconGradient,
                                border: Border.all(
                                  color: palette.content.withValues(
                                    alpha: dark ? 0.45 : 0.30,
                                  ),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.content.withValues(
                                      alpha: dark ? 0.35 : 0.20,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: -1,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Icon(icon,
                                    size: 22, color: palette.content),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.15,
                                      shadows: dark
                                          ? [
                                              Shadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.6),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      letterSpacing: 0.1,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: palette.content,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
