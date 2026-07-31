import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
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
      title: const Text('Tekrarlanan Personel Var'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aynı personel aynı tarihte birden fazla görevde bulunuyor. '
                'Aktarmadan önce önizlemedeki tekrarları düzeltin.',
              ),
              const SizedBox(height: 12),
              for (final duplicate in duplicates)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(duplicate.personnelName),
                  subtitle: Text(
                    '${duplicate.date} • '
                    '${squadNames[duplicate.teamId] ?? 'Timsiz'}\n'
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
          child: const Text('ÖNİZLEMEYE DÖN'),
        ),
      ],
    ),
  );
}
