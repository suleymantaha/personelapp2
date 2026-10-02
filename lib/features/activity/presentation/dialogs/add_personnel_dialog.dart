import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/single_assignment_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';

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

/// Full-screen, two-stage editor with a route-local single-person draft.
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
  final _noteController = TextEditingController();
  bool _details = false;
  late final Future<Map<int, String>> _reservations;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft =
        ActivityFormDraft(initialDate: DateTime.parse(widget.activity.tarih))
          ..setActivityName(widget.activity.faaliyetAdi)
          ..setCommonDuty(DutyOrLeaveType.gorevli);

    _reservations = ref
        .read(activityRepositoryProvider)
        .getDailyReservationDescriptions(widget.activity.tarih);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _select(PersonelTableData person) {
    setState(() {
      for (final id in _draft.selectedPersonnelIds.toList()) {
        if (id != person.id) _draft.togglePersonnel(id);
      }
      if (!_draft.selectedPersonnelIds.contains(person.id)) {
        _draft.togglePersonnel(person.id);
        _draft.setNote(person.id, _noteController.text);
      }
    });
  }

  void _back() {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_details) {
      setState(() => _details = false);
    } else {
      Navigator.of(context).pop(false);
    }
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
        .where((p) => (widget.isAdmin ||
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
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope<bool>(
      canPop: !_saving && !_details,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              tooltip: 'Geri',
              onPressed: _saving ? null : _back,
              icon: const Icon(Icons.arrow_back)),
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Personel Ekle',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
                '${widget.activity.faaliyetAdi} · ${DateFormat.yMMMMd('tr_TR').format(DateTime.parse(widget.activity.tarih))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).appBarTheme.foregroundColor ??
                          colorScheme.onSurface,
                    )),
          ]),
          actions: [
            IconButton(
                tooltip: 'Kapat',
                onPressed:
                    _saving ? null : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close))
          ],
        ),
        body: SafeArea(
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(_details ? Icons.check_circle : Icons.looks_one,
                        color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Personel'),
                    const Expanded(
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider())),
                    Icon(Icons.looks_two,
                        color: _details
                            ? colorScheme.primary
                            : colorScheme.outline),
                    const SizedBox(width: 8),
                    const Text('Görev'),
                  ])),
              Expanded(
                  child: AbsorbPointer(
                      absorbing: _saving,
                      child: _details && selected.length == 1
                          ? SingleAssignmentDetails(
                              person: selected.single,
                              teamName: squads
                                      .where(
                                          (s) => s.id == selected.single.timId)
                                      .firstOrNull
                                      ?.timAdi ??
                                  'Tim Dışı',
                              duty: _draft.commonDuty,
                              duties: duties,
                              noteController: _noteController,
                              isAdmin: widget.isAdmin,
                              onChangePerson: _back,
                              onDutyChanged: (value) =>
                                  setState(() => _draft.setCommonDuty(value)),
                              onNoteChanged: (value) =>
                                  _draft.setNote(selected.single.id, value),
                            )
                          : FutureBuilder<Map<int, String>>(
                              future: _reservations,
                              builder: (context, snapshot) {
                                if (peopleAsync.hasError ||
                                    squadsAsync.hasError ||
                                    snapshot.hasError) {
                                  return const Center(
                                      child: Text(
                                          'Personel bilgileri yüklenemedi. Ekranı kapatıp yeniden deneyin.'));
                                }
                                if (peopleAsync.isLoading ||
                                    squadsAsync.isLoading ||
                                    !snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (people.isEmpty) {
                                  return const Center(
                                      child: Text(
                                          'Eklenebilecek personel bulunamadı.'));
                                }
                                return PersonnelPickerSheet(
                                  personnel: people,
                                  squads: squads,
                                  selectedPersonnelId: selected.firstOrNull?.id,
                                  preferredTimId:
                                      widget.isAdmin ? null : session?.timId,
                                  disabledReasons: {
                                    ...snapshot.data!,
                                    for (final id
                                        in widget.existingPersonnelIds)
                                      id: 'Bu faaliyette zaten kayıtlı'
                                  },
                                  onSelected: _select,
                                );
                              },
                            ))),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (!_details) ...[
                      Text('${selected.length} personel seçildi'),
                      const SizedBox(height: 8)
                    ],
                    Row(children: [
                      if (_details) ...[
                        OutlinedButton(
                            onPressed: _saving ? null : _back,
                            child: const Text('Geri')),
                        const SizedBox(width: 12)
                      ],
                      Expanded(
                          child: FilledButton(
                        onPressed: _saving || selected.length != 1
                            ? null
                            : _details
                                ? _save
                                : () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    setState(() => _details = true);
                                  },
                        child: Text(_saving
                            ? 'Kaydediliyor…'
                            : _details
                                ? 'Faaliyete Ekle'
                                : 'Devam et'),
                      )),
                    ]),
                  ])),
            ]),
          )),
        ),
      ),
    );
  }
}
