import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_details_step.dart';

const List<String> kActivityAssignmentDuties = [
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

const Set<String> kActivityAdminOnlyDuties = {
  DutyOrLeaveType.heybetKomutani,
  DutyOrLeaveType.nobSb,
  DutyOrLeaveType.mebsNob,
  DutyOrLeaveType.garajNob,
  DutyOrLeaveType.ttzaNob,
  DutyOrLeaveType.kuleNob,
};

/// A route-local single-person draft using the schedule's assignment editor.
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
  late final ActivityFormDraft _draft;
  late final TextEditingController _nameController;
  late final Future<Map<int, String>> _reservations;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft =
        ActivityFormDraft(initialDate: DateTime.parse(widget.activity.tarih))
          ..setActivityName(widget.activity.faaliyetAdi)
          ..setCommonDuty(DutyOrLeaveType.gorevli);
    _nameController = TextEditingController(text: widget.activity.faaliyetAdi);
    _reservations = ref
        .read(activityRepositoryProvider)
        .getDailyReservationDescriptions(widget.activity.tarih);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPersonnel(
      List<PersonelTableData> people, List<TimTableData> squads) async {
    final reservations = await _reservations;
    if (!mounted) return;
    final selected = await showPersonnelPicker(
      context: context,
      personnel: people,
      squads: squads,
      selectedPersonnelId: _draft.selectedPersonnelIds.firstOrNull,
      preferredTimId:
          widget.isAdmin ? null : ref.read(userSessionProvider)?.timId,
      disabledReasons: reservations,
    );
    if (!mounted || selected == null) return;
    setState(() {
      for (final id in _draft.selectedPersonnelIds.toList()) {
        if (id != selected.id) _draft.togglePersonnel(id);
      }
      if (!_draft.selectedPersonnelIds.contains(selected.id)) {
        _draft.togglePersonnel(selected.id);
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_draft.canPreview) return;
    final actor = ref.read(userSessionProvider);
    if (actor == null) return;
    final assignment = _draft.resolvedPersonnelAssignments.single;
    setState(() => _saving = true);
    try {
      await ref.read(activityRepositoryProvider).addSingleAssignment(
            faaliyetId: widget.activity.id,
            personelId: assignment.personnelId,
            gorevVeyaIzin: assignment.duty,
            aciklama: assignment.note,
            tarih: widget.activity.tarih,
            actor: actor,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AssignmentConflictException catch (error) {
      if (mounted) AppNotifications.error(error.message);
    } catch (error) {
      if (mounted) AppNotifications.error('Personel eklenemedi: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final peopleAsync = ref.watch(allPersonnelProvider);
    final squadsAsync = ref.watch(allSquadsProvider);
    final people = (peopleAsync.value ?? <PersonelTableData>[])
        .where((p) =>
            !widget.existingPersonnelIds.contains(p.id) &&
            (widget.isAdmin ||
                (session?.timId != null && p.timId == session!.timId)))
        .toList();
    final squads = (squadsAsync.value ?? <TimTableData>[])
        .where((s) => widget.isAdmin || s.id == session?.timId)
        .toList();
    final selected = people
        .where((p) => _draft.selectedPersonnelIds.contains(p.id))
        .toList();
    final duties = widget.isAdmin
        ? kActivityAssignmentDuties
        : kActivityAssignmentDuties
            .where((duty) => !kActivityAdminOnlyDuties.contains(duty))
            .toList(growable: false);
    void change(VoidCallback action) {
      if (mounted) setState(action);
    }

    void pick() {
      _pickPersonnel(people, squads);
    }

    return AlertDialog(
      title: Text('${widget.activity.faaliyetAdi} - Personel Ekle'),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 680,
        height: MediaQuery.sizeOf(context).height * .65,
        child: AbsorbPointer(
          absorbing: _saving,
          child: ActivityDetailsStep(
            draft: _draft,
            selectedPersonnel: selected,
            squadNames: {for (final s in squads) s.id: s.timAdi},
            activityNameController: _nameController,
            activityTemplates: const [],
            availableDuties: duties,
            showNameError: false,
            onPickDate: () {},
            onActivityChanged: (_) {},
            onActivityTemplateSelected: (_) {},
            showPreviewHint: false,
            header:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.activity.faaliyetAdi} • ${widget.activity.tarih}'),
              const SizedBox(height: 12),
              if (peopleAsync.isLoading || squadsAsync.isLoading)
                const LinearProgressIndicator()
              else if (peopleAsync.hasError || squadsAsync.hasError)
                const Text('Personel bilgileri yüklenemedi.')
              else if (people.isEmpty)
                const Text('Eklenebilecek personel bulunamadı.')
              else
                OutlinedButton.icon(
                    onPressed: pick,
                    icon: const Icon(Icons.person_search),
                    label: const Text('Personel Seçiniz')),
            ]),
            onCommonDutyChanged: (duty) =>
                change(() => _draft.setCommonDuty(duty)),
            onDutyOverrideChanged: (id, duty) =>
                change(() => _draft.setDutyOverride(id, duty)),
            onSquadDutyChanged: (ids, duty) =>
                change(() => _draft.setDutyForPersonnel(ids, duty)),
            onNoteChanged: (id, note) => change(() => _draft.setNote(id, note)),
            onRemovePersonnel: (id) => change(() => _draft.togglePersonnel(id)),
            onEditPersonnel: pick,
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('İPTAL')),
        FilledButton(
            onPressed: !_saving && selected.length == 1 && _draft.canPreview
                ? _save
                : null,
            child: Text(_saving ? 'KAYDEDİLİYOR…' : 'EKLE')),
      ],
    );
  }
}
