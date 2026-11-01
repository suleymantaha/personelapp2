import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> _rows(AppDatabase db) async {
  final rows = <String, Object?>{};
  for (final table in db.allTables) {
    rows[table.actualTableName] = (await db
            .customSelect(
                'SELECT * FROM "${table.actualTableName}" ORDER BY rowid')
            .get())
        .map((row) => row.data)
        .toList();
  }
  return jsonEncode(rows);
}

/// Route smoke coverage, not an end-to-end login or real export handoff test.
Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final authenticated in [false, true]) {
      testWidgets('audit routes ${mode.name} authenticated=$authenticated',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        final db = AppDatabase(NativeDatabase.memory());
        await db.ensureSeeded();
        final before = await _rows(db);
        final session = authenticated
            ? const UserSessionState(username: 'admin', role: UserRole.admin)
            : null;
        final router = createAppRouter(session: session);
        final container = ProviderContainer(overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((_) => session),
          themeModeProvider.overrideWith((_) => mode),
          appRouterProvider.overrideWithValue(router),
        ]);
        addTearDown(() async {
          container.dispose();
          router.dispose();
          await db.close();
        });
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container, child: const PersonelApp()));
        await tester.pumpAndSettle();
        await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
        final routes = authenticated
            ? [
                AppRoutes.dashboard,
                AppRoutes.personnelManagement,
                AppRoutes.activityForm,
                AppRoutes.pendingApprovals,
                AppRoutes.activityArchive,
                AppRoutes.teamAnalytics,
                AppRoutes.watchRoster,
                AppRoutes.monthlyMatrix,
                AppRoutes.temgundrap,
              ]
            : [AppRoutes.login];
        for (final route in routes) {
          router.go(route);
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, route);
          expect(tester.takeException(), isNull, reason: route);
          await binding
              .takeScreenshot('surface-${route.substring(1)}-${mode.name}');
          if (route == AppRoutes.dashboard) {
            await tester.tap(find.byIcon(Icons.settings));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await binding.takeScreenshot('surface-settings-${mode.name}');
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
          }
        }
        expect(await _rows(db), before,
            reason:
                'Route browsing must preserve all Drift application tables');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
