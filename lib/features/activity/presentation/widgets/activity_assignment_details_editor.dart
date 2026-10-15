import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'activity_form/activity_details_step.dart';

/// Uses the same personnel/squad editor as the Activity Schedule screen.
/// Archive additions must not fork the per-person duty and note interaction.
class ActivityAssignmentDetailsEditor extends StatefulWidget {
  const ActivityAssignmentDetailsEditor({
    required this.people,
    required this.squadNames,
    required this.draft,
    required this.duties,
    required this.isAdmin,
    required this.onChangePerson,
    required this.onChanged,
    super.key,
  });

  final List<PersonelTableData> people;
  final Map<int, String> squadNames;
  final ActivityFormDraft draft;
  final List<String> duties;
  final bool isAdmin;
  final VoidCallback onChangePerson;
  final VoidCallback onChanged;

  @override
  State<ActivityAssignmentDetailsEditor> createState() =>
      _ActivityAssignmentDetailsEditorState();
}

class _ActivityAssignmentDetailsEditorState
    extends State<ActivityAssignmentDetailsEditor> {
  late final TextEditingController _activityNameController;

  @override
  void initState() {
    super.initState();
    // Activity title and date are fixed when adding to an archived activity;
    // the shared form's header is intentionally not displayed.
    _activityNameController = TextEditingController(
      text: widget.draft.activityName,
    );
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ActivityDetailsStep(
        draft: widget.draft,
        selectedPersonnel: widget.people,
        squadNames: widget.squadNames,
        activityNameController: _activityNameController,
        activityTemplates: const [],
        availableDuties: widget.duties,
        showNameError: false,
        header: const SizedBox.shrink(),
        showPreviewHint: false,
        onPickDate: () {},
        onActivityChanged: (_) {},
        onActivityTemplateSelected: (_) {},
        onCommonDutyChanged: (duty) {
          widget.draft.setCommonDuty(duty);
          widget.onChanged();
        },
        onDutyOverrideChanged: (id, duty) {
          widget.draft.setDutyOverride(id, duty);
          widget.onChanged();
        },
        onSquadDutyChanged: (ids, duty) {
          widget.draft.setDutyForPersonnel(ids, duty);
          widget.onChanged();
        },
        onNoteChanged: (id, note) {
          widget.draft.setNote(id, note);
          widget.onChanged();
        },
        onRemovePersonnel: (id) {
          widget.draft.togglePersonnel(id);
          widget.onChanged();
          if (widget.draft.selectedPersonnelIds.isEmpty) {
            widget.onChangePerson();
          }
        },
        onEditPersonnel: widget.onChangePerson,
      );
}
