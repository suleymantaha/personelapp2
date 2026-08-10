import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

/// Dialog to edit an individual personnel's duty and note
class EditAssignmentDialog extends ConsumerStatefulWidget {
  const EditAssignmentDialog({
    required this.assignment,
    required this.personnelName,
    required this.isAdmin,
    super.key,
  });

  final FaaliyetPersonelAtamaTableData assignment;
  final String personnelName;
  final bool isAdmin;

  @override
  ConsumerState<EditAssignmentDialog> createState() =>
      _EditAssignmentDialogState();
}

class _EditAssignmentDialogState extends ConsumerState<EditAssignmentDialog> {
  static const List<String> _adminOnlyDuties = [
    DutyOrLeaveType.heybetKomutani,
    DutyOrLeaveType.nobSb,
    DutyOrLeaveType.mebsNob,
    DutyOrLeaveType.garajNob,
    DutyOrLeaveType.ttzaNob,
    DutyOrLeaveType.kuleNob,
  ];

  late String _selectedDuty;
  late TextEditingController _noteController;

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
  void initState() {
    super.initState();
    _selectedDuty = availableDuties.contains(widget.assignment.gorevVeyaIzin)
        ? widget.assignment.gorevVeyaIzin
        : DutyOrLeaveType.gorevli;
    _noteController = TextEditingController(
      text: widget.assignment.aciklama ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDuties = widget.isAdmin
        ? availableDuties
        : availableDuties
            .where((duty) => !_adminOnlyDuties.contains(duty))
            .toList(growable: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit_note, color: context.accentOrOlive),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Görev Değişikliği',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.personnelName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              menuMaxHeight: modernDropdownMenuMaxHeight(context),
              borderRadius: modernDropdownBorderRadius,
              dropdownColor: modernDropdownColor(context),
              initialValue: _selectedDuty,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Görev / İzin Türü',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
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
                hintText: 'Örn: Gece nöbeti, özel devriye vb.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('İPTAL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.accentOrOlive,
            foregroundColor: context.onAccentOrOlive,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            final actor = ref.read(userSessionProvider);
            if (actor == null) return;
            final repo = ref.read(activityRepositoryProvider);
            final note = _noteController.text.trim();
            final newStatus = widget.isAdmin
                ? AssignmentStatus.onaylandi
                : AssignmentStatus.beklemede;
            try {
              await repo.updateAssignmentDetails(
                assignmentId: widget.assignment.id,
                gorevVeyaIzin: _selectedDuty,
                aciklama: note.isNotEmpty ? note : null,
                newStatus: newStatus,
                actor: actor,
              );
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            } on AssignmentConflictException catch (error) {
              if (context.mounted) {
                AppNotifications.error(error.message);
              }
            }
          },
          child: const Text('KAYDET'),
        ),
      ],
    );
  }
}
