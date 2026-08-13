import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_archive_action.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_menu_card.dart';

void main() {
  Future<void> pumpDashboard(
    WidgetTester tester,
    UserSessionState session,
  ) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/personnel-management',
          builder: (context, state) =>
              const Scaffold(body: Text('Personel yönetimi hedefi')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionProvider.overrideWith((ref) => session),
          pendingAssignmentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  testWidgets('admin sees OCR import instead of pending approvals grid action',
      (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      const UserSessionState(username: 'admin', role: UserRole.admin),
    );

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(DashboardMenuCard), findsNWidgets(6));
    expect(find.byType(DashboardArchiveAction), findsOneWidget);
    expect(find.text('Metinden Toplu Aktar'), findsOneWidget);
    expect(find.text('Görselden Toplu Aktar'), findsOneWidget);
    expect(find.text('Bekleyen Onaylar'), findsNothing);
  });

  testWidgets('non-admin sees four grid actions and a separate archive action',
      (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      const UserSessionState(username: 'tim', role: UserRole.teamCommander),
    );

    expect(find.byType(DashboardMenuCard), findsNWidgets(4));
    expect(find.byType(DashboardArchiveAction), findsOneWidget);
    expect(find.text('Metinden Toplu Aktar'), findsNothing);
    expect(find.text('Bekleyen Onaylar'), findsNothing);
    expect(find.text('Kadro Durumu'), findsOneWidget);
  });

  testWidgets('dashboard keeps one personnel and squad entry point', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await pumpDashboard(
      tester,
      const UserSessionState(username: 'admin', role: UserRole.admin),
    );

    for (final size in <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(600, 960),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Taşma oluştu: $size');
    }

    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();

    expect(find.text('Personel & Tim'), findsOneWidget);
    expect(find.text('Kayıt ve Yetki'), findsOneWidget);
    expect(find.text('Yeni Tim Ekle'), findsNothing);
    expect(find.text('Tim & Komutan Ekle'), findsNothing);

    await tester.tap(find.text('Personel & Tim'));
    await tester.pumpAndSettle();

    expect(find.text('Personel yönetimi hedefi'), findsOneWidget);
  });

  testWidgets('dashboard handles textScaleFactor 1.3 without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await pumpDashboard(
      tester,
      const UserSessionState(username: 'admin', role: UserRole.admin),
    );

    for (final size in <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
      const Size(600, 960),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'Taşma oluştu: $size at 1.3 text scale');
    }
  });
}
