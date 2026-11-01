import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/staged_bulk_import.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';

void main() {
  late AppDatabase db;
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  late int team;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    team = await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: '6-B', olusturmaTarihi: '2026-01-01'));
  });
  tearDown(() => db.close());
  List<ParsedActivityBlock> blocks() => [
        ParsedActivityBlock(
            rawTitle: '',
            parsedTimName: '6-B',
            parsedActivityType: 'HEYBET',
            parsedDate: '2026-11-01',
            personnelList: [
              ParsedPersonnelItem(
                  rawIndex: 1,
                  rawRank: 'J.Uzm.Çvş.',
                  rawName: 'Yeni KİŞİ',
                  matchedPersonnelId: -1)
            ])
      ];
  StagedBulkImport draft() => StagedBulkImport()
    ..people[-1] = PersonelTableCompanion.insert(
        adSoyad: 'Yeni KİŞİ',
        rutbe: 'J.Uzm.Çvş.',
        birlik: '6-B',
        timId: Value(team),
        kayitTarihi: '2026-11-01');

  test('admin draft persists IDs and membership history only on Save',
      () async {
    final staged = draft();
    expect(await db.select(db.personelTable).get(), isEmpty);
    final ids = await db.transaction(() => staged.persist(db, admin, blocks()));
    expect(ids[-1], greaterThan(0));
    expect((await db.select(db.timUyelikGecmisiTable).get()).single.personelId,
        ids[-1]);
    expect(
        StagedBulkImport.remapBlocks(blocks(), ids)
            .single
            .personnelList
            .single
            .matchedPersonnelId,
        ids[-1]);
  });
  test('actorless and revoked admin cannot persist staged people', () async {
    await expectLater(
        StagedBulkImport.requireActor(db, null), throwsStateError);
    await (db.update(db.kullaniciTable)
          ..where((u) => u.kullaniciAdi.equals('admin')))
        .write(const KullaniciTableCompanion(rol: Value('tim_komutani')));
    await expectLater(draft().persist(db, admin, blocks()), throwsStateError);
    expect(await db.select(db.personelTable).get(), isEmpty);
  });
  test('metadata failure rolls back personnel history and committed assignment',
      () async {
    await expectLater(db.transaction(() async {
      final ids = await draft().persist(db, admin, blocks());
      await ActivityRepository(db).createActivitiesWithAssignments([
        ActivityCreateRequest(
            faaliyetAdi: 'HEYBET',
            tarih: '2026-11-01',
            olusturanKullanici: 'admin',
            personnelAssignments: [
              PersonnelAssignmentInput(
                  personnelId: ids[-1]!, duty: 'HEYBET', teamId: team)
            ])
      ], actor: admin);
      await db
          .customStatement('INSERT INTO missing_import_metadata VALUES (1)');
    }), throwsA(isA<Exception>()));
    expect(await db.select(db.personelTable).get(), isEmpty);
    expect(await db.select(db.timUyelikGecmisiTable).get(), isEmpty);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
    expect(await db.select(db.gunlukFaaliyetTable).get(), isEmpty);
  });
  test('commander authority is current and cannot create people', () async {
    final id = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'cmd', rol: 'tim_komutani'));
    await PersonnelRepository(db)
        .assignCommanderToSquad(userId: id, timId: team);
    final actor = UserSessionState(
        username: 'cmd', role: UserRole.teamCommander, timId: team);
    expect(await StagedBulkImport.authorizedTeam(db, actor), team);
    await StagedBulkImport.requireActor(db, actor);
    await expectLater(draft().persist(db, actor, blocks()), throwsStateError);
    await PersonnelRepository(db)
        .assignCommanderToSquad(userId: id, timId: null);
    expect(await StagedBulkImport.authorizedTeam(db, actor), isNull);
    await expectLater(
        StagedBulkImport.requireActor(db, actor), throwsStateError);
  });
}
