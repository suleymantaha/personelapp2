import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';

/// Compact assignment fields for the archive's single-person flow.
class SingleAssignmentDetails extends StatelessWidget {
  const SingleAssignmentDetails({
    required this.person,
    required this.teamName,
    required this.duty,
    required this.duties,
    required this.noteController,
    required this.isAdmin,
    required this.onChangePerson,
    required this.onDutyChanged,
    required this.onNoteChanged,
    super.key,
  });

  final PersonelTableData person;
  final String teamName;
  final String duty;
  final List<String> duties;
  final TextEditingController noteController;
  final bool isAdmin;
  final VoidCallback onChangePerson;
  final ValueChanged<String> onDutyChanged;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
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
                              Text(person.adSoyad,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text('${person.rutbe} · $teamName'),
                            ])),
                      ]),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: onChangePerson,
                              child: const Text('Değiştir'))),
                    ],
                  ))),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: duty,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Görev',
                helperText: 'Bu faaliyet için atanacak görev'),
            items: duties
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (value) {
              if (value != null) onDutyChanged(value);
            },
          ),
          const SizedBox(height: 24),
          TextField(
            key: const Key('assignment-note'),
            controller: noteController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                hintText: 'Görevle ilgili açıklama ekleyin',
                border: OutlineInputBorder()),
            onChanged: onNoteChanged,
          ),
          const SizedBox(height: 20),
          Text(isAdmin
              ? 'Seçilen personel bu faaliyete eklenecek.'
              : 'Personel eklendikten sonra admin onayına gönderilecek.'),
        ],
      );
}
