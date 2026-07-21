import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
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
  final String username;
  final String role; // 'yönetici' veya 'tim_komutani'
  final int? timId;

  const UserSessionState({
    required this.username,
    required this.role,
    this.timId,
  });

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

/// Pending Assignments Provider (for Dashboard Alert Badge)
final pendingAssignmentsProvider =
    StreamProvider<List<FaaliyetPersonelAtamaTableData>>((ref) {
  return ref.watch(activityRepositoryProvider).watchPendingAssignments();
});
