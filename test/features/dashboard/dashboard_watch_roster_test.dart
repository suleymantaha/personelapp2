import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('NÖBET belongs inside analytics, not the dashboard',
      (tester) async {
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, state) => const DashboardScreen()),
      GoRoute(
          path: '/watch-roster',
          builder: (_, state) =>
              const Scaffold(body: Text('Aylık nöbet hedefi'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(overrides: [
      userSessionProvider.overrideWith((ref) =>
          const UserSessionState(username: 'test', role: UserRole.admin)),
      pendingAssignmentsProvider.overrideWith((ref) => Stream.value(const [])),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    expect(find.text('Tim Görev Analizi'), findsOneWidget);
    expect(find.text('Aylık Matris'), findsOneWidget);
    expect(find.text('NÖBET'), findsNothing);
  });
}
