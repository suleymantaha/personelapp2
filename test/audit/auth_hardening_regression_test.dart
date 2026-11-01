import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/session_storage.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  const actor = UserSessionState(username: 'audit', role: UserRole.admin);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('F01 new and legacy commanders resolve and assign their own team',
      () async {
    final personnel = PersonnelRepository(db);
    final team = await personnel.addSquadWithCommander(
        timAdi: 'AUDIT',
        olusturmaTarihi: '2026-11-01',
        komutanKullaniciAdi: 'audit');
    var user = await db.select(db.kullaniciTable).getSingle();
    expect(user.timId, team);
    await personnel.updateUserPassword(
        kullaniciAdi: 'audit', newPassword: 'AuditPassword123!');
    for (final legacy in [false, true]) {
      if (legacy) {
        await (db.update(db.kullaniciTable)..where((u) => u.id.equals(user.id)))
            .write(const KullaniciTableCompanion(timId: Value(null)));
      }
      expect(await personnel.currentCommanderTeam('audit'), team);
      expect(await personnel.watchCommanderTeam('audit').first, team);
      SharedPreferences.setMockInitialValues({'session_username': 'audit'});
      final session = (await SessionStorage.loadValidatedSession(db))!;
      expect(session.timId, team);
      final person = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: 'AUDIT',
              rutbe: 'Er',
              birlik: '',
              timId: Value(team),
              kayitTarihi: '2026-11-01'));
      await ActivityRepository(db).createActivityWithAssignments(
          faaliyetAdi: 'AUDIT',
          tarih: '2099-11-01',
          olusturanKullanici: 'audit',
          personnelAssignments: [
            PersonnelAssignmentInput(personnelId: person, duty: 'GÖREVLİ')
          ],
          actor: session);
    }
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).get())
            .map((a) => a.durum),
        everyElement('beklemede'));
  });

  for (final state in ['demoted', 'deleted', 'forged']) {
    test('F02 $state admin cannot mutate through stale actor', () async {
      final id = await db.into(db.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
              kullaniciAdi: 'audit',
              rol: state == 'forged' ? 'tim_komutani' : 'yönetici'));
      final person = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: 'AUDIT',
              rutbe: 'Er',
              birlik: '',
              kayitTarihi: '2026-11-01'));
      final activity = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'AUDIT',
              tarih: '2099-11-01',
              olusturanKullanici: 'audit',
              olusturmaTarihi: '2026-11-01'));
      final assignment = await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activity,
              personelId: person,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: 'beklemede'));
      if (state == 'deleted') {
        await (db.delete(db.kullaniciTable)..where((u) => u.id.equals(id)))
            .go();
      } else {
        await (db.update(db.kullaniciTable)..where((u) => u.id.equals(id)))
            .write(const KullaniciTableCompanion(rol: Value('tim_komutani')));
      }
      final repository = ActivityRepository(db);
      final operations = <Future<Object?> Function()>[
        () => repository.approveAssignment(assignment, actor: actor),
        () =>
            repository.approveAllAssignmentsForActivity(activity, actor: actor),
        () =>
            repository.rejectAllAssignmentsForActivity(activity, actor: actor),
        () => repository.updateAssignmentStatus(assignment, 'reddedildi',
            actor: actor),
        () => repository.renameActivity(
            activityId: activity, newName: 'OTHER', actor: actor),
        () => repository.changeActivityDate(
            activityId: activity, newDate: '2099-11-02', actor: actor),
        () => repository.updateAssignmentDetails(
            assignmentId: assignment,
            gorevVeyaIzin: 'GÖREVLİ',
            newStatus: 'reddedildi',
            actor: actor),
        () => repository.createActivityWithAssignments(
            faaliyetAdi: 'OTHER',
            tarih: '2099-11-02',
            olusturanKullanici: 'audit',
            personnelAssignments: [],
            actor: actor),
      ];
      for (final operation in operations) {
        await expectLater(
            Future.sync(operation), throwsA(isA<AuthorizationException>()));
      }
      expect((await db.select(db.faaliyetPersonelAtamaTable).getSingle()).durum,
          'beklemede');
      expect((await db.select(db.gunlukFaaliyetTable).getSingle()).faaliyetAdi,
          'AUDIT');
    });
  }

  test('F04 legacy password reset clears saved session until password setup',
      () async {
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', sifre: const Value('123456'), rol: 'yönetici'));
    SharedPreferences.setMockInitialValues({'session_username': 'admin'});
    await db.ensureSeeded();
    expect(await SessionStorage.loadValidatedSession(db), isNull);
    expect(
        (await SharedPreferences.getInstance()).getString('session_username'),
        isNull);
    await PersonnelRepository(db).updateUserPassword(
        kullaniciAdi: 'admin', newPassword: 'AuditPassword123!');
    await SessionStorage.saveSession(
        const UserSessionState(username: 'admin', role: UserRole.admin));
    expect((await SessionStorage.loadValidatedSession(db))?.isAdmin, isTrue);
  });
}
