import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/analytics/data/team_analytics_repository.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'Android analytics reads SQLite and opens personnel without writes',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'TEST TİMİ', olusturmaTarihi: '2026-01-01'));
    final person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'SENTETİK PERSONEL',
            rutbe: 'Er',
            birlik: '',
            kayitTarihi: '2026-01-01'));
    final activity = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'TEST FAALİYETİ',
            tarih: '2026-10-02',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-10-02'));
    await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activity,
            personelId: person,
            gorevVeyaIzin: 'HEYBET',
            durum: 'onaylandi',
            gorevTimId: Value(team)));
    final before = await db.select(db.faaliyetPersonelAtamaTable).get();
    final filter = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');
    const admin = UserSessionState(username: 'admin', role: UserRole.admin);
    final result = await TeamAnalyticsRepository(db).load(filter, admin);
    expect(result.metrics.participations, 1);
    expect(result.metrics.personnelTasks, 1);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((ref) => admin)
        ],
        child: Consumer(
            builder: (context, ref, child) => MaterialApp(
                themeMode: ref.watch(themeModeProvider),
                theme: AppTheme.militaryTheme,
                darkTheme: AppTheme.darkMilitaryTheme,
                home: TeamAnalyticsScreen(initialFilter: filter)))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Temayı değiştir'));
    await tester.pumpAndSettle();
    expect(
        Theme.of(tester.element(find.byType(TeamAnalyticsScreen))).brightness,
        Brightness.dark);
    final tabDetails = find.byKey(const ValueKey('tab-details'));
    await tester.ensureVisible(tabDetails);
    await tester.tap(tabDetails);
    await tester.pumpAndSettle();
    for (final key in [
      'analytics-team-$team',
      'analytics-duty-$team-HEYBET',
      'analytics-date-$team-HEYBET-2026-10-02',
      'analytics-activity-$team-HEYBET-2026-10-02-$activity'
    ]) {
      final tile = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(tile, 200,
          scrollable: find.byType(Scrollable).first);
      final header =
          find.descendant(of: tile, matching: find.byType(ListTile)).first;

      await tester.ensureVisible(header);
      await tester.pumpAndSettle();
      await tester.tap(header);
      await tester.pumpAndSettle();
    }
    expect(find.text('SENTETİK PERSONEL'), findsOneWidget);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
  });
}
