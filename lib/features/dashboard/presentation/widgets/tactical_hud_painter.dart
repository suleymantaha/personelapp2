import 'dart:math' as math;
import 'package:flutter/material.dart';

class TacticalHudPainter extends CustomPainter {
  const TacticalHudPainter({
    required this.isDarkMode,
    required this.accentColor,
    this.animationProgress,
  });

  final bool isDarkMode;
  final Color accentColor;
  final double? animationProgress;

  @override
  void paint(Canvas canvas, Size size) {
    const bracketLength = 9.0;
    const bracketOffset = 5.0;
    const bracketStroke = 1.6;

    final bracketPaint = Paint()
      ..color = accentColor.withValues(alpha: isDarkMode ? 0.90 : 0.70)
      ..strokeWidth = bracketStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // 1. Top-Left Corner Bracket
    final topLeft = Path()
      ..moveTo(bracketOffset, bracketOffset + bracketLength)
      ..lineTo(bracketOffset, bracketOffset)
      ..lineTo(bracketOffset + bracketLength, bracketOffset);
    canvas.drawPath(topLeft, bracketPaint);

    // 2. Top-Right Corner Bracket
    final topRight = Path()
      ..moveTo(size.width - bracketOffset - bracketLength, bracketOffset)
      ..lineTo(size.width - bracketOffset, bracketOffset)
      ..lineTo(size.width - bracketOffset, bracketOffset + bracketLength);
    canvas.drawPath(topRight, bracketPaint);

    // 3. Bottom-Left Corner Bracket
    final bottomLeft = Path()
      ..moveTo(bracketOffset, size.height - bracketOffset - bracketLength)
      ..lineTo(bracketOffset, size.height - bracketOffset)
      ..lineTo(bracketOffset + bracketLength, size.height - bracketOffset);
    canvas.drawPath(bottomLeft, bracketPaint);

    // 4. Bottom-Right Corner Bracket
    final bottomRight = Path()
      ..moveTo(size.width - bracketOffset - bracketLength, size.height - bracketOffset)
      ..lineTo(size.width - bracketOffset, size.height - bracketOffset)
      ..lineTo(size.width - bracketOffset, size.height - bracketOffset - bracketLength);
    canvas.drawPath(bottomRight, bracketPaint);

    // 5. Türk Bayrağı İkonografisi (Hilal & Yıldız Emblem Watermark)
    final flagPaint = Paint()
      ..color = isDarkMode
          ? const Color(0xFFE53935).withValues(alpha: 0.32)
          : const Color(0xFFD32F2F).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final flagGlowPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: isDarkMode ? 0.20 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final flagX = size.width - 28.0;
    final flagY = 17.0;

    // Crescent (Hilal)
    final crescentOuter = Path()
      ..addOval(Rect.fromCircle(center: Offset(flagX, flagY), radius: 7.5));
    final crescentInner = Path()
      ..addOval(Rect.fromCircle(center: Offset(flagX + 2.0, flagY), radius: 6.0));
    final crescentPath = Path.combine(
      PathOperation.difference,
      crescentOuter,
      crescentInner,
    );

    // 5-Pointed Star (Yıldız)
    final starCenter = Offset(flagX + 9.0, flagY - 0.5);
    final starPath = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? 3.0 : 1.2;
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

    // Draw Glow & Flag Emblem
    canvas.drawPath(crescentPath, flagGlowPaint);
    canvas.drawPath(starPath, flagGlowPaint);
    canvas.drawPath(crescentPath, flagPaint);
    canvas.drawPath(starPath, flagPaint);

    // 6. Moving Tracer Bullet / Laser Beam Effect (Kayan Mermi İzi Efekti)
    if (animationProgress != null) {
      final p = animationProgress!;

      final startX = -size.width * 0.4 + (size.width * 1.8) * p;
      final startY = -size.height * 0.2 + (size.height * 1.4) * p;

      const tracerLength = 48.0;
      const dx = tracerLength * 0.866;
      const dy = tracerLength * 0.5;

      final bulletHead = Offset(startX, startY);
      final bulletTail = Offset(startX - dx, startY - dy);

      final tracerPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: isDarkMode ? 0.95 : 0.85),
            accentColor.withValues(alpha: isDarkMode ? 0.80 : 0.65),
            accentColor.withValues(alpha: isDarkMode ? 0.30 : 0.20),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.70, 1.0],
        ).createShader(Rect.fromPoints(bulletHead, bulletTail))
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(bulletHead, bulletTail, tracerPaint);

      final tipPaint = Paint()..color = Colors.white;
      canvas.drawCircle(bulletHead, 1.6, tipPaint);

      final auraPaint = Paint()
        ..color = accentColor.withValues(alpha: isDarkMode ? 0.50 : 0.35);
      canvas.drawCircle(bulletHead, 4.0, auraPaint);
    }

    // 7. Subtle Technical Grid Scan Shader Overlay
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: isDarkMode ? 0.09 : 0.04),
          Colors.transparent,
          accentColor.withValues(alpha: isDarkMode ? 0.05 : 0.02),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), scanPaint);
  }

  @override
  bool shouldRepaint(covariant TacticalHudPainter oldDelegate) =>
      oldDelegate.isDarkMode != isDarkMode ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.animationProgress != animationProgress;
}
