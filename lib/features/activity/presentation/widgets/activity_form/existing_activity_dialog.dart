import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

enum ExistingActivityAction { merge, createNew }

class ExistingActivityChoice {
  const ExistingActivityChoice({
    required this.action,
    this.activityId,
    this.updateDifferentAssignments = false,
  });

  final ExistingActivityAction action;
  final int? activityId;
  final bool updateDifferentAssignments;
}

class ExistingActivityDialog extends StatefulWidget {
  const ExistingActivityDialog({
    required this.matches,
    super.key,
  });

  final List<ExistingActivityMatch> matches;

  static Future<ExistingActivityChoice?> show(
    BuildContext context,
    List<ExistingActivityMatch> matches,
  ) {
    return showDialog<ExistingActivityChoice>(
      context: context,
      builder: (context) => ExistingActivityDialog(matches: matches),
    );
  }

  @override
  State<ExistingActivityDialog> createState() => _ExistingActivityDialogState();
}

class _ExistingActivityDialogState extends State<ExistingActivityDialog> {
  late int _selectedId;
  bool _updateDifferent = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.matches.first.activity.id;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.matches.firstWhere(
      (match) => match.activity.id == _selectedId,
    );

    return AlertDialog(
      title: const Text('Aynı faaliyet zaten var'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selected.activity.tarih} tarihinde '
              '“${selected.activity.faaliyetAdi}” adlı '
              '${widget.matches.length} kayıt bulundu.',
            ),
            const SizedBox(height: 12),
            if (widget.matches.length > 1)
              DropdownButtonFormField<int>(
                initialValue: _selectedId,
                decoration: const InputDecoration(
                  labelText: 'Güncellenecek faaliyet',
                  border: OutlineInputBorder(),
                ),
                items: widget.matches
                    .map(
                      (match) => DropdownMenuItem(
                        value: match.activity.id,
                        child: Text(
                          '#${match.activity.id} • '
                          '${match.activity.faaliyetAdi}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedId = value;
                      _updateDifferent = false;
                    });
                  }
                },
              ),
            if (widget.matches.length > 1) const SizedBox(height: 12),
            Text('${selected.newPersonnelCount} yeni personel eklenecek'),
            Text(
              '${selected.unchangedPersonnelCount} personel zaten kayıtlı',
            ),
            Text(
              '${selected.differentPersonnelCount} personelin '
              'görev/not bilgisi farklı',
            ),
            if (selected.differentPersonnelCount > 0)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _updateDifferent,
                title: const Text(
                  'Farklı görev/not bilgilerini güncelle',
                ),
                subtitle: const Text(
                  'Seçilmezse mevcut bilgiler korunur.',
                ),
                onChanged: (value) => setState(
                  () => _updateDifferent = value ?? false,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İPTAL'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(
            context,
            const ExistingActivityChoice(
              action: ExistingActivityAction.createNew,
            ),
          ),
          child: const Text('YENİ FAALİYET OLUŞTUR'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ExistingActivityChoice(
              action: ExistingActivityAction.merge,
              activityId: _selectedId,
              updateDifferentAssignments: _updateDifferent,
            ),
          ),
          child: const Text('MEVCUDA EKLE'),
        ),
      ],
    );
  }
}
