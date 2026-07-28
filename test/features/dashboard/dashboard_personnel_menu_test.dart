import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('dashboard keeps one personnel and squad entry point', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          userSessionProvider.overrideWith(
            (ref) => const UserSessionState(
              username: 'admin',
              role: UserRole.admin,
            ),
          ),
          pendingAssignmentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Personel & Tim'), findsOneWidget);
    expect(find.text('Kayıt ve Yetki'), findsOneWidget);
    expect(find.text('Yeni Tim Ekle'), findsNothing);
    expect(find.text('Tim & Komutan Ekle'), findsNothing);

    await tester.tap(find.text('Personel & Tim'));
    await tester.pumpAndSettle();

    expect(find.text('Personel yönetimi hedefi'), findsOneWidget);
  });
}
