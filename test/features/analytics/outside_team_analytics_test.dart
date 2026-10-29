import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/analytics/data/team_analytics_repository.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';

void main() {
  test('explicit outside task is not reported as missing historical team',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01'));
    final activity = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'HEYBET',
            tarih: '2001-01-02',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2001-01-02'));
    await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activity,
            personelId: person,
            gorevVeyaIzin: 'HEYBET',
            durum: 'onaylandi',
            gorevTimAdi: const Value('Tim dışı')));
    final result = await TeamAnalyticsRepository(db).load(
        AnalyticsFilter(start: '2001-01-01', end: '2001-01-31'),
        const UserSessionState(username: 'admin', role: UserRole.admin));
    expect(result.unknownTeamAssignments, 0);
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle())
            .gorevTimAdi,
        'Tim dışı');
  });
}
