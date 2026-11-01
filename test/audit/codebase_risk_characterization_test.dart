import 'package:drift/drift.dart' show Value, ApplyInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/audit_backup_interceptor.dart';

/// These tests prove CURRENT defects, not the desired security contract.
/// A future fix must invert the affected assertions and update the audit report.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late AuditBackupInterceptor interceptor;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    interceptor = AuditBackupInterceptor();
    db = AppDatabase(NativeDatabase.memory().interceptWith(interceptor));
  });
  tearDown(() => db.close());

  test('AUDIT F01: new squad commander has no resolvable team', () async {
    final repository = PersonnelRepository(db);
    final team = await repository.addSquadWithCommander(
        timAdi: 'AUDIT',
        olusturmaTarihi: '2026-11-01',
        komutanKullaniciAdi: 'audit');
    final user = await db.select(db.kullaniciTable).getSingle();
    expect((await db.select(db.timTable).getSingle()).id, team);
    expect(user.timId, isNull, reason: 'Observed defect: missing reverse link');
    expect(await repository.currentCommanderTeam('audit'), isNull);
  });

  test('AUDIT F02: demoted admin session still approves assignment', () async {
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'audit', rol: 'tim_komutani'));
    final person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'AUDIT',
            rutbe: 'Er',
            birlik: '',
            kayitTarihi: '2026-11-01'));
    final activity = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'AUDIT',
            tarih: '2026-11-01',
            olusturanKullanici: 'audit',
            olusturmaTarihi: '2026-11-01'));
    final assignment = await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activity,
            personelId: person,
            gorevVeyaIzin: 'GÖREVLİ',
            durum: 'beklemede'));
    await ActivityRepository(db).approveAssignment(assignment,
        actor: const UserSessionState(username: 'audit', role: UserRole.admin));
    expect((await db.select(db.faaliyetPersonelAtamaTable).getSingle()).durum,
        'onaylandi',
        reason: 'Observed defect: stale role accepted');
  });

  test('AUDIT F03: concurrent table write creates a rejected backup', () async {
    await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
        id: const Value(1),
        adSoyad: 'AUDIT',
        rutbe: 'Er',
        birlik: '',
        kayitTarihi: '2026-11-01'));
    final service = AppBackupService(db);
    final stable = await service.exportBackupJson();
    await service.inspectBackupJson(stable);
    interceptor.armed = true;
    final raced = await service.exportBackupJson();
    expect(interceptor.armed, isFalse,
        reason: 'Writer hook must have executed');
    expect(await db.select(db.gunlukFaaliyetTable).get(), hasLength(1));
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
    await expectLater(
        service.inspectBackupJson(raced),
        throwsA(isA<FormatException>().having((error) => error.message,
            'reference validation', contains('Faaliyet-atama bağlantısı'))));
  });

  test('AUDIT F04: password reset does not invalidate saved session', () async {
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', sifre: const Value('123456'), rol: 'yönetici'));
    SharedPreferences.setMockInitialValues({'session_username': 'admin'});
    await db.ensureSeeded();
    final admin = await (db.select(db.kullaniciTable)
          ..where((row) => row.kullaniciAdi.equals('admin')))
        .getSingle();
    expect(admin.sifre, isEmpty);
    expect((await SessionStorage.loadValidatedSession(db))?.isAdmin, isTrue,
        reason: 'Observed defect: password setup bypassed by saved session');
  });
}
