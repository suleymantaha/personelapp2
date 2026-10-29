import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/analytics/data/team_analytics_repository.dart';
import 'package:personelapp2/features/analytics/domain/monthly_analytics_report.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/services/monthly_analytics_excel_exporter.dart';
import 'package:personelapp2/features/analytics/presentation/monthly_analytics_view.dart';

void main() {
  late AppDatabase db;
  late int team, person;
  const pollutedDuty = '.Uzm.Çvş. Adı GEÇEN(Keskin Nişancı Timi)';
  const actor = UserSessionState(username: 'admin', role: UserRole.admin);
  final filter = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: '6-B Timi', olusturmaTarihi: '2026-01-01'));
    for (final name in ['Adı GEÇEN', 'Atanan PERSONEL']) {
      person = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: name,
              rutbe: 'J.Uzm.Çvş.',
              birlik: 'Test',
              timId: Value(team),
              kayitTarihi: '2026-01-01'));
    }
  });
  tearDown(() => db.close());

  Future<int> assign(
      {String duty = pollutedDuty,
      String activity = 'Heybet',
      bool unknownTeam = false}) async {
    final id = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: activity,
            tarih: '2026-10-06',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-10-06'));
    return db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: id,
            personelId: person,
            gorevVeyaIzin: duty,
            durum: 'onaylandi',
            gorevTimId: Value(unknownTeam ? null : team),
            gorevTimAdi: Value(unknownTeam ? null : '6-B Timi')));
  }

  Future<String> sourceSnapshot() async => jsonEncode({
        'assignments': (await db.select(db.faaliyetPersonelAtamaTable).get())
            .map((r) => r.toJson())
            .toList(),
        'activities': (await db.select(db.gunlukFaaliyetTable).get())
            .map((r) => r.toJson())
            .toList(),
        'people': (await db.select(db.personelTable).get())
            .map((r) => r.toJson())
            .toList(),
        'teams': (await db.select(db.timTable).get())
            .map((r) => r.toJson())
            .toList(),
        'history': (await db.select(db.timUyelikGecmisiTable).get())
            .map((r) => r.toJson())
            .toList(),
      });

  test(
      'personnel-line duty displays parent duty under stored team without writes',
      () async {
    final id = await assign();
    final before = await sourceSnapshot();
    final data = await TeamAnalyticsRepository(db).load(filter, actor);
    expect(data.entries.single.duty, 'HEYBET');
    expect(data.entries.single.personnelId, person);
    expect(data.entries.single.teamId, team);
    expect(data.entries.single.teamName, '6-B Timi');
    expect(data.teams.values, ['6-B Timi']);
    final report =
        MonthlyAnalyticsReport(data: data, asOf: DateTime(2026, 10, 29));
    expect(report.assignmentCount, 1);
    expect(report.duties.single.duty, 'HEYBET');
    expect(report.teams.single.duties, {'HEYBET': 1});
    expect(report.unclassifiedAssignments, 0);
    final book =
        Excel.decodeBytes(MonthlyAnalyticsExcelExporter.generate(report));
    expect(book['Görevler'].cell(CellIndex.indexByString('A2')).value,
        TextCellValue('HEYBET'));
    expect(book['Tim Matrisi'].cell(CellIndex.indexByString('A2')).value,
        TextCellValue('6-B Timi'));
    expect(await sourceSnapshot(), before);
    final original = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(original.id, id);
    expect(original.gorevVeyaIzin, pollutedDuty);
  });
  test('a valid task override is never replaced with activity title', () async {
    await assign(duty: 'HAZIR KITA');
    final data = await TeamAnalyticsRepository(db).load(filter, actor);
    expect(data.entries.single.duty, 'HAZIR KITA');
  });
  test('unrecognized activity cannot justify repairing a personnel-line duty',
      () async {
    await assign(activity: 'Günlük Faaliyet (2026-10-06)');
    final data = await TeamAnalyticsRepository(db).load(filter, actor);
    expect(data.entries.single.duty, pollutedDuty.toUpperCase());
  });
  test('unregistered personnel text and custom duties remain unclassified',
      () async {
    await assign(duty: '.Uzm.Çvş. Bilinmeyen KİŞİ(Keskin Timi)');
    final data = await TeamAnalyticsRepository(db).load(filter, actor);
    expect(data.entries.single.duty,
        '.Uzm.Çvş. Bilinmeyen KİŞİ(Keskin Timi)'.toUpperCase());
    final report =
        MonthlyAnalyticsReport(data: data, asOf: DateTime(2026, 10, 29));
    expect(report.unclassifiedAssignments, 1);
  });
  test('unknown historic team never falls back to current membership',
      () async {
    await assign(unknownTeam: true);
    final before = await sourceSnapshot();
    final data = await TeamAnalyticsRepository(db).load(filter, actor);
    expect(data.entries, isEmpty);
    expect(data.unknownEntries.single.duty, 'HEYBET');
    expect(data.unknownEntries.single.teamId, isNull);
    expect(await sourceSnapshot(), before);
  });
  testWidgets('monthly analysis shows corrected duty and stored own team',
      (tester) async {
    await assign();
    final data = await TeamAnalyticsRepository(db).load(filter, actor);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: MonthlyAnalyticsView(
                    data: data, asOf: DateTime(2026, 10, 29))))));
    expect(find.textContaining('HEYBET'), findsWidgets);
    expect(find.text('6-B Timi'), findsWidgets);
    expect(find.textContaining('ADI GEÇEN'), findsNothing);
    expect(find.textContaining('KESKIN NIŞANCI TIMI'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
