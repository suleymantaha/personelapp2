import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

/// Dialog to add a single personnel to an existing activity
class AddPersonnelToActivityDialog extends ConsumerStatefulWidget {
  const AddPersonnelToActivityDialog({
    required this.activity,
    required this.isAdmin,
    required this.existingPersonnelIds,
    super.key,
  });

  final GunlukFaaliyetTableData activity;
  final bool isAdmin;
  final Set<int> existingPersonnelIds;

  @override
  ConsumerState<AddPersonnelToActivityDialog> createState() =>
      _AddPersonnelToActivityDialogState();
}

class _AddPersonnelToActivityDialogState
    extends ConsumerState<AddPersonnelToActivityDialog> {
  int? _selectedPersonnelId;
  String _selectedDuty = DutyOrLeaveType.gorevli;
  final _noteController = TextEditingController();

  static const List<String> availableDuties = [
    DutyOrLeaveType.heybetKomutani,
    DutyOrLeaveType.nobSb,
    DutyOrLeaveType.mebsNob,
    DutyOrLeaveType.garajNob,
    DutyOrLeaveType.ttzaNob,
    DutyOrLeaveType.kuleNob,
    DutyOrLeaveType.hazirKita,
    DutyOrLeaveType.guluskur,
    DutyOrLeaveType.heybet,
    DutyOrLeaveType.gorevli,
    DutyOrLeaveType.nobetci,
    DutyOrLeaveType.izinli,
    DutyOrLeaveType.istirahatli,
    DutyOrLeaveType.raporlu,
    DutyOrLeaveType.sevk,
    DutyOrLeaveType.diger,
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPersonnelAsync = ref.watch(allPersonnelProvider);
    final session = ref.watch(userSessionProvider);

    final allPersonnel = allPersonnelAsync.value ?? [];
    // Filter out personnel already in this activity
    var candidatePersonnel = allPersonnel
        .where((p) => !widget.existingPersonnelIds.contains(p.id))
        .toList();

    // If Tim Komutanı, filter personnel by squad
    if (!widget.isAdmin && session?.timId != null) {
      candidatePersonnel = candidatePersonnel
          .where((p) => p.timId == session!.timId)
          .toList();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.person_add_alt_1, color: context.accentOrOlive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.activity.faaliyetAdi} - Personel Ekle',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (candidatePersonnel.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Eklenebilecek personel bulunamadı (Tüm personel eklenmiş olabilir).',
                  style: TextStyle(color: context.textSecondary),
                ),
              )
            else ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedPersonnelId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Personel Seçiniz',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: candidatePersonnel.map((p) {
                  return DropdownMenuItem<int>(
                    value: p.id,
                    child: Text('${p.rutbe} ${p.adSoyad} (${p.birlik})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPersonnelId = val),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedDuty,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Görev / İzin Türü',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: availableDuties.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDuty = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Açıklama / Not (İsteğe Bağlı)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('İPTAL'),
        ),
        if (candidatePersonnel.isNotEmpty)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentOrOlive,
              foregroundColor: context.onAccentOrOlive,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _selectedPersonnelId == null
                ? null
                : () async {
                    final repo = ref.read(activityRepositoryProvider);
                    final note = _noteController.text.trim();
                    await repo.addSingleAssignment(
                      faaliyetId: widget.activity.id,
                      personelId: _selectedPersonnelId!,
                      gorevVeyaIzin: _selectedDuty,
                      aciklama: note.isNotEmpty ? note : null,
                      tarih: widget.activity.tarih,
                      isCommander: !widget.isAdmin,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
            child: const Text('EKLE'),
          ),
      ],
    );
  }
}
