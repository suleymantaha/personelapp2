import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';

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
  static const List<String> _adminOnlyDuties = [
    DutyOrLeaveType.heybetKomutani,
    DutyOrLeaveType.nobSb,
    DutyOrLeaveType.mebsNob,
    DutyOrLeaveType.garajNob,
    DutyOrLeaveType.ttzaNob,
    DutyOrLeaveType.kuleNob,
  ];

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
    final allSquadsAsync = ref.watch(allSquadsProvider);
    final session = ref.watch(userSessionProvider);

    final allPersonnel = allPersonnelAsync.value ?? [];
    final allSquads = allSquadsAsync.value ?? [];
    // Filter out personnel already in this activity
    var candidatePersonnel = allPersonnel
        .where((p) => !widget.existingPersonnelIds.contains(p.id))
        .toList();

    // If Tim Komutanı, filter personnel by squad
    if (!widget.isAdmin) {
      if (session?.timId == null) {
        candidatePersonnel = <PersonelTableData>[];
      } else {
        candidatePersonnel =
            candidatePersonnel.where((p) => p.timId == session!.timId).toList();
      }
    }

    final filteredDuties = widget.isAdmin
        ? availableDuties
        : availableDuties
            .where((duty) => !_adminOnlyDuties.contains(duty))
            .toList(growable: false);

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
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final selected = await showPersonnelPicker(
                    context: context,
                    personnel: candidatePersonnel,
                    squads: widget.isAdmin
                        ? allSquads
                        : allSquads
                            .where((squad) => squad.id == session?.timId)
                            .toList(),
                    selectedPersonnelId: _selectedPersonnelId,
                    preferredTimId: widget.isAdmin ? null : session?.timId,
                  );
                  if (selected != null && mounted) {
                    setState(() => _selectedPersonnelId = selected.id);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Personel Seçiniz',
                    suffixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      final selected = candidatePersonnel
                          .where((p) => p.id == _selectedPersonnelId)
                          .firstOrNull;
                      if (selected == null) {
                        return Text(
                          'İsim veya tim ile personel bulun',
                          style: TextStyle(color: context.textSecondary),
                        );
                      }
                      final squadName = allSquads
                          .where((s) => s.id == selected.timId)
                          .map((s) => s.timAdi)
                          .firstOrNull;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selected.rutbe} ${selected.adSoyad}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${selected.rutbe} • ${squadName ?? 'Tim Dışı'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
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
                items: filteredDuties.map((d) {
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
                    final actor = ref.read(userSessionProvider);
                    if (actor == null) return;
                    final note = _noteController.text.trim();
                    await repo.addSingleAssignment(
                      faaliyetId: widget.activity.id,
                      personelId: _selectedPersonnelId!,
                      gorevVeyaIzin: _selectedDuty,
                      aciklama: note.isNotEmpty ? note : null,
                      tarih: widget.activity.tarih,
                      actor: actor,
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
