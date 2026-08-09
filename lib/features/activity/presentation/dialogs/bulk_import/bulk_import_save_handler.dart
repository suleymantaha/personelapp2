import 'package:flutter/material.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_activity_import_preparer.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/duplicate_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/conflict_personnel_dialog.dart';

class BulkImportSaveHandler {
  static Map<String, List<String>> findDuplicateAssignments(
    List<ParsedActivityBlock> blocks,
  ) {
    final occurrences = <String, List<({int blockIndex, int personIndex})>>{};
    for (final blockEntry in blocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final id = personEntry.value.matchedPersonnelId;
        if (id == null) continue;
        final key =
            '${blockEntry.value.parsedDate}:${blockEntry.value.parsedActivityType.trim().toUpperCase()}:$id';
        occurrences.putIfAbsent(key, () => []).add(
          (blockIndex: blockEntry.key, personIndex: personEntry.key),
        );
      }
    }

    final result = <String, List<String>>{};
    for (final entries
        in occurrences.values.where((items) => items.length > 1)) {
      for (final entry in entries) {
        result['${entry.blockIndex}:${entry.personIndex}'] =
            entries.where((other) => other != entry).map((other) {
          final block = blocks[other.blockIndex];
          final time = block.parsedTimeRange?.trim();
          return time == null || time.isEmpty
              ? block.parsedActivityType
              : '${block.parsedActivityType} ($time)';
        }).toList(growable: false);
      }
    }
    return result;
  }

  static ({
    List<ParsedActivityBlock> blocks,
    int removedCount,
  }) deduplicateSameDuty(List<ParsedActivityBlock> blocks) {
    final seen = <String>{};
    var removedCount = 0;
    final result = <ParsedActivityBlock>[];
    for (final block in blocks) {
      final personnel = <ParsedPersonnelItem>[];
      for (final person in block.personnelList) {
        final id = person.matchedPersonnelId;
        if (id == null) {
          personnel.add(person);
          continue;
        }
        final key = '${block.parsedDate}:'
            '${block.parsedActivityType.trim().toUpperCase()}:$id';
        if (seen.add(key)) {
          personnel.add(person);
        } else {
          removedCount++;
        }
      }
      result.add(block.copyWith(personnelList: personnel));
    }
    return (blocks: result, removedCount: removedCount);
  }

  static Future<bool> confirmSavePreflight({
    required BuildContext context,
    required AppDatabase database,
    required UserSessionState? actor,
    required List<ParsedActivityBlock> blocks,
    required List<TimTableData> squads,
    BulkImportPreparation? preparation,
  }) async {
    final prepared = preparation ?? BulkActivityImportPreparer.prepare(blocks);
    if (prepared.duplicates.isNotEmpty) {
      await showDuplicatePersonnelDialog(
        context: context,
        duplicates: prepared.duplicates,
        squads: squads,
      );
      return false;
    }

    if (actor == null) {
      throw StateError('Oturum doğrulanamadı.');
    }

    final learningService = BulkImportLearningService(database);
    final fingerprint = BulkImportLearningService.fingerprint(blocks);
    final existingImport = await learningService.findImport(fingerprint);
    if (existingImport == null) return true;

    final activeCount = await learningService.countActiveAssignments(blocks);
    if (activeCount == 0) {
      await learningService.deleteImportRecord(fingerprint);
      return true;
    }

    if (!context.mounted) return false;
    final userChoice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bu Liste Daha Önce Aktarıldı'),
        content: Text(
          '${existingImport.tarihler} tarihli bu içerik '
          '${existingImport.kayitTarihi} tarihinde '
          '${existingImport.aktaranKullanici} tarafından kaydedilmiş.\n\n'
          'Veritabanında bu listeye ait $activeCount personel kaydı aktif duruyor. '
          'Eksik olanları tamamlamak veya yeniden aktarmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('EKSİKLERİ TAMAMLA / YENİDEN AKTAR'),
          ),
        ],
      ),
    );
    return userChoice == true;
  }

  static Future<bool?> saveAllToFaaliyet({
    required BuildContext context,
    required AppDatabase database,
    required ActivityRepository activityRepository,
    required UserSessionState? actor,
    required List<ParsedActivityBlock> blocks,
    required List<TimTableData> squads,
    required bool keepAuditText,
    required String rawText,
    required int deduplicatedPersonnelCount,
    bool skipPreflight = false,
  }) async {
    final preparation = BulkActivityImportPreparer.prepare(blocks);
    if (!skipPreflight) {
      final confirmed = await confirmSavePreflight(
        context: context,
        database: database,
        actor: actor,
        blocks: blocks,
        squads: squads,
        preparation: preparation,
      );
      if (!confirmed) return null;
    }

    if (actor == null) {
      throw StateError('Oturum doğrulanamadı.');
    }

    final learningService = BulkImportLearningService(database);
    final fingerprint = BulkImportLearningService.fingerprint(blocks);
    final result = await activityRepository.createActivitiesWithAssignments(
      preparation.requests,
      actor: actor,
    );

    final aliasPairs = blocks
        .expand((b) => b.personnelList)
        .where(
          (p) => p.matchedPersonnelId != null && p.rawName.trim().isNotEmpty,
        )
        .map((p) => (rawName: p.rawName, personnelId: p.matchedPersonnelId!));
    await learningService.rememberAliases(aliasPairs);

    await learningService.recordImport(
      fingerprint: fingerprint,
      blocks: blocks,
      actor: actor.username,
      rawText: keepAuditText ? rawText : null,
    );

    if (context.mounted) {
      if (result.skippedAssignmentCount > 0) {
        await showDialog<void>(
          context: context,
          builder: (_) => ConflictPersonnelDialog(
            descriptions: result.conflictDescriptions,
          ),
        );
        if (!context.mounted) return null;
      }

      final summaryLines = <String>[
        '${preparation.requests.length} günlük faaliyet işlendi.',
        '${result.addedAssignmentCount} yeni personel eklendi.',
        if (result.alreadyAssignedCount > 0)
          '${result.alreadyAssignedCount} personel zaten o görevde ekliydi.',
        if (deduplicatedPersonnelCount > 0)
          '$deduplicatedPersonnelCount tekrar tekilleştirildi.',
        if (result.skippedAssignmentCount > 0)
          '${result.skippedAssignmentCount} çakışan kayıt atlandı.',
      ];

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Aktarım Tamamlandı'),
          content: Text(summaryLines.join('\n')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('TAMAM'),
            ),
          ],
        ),
      );
      if (!context.mounted) return null;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${blocks.length} blok → ${preparation.requests.length} '
            'günlük faaliyet, ${result.addedAssignmentCount} personel '
            'başarıyla eklendi.',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }
    return null;
  }
}
