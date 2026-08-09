import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class TurkishFlagWatermarkBackground extends StatefulWidget {
  const TurkishFlagWatermarkBackground({
    required this.child,
    this.opacityMultiplier = 1.0,
    this.enableBreathing = true,
    super.key,
  });

  final Widget child;
  final double opacityMultiplier;
  final bool enableBreathing;

  @override
  State<TurkishFlagWatermarkBackground> createState() =>
      _TurkishFlagWatermarkBackgroundState();
}

class _TurkishFlagWatermarkBackgroundState
    extends State<TurkishFlagWatermarkBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  bool get _isTestEnvironment {
    final binding = WidgetsBinding.instance.runtimeType.toString();
    return binding.contains('Test') || binding.contains('Automated');
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.enableBreathing && !_isTestEnvironment) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              final pulseFactor = (widget.enableBreathing && !_isTestEnvironment)
                  ? 0.75 + (_pulseAnimation.value * 0.50)
                  : 1.0;
              return CustomPaint(
                painter: _TurkishFlagBackgroundPainter(
                  isDarkMode: context.isDarkMode,
                  opacityMultiplier: widget.opacityMultiplier * pulseFactor,
                ),
              );
            },
          ),
        ),
        widget.child,
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
    final emblemScale = math.min(size.width, size.height) * 0.36;
    final flagX = size.width * 0.46;
    final flagY = size.height * 0.44;

    final baseAlpha = isDarkMode ? 0.095 : 0.065;
    final alpha = (baseAlpha * opacityMultiplier).clamp(0.0, 1.0);

    final flagPaint = Paint()
      ..color = (isDarkMode ? const Color(0xFFE53935) : const Color(0xFFD32F2F))
          .withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final flagGlowPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: alpha * 0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, emblemScale * 0.4);

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
