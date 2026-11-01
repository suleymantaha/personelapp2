import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

/// Negative IDs belong only to this dialog and never reach repository writes.
class StagedBulkImport {
  final people = <int, PersonelTableCompanion>{};

  static Future<int?> authorizedTeam(
      AppDatabase db, UserSessionState? actor) async {
    if (actor == null) return null;
    if (actor.isAdmin) return null;
    final team =
        await PersonnelRepository(db).currentCommanderTeam(actor.username);
    return team == actor.timId ? team : null;
  }

  static Future<void> requireActor(
      AppDatabase db, UserSessionState? actor) async {
    if (actor == null) throw StateError('Oturum gerekli.');
    final account = await (db.select(db.kullaniciTable)
          ..where((t) => t.kullaniciAdi.equals(actor.username)))
        .getSingleOrNull();
    if (account == null ||
        account.rol != actor.role.storageValue ||
        (!actor.isAdmin && await authorizedTeam(db, actor) == null)) {
      throw StateError('Oturum yetkisi değişti.');
    }
  }

  Future<Map<int, int>> persist(AppDatabase db, UserSessionState actor,
      List<ParsedActivityBlock> blocks) async {
    await requireActor(db, actor);
    final used = blocks
        .expand((b) => b.personnelList)
        .map((p) => p.matchedPersonnelId)
        .toSet();
    final ids = <int, int>{};
    for (final entry in people.entries.where((e) => used.contains(e.key))) {
      if (!actor.isAdmin) {
        throw StateError('Yeni personel için yönetici gerekli.');
      }
      final p = entry.value;
      ids[entry.key] = await PersonnelRepository(db).addPersonnel(
          adSoyad: p.adSoyad.value,
          rutbe: p.rutbe.value,
          birlik: p.birlik.value,
          kayitTarihi: p.kayitTarihi.value,
          timId: p.timId.value);
    }
    return ids;
  }

  static List<ParsedActivityBlock> remapBlocks(
          List<ParsedActivityBlock> blocks, Map<int, int> ids) =>
      [
        for (final b in blocks)
          b.copyWith(personnelList: [
            for (final p in b.personnelList)
              p.copyWith(matchedPersonnelId: ids[p.matchedPersonnelId])
          ])
      ];

  static PersonnelAssignmentInput remapAssignment(
          PersonnelAssignmentInput a, Map<int, int> ids) =>
      PersonnelAssignmentInput(
          personnelId: ids[a.personnelId] ?? a.personnelId,
          duty: a.duty,
          note: a.note,
          teamId: a.teamId,
          isOutsideTeam: a.isOutsideTeam);
}
