import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_form_header.dart';

import 'activity_duty_picker.dart';
import 'activity_duty_action_card.dart';
import 'activity_selected_personnel_card.dart';

class ActivityDetailsStep extends StatelessWidget {
  const ActivityDetailsStep({
    required this.draft,
    required this.selectedPersonnel,
    required this.squadNames,
    required this.activityNameController,
    required this.activityTemplates,
    required this.availableDuties,
    required this.showNameError,
    required this.onPickDate,
    required this.onActivityChanged,
    required this.onActivityTemplateSelected,
    required this.onCommonDutyChanged,
    required this.onDutyOverrideChanged,
    required this.onSquadDutyChanged,
    required this.onNoteChanged,
    required this.onRemovePersonnel,
    required this.onEditPersonnel,
    this.header,
    this.showPreviewHint = true,
    super.key,
  });

  final Widget? header;
  final bool showPreviewHint;
  final ActivityFormDraft draft;
  final List<PersonelTableData> selectedPersonnel;
  final Map<int, String> squadNames;
  final TextEditingController activityNameController;
  final List<String> activityTemplates;
  final List<String> availableDuties;
  final bool showNameError;
  final VoidCallback onPickDate;
  final ValueChanged<String> onActivityChanged;
  final ValueChanged<String> onActivityTemplateSelected;
  final ValueChanged<String> onCommonDutyChanged;
  final void Function(int personnelId, String? duty) onDutyOverrideChanged;
  final void Function(Iterable<int> personnelIds, String? duty)
      onSquadDutyChanged;
  final void Function(int personnelId, String? note) onNoteChanged;
  final ValueChanged<int> onRemovePersonnel;
  final VoidCallback onEditPersonnel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('activity-details-step'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        header ??
            ActivityFormHeader(
              selectedDate: draft.selectedDate,
              onPickDate: onPickDate,
              activityNameController: activityNameController,
              showNameError: showNameError,
              onNameChanged: onActivityChanged,
              templates: activityTemplates,
              onTemplateSelected: onActivityTemplateSelected,
            ),
        const SizedBox(height: 14),
        ActivityDutyActionCard(
          key: const Key('common-duty-field'),
          icon: Icons.assignment_ind_outlined,
          label: context.l10n.activityAssignCommonDuty,
          value: draft.commonDuty.isEmpty
              ? context.l10n.activityAssignDutyToSelected
              : draft.commonDuty,
          onTap: () async {
            final duty = await showActivityDutyPicker(
              context,
              title: context.l10n.activitySelectCommonDuty,
              duties: availableDuties,
              keyPrefix: 'common-duty',
            );
            if (context.mounted && duty != null) onCommonDutyChanged(duty);
          },
        ),
        const SizedBox(height: 14),
        ActivitySelectedPersonnelCard(
          personnel: selectedPersonnel,
          squadNames: squadNames,
          draft: draft,
          onRemovePersonnel: onRemovePersonnel,
          onEditPersonnel: onEditPersonnel,
          onEditAssignment: (person) =>
              _editPersonnelAssignment(context, person),
          onAssignSquad: (squadName, personnel) =>
              _assignSquadDuty(context, squadName, personnel),
        ),
        const SizedBox(height: 14),
        if (showPreviewHint)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.accentSubtleBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: context.accentOrOlive),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.activityPreviewHint,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _assignSquadDuty(
    BuildContext context,
    String squadName,
    List<PersonelTableData> personnel,
  ) async {
    final duty = await showActivityDutyPicker(
      context,
      title: context.l10n.activitySquadDutyAssignTitle(squadName),
      duties: availableDuties,
      keyPrefix: 'squad-duty-$squadName',
      inheritLabel: draft.commonDuty.isEmpty
          ? null
          : context.l10n.activityUseCommonDuty,
    );
    if (!context.mounted) return;
    if (duty == inheritCommonDutyValue) {
      onSquadDutyChanged(personnel.map((person) => person.id), null);
    } else if (duty != null) {
      onSquadDutyChanged(personnel.map((person) => person.id), duty);
    }
  }

  Future<void> _editPersonnelAssignment(
    BuildContext context,
    PersonelTableData person,
  ) async {
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
        content: TextFormField(
          key: ValueKey('personnel-note-${person.id}'),
          initialValue: noteValue,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: dialogContext.l10n.activityOptionalNoteHint,
          ),
          onChanged: (value) => noteValue = value,
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
}

enum _PersonnelEditAction { duty, note }
