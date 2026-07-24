import 'package:flutter/material.dart';

/// Screen Breakpoints for the application
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

/// Helper extension on [BuildContext] for responsive layout checks and values
extension ResponsiveContext on BuildContext {
  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// True if current screen is mobile (< 600px)
  bool get isMobile => screenWidth < AppBreakpoints.mobile;

  /// True if current screen is tablet (600px - 1024px)
  bool get isTablet =>
      screenWidth >= AppBreakpoints.mobile && screenWidth < AppBreakpoints.tablet;

  /// True if current screen is desktop/wide (> 1024px)
  bool get isDesktop => screenWidth >= AppBreakpoints.tablet;

  /// Return value based on current breakpoint
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Calculates responsive cross axis count for grid views
  int gridCrossAxisCount({
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    if (screenWidth < 360) return 1;
    return mobile;
  }
}

/// A wrapper widget that centers content and limits max width on desktop/tablet views
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    super.key,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Widget that builds different UI depending on screen size
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
