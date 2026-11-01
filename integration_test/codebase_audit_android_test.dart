import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';

import '../test/support/archive_flow_scenario.dart';
import '../test/audit/codebase_risk_characterization_test.dart' as risks;
import '../test/core/services/task_team_history_test.dart' as history;
import 'monthly_visual_android_test.dart' as monthly;

/// Audit-only entry point: synthetic memory databases, never the user's database.
Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  var converted = false;
  setUp(() => converted = false);
  Future<void> capture(String name, WidgetTester tester) async {
    if (!converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
      await tester.pumpAndSettle();
    }
    await binding.takeScreenshot(name);
  }

  archiveFlowScenario(onScreen: capture);
  monthly.main();

  for (final dark in [false, true]) {
    testWidgets('audit personnel search and cancel preserve rows (dark=$dark)',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      // Establish the normal seeded state before measuring read-only actions.
      await db.ensureSeeded();
      final team = (await db.select(db.timTable).get()).first.id;
      for (final name in ['SENTETİK ALİ', 'SENTETİK MEHMET']) {
        await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: 'Er',
            birlik: 'TEST',
            kayitTarihi: '2026-11-01',
            timId: Value(team)));
      }
      final before = await db.select(db.personelTable).get();
      final teamsBefore = await db.select(db.timTable).get();
      await tester.pumpWidget(ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userSessionProvider.overrideWith((_) => const UserSessionState(
                username: 'audit', role: UserRole.admin)),
          ],
          child: MaterialApp(
              theme: dark ? AppTheme.darkMilitaryTheme : AppTheme.militaryTheme,
              home: const PersonnelManagementScreen())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('team-header-$team')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'MEHMET');
      await tester.pumpAndSettle();
      expect(find.text('SENTETİK MEHMET'), findsOneWidget);
      expect(find.text('SENTETİK ALİ'), findsNothing);
      await capture('personnel-search-${dark ? 'dark' : 'light'}', tester);
      await tester.enterText(find.byType(TextField), 'NO_MATCH_AUDIT');
      await tester.pumpAndSettle();
      expect(find.text('SENTETİK MEHMET'), findsNothing);
      await capture('personnel-empty-${dark ? 'dark' : 'light'}', tester);
      await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-personnel-order')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('order-team-$team')));
      await tester.pumpAndSettle();
      final ali = before.firstWhere((row) => row.adSoyad == 'SENTETİK ALİ');
      final mehmet =
          before.firstWhere((row) => row.adSoyad == 'SENTETİK MEHMET');
      // Exercise the real accessible reorder action deterministically. This
      // does not claim verification of a physical drag or TalkBack dispatch.
      final row = tester
          .widget<Semantics>(find.byKey(ValueKey('order-person-${ali.id}')));
      row.properties.customSemanticsActions!.entries
          .singleWhere((entry) => entry.key.label == 'Aşağı taşı')
          .value();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text(mehmet.adSoyad)).dy,
          lessThan(tester.getTopLeft(find.text(ali.adSoyad)).dy));
      await capture('personnel-order-${dark ? 'dark' : 'light'}', tester);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(await db.select(db.personelTable).get(), before);
      expect(await db.select(db.timTable).get(), teamsBefore);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
  group('Android task team history', history.main);
  group('Android observed risks (not fixes)', risks.main);
}
