import 'package:flutter/material.dart';

class GlassMirrorSheenPainter extends CustomPainter {
  const GlassMirrorSheenPainter({
    required this.isDarkMode,
    required this.accentColor,
  });

  final bool isDarkMode;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Diagonal mirror reflection sheen sweep across top-left to mid-right
    final mirrorPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.85, 0)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.42,
        0,
        size.height * 0.72,
      )
      ..close();

    final mirrorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDarkMode ? 0.16 : 0.45),
          Colors.white.withValues(alpha: isDarkMode ? 0.04 : 0.15),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(mirrorPath, mirrorPaint);

    // 2. Ambient corner light flare at top-right
    final flarePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 0.65,
        colors: [
          accentColor.withValues(alpha: isDarkMode ? 0.18 : 0.14),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flarePaint);

    // 3. Top rim glass light stroke (mirror rim reflection)
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: isDarkMode ? 0.45 : 0.80),
          accentColor.withValues(alpha: isDarkMode ? 0.40 : 0.50),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.95],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1.5))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(12, 0.75),
      Offset(size.width - 12, 0.75),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GlassMirrorSheenPainter oldDelegate) =>
      oldDelegate.isDarkMode != isDarkMode ||
      oldDelegate.accentColor != accentColor;
}
