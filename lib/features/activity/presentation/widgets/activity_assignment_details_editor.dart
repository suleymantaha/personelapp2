import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import '../view_models/activity_form_draft.dart';
import 'activity_form/activity_duty_action_card.dart';
import 'activity_form/activity_duty_picker.dart';

class ActivityAssignmentDetailsEditor extends StatelessWidget {
  const ActivityAssignmentDetailsEditor(
      {required this.people,
      required this.squadNames,
      required this.draft,
      required this.duties,
      required this.isAdmin,
      required this.onChangePerson,
      required this.onChanged,
      super.key});
  final List<PersonelTableData> people;
  final Map<int, String> squadNames;
  final ActivityFormDraft draft;
  final List<String> duties;
  final bool isAdmin;
  final VoidCallback onChangePerson;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
                child: Text(
                    context.l10n.activitySelectedPersonnelCount(people.length),
                    style: Theme.of(context).textTheme.titleMedium)),
            TextButton(
                onPressed: onChangePerson,
                child: Text(context.l10n.activityChange))
          ]),
          const SizedBox(height: 12),
          ActivityDutyActionCard(
            key: const Key('common-duty-field'),
            icon: Icons.assignment_ind_outlined,
            label: context.l10n.activityCommonDuty,
            value: draft.commonDuty.isEmpty
                ? context.l10n.activityCommonDuty
                : draft.commonDuty,
            onTap: () async {
              final value = await showActivityDutyPicker(
                context,
                title: context.l10n.activityCommonDuty,
                duties: duties,
                keyPrefix: 'common-duty',
                selectedDuty: draft.commonDuty,
              );
              if (value == null) return;
              draft.setCommonDuty(value);
              for (final person in people) {
                draft.setDutyOverride(person.id, null);
              }
              onChanged();
            },
          ),
          const SizedBox(height: 16),
          for (final person in people)
            _AssignmentCard(
                key: ValueKey(person.id),
                person: person,
                teamName:
                    squadNames[person.timId] ?? context.l10n.activityOutsideSquad,
                draft: draft,
                duties: duties,
                showDuty: people.length > 1 ||
                    draft.dutyOverrides.containsKey(person.id),
                onChanged: onChanged),
          const SizedBox(height: 12),
          Text(isAdmin
              ? context.l10n.activityAdminAddNotice
              : context.l10n.activityUserAddNotice),
        ],
      );
}

class _AssignmentCard extends StatefulWidget {
  const _AssignmentCard(
      {required this.person,
      required this.teamName,
      required this.draft,
      required this.duties,
      required this.showDuty,
      required this.onChanged,
      super.key});
  final PersonelTableData person;
  final String teamName;
  final ActivityFormDraft draft;
  final List<String> duties;
  final bool showDuty;
  final VoidCallback onChanged;
  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  bool _noteOpen = false;
  @override
  Widget build(BuildContext context) {
    final id = widget.person.id;
    final duty = widget.draft.dutyFor(id) ?? widget.draft.commonDuty;
    final note = widget.draft.notes[id] ?? '';
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const CircleAvatar(child: Icon(Icons.person_outline)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(widget.person.adSoyad,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('${widget.person.rutbe} · ${widget.teamName}'),
                      ])),
                ]),
                if (widget.showDuty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    key: Key('assignment-duty-$id-$duty'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final newDuty = await showActivityDutyPicker(
                        context,
                        title: '${widget.person.adSoyad} için görev',
                        duties: widget.duties,
                        keyPrefix: 'assignment-duty-$id',
                        selectedDuty: duty,
                      );
                      if (newDuty != null) {
                        widget.draft.setDutyOverride(id, newDuty);
                        widget.onChanged();
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: context.l10n.activityPersonalDutyLabel,
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        duty,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                if (!_noteOpen && note.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(note,
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
                TextButton.icon(
                  onPressed: () => setState(() => _noteOpen = !_noteOpen),
                  icon: Icon(_noteOpen ? Icons.check : Icons.note_add_outlined),
                  label: Text(_noteOpen
                      ? context.l10n.activityCloseNote
                      : note.isEmpty
                          ? context.l10n.activityAddNote
                          : context.l10n.activityEditNote),
                ),
                if (_noteOpen)
                  TextFormField(
                    key: Key('assignment-note-$id'),
                    initialValue: note,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                        hintText: context.l10n.activityGeneralDutyNoteHint,
                        border: const OutlineInputBorder()),
                    onChanged: (value) => widget.draft.setNote(id, value),
                  ),
              ],
            )));
  }
}
