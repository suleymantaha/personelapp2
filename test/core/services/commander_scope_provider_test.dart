import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

void main() {
  test(
    'an old commander session no longer reads the squad after handover',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = PersonnelRepository(db);
      final team = await repo.addSquad(
        timAdi: '1-B',
        olusturmaTarihi: '2026-01-01',
      );
      final user = await db
          .into(db.kullaniciTable)
          .insert(
            KullaniciTableCompanion.insert(
              kullaniciAdi: 'old',
              rol: 'tim_komutani',
            ),
          );
      await repo.assignCommanderToSquad(userId: user, timId: team);
      final person = await repo.addPersonnel(
        adSoyad: 'Ali',
        rutbe: 'J.Er',
        birlik: 'Asayiş',
        kayitTarihi: '2026-01-01',
        timId: team,
      );
      await ActivityRepository(db).createActivityWithAssignments(
        faaliyetAdi: 'HEYBET',
        tarih: '2026-10-02',
        olusturanKullanici: 'admin',
        personnelAssignments: [
          PersonnelAssignmentInput(personnelId: person, duty: 'HEYBET'),
        ],
        actor: const UserSessionState(username: 'admin', role: UserRole.admin),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith(
            (ref) => UserSessionState(
              username: 'old',
              role: UserRole.teamCommander,
              timId: team,
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      expect(
        await container.read(filteredActivitiesProvider.future),
        hasLength(1),
      );
      expect(
        await container.read(monthlyMatrixProvider('2026-10').future),
        isNotEmpty,
      );
      await repo.assignCommanderToSquad(userId: user, timId: null);
      container.invalidate(filteredActivitiesProvider);
      expect(await container.read(filteredActivitiesProvider.future), isEmpty);
      container.invalidate(monthlyMatrixProvider('2026-10'));
      expect(
        await container.read(monthlyMatrixProvider('2026-10').future),
        isEmpty,
      );
    },
  );
}
