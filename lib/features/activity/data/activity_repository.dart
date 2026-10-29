import 'dart:async';

import 'package:drift/drift.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/task_team_history.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';
import 'package:personelapp2/features/activity/domain/models/activity_create_request.dart';

import 'package:personelapp2/features/activity/data/activity_repository_results.dart';

export 'package:personelapp2/features/activity/domain/models/activity_create_request.dart';
export 'package:personelapp2/features/activity/data/activity_repository_results.dart';

part 'activity_repository_dates.dart';
part 'activity_repository_queries.dart';
part 'activity_repository_conflicts.dart';
part 'activity_repository_assignments.dart';
part 'activity_repository_transfers.dart';
part 'activity_repository_task_teams.dart';

class ActivityRepository {
  ActivityRepository(this.db);

  final AppDatabase db;

  void _requireAdmin(UserSessionState actor) {
    if (!actor.isAdmin) {
      throw const AuthorizationException(
        'Bu işlem yalnızca yöneticiler tarafından yapılabilir.',
      );
    }
  }

  Future<void> _requirePersonnelScope(
    UserSessionState actor,
    List<PersonnelAssignmentInput> assignments,
  ) async {
    final personnelIds = assignments.map((item) => item.personnelId).toSet();
    if (personnelIds.isEmpty) return;

    final personnel = await (db.select(db.personelTable)
          ..where((table) => table.id.isIn(personnelIds)))
        .get();
    if (personnel.length != personnelIds.length) {
      throw const AuthorizationException(
        'Atama listesindeki personelden biri bulunamadı.',
      );
    }
    if (personnel.any((p) => !p.aktif || p.isDemo)) {
      throw const AuthorizationException(
        'Atama için aktif gerçek personel seçilmeli.',
      );
    }
    if (actor.isAdmin) return;

    final account = await (db.select(db.kullaniciTable)
          ..where(
            (table) => table.kullaniciAdi.equals(actor.username),
          ))
        .getSingleOrNull();
    final teamId = account?.timId;
    final team = teamId == null
        ? null
        : await (db.select(db.timTable)
              ..where((table) => table.id.equals(teamId)))
            .getSingleOrNull();
    if (account == null ||
        account.rol != UserRole.teamCommander.storageValue ||
        teamId == null ||
        teamId != actor.timId ||
        team?.timKomutaniId != account.id ||
        personnel.any((person) => person.timId != teamId) ||
        assignments.any((a) =>
            a.isOutsideTeam || (a.teamId != null && a.teamId != teamId))) {
      throw const AuthorizationException(
        'Tim komutanı yalnızca kendi timindeki personele atama yapabilir.',
      );
    }
  }

  Future<FaaliyetPersonelAtamaTableCompanion> _newAssignment({
    required int faaliyetId,
    required int personelId,
    required String gorevVeyaIzin,
    required String durum,
    required UserSessionState actor,
    Value<String?> aciklama = const Value.absent(),
    int? taskTeamId,
    bool isOutsideTeam = false,
    FaaliyetPersonelAtamaTableData? sourceAssignment,
  }) async {
    final activity = await (db.select(db.gunlukFaaliyetTable)
          ..where((f) => f.id.equals(faaliyetId)))
        .getSingle();
    final snapshot = await _snapshotForAssignment(
        personelId, activity.tarih, actor,
        taskTeamId: taskTeamId,
        isOutsideTeam: isOutsideTeam,
        source: sourceAssignment);
    return FaaliyetPersonelAtamaTableCompanion.insert(
      faaliyetId: faaliyetId,
      personelId: personelId,
      gorevVeyaIzin: gorevVeyaIzin,
      durum: durum,
      aciklama: aciklama,
      gorevTimId: Value(snapshot.$1),
      gorevTimAdi: Value(snapshot.$2),
    );
  }

  String _normalizeActivityName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

  String _normalizeNote(String? value) {
    final note = value?.trim() ?? '';
    return note.replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isValidIsoDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return false;
    final canonical = '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    return canonical == value;
  }
}
