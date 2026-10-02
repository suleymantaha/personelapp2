import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import '../view_models/activity_form_draft.dart';

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
                child: Text('${people.length} personel seçildi',
                    style: Theme.of(context).textTheme.titleMedium)),
            TextButton(onPressed: onChangePerson, child: const Text('Değiştir'))
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: draft.commonDuty,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Ortak görev',
                helperText: 'Tüm seçilen personele uygular'),
            items: duties
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (value) {
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
                teamName: squadNames[person.timId] ?? 'Tim Dışı',
                draft: draft,
                duties: duties,
                showDuty: people.length > 1 ||
                    draft.dutyOverrides.containsKey(person.id),
                onChanged: onChanged),
          const SizedBox(height: 12),
          Text(isAdmin
              ? 'Seçilen personel bu faaliyete eklenecek.'
              : 'Personel eklendikten sonra admin onayına gönderilecek.'),
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
    final duty = widget.draft.dutyFor(id)!;
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
                  DropdownButtonFormField<String>(
                    key: Key('assignment-duty-$id-$duty'),
                    initialValue: duty,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Kişiye özel görev'),
                    items: widget.duties
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) {
                      widget.draft.setDutyOverride(id, value);
                      widget.onChanged();
                    },
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
                      ? 'Notu kapat'
                      : note.isEmpty
                          ? 'Not ekle'
                          : 'Notu düzenle'),
                ),
                if (_noteOpen)
                  TextFormField(
                    key: Key('assignment-note-$id'),
                    initialValue: note,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'Görevle ilgili not',
                        border: OutlineInputBorder()),
                    onChanged: (value) => widget.draft.setNote(id, value),
                  ),
              ],
            )));
  }
}
