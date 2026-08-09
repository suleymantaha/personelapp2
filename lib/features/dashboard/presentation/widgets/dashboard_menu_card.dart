import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/tactical_hud_painter.dart';

class DashboardMenuCard extends StatefulWidget {
  const DashboardMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
    this.animationIndex = 0,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DashboardActionTone tone;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  State<DashboardMenuCard> createState() => _DashboardMenuCardState();
}

class _DashboardMenuCardState extends State<DashboardMenuCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5400),
    );

    final isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTestEnv) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.tone.resolve(context);
    final dark = context.isDarkMode;

    return Semantics(
      button: true,
      label: '${widget.title}, ${widget.subtitle}',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: palette.borderGradient,
            boxShadow: [
              BoxShadow(
                color: palette.glowColor.withValues(alpha: dark ? 0.24 : 0.14),
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
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final rawValue =
                          _controller.isAnimating ? _controller.value : 0.45;
                      final staggeredValue =
                          (rawValue + (widget.animationIndex * 0.18)) % 1.0;
                      return CustomPaint(
                        painter: TacticalHudPainter(
                          isDarkMode: dark,
                          accentColor: palette.content,
                          animationProgress: staggeredValue,
                        ),
                      );
                    },
                  ),
                ),
                // Glowing HUD Active Status Dot
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
                    onTap: widget.onTap,
                    splashColor: palette.content.withValues(alpha: 0.18),
                    highlightColor: palette.content.withValues(alpha: 0.09),
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
                              padding: const EdgeInsets.all(7.0),
                              child: Icon(
                                widget.icon,
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
                                      widget.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.15,
                                        height: 1.15,
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
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      letterSpacing: 0.1,
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
