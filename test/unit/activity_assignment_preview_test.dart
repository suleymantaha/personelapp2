import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

void main() {
  test('preview reports groups and conflicts without writing data', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ActivityRepository(database);
    final squadId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '7-B Timi',
            olusturmaTarihi: '2026-08-05',
          ),
        );
    Future<int> addPerson(String name) =>
        database.into(database.personelTable).insert(
              PersonelTableCompanion.insert(
                adSoyad: name,
                rutbe: 'J.Asb.',
                birlik: '7-B',
                timId: Value(squadId),
                kayitTarihi: '2026-08-05',
              ),
            );
    final availableId = await addPerson('Ali YILMAZ');
    final conflictId = await addPerson('Veli DEMİR');
    final activityId = await database.into(database.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Mevcut Görev',
            tarih: '2026-08-06',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-08-05T12:00:00',
          ),
        );
    await database.into(database.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activityId,
            personelId: conflictId,
            gorevVeyaIzin: DutyOrLeaveType.gorevli,
            durum: AssignmentStatus.onaylandi,
          ),
        );
    final activityCountBefore =
        await database.select(database.gunlukFaaliyetTable).get();

    final preview = await repository.previewActivityAssignments(
      tarih: '2026-08-06',
      personnelAssignments: [
        PersonnelAssignmentInput(
          personnelId: availableId,
          duty: DutyOrLeaveType.heybet,
        ),
        PersonnelAssignmentInput(
          personnelId: conflictId,
          duty: DutyOrLeaveType.nobetci,
          note: 'Gece görevi',
        ),
      ],
      actor: const UserSessionState(
        username: 'admin',
        role: UserRole.admin,
      ),
    );

    expect(preview.items, hasLength(2));
    expect(preview.squadCount, 1);
    expect(preview.warningCount, 1);
    expect(preview.squadNames[squadId], '7-B Timi');
    expect(
      preview.items.singleWhere((item) => item.personnelId == conflictId).note,
      'Gece görevi',
    );
    expect(
      preview.items
          .singleWhere((item) => item.personnelId == conflictId)
          .hasConflict,
      isTrue,
    );
    expect(
      await database.select(database.gunlukFaaliyetTable).get(),
      hasLength(activityCountBefore.length),
    );
  });
}
