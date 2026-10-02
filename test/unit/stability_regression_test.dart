import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';

void main() {
  late AppDatabase db;
  late PersonnelRepository people;
  late ActivityRepository activities;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    people = PersonnelRepository(db);
    activities = ActivityRepository(db);
  });
  tearDown(() => db.close());

  Future<int> team(String name) =>
      people.addSquad(timAdi: name, olusturmaTarihi: '2026-01-01');
  Future<int> commander(String name, int squad) async {
    final id = await db
        .into(db.kullaniciTable)
        .insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: name,
            rol: 'tim_komutani',
            timId: Value(squad),
          ),
        );
    await people.assignCommanderToSquad(userId: id, timId: squad);
    return id;
  }

  test(
    'archive default includes records older than the last hundred',
    () async {
      await db.batch(
        (b) => b.insertAll(db.gunlukFaaliyetTable, [
          for (var i = 0; i < 150; i++)
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Faaliyet $i',
              tarih: i == 0 ? '2025-01-01' : '2026-10-02',
              olusturanKullanici: 'admin',
              olusturmaTarihi: '2026-01-01',
            ),
        ]),
      );
      final all = await activities.watchAllActivities().first;
      expect(all, hasLength(150));
      expect(all.any((a) => a.tarih == '2025-01-01'), isTrue);
      expect(
        await activities.watchAllActivities(limit: 10).first,
        hasLength(10),
      );
      expect(
        await activities
            .watchAllActivities(startDate: '2025-01-01', endDate: '2025-01-01')
            .first,
        hasLength(1),
      );
    },
  );

  test('commander handover revokes the previous account team', () async {
    final squad = await team('1-B');
    final first = await commander('first', squad);
    final second = await commander('second', squad);
    final users = await db.select(db.kullaniciTable).get();
    expect(users.singleWhere((u) => u.id == first).timId, isNull);
    expect(users.singleWhere((u) => u.id == second).timId, squad);
    expect((await db.select(db.timTable).get()).single.timKomutaniId, second);
  });

  test('moving a commander clears the old squad link', () async {
    final oldTeam = await team('1-B');
    final newTeam = await team('2-B');
    final user = await commander('moving', oldTeam);
    await people.assignCommanderToSquad(userId: user, timId: newTeam);
    final squads = await db.select(db.timTable).get();
    expect(squads.singleWhere((s) => s.id == oldTeam).timKomutaniId, isNull);
    expect(squads.singleWhere((s) => s.id == newTeam).timKomutaniId, user);
  });

  test(
    'a session opened before handover cannot assign the old squad',
    () async {
      final squad = await team('1-B');
      await commander('old', squad);
      final person = await people.addPersonnel(
        adSoyad: 'Ali KAYA',
        rutbe: 'J.Er',
        birlik: '1/B',
        kayitTarihi: '2026-01-01',
        timId: squad,
      );
      final staleSession = UserSessionState(
        username: 'old',
        role: UserRole.teamCommander,
        timId: squad,
      );
      await commander('new', squad);
      await expectLater(
        activities.createActivityWithAssignments(
          faaliyetAdi: 'Heybet',
          tarih: '2026-10-02',
          olusturanKullanici: 'old',
          personnelAssignments: [
            PersonnelAssignmentInput(personnelId: person, duty: 'HEYBET'),
          ],
          actor: staleSession,
        ),
        throwsA(isA<AuthorizationException>()),
      );
      expect(await db.select(db.gunlukFaaliyetTable).get(), isEmpty);
    },
  );
}
