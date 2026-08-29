import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

double contrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('light theme uses the slate and emerald palette', () {
    final theme = AppTheme.militaryTheme;

    expect(theme.colorScheme.primary, const Color(0xFF0F766E));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF5F7FA));
    expect(theme.colorScheme.onSurface, const Color(0xFF0F172A));
    expect(
      contrastRatio(theme.colorScheme.onSurface, theme.colorScheme.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('dark theme uses deep slate surfaces and a bright emerald accent', () {
    final theme = AppTheme.darkMilitaryTheme;

    expect(theme.colorScheme.primary, const Color(0xFF5EEAD4));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0B1220));
    expect(theme.colorScheme.surface, const Color(0xFF111827));
    expect(
      contrastRatio(theme.colorScheme.onSurface, theme.colorScheme.surface),
      greaterThanOrEqualTo(4.5),
    );
  });
}
