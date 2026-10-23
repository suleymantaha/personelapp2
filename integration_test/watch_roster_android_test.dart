import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/analytics/data/team_analytics_repository.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/watch_roster/domain/watch_roster.dart';
import 'package:personelapp2/features/watch_roster/presentation/watch_roster_screen.dart';

// Dedicated nizam-nobet-test AVD only. Never target the user's emulator.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('independent monthly roster reads records without changing data',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    const admin = UserSessionState(username: 'test', role: UserRole.admin);
    final person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'ÖRNEK NÖBETÇİ',
            rutbe: 'Er',
            birlik: '',
            kayitTarihi: '2026-01-01'));
    Future<void> add(String date, String duty,
        {String status = 'onaylandi'}) async {
      final activity = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Örnek nöbet heyeti',
              tarih: date,
              olusturanKullanici: 'test',
              olusturmaTarihi: date));
      await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activity,
              personelId: person,
              gorevVeyaIzin: duty,
              durum: status,
              gorevTimId: const Value(null)));
    }

    for (final duty in watchDuties.keys) {
      await add('2026-10-01', duty);
    }
    await add('2026-09-30', 'MEBS NÖB.');
    await add('2026-10-01', 'MEBS NÖB.', status: 'beklemede');
    Future<List<Object?>> snapshot() async => [
          for (final table in db.allTables)
            await db
                .customSelect('SELECT * FROM "${table.actualTableName}"')
                .get()
                .then((rows) => rows.map((r) => r.data).toList()),
        ];
    final before = await snapshot();
    final data = await TeamAnalyticsRepository(db)
        .load(AnalyticsFilter(start: '2026-10-01', end: '2026-10-31'), admin);
    final roster = WatchRoster(data);
    expect(roster.records('2026-10-01', 'MEBS NÖB.'), hasLength(1));
    expect(roster.records('2026-10-02', 'MEBS NÖB.'), isEmpty);
    final router = createAppRouter(session: admin);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((ref) => admin),
          pendingAssignmentsProvider
              .overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp.router(
            routerConfig: router, theme: AppTheme.darkMilitaryTheme)));
    await tester.pumpAndSettle();
    expect(find.text('NÖBET'), findsNothing);
    await tester.tap(find.text('Tim Görev Analizi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NÖBET'));
    await tester.pumpAndSettle();
    expect(find.byType(WatchRosterScreen), findsOneWidget);
    // Select the fixture month through the actual month picker, independent of device date.
    await tester.tap(find.byKey(const ValueKey('watch-select-month')));
    await tester.pumpAndSettle();
    final currentYear = DateTime.now().year;
    for (var y = currentYear; y != 2026; y += y < 2026 ? 1 : -1) {
      await tester.tap(find.byTooltip(y < 2026 ? 'Sonraki yıl' : 'Önceki yıl'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ekim').last);
    await tester.tap(find.text('Ekim').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seç'));
    await tester.pumpAndSettle();
    expect(find.text('Ekim 2026'), findsOneWidget);
    expect(find.text('ÖRNEK NÖBETÇİ'), findsNothing);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('watch-day-2026-10-31')), findsOneWidget);
    await binding.takeScreenshot('watch-calendar-month');
    await tester.tap(find.byKey(const ValueKey('watch-day-2026-10-01')));
    await tester.pumpAndSettle();
    expect(find.text('ÖRNEK NÖBETÇİ'), findsWidgets);
    expect(find.text('Timi bilinmiyor'), findsWidgets);
    await binding.takeScreenshot('watch-calendar-personnel');
    await tester.tap(find.byKey(const ValueKey('watch-day-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('watch-day-2026-10-02')));
    await tester.pumpAndSettle();
    expect(find.text('ÖRNEK NÖBETÇİ'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('watch-day-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('watch-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('Kasım 2026'), findsOneWidget);
    expect(find.text('ÖRNEK NÖBETÇİ'), findsNothing);
    expect(await snapshot(), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    router.dispose();
    await db.close();
  });
}
