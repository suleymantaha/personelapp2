import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
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
        occurrences.putIfAbsent(key, () => []).add((
          blockIndex: blockEntry.key,
          personIndex: personEntry.key,
        ));
      }
    }

    final result = <String, List<String>>{};
    for (final entries in occurrences.values.where(
      (items) => items.length > 1,
    )) {
      for (final entry in entries) {
        result['${entry.blockIndex}:${entry.personIndex}'] = entries
            .where((other) => other != entry)
            .map((other) {
              final block = blocks[other.blockIndex];
              final time = block.parsedTimeRange?.trim();
              return time == null || time.isEmpty
                  ? block.parsedActivityType
                  : '${block.parsedActivityType} ($time)';
            })
            .toList(growable: false);
      }
    }
    return result;
  }

  static ({List<ParsedActivityBlock> blocks, int removedCount})
  deduplicateSameDuty(List<ParsedActivityBlock> blocks) =>
      BulkActivityImportPreparer.deduplicateSameDuty(blocks);

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
      throw StateError(context.l10n.authSessionFailed);
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
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.l10n.bulkImportDuplicateListTitle),
            content: Text(
              context.l10n.bulkImportDuplicateWarningContent(
                existingImport.tarihler,
                existingImport.kayitTarihi,
                existingImport.aktaranKullanici,
                activeCount,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.commonCancel.toUpperCase()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.l10n.bulkImportCompleteMissingOrReimport),
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
    final l10n = context.l10n;
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
      throw StateError(l10n.authSessionFailed);
    }

    final learningService = BulkImportLearningService(database);
    final fingerprint = BulkImportLearningService.fingerprint(blocks);
    final result = await activityRepository.createActivitiesWithAssignments(
      preparation.requests,
      actor: actor,
    );

    await learningService.rememberBlockAliases(blocks);

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
          builder:
              (_) => ConflictPersonnelDialog(
                descriptions: result.conflictDescriptions,
              ),
        );
        if (!context.mounted) return null;
      }

      final summaryLines = <String>[
        context.l10n.bulkImportSummaryActivitiesProcessed(preparation.requests.length),
        context.l10n.bulkImportSummaryPersonnelAdded(result.addedAssignmentCount),
        if (result.alreadyAssignedCount > 0)
          context.l10n.bulkImportSummaryAlreadyAssigned(result.alreadyAssignedCount),
        if (deduplicatedPersonnelCount > 0)
          context.l10n.bulkImportSummaryDeduplicated(deduplicatedPersonnelCount),
        if (result.skippedAssignmentCount > 0)
          context.l10n.bulkImportSummarySkippedConflict(result.skippedAssignmentCount),
      ];

      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: Text(context.l10n.bulkImportCompletedTitle),
              content: Text(summaryLines.join('\n')),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.l10n.commonOk.toUpperCase()),
                ),
              ],
            ),
      );
      if (!context.mounted) return null;
      Navigator.pop(context, true);
      AppNotifications.success(
        context.l10n.bulkImportSuccessMessage(
          blocks.length,
          preparation.requests.length,
          result.addedAssignmentCount,
        ),
      );
      return true;
    }
    return null;
  }
}
