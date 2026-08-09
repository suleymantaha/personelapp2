import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class TurkishFlagWatermarkBackground extends StatelessWidget {
  const TurkishFlagWatermarkBackground({
    required this.child,
    this.opacityMultiplier = 1.0,
    super.key,
  });

  final Widget child;
  final double opacityMultiplier;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _TurkishFlagBackgroundPainter(
              isDarkMode: context.isDarkMode,
              opacityMultiplier: opacityMultiplier,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _TurkishFlagBackgroundPainter extends CustomPainter {
  const _TurkishFlagBackgroundPainter({
    required this.isDarkMode,
    required this.opacityMultiplier,
  });

  final bool isDarkMode;
  final double opacityMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final emblemScale = math.min(size.width, size.height) * 0.32;
    final flagX = size.width * 0.52;
    final flagY = size.height * 0.42;

    final baseAlpha = isDarkMode ? 0.055 : 0.038;
    final alpha = (baseAlpha * opacityMultiplier).clamp(0.0, 1.0);

    final flagPaint = Paint()
      ..color = (isDarkMode ? const Color(0xFFE53935) : const Color(0xFFD32F2F))
          .withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final flagGlowPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: alpha * 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, emblemScale * 0.5);

    // Large Crescent (Büyük Hilal)
    final crescentOuter = Path()
      ..addOval(Rect.fromCircle(center: Offset(flagX - emblemScale * 0.25, flagY), radius: emblemScale));
    final crescentInner = Path()
      ..addOval(Rect.fromCircle(center: Offset(flagX - emblemScale * 0.25 + emblemScale * 0.28, flagY), radius: emblemScale * 0.79));
    final crescentPath = Path.combine(
      PathOperation.difference,
      crescentOuter,
      crescentInner,
    );

    // Large 5-Pointed Star (Büyük 5 Köşeli Yıldız)
    final starCenter = Offset(flagX - emblemScale * 0.25 + emblemScale * 1.18, flagY - emblemScale * 0.06);
    final starPath = Path();
    const points = 5;
    final starRadius = emblemScale * 0.42;
    final starInnerRadius = starRadius * 0.38;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? starRadius : starInnerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = starCenter.dx + radius * math.cos(angle);
      final y = starCenter.dy + radius * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    canvas.drawPath(crescentPath, flagGlowPaint);
    canvas.drawPath(starPath, flagGlowPaint);
    canvas.drawPath(crescentPath, flagPaint);
    canvas.drawPath(starPath, flagPaint);
  }

  @override
  bool shouldRepaint(covariant _TurkishFlagBackgroundPainter oldDelegate) =>
      oldDelegate.isDarkMode != isDarkMode ||
      oldDelegate.opacityMultiplier != opacityMultiplier;
}
