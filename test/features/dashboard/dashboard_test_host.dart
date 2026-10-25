import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/navigation/app_routes.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/dashboard/presentation/dashboard_screen.dart';
import 'package:personelapp2/l10n/generated/app_localizations.dart';

Future<void> pumpDashboard(
  WidgetTester tester, {
  bool admin = true,
  Size size = const Size(390, 844),
  double scale = 1,
  ThemeMode mode = ThemeMode.light,
  bool pending = false,
  AppDatabase? database,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = GoRouter(initialLocation: AppRoutes.dashboard, routes: [
    GoRoute(
        path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
    for (final path in [
      AppRoutes.activityForm,
      AppRoutes.personnelManagement,
      AppRoutes.monthlyMatrix,
      AppRoutes.teamAnalytics,
      AppRoutes.temgundrap,
      AppRoutes.activityArchive,
      AppRoutes.pendingApprovals
    ])
      GoRoute(
          path: path, builder: (_, __) => Scaffold(body: Text('target:$path'))),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
      overrides: [
        if (database != null) databaseProvider.overrideWithValue(database),
        userSessionProvider.overrideWith((ref) => UserSessionState(
            username: 'test',
            role: admin ? UserRole.admin : UserRole.teamCommander)),
        pendingAssignmentsProvider.overrideWith((ref) => Stream.value(pending
            ? [
                const FaaliyetPersonelAtamaTableData(
                    id: 1,
                    faaliyetId: 1,
                    personelId: 1,
                    gorevVeyaIzin: 'TEST',
                    durum: 'beklemede')
              ]
            : const [])),
      ],
      child: RepaintBoundary(
          key: const ValueKey('dashboard-capture'),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.militaryTheme,
            darkTheme: AppTheme.darkMilitaryTheme,
            themeMode: mode,
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ))));
  await tester.pumpAndSettle();
}
