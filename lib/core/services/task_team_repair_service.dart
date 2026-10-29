import 'package:drift/drift.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'app_backup_service.dart';
import 'task_team_history.dart';
import 'task_team_repair_guard.dart';

class TaskTeamRepairCandidate {
  const TaskTeamRepairCandidate(
      {required this.assignmentId,
      required this.activityId,
      required this.personnelId,
      required this.date,
      required this.teamId,
      required this.teamName});
  final int assignmentId, activityId, personnelId;
  final String date, teamName;
  final int? teamId;
}

class TaskTeamRepairPreview {
  TaskTeamRepairPreview._(
      this._owner,
      this.backupJson,
      this._rawSnapshot,
      this._payloadChecksum,
      List<TaskTeamRepairCandidate> candidates,
      this.unknownCount,
      this.outsideCount)
      : candidates = List.unmodifiable(candidates);
  final Object _owner;
  final String backupJson, _rawSnapshot, _payloadChecksum;
  final List<TaskTeamRepairCandidate> candidates;
  final int unknownCount, outsideCount;
}

class TaskTeamRepairService {
  TaskTeamRepairService(this.db, {AppBackupService? backupService})
      : _backup = backupService ?? AppBackupService(db);
  final AppDatabase db;
  final AppBackupService _backup;
  final Object _owner = Object();

  Future<void> _authorize(UserSessionState actor) async {
    final user = await (db.select(db.kullaniciTable)
          ..where((t) => t.kullaniciAdi.equals(actor.username)))
        .getSingleOrNull();
    if (!actor.isAdmin || user?.rol != UserRole.admin.storageValue) {
      throw StateError('Bu işlem için güncel yönetici yetkisi gerekiyor.');
    }
  }

  Future<TaskTeamRepairPreview> prepare(UserSessionState actor) =>
      db.transaction(() async {
        await _authorize(actor);
        final guard = TaskTeamRepairGuard(db, _backup);
        final raw = await guard.rawSnapshot();
        final backup = await guard.safeBackup();
        final scan = await _scan();
        return TaskTeamRepairPreview._(_owner, backup, raw,
            guard.payloadChecksum(backup), scan.$1, scan.$2, scan.$3);
      });

  Future<int> apply(
          {required TaskTeamRepairPreview preview,
          required String verifiedBackupJson,
          required UserSessionState actor}) =>
      db.transaction(() async {
        await _authorize(actor);
        if (!identical(preview._owner, _owner) ||
            verifiedBackupJson != preview.backupJson) {
          throw StateError(
              'Kaydedilip yeniden açılan yedek önizleme ile eşleşmiyor.');
        }
        final guard = TaskTeamRepairGuard(db, _backup);
        if (await guard.rawSnapshot() != preview._rawSnapshot ||
            guard.payloadChecksum(await guard.safeBackup()) !=
                preview._payloadChecksum) {
          throw StateError(
              'Veriler değişti; yeni önizleme ve yedek gerekiyor.');
        }
        final scan = await _scan();
        if (!_same(scan.$1, preview.candidates) ||
            scan.$2 != preview.unknownCount ||
            scan.$3 != preview.outsideCount) {
          throw StateError('Onarım adayları değişti.');
        }
        if (guard.payloadChecksum(await guard.safeBackup()) !=
            preview._payloadChecksum) {
          throw StateError(
              'Ayarlar değişti; yeni önizleme ve yedek gerekiyor.');
        }
        for (final c in scan.$1) {
          final changed = await (db.update(db.faaliyetPersonelAtamaTable)
                ..where((t) =>
                    t.id.equals(c.assignmentId) &
                    t.gorevTimId.isNull() &
                    t.gorevTimAdi.isNull()))
              .write(FaaliyetPersonelAtamaTableCompanion(
                  gorevTimId: Value(c.teamId), gorevTimAdi: Value(c.teamName)));
          if (changed != 1) throw StateError('Atama değişti.');
          await db.customStatement(
              'INSERT INTO task_team_repair_audit '
              '(assignment_id,old_team_id,old_team_name,new_team_id,new_team_name,backup_checksum) '
              'VALUES (?,NULL,NULL,?,?,?)',
              [c.assignmentId, c.teamId, c.teamName, preview._payloadChecksum]);
        }
        return scan.$1.length;
      });

  Future<(List<TaskTeamRepairCandidate>, int, int)> _scan() async {
    final rows = await db
        .customSelect('SELECT a.id, a.faaliyet_id, a.personel_id, f.tarih '
            'FROM faaliyet_personel_atama_table a JOIN gunluk_faaliyet_table f ON f.id=a.faaliyet_id '
            'WHERE a.gorev_tim_id IS NULL AND a.gorev_tim_adi IS NULL ORDER BY a.id')
        .get();
    final candidates = <TaskTeamRepairCandidate>[];
    var unknown = 0, outside = 0;
    for (final row in rows) {
      final snapshot = await TaskTeamHistory(db)
          .resolve(row.read<int>('personel_id'), row.read<String>('tarih'));
      if (snapshot == null) {
        unknown++;
        continue;
      }
      if (snapshot.teamId == null) {
        outside++;
        continue;
      }
      candidates.add(TaskTeamRepairCandidate(
          assignmentId: row.read<int>('id'),
          activityId: row.read<int>('faaliyet_id'),
          personnelId: row.read<int>('personel_id'),
          date: row.read<String>('tarih'),
          teamId: snapshot.teamId,
          teamName: snapshot.teamName));
    }
    return (candidates, unknown, outside);
  }

  bool _same(List<TaskTeamRepairCandidate> a, List<TaskTeamRepairCandidate> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].assignmentId != b[i].assignmentId ||
          a[i].activityId != b[i].activityId ||
          a[i].personnelId != b[i].personnelId ||
          a[i].date != b[i].date ||
          a[i].teamId != b[i].teamId ||
          a[i].teamName != b[i].teamName) {
        return false;
      }
    }
    return true;
  }
}
