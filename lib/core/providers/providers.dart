export 'package:personelapp2/core/auth/domain/user_session.dart';

import 'package:flutter/material.dart';
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
    StreamProvider<List<GunlukFaaliyetTableData>>((ref) {
      final session = ref.watch(userSessionProvider);
      final repo = ref.watch(activityRepositoryProvider);

      if (session == null) {
        return Stream.value(const <GunlukFaaliyetTableData>[]);
      }

      if (!session.isAdmin && session.timId == null) {
        return Stream.value(const <GunlukFaaliyetTableData>[]);
      }

      if (!session.isAdmin && session.timId != null) {
        return repo.watchActivitiesForTeam(session.timId!);
      }
      return repo.watchAllActivities();
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
