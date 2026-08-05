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
  late int targetActivityId;
  late int ownTeamPersonId;
  late int otherTeamPersonId;
  late int conflictPersonId;

  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  const commander = UserSessionState(
    username: 'komutan',
    role: UserRole.teamCommander,
    timId: 1,
  );

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(database);
    for (final name in ['1. Tim', '2. Tim']) {
      await database.into(database.timTable).insert(
            TimTableCompanion.insert(
              timAdi: name,
              olusturmaTarihi: '2026-08-05',
            ),
          );
    }
    Future<int> addPerson(String name, int teamId) {
      return database.into(database.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: name,
              rutbe: 'J.Uzm.Çvş.',
              birlik: 'Asayiş',
              timId: Value(teamId),
              kayitTarihi: '2026-08-05',
            ),
          );
    }

    ownTeamPersonId = await addPerson('Birinci Personel', 1);
    otherTeamPersonId = await addPerson('İkinci Personel', 2);
    conflictPersonId = await addPerson('Çakışan Personel', 1);
    targetActivityId = await database.into(database.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Hedef Faaliyet',
            tarih: '2026-08-05',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-08-05T08:00:00',
          ),
        );
    final otherActivityId =
        await database.into(database.gunlukFaaliyetTable).insert(
              GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: 'Diğer Faaliyet',
                tarih: '2026-08-05',
                olusturanKullanici: 'admin',
                olusturmaTarihi: '2026-08-05T08:00:00',
              ),
            );
    await database.into(database.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: otherActivityId,
            personelId: conflictPersonId,
            gorevVeyaIzin: DutyOrLeaveType.gorevli,
            durum: AssignmentStatus.onaylandi,
          ),
        );
  });

  tearDown(() => database.close());

  test('adds valid rows and reports duplicates and conflicts', () async {
    final first = await repository.addAssignmentsToActivity(
      activityId: targetActivityId,
      assignments: [
        PersonnelAssignmentInput(
          personnelId: ownTeamPersonId,
          duty: DutyOrLeaveType.gorevli,
        ),
        PersonnelAssignmentInput(
          personnelId: conflictPersonId,
          duty: DutyOrLeaveType.gorevli,
        ),
      ],
      actor: admin,
    );
    final second = await repository.addAssignmentsToActivity(
      activityId: targetActivityId,
      assignments: [
        PersonnelAssignmentInput(
          personnelId: ownTeamPersonId,
          duty: DutyOrLeaveType.gorevli,
        ),
      ],
      actor: admin,
    );

    expect(first.addedCount, 1);
    expect(first.conflictSkippedCount, 1);
    expect(first.conflictDescriptions, hasLength(1));
    expect(second.alreadyAssignedCount, 1);
  });

  test('commander can add own team but not another team', () async {
    final result = await repository.addAssignmentsToActivity(
      activityId: targetActivityId,
      assignments: [
        PersonnelAssignmentInput(
          personnelId: ownTeamPersonId,
          duty: DutyOrLeaveType.gorevli,
        ),
      ],
      actor: commander,
    );
    expect(result.addedCount, 1);
    final row =
        await database.select(database.faaliyetPersonelAtamaTable).get();
    expect(
      row.singleWhere((item) => item.personelId == ownTeamPersonId).durum,
      AssignmentStatus.beklemede,
    );

    await expectLater(
      repository.addAssignmentsToActivity(
        activityId: targetActivityId,
        assignments: [
          PersonnelAssignmentInput(
            personnelId: otherTeamPersonId,
            duty: DutyOrLeaveType.gorevli,
          ),
        ],
        actor: commander,
      ),
      throwsA(isA<AuthorizationException>()),
    );
  });
}
