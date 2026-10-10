import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/domain/bulk_activity_import_preparer.dart';

Future<void> showDuplicatePersonnelDialog({
  required BuildContext context,
  required List<BulkImportDuplicate> duplicates,
  required List<TimTableData> squads,
}) {
  final squadNames = {for (final squad in squads) squad.id: squad.timAdi};
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.bulkImportDuplicateTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.bulkImportDuplicateDatePersonnelWarning,
              ),
              const SizedBox(height: 12),
              for (final duplicate in duplicates)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(duplicate.personnelName),
                  subtitle: Text(
                    '${duplicate.date} • '
                    '${squadNames[duplicate.teamId] ?? context.l10n.commonNoTeam}\n'
                    '${duplicate.assignments.join(' / ')}',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n.bulkImportReturnToPreviewButton),
        ),
      ],
    ),
  );
}
