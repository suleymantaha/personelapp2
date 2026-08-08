import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';
import 'package:personelapp2/features/temgundrap/presentation/temgundrap_screen.dart';
import 'package:personelapp2/features/auth/presentation/login_screen.dart';
import 'package:personelapp2/features/personnel/presentation/widgets/personnel_form_dialog.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget screen, {double textScale = 1.0}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      ),
    );
  }

  Future<void> setSurfaceSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Responsive Layout & Overflow Prevention Tests', () {
    const viewports = [
      Size(360, 800),   // Mobile Portrait
      Size(800, 360),   // Mobile Landscape
      Size(768, 1024),  // Tablet Portrait
      Size(1440, 900),  // Desktop Wide
    ];

    for (final size in viewports) {
      testWidgets('DashboardScreen has zero layout overflow on viewport ${size.width}x${size.height}', (WidgetTester tester) async {
        await setSurfaceSize(tester, size);
        await tester.pumpWidget(buildTestableWidget(const DashboardScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byType(DashboardScreen), findsOneWidget);
        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 200));
      });

      testWidgets('PersonnelManagementScreen has zero layout overflow on viewport ${size.width}x${size.height}', (WidgetTester tester) async {
        await setSurfaceSize(tester, size);
        await tester.pumpWidget(buildTestableWidget(const PersonnelManagementScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byType(PersonnelManagementScreen), findsOneWidget);
        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 200));
      });

      testWidgets('TemgundrapScreen has zero layout overflow on viewport ${size.width}x${size.height}', (WidgetTester tester) async {
        await setSurfaceSize(tester, size);
        await tester.pumpWidget(buildTestableWidget(const TemgundrapScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byType(TemgundrapScreen), findsOneWidget);
        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 200));
      });

      testWidgets('LoginScreen has zero layout overflow on viewport ${size.width}x${size.height}', (WidgetTester tester) async {
        await setSurfaceSize(tester, size);
        await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 200));
      });
    }

    testWidgets('PersonnelFormDialog renders cleanly with 1.5x large text scaling without overflow', (WidgetTester tester) async {
      await setSurfaceSize(tester, const Size(360, 800));
      await tester.pumpWidget(buildTestableWidget(const PersonnelFormDialog(), textScale: 1.5));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.byType(PersonnelFormDialog), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
