import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'activity_form/activity_duty_action_card.dart';
import 'activity_form/activity_duty_picker.dart';
import 'activity_form/activity_personnel_assignment_actions.dart';
import 'activity_form/activity_selected_personnel_card.dart';

/// Uses the same squad cards, single-person actions and duty/note draft as
/// ActivityDetailsStep (the regular Activity Schedule flow).
class ActivityAssignmentDetailsEditor extends StatelessWidget {
  const ActivityAssignmentDetailsEditor({
    required this.people,
    required this.squadNames,
    required this.draft,
    required this.duties,
    required this.isAdmin,
    required this.onChangePerson,
    required this.onRemovePersonnel,
    required this.onChanged,
    super.key,
  });

  final List<PersonelTableData> people;
  final Map<int, String> squadNames;
  final ActivityFormDraft draft;
  final List<String> duties;
  final bool isAdmin;
  final VoidCallback onChangePerson;
  final ValueChanged<int> onRemovePersonnel;
  final VoidCallback onChanged;

  Future<void> _editAssignment(
    BuildContext context,
    PersonelTableData person,
  ) async {
    await showActivityPersonnelAssignmentActions(
      context: context,
      person: person,
      draft: draft,
      availableDuties: duties,
      onDutyOverrideChanged: (id, duty) {
        draft.setDutyOverride(id, duty);
        onChanged();
      },
      onNoteChanged: (id, note) {
        draft.setNote(id, note);
        onChanged();
      },
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
      duties: duties,
      keyPrefix: 'squad-duty-$squadName',
      inheritLabel: draft.commonDuty.isEmpty
          ? null
          : context.l10n.activityUseCommonDuty,
    );
    if (!context.mounted || duty == null) return;
    draft.setDutyForPersonnel(
      personnel.map((person) => person.id),
      duty == inheritCommonDutyValue ? null : duty,
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('archive-assignment-details-editor'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
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
              duties: duties,
              keyPrefix: 'common-duty',
              selectedDuty: draft.commonDuty,
            );
            if (!context.mounted || duty == null) return;
            draft.setCommonDuty(duty);
            onChanged();
          },
        ),
        const SizedBox(height: 14),
        ActivitySelectedPersonnelCard(
          personnel: people,
          squadNames: squadNames,
          draft: draft,
          expandSingleSquad: true,
          onRemovePersonnel: onRemovePersonnel,
          onEditPersonnel: onChangePerson,
          onEditAssignment: (person) => _editAssignment(context, person),
          onAssignSquad: (name, members) =>
              _assignSquadDuty(context, name, members),
        ),
        const SizedBox(height: 12),
        Text(
          isAdmin
              ? context.l10n.activityAdminAddNotice
              : context.l10n.activityUserAddNotice,
        ),
      ],
    );
  }
}
