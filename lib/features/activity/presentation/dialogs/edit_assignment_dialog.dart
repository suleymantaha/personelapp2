import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import '../widgets/activity_form/activity_duty_picker.dart';

/// Shows duty and note editor as a bottom sheet on mobile, or dialog on wide screens
Future<bool?> showEditAssignmentModal({
  required BuildContext context,
  required FaaliyetPersonelAtamaTableData assignment,
  required String personnelName,
  required bool isAdmin,
}) {
  if (MediaQuery.sizeOf(context).width < AppBreakpoints.mobile) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => _EditAssignmentSheet(
        assignment: assignment,
        personnelName: personnelName,
        isAdmin: isAdmin,
      ),
    );
  }
  return showDialog<bool>(
    context: context,
    builder: (_) => EditAssignmentDialog(
      assignment: assignment,
      personnelName: personnelName,
      isAdmin: isAdmin,
    ),
  );
}

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
  late String _selectedDuty;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final duties = DutyOrLeaveType.dutiesForRole(isAdmin: widget.isAdmin);
    _selectedDuty = duties.contains(widget.assignment.gorevVeyaIzin)
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
    final filteredDuties =
        DutyOrLeaveType.dutiesForRole(isAdmin: widget.isAdmin);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit_note, color: context.accentOrOlive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.activityDutyChange,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final duty = await showActivityDutyPicker(
                  context,
                  title: '${widget.personnelName} için görev',
                  duties: filteredDuties,
                  keyPrefix: 'edit-assignment-duty',
                  selectedDuty: _selectedDuty,
                );
                if (duty != null && mounted) {
                  setState(() => _selectedDuty = duty);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: context.l10n.activityDutyOrLeaveType,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_ind_outlined,
                      size: 20,
                      color: context.accentOrOlive,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDuty,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: context.l10n.activityDutyNoteOptional,
                hintText: context.l10n.activityDutyNoteHint,
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
          child: Text(context.l10n.commonCancel.toUpperCase()),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.accentOrOlive,
            foregroundColor: context.onAccentOrOlive,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _saveAssignment,
          child: Text(context.l10n.commonSave.toUpperCase()),
        ),
      ],
    );
  }

  Future<void> _saveAssignment() async {
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
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AssignmentConflictException catch (error) {
      if (mounted) {
        AppNotifications.error(error.message);
      }
    }
  }
}

/// Bottom Sheet presentation for mobile devices
class _EditAssignmentSheet extends ConsumerStatefulWidget {
  const _EditAssignmentSheet({
    required this.assignment,
    required this.personnelName,
    required this.isAdmin,
  });

  final FaaliyetPersonelAtamaTableData assignment;
  final String personnelName;
  final bool isAdmin;

  @override
  ConsumerState<_EditAssignmentSheet> createState() =>
      _EditAssignmentSheetState();
}

class _EditAssignmentSheetState extends ConsumerState<_EditAssignmentSheet> {
  late String _selectedDuty;
  late TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final duties = DutyOrLeaveType.dutiesForRole(isAdmin: widget.isAdmin);
    _selectedDuty = duties.contains(widget.assignment.gorevVeyaIzin)
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
    final filteredDuties =
        DutyOrLeaveType.dutiesForRole(isAdmin: widget.isAdmin);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: context.accentOrOlive, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.activityDutyChange,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.personnelName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final duty = await showActivityDutyPicker(
                  context,
                  title: '${widget.personnelName} için görev',
                  duties: filteredDuties,
                  keyPrefix: 'sheet-edit-duty',
                  selectedDuty: _selectedDuty,
                );
                if (duty != null && mounted) {
                  setState(() => _selectedDuty = duty);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: context.l10n.activityDutyOrLeaveType,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_ind_outlined,
                      size: 20,
                      color: context.accentOrOlive,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDuty,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: context.l10n.activityDutyNoteOptional,
                hintText: context.l10n.activityDutyNoteHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(context.l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentOrOlive,
                      foregroundColor: context.onAccentOrOlive,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            context.l10n.commonSave,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAssignment() async {
    final actor = ref.read(userSessionProvider);
    if (actor == null) return;
    final repo = ref.read(activityRepositoryProvider);
    final note = _noteController.text.trim();
    final newStatus = widget.isAdmin
        ? AssignmentStatus.onaylandi
        : AssignmentStatus.beklemede;
    setState(() => _saving = true);
    try {
      await repo.updateAssignmentDetails(
        assignmentId: widget.assignment.id,
        gorevVeyaIzin: _selectedDuty,
        aciklama: note.isNotEmpty ? note : null,
        newStatus: newStatus,
        actor: actor,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AssignmentConflictException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        AppNotifications.error(error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
