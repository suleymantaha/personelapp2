export 'package:personelapp2/core/auth/domain/user_session.dart';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';

/// Database instance whose lifecycle is owned by the provider container.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// Repositories
final personnelRepositoryProvider = Provider<PersonnelRepository>((ref) {
  return PersonnelRepository(ref.watch(databaseProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(databaseProvider));
});

final userSessionProvider = StateProvider<UserSessionState?>((ref) => null);

/// Dynamic Theme Mode Provider (System / Light / Dark)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Personnel Stream Providers
final allPersonnelProvider = StreamProvider<List<PersonelTableData>>((ref) {
  return ref.watch(personnelRepositoryProvider).watchAllPersonnelSorted();
});

final historicalPersonnelProvider = StreamProvider<List<PersonelTableData>>(
  (ref) => ref
      .watch(personnelRepositoryProvider)
      .watchAllPersonnelSorted(includeInactive: true),
);

final commanderAuthorityProvider = StreamProvider<int?>((ref) {
  final session = ref.watch(userSessionProvider);
  if (session == null || session.isAdmin) return Stream.value(null);
  final db = ref.watch(databaseProvider);
  final query = db.select(db.kullaniciTable).join([
    innerJoin(
      db.timTable,
      db.timTable.id.equalsExp(db.kullaniciTable.timId) &
          db.timTable.timKomutaniId.equalsExp(db.kullaniciTable.id),
    ),
  ])..where(
    db.kullaniciTable.kullaniciAdi.equals(session.username) &
        db.kullaniciTable.rol.equals(UserRole.teamCommander.storageValue),
  );
  return query.watch().map(
    (rows) => rows.isEmpty ? null : rows.single.readTable(db.timTable).id,
  );
});

final allSquadsProvider = StreamProvider<List<TimTableData>>((ref) {
  return ref.watch(personnelRepositoryProvider).watchAllSquads();
});

final allCommandersProvider = StreamProvider<List<KullaniciTableData>>((ref) {
  return ref.watch(personnelRepositoryProvider).watchAllCommanders();
});

/// Pending Assignments Provider (for Dashboard Alert Badge)
final pendingAssignmentsProvider =
    StreamProvider<List<FaaliyetPersonelAtamaTableData>>((ref) {
      final session = ref.watch(userSessionProvider);
      if (session?.isAdmin != true) {
        return Stream.value(const <FaaliyetPersonelAtamaTableData>[]);
      }
      return ref.watch(activityRepositoryProvider).watchPendingAssignments();
    });

/// Role-Filtered Activities Stream Provider
final filteredActivitiesProvider =
    StreamProvider<List<GunlukFaaliyetTableData>>((ref) async* {
      final session = ref.watch(userSessionProvider);
      final repo = ref.watch(activityRepositoryProvider);
      if (session == null) {
        yield const [];
      } else if (session.isAdmin) {
        yield* repo.watchAllActivities();
      } else {
        final authority = ref.watch(commanderAuthorityProvider);
        final teamId =
            authority.hasValue
                ? authority.value
                : await ref.watch(commanderAuthorityProvider.future);
        if (teamId == null) {
          yield const [];
        } else {
          yield* repo.watchActivitiesForTeam(teamId);
        }
      }
    });

/// Matrix Repository & Monthly Matrix Provider
final matrixRepositoryProvider = Provider<MatrixRepository>((ref) {
  return MatrixRepository(ref.watch(databaseProvider));
});

final StreamProviderFamily<Map<int, Map<int, MatrixDayCell>>, String>
monthlyMatrixProvider =
    StreamProvider.family<Map<int, Map<int, MatrixDayCell>>, String>((
      ref,
      yearMonth,
    ) {
      return ref.watch(matrixRepositoryProvider).watchMonthlyMatrix(yearMonth);
    });
