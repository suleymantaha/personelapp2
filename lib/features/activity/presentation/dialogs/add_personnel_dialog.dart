import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/activity_assignment_details_editor.dart';
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

  void _select(PersonelTableData person) {
    setState(() => _draft.togglePersonnel(person.id));
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
    final assignments = _draft.resolvedPersonnelAssignments;
    setState(() => _saving = true);
    try {
      final result =
          await ref.read(activityRepositoryProvider).addAssignmentsToActivity(
                activityId: widget.activity.id,
                assignments: assignments,
                actor: actor,
              );
      if (!mounted) return;
      if (result.alreadyAssignedCount + result.conflictSkippedCount > 0) {
        await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
                  title: const Text('Ekleme sonucu'),
                  content: Text(
                      '${result.addedCount} personel eklendi.\n${result.alreadyAssignedCount} personel zaten kayıtlı.\n${result.conflictSkippedCount} personel çakışma nedeniyle eklenemedi.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Tamam'))
                  ],
                ));
      }
      if (mounted) Navigator.of(context).pop(result.addedCount > 0);
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
                      child: _details && selected.isNotEmpty
                          ? ActivityAssignmentDetailsEditor(
                              people: selected,
                              squadNames: {
                                for (final squad in squads)
                                  squad.id: squad.timAdi
                              },
                              draft: _draft,
                              duties: duties,
                              isAdmin: widget.isAdmin,
                              onChangePerson: _back,
                              onChanged: () => setState(() {}),
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
                                  selectedPersonnelIds:
                                      _draft.selectedPersonnelIds,
                                  onToggleSquad: (ids) =>
                                      setState(() => _draft.toggleSquad(ids)),
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
                        onPressed: _saving || selected.isEmpty
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
