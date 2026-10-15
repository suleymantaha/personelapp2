import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';

import 'activity_duty_picker.dart';

/// Shared personnel duty/note actions for both activity creation and
/// archive -> Add Personnel. Changes stay in the caller's draft until save.
Future<void> showActivityPersonnelAssignmentActions({
  required BuildContext context,
  required PersonelTableData person,
  required ActivityFormDraft draft,
  required List<String> availableDuties,
  required void Function(int personnelId, String? duty) onDutyOverrideChanged,
  required void Function(int personnelId, String? note) onNoteChanged,
}) async {
    final action = await showModalBottomSheet<_PersonnelEditAction>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              person.adSoyad,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(person.rutbe, style: sheetContext.textStyleSecondary),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(sheetContext.l10n.activitySelectDifferentDuty),
              subtitle: Text(draft.dutyFor(person.id) ??
                  sheetContext.l10n.activityDutyNotSelected),
              onTap: () => Navigator.pop(
                sheetContext,
                _PersonnelEditAction.duty,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notes_rounded),
              title: Text(sheetContext.l10n.activityAddOrEditNote),
              subtitle: Text(draft.notes[person.id] ??
                  sheetContext.l10n.activityNoNote),
              onTap: () => Navigator.pop(
                sheetContext,
                _PersonnelEditAction.note,
              ),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == _PersonnelEditAction.duty) {
      final duty = await showActivityDutyPicker(
        context,
        title: context.l10n.activityPersonnelDutyTitle(person.adSoyad),
        duties: availableDuties,
        keyPrefix: 'personnel-duty-${person.id}',
        inheritLabel: draft.commonDuty.isEmpty
            ? null
            : context.l10n.activityUseCommonDuty,
        selectedDuty: draft.dutyFor(person.id),
      );
      if (!context.mounted) return;
      if (duty == inheritCommonDutyValue) {
        onDutyOverrideChanged(person.id, null);
      } else if (duty != null) {
        onDutyOverrideChanged(person.id, duty);
      }
      return;
    }

    var noteValue = draft.notes[person.id] ?? '';
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.activityPersonnelNoteTitle(person.adSoyad)),
        content: SingleChildScrollView(
          child: TextFormField(
            key: ValueKey('personnel-note-${person.id}'),
            initialValue: noteValue,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: dialogContext.l10n.activityOptionalNoteHint,
            ),
            onChanged: (value) => noteValue = value,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.commonDismiss),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, noteValue),
            child: Text(dialogContext.l10n.commonOk),
          ),
        ],
      ),
    );
    if (context.mounted && note != null) onNoteChanged(person.id, note);
}

enum _PersonnelEditAction { duty, note }
