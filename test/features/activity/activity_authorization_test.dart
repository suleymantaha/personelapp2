import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

void main() {
  late AppDatabase database;
  late ActivityRepository repository;
  late int assignmentId;
  late int activityId;
  late int personId;

  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  const commander = UserSessionState(
    username: 'komutan',
    role: UserRole.teamCommander,
    timId: 1,
  );

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(database);
    await database
        .into(database.timTable)
        .insert(
          TimTableCompanion.insert(
            timAdi: 'Komutan Takımı',
            olusturmaTarihi: '2026-07-28',
          ),
        );
    await database
        .into(database.timTable)
        .insert(
          TimTableCompanion.insert(
            timAdi: 'Diğer Takım',
            olusturmaTarihi: '2026-07-28',
          ),
        );
    personId = await database
        .into(database.personelTable)
        .insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Yetki Testi',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            timId: const Value(2),
            kayitTarihi: '2026-07-28',
          ),
        );
    activityId = await database
        .into(database.gunlukFaaliyetTable)
        .insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Yetki',
            tarih: '2026-07-28',
            olusturanKullanici: 'komutan',
            olusturmaTarihi: '2026-07-28T00:00:00',
          ),
        );
    assignmentId = await database
        .into(database.faaliyetPersonelAtamaTable)
        .insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activityId,
            personelId: personId,
            gorevVeyaIzin: 'GÖREVLİ',
            durum: AssignmentStatus.beklemede,
          ),
        );
  });

  tearDown(() => database.close());

  test('commander cannot approve or delete assignments', () async {
    await expectLater(
      Future<ApprovalResult>.sync(
        () => repository.approveAssignment(assignmentId, actor: commander),
      ),
      throwsA(isA<AuthorizationException>()),
    );
    expect(
      () => repository.deleteAssignment(assignmentId, actor: commander),
      throwsA(isA<AuthorizationException>()),
    );

    final row = await (database.select(
      database.faaliyetPersonelAtamaTable,
    )..where((table) => table.id.equals(assignmentId))).getSingle();
    expect(row.durum, AssignmentStatus.beklemede);
  });

  test('admin can approve and delete assignments', () async {
    final approval = await repository.approveAssignment(
      assignmentId,
      actor: admin,
    );
    final deleted = await repository.deleteAssignment(
      assignmentId,
      actor: admin,
    );

    expect(approval.approvedCount, 1);
    expect(deleted, 1);
  });

  test('commander cannot create assignments for another team', () async {
    await expectLater(
      repository.createActivityWithAssignments(
        faaliyetAdi: 'Yetkisiz faaliyet',
        tarih: '2026-07-29',
        olusturanKullanici: commander.username,
        personnelAssignments: [
          PersonnelAssignmentInput(personnelId: personId, duty: 'GÖREVLİ'),
        ],
        actor: commander,
      ),
      throwsA(isA<AuthorizationException>()),
    );
    expect(
      await database.select(database.gunlukFaaliyetTable).get(),
      hasLength(1),
    );
  });

  test('bulk activity import is admin only', () async {
    await expectLater(
      repository.createActivitiesWithAssignments(const [], actor: commander),
      throwsA(isA<AuthorizationException>()),
    );
  });

  test(
    'admin can rename an activity and surrounding whitespace is removed',
    () async {
      final updated = await repository.renameActivity(
        activityId: activityId,
        newName: '  Gece Nöbeti  ',
        actor: admin,
      );

      expect(updated, 1);
      final activity = await (database.select(
        database.gunlukFaaliyetTable,
      )..where((table) => table.id.equals(activityId))).getSingle();
      expect(activity.faaliyetAdi, 'Gece Nöbeti');
    },
  );

  test('commander cannot rename an activity', () async {
    await expectLater(
      repository.renameActivity(
        activityId: activityId,
        newName: 'Yetkisiz Ad',
        actor: commander,
      ),
      throwsA(isA<AuthorizationException>()),
    );
  });

  test('activity name cannot be blank', () async {
    await expectLater(
      repository.renameActivity(
        activityId: activityId,
        newName: '   ',
        actor: admin,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
