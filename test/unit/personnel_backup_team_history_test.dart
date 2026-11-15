import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:personelapp2/core/services/task_team_history.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/features/personnel/services/personnel_backup_service.dart';

import '../features/activity/activity_date_team_test_support.dart';

void main() {
  Future<DateTeamFixture> openTarget() async {
    final target = DateTeamFixture();
    addTearDown(target.db.close);
    await target.initialize();
    return target;
  }

  final legacyBackup = {
    'version': 1,
    'exportedAt': '2020-02-15T10:00:00',
    'squads': [
      {'id': 9, 'timAdi': 'Other team', 'olusturmaTarihi': '2000-01-01'},
    ],
    'personnel': [
      {
        'id': 42,
        'adSoyad': 'Imported test person',
        'rutbe': 'Er',
        'timId': 9,
        'kayitTarihi': '2020-01-01',
      },
    ],
  };

  test('restored team changes determine the saved activity team by date',
      () async {
    final source = AppDatabase(NativeDatabase.memory());
    final String backup;
    try {
      final personnel = PersonnelRepository(source);
      final first = await personnel.addSquad(
          timAdi: 'Other team', olusturmaTarihi: '2000-01-01');
      final second = await personnel.addSquad(
          timAdi: 'Saved team', olusturmaTarihi: '2000-01-01');
      await personnel.addPersonnel(
          adSoyad: 'Imported test person',
          rutbe: 'Er',
          birlik: 'Test',
          kayitTarihi: '2020-01-01',
          timId: first);
      final original = await source.select(source.personelTable).getSingle();
      await personnel.updatePersonnel(original.copyWith(timId: Value(second)),
          tarih: '2020-03-01');

      backup = await PersonnelBackupService(source).exportBackupJson();
    } finally {
      await source.close();
    }
    final target = await openTarget();
    final service = PersonnelBackupService(target.db);
    expect(await service.importBackupJson(backup), 1);
    expect(await service.importBackupJson(backup), 0);
    final imported = await (target.db.select(target.db.personelTable)
          ..where((p) => p.adSoyad.equals('Imported test person')))
        .getSingle();
    expect(imported.timId, target.team);
    for (final entry in {
      '2020-02-01': target.otherTeam,
      '2020-03-01': target.team,
    }.entries) {
      final activity =
          await target.db.into(target.db.gunlukFaaliyetTable).insert(
                GunlukFaaliyetTableCompanion.insert(
                  faaliyetAdi: 'Historical test',
                  tarih: entry.key,
                  olusturanKullanici: 'admin',
                  olusturmaTarihi: '2020-03-02',
                ),
              );
      final result = await target.repo.addAssignmentsToActivity(
        activityId: activity,
        expectedDate: entry.key,
        actor: dateChangeAdmin,
        assignments: [
          PersonnelAssignmentInput(
              personnelId: imported.id, duty: 'G\u00d6REVL\u0130'),
        ],
      );
      expect(result.addedCount, 1);
      final assignment =
          await (target.db.select(target.db.faaliyetPersonelAtamaTable)
                ..where((a) => a.faaliyetId.equals(activity)))
              .getSingle();
      expect(assignment.gorevTimId, entry.value);
    }
    expect(await target.db.select(target.db.timUyelikGecmisiTable).get(),
        hasLength(2));
  });

  test('legacy JSON establishes a baseline from its snapshot date', () async {
    final target = await openTarget();
    final restored = await AppBackupService(target.db)
        .restoreBackupJson(jsonEncode(legacyBackup));
    expect(restored.importedPersonnel, 1);
    final imported = await (target.db.select(target.db.personelTable)
          ..where((p) => p.adSoyad.equals('Imported test person')))
        .getSingle();
    final history = TaskTeamHistory(target.db);
    expect(await history.resolve(imported.id, '2020-02-14'), isNull);
    expect((await history.resolve(imported.id, '2020-02-15'))?.teamId,
        target.otherTeam);
    await PersonnelRepository(target.db).updatePersonnel(
        imported.copyWith(timId: Value(target.team)),
        tarih: '2020-03-01');
    expect((await history.resolve(imported.id, '2020-02-28'))?.teamId,
        target.otherTeam);
    expect((await history.resolve(imported.id, '2020-03-01'))?.teamId,
        target.team);
  });

  test('unknown history squad rolls the import back', () async {
    final target = await openTarget();
    final backup = {
      ...legacyBackup,
      'membershipHistory': [
        {
          'personelId': 42,
          'timId': 999,
          'tarih': '2020-01-01',
          'islem': 'eklendi'
        },
      ],
    };
    await expectLater(
      PersonnelBackupService(target.db).importBackupJson(jsonEncode(backup)),
      throwsA(isA<FormatException>()),
    );
    expect(await target.db.select(target.db.personelTable).get(), hasLength(1));
    expect(
        await target.db.select(target.db.timUyelikGecmisiTable).get(), isEmpty);
  });

  test('reimport fills an earlier gap for an already imported person',
      () async {
    final target = await openTarget();
    final id = await target.db.into(target.db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Imported test person',
            rutbe: 'Er',
            birlik: 'Test',
            timId: Value(target.team),
            kayitTarihi: '2020-01-01',
          ),
        );
    await target.db.into(target.db.timUyelikGecmisiTable).insert(
          TimUyelikGecmisiTableCompanion.insert(
            personelId: id,
            timId: Value(target.team),
            tarih: '2020-03-01',
            islem: 'eklendi',
          ),
        );
    final appBackup = AppBackupService(target.db);
    for (var attempt = 0; attempt < 2; attempt++) {
      final result =
          await appBackup.restoreBackupJson(jsonEncode(legacyBackup));
      expect(result.importedPersonnel, 0);
    }
    final history = TaskTeamHistory(target.db);
    expect((await history.resolve(id, '2020-02-28'))?.teamId, target.otherTeam);
    expect((await history.resolve(id, '2020-03-01'))?.teamId, target.team);
    expect(await target.db.select(target.db.timUyelikGecmisiTable).get(),
        hasLength(2));
  });
}
