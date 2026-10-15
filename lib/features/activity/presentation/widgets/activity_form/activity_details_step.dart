import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/widgets/app_card.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_form_header.dart';

import 'activity_duty_picker.dart';
import 'activity_duty_action_card.dart';
import 'activity_personnel_assignment_actions.dart';
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
              selectedDuty: draft.commonDuty,
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
          AppNoticeBanner(
            message: context.l10n.activityPreviewHint,
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
  ) => showActivityPersonnelAssignmentActions(
    context: context,
    person: person,
    draft: draft,
    availableDuties: availableDuties,
    onDutyOverrideChanged: onDutyOverrideChanged,
    onNoteChanged: onNoteChanged,
  );
}
