import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/glass_mirror_sheen_painter.dart';

class DashboardMenuCard extends StatelessWidget {
  const DashboardMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DashboardActionTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = tone.resolve(context);
    final dark = context.isDarkMode;

    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: palette.borderGradient,
            boxShadow: [
              BoxShadow(
                color: palette.glowColor.withValues(alpha: dark ? 0.22 : 0.12),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.8),
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
                    painter: GlassMirrorSheenPainter(
                      isDarkMode: dark,
                      accentColor: palette.content,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: palette.content.withValues(alpha: 0.15),
                    highlightColor: palette.content.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: palette.iconGradient,
                              border: Border.all(
                                color: palette.content.withValues(
                                  alpha: dark ? 0.38 : 0.25,
                                ),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.content.withValues(
                                    alpha: dark ? 0.30 : 0.18,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(7.0),
                              child: Icon(
                                icon,
                                size: 20,
                                color: palette.content,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        height: 1.15,
                                        shadows: dark
                                            ? [
                                                Shadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}
