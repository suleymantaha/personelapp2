import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';


/// Database Instance Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Repositories
final personnelRepositoryProvider = Provider<PersonnelRepository>((ref) {
  return PersonnelRepository(ref.watch(databaseProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(databaseProvider));
});

/// Current Logged-in User Session State
class UserSessionState {
  const UserSessionState({
    required this.username,
    required this.role,
    this.timId,
  });

  final String username;
  final String role; // 'yönetici' veya 'tim_komutani'
  final int? timId;

  bool get isAdmin => role == 'yönetici';
}

final userSessionProvider =
    StateProvider<UserSessionState?>((ref) => null);

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
  return ref.watch(activityRepositoryProvider).watchPendingAssignments();
});

/// Role-Filtered Activities Stream Provider
final filteredActivitiesProvider =
    StreamProvider<List<GunlukFaaliyetTableData>>((ref) {
  final session = ref.watch(userSessionProvider);
  final repo = ref.watch(activityRepositoryProvider);

  if (session != null && !session.isAdmin && session.timId != null) {
    return repo.watchActivitiesForTeam(session.timId!);
  }
  return repo.watchAllActivities();
});


/// Matrix Repository & Monthly Matrix Provider
final matrixRepositoryProvider = Provider<MatrixRepository>((ref) {
  return MatrixRepository(ref.watch(databaseProvider));
});

final StreamProviderFamily<Map<int, Map<int, String>>, String>
    monthlyMatrixProvider =
    StreamProvider.family<Map<int, Map<int, String>>, String>(
        (ref, yearMonth) {
  return ref.watch(matrixRepositoryProvider).watchMonthlyMatrix(yearMonth);
});
