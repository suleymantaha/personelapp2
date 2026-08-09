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

    // 5. Türk Bayrağı İkonografisi (Büyük Merkez Filigran / Large Centered Emblem Watermark)
    final emblemScale = math.min(size.width, size.height) * 0.28;
    final flagX = size.width * 0.52;
    final flagY = size.height * 0.48;

    final flagPaint = Paint()
      ..color = isDarkMode
          ? const Color(0xFFE53935).withValues(alpha: 0.14)
          : const Color(0xFFD32F2F).withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    final flagGlowPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: isDarkMode ? 0.09 : 0.05)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, emblemScale * 0.45);

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

    // Draw Glow & Centered Flag Watermark
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
