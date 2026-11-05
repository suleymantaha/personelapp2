import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';
import 'package:personelapp2/features/matrix/presentation/monthly_matrix_screen.dart';
import 'package:personelapp2/main.dart' show PersonelApp;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  for (final toolbar in [false, true]) {
    for (final matrix in [false, true]) {
      testWidgets(
          '${toolbar ? 'toolbar' : 'system'} back closes ${matrix ? 'matrix' : 'personnel'} search first',
          (tester) async {
        await withApp(tester, (db, router) async {
          final route =
              matrix ? AppRoutes.monthlyMatrix : AppRoutes.personnelManagement;
          router.push<void>(route);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey(matrix
              ? 'matrix-mobile-search-button'
              : 'personnel-search-toggle')));
          await tester.pumpAndSettle();
          final field = find.byKey(ValueKey(
              matrix ? 'matrix-personnel-search' : 'personnel-search-field'));
          await tester.enterText(field, 'Synthetic');
          await tester.pumpAndSettle();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          if (toolbar) {
            await tester.tap(find.byType(BackButton));
          } else {
            await tester.binding.handlePopRoute();
          }
          await tester.pumpAndSettle();
          expect(
              find.byType(
                  matrix ? MonthlyMatrixScreen : PersonnelManagementScreen),
              findsOneWidget);
          expect(field, findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path,
              AppRoutes.dashboard);
          expect(
              find.byType(
                  matrix ? MonthlyMatrixScreen : PersonnelManagementScreen),
              findsNothing);
          expect(tester.takeException(), isNull);
        });
      });
    }
  }
  testWidgets(
      'back collapses most recently expanded personnel team before earlier team and page',
      (tester) async {
    await withApp(tester, (db, router) async {
      final first = await db.into(db.timTable).insert(
          TimTableCompanion.insert(timAdi: 'First team', olusturmaTarihi: ''));
      final second = await db.into(db.timTable).insert(
          TimTableCompanion.insert(timAdi: 'Second team', olusturmaTarihi: ''));
      router.push<void>(AppRoutes.personnelManagement);
      await tester.pumpAndSettle();
      final firstHeader = find.byKey(ValueKey('team-header-$first'));
      final secondHeader = find.byKey(ValueKey('team-header-$second'));
      await tester.tap(firstHeader);
      await tester.pumpAndSettle();
      await tester.tap(secondHeader);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PersonnelManagementScreen), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(ValueKey('team-card-$second')),
              matching: find.byIcon(Icons.expand_more)),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(ValueKey('team-card-$first')),
              matching: find.byIcon(Icons.expand_less)),
          findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(PersonnelManagementScreen), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(ValueKey('team-card-$first')),
              matching: find.byIcon(Icons.expand_more)),
          findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
          router.routeInformationProvider.value.uri.path, AppRoutes.dashboard);
      expect(find.byType(PersonnelManagementScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> withApp(WidgetTester tester,
    Future<void> Function(AppDatabase, GoRouter) body) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final db = AppDatabase(NativeDatabase.memory());
  const actor = UserSessionState(username: 'admin', role: UserRole.admin);
  final router = createAppRouter(session: actor);
  try {
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', rol: UserRole.admin.storageValue));
    await tester.pumpWidget(ProviderScope(overrides: [
      databaseProvider.overrideWithValue(db),
      userSessionProvider.overrideWith((ref) => actor),
      appRouterProvider.overrideWithValue(router)
    ], child: const PersonelApp()));
    await tester.pumpAndSettle();
    await body(db, router);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    router.dispose();
    await db.close();
  }
}
