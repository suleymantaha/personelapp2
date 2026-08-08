import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';

void main() {
  group('Responsive Breakpoint & Context Extensions Tests', () {
    testWidgets('screenWidth and isMobile/isTablet/isDesktop return accurate flags based on width', (WidgetTester tester) async {
      late bool isMobileVal;
      late bool isTabletVal;
      late bool isDesktopVal;

      Widget buildTestWidget(Size size) {
        return MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Builder(
              builder: (context) {
                isMobileVal = context.isMobile;
                isTabletVal = context.isTablet;
                isDesktopVal = context.isDesktop;
                return const Scaffold(body: Text('Responsive Test'));
              },
            ),
          ),
        );
      }

      // Mobile check (<600px)
      await tester.pumpWidget(buildTestWidget(const Size(400, 800)));
      expect(isMobileVal, isTrue);
      expect(isTabletVal, isFalse);
      expect(isDesktopVal, isFalse);

      // Tablet check (600px - 1024px)
      await tester.pumpWidget(buildTestWidget(const Size(800, 1000)));
      expect(isMobileVal, isFalse);
      expect(isTabletVal, isTrue);
      expect(isDesktopVal, isFalse);

      // Desktop check (>1024px)
      await tester.pumpWidget(buildTestWidget(const Size(1280, 900)));
      expect(isMobileVal, isFalse);
      expect(isTabletVal, isFalse);
      expect(isDesktopVal, isTrue);
    });
  });
}
