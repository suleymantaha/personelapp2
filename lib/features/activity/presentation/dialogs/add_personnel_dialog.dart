import 'package:personelapp2/core/widgets/confirm_discard_changes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/activity_assignment_details_editor.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/personnel_picker_sheet.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';

const List<String> kActivityAssignmentDuties = DutyOrLeaveType.allDuties;
final Set<String> kActivityAdminOnlyDuties =
    DutyOrLeaveType.adminOnlyDuties.toSet();

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
  bool _allowExit = false;
  bool _confirming = false;

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

  Future<void> _back() async {
    if (_saving || _confirming) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_details) {
      setState(() => _details = false);
      return;
    }
    await _close();
  }

  Future<void> _close() async {
    if (_saving || _confirming) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _confirming = true;
    try {
      if (_draft.selectedPersonnelIds.isNotEmpty &&
          !await confirmDiscardChanges(context)) {
        return;
      }
      await _leave(false);
    } finally {
      _confirming = false;
    }
  }

  Future<void> _leave(bool result) async {
    if (!mounted) return;
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _save() async {
    if (_saving || !_draft.canPreview) return;
    final actor = ref.read(userSessionProvider);
    if (actor == null) return;
    final assignments = _draft.resolvedPersonnelAssignments;
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(activityRepositoryProvider)
          .addAssignmentsToActivity(
            activityId: widget.activity.id,
            assignments: assignments,
            actor: actor,
          );
      if (!mounted) return;
      if (result.alreadyAssignedCount + result.conflictSkippedCount > 0) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(dialogContext.l10n.addPersonnelResultTitle),
            content: Text(
              dialogContext.l10n.addPersonnelResultContent(
                result.addedCount,
                result.alreadyAssignedCount,
                result.conflictSkippedCount,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogContext.l10n.commonOk),
              ),
            ],
          ),
        );
      }
      await _leave(result.addedCount > 0);
    } on AssignmentConflictException catch (error) {
      if (mounted) AppNotifications.error(error.message);
    } catch (error) {
      if (mounted) AppNotifications.error(context.l10n.addPersonnelFailed('$error'));
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
        .where(
          (p) =>
              (widget.isAdmin ||
              (session?.timId != null && p.timId == session!.timId)),
        )
        .toList();
    final squads = (squadsAsync.value ?? <TimTableData>[])
        .where((s) => widget.isAdmin || s.id == session?.timId)
        .toList();
    final selected = people
        .where((p) => _draft.selectedPersonnelIds.contains(p.id))
        .toList();
    final duties = DutyOrLeaveType.dutiesForRole(isAdmin: widget.isAdmin);
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope<bool>(
      canPop:
          _allowExit ||
          (!_saving && !_details && _draft.selectedPersonnelIds.isEmpty),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: context.l10n.commonBack,
            onPressed: _saving ? null : _back,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.addPersonnelDialogTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${widget.activity.faaliyetAdi} · ${DateFormat.yMMMMd('tr_TR').format(DateTime.parse(widget.activity.tarih))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).appBarTheme.foregroundColor ??
                      colorScheme.onSurface,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.commonClose,
              onPressed: _saving ? null : _close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _details ? Icons.check_circle : Icons.looks_one,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(context.l10n.addPersonnelStepPersonnel),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(),
                          ),
                        ),
                        Icon(
                          Icons.looks_two,
                          color: _details
                              ? colorScheme.primary
                              : colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(context.l10n.addPersonnelStepDuty),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _saving,
                      child: _details && selected.isNotEmpty
                          ? ActivityAssignmentDetailsEditor(
                              people: selected,
                              squadNames: {
                                for (final squad in squads)
                                  squad.id: squad.timAdi,
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
                                  return Center(
                                    child: Text(
                                      context.l10n.addPersonnelLoadError,
                                    ),
                                  );
                                }
                                if (peopleAsync.isLoading ||
                                    squadsAsync.isLoading ||
                                    !snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (people.isEmpty) {
                                  return Center(
                                    child: Text(
                                      context.l10n.addPersonnelNoAvailable,
                                    ),
                                  );
                                }
                                return PersonnelPickerSheet(
                                  personnel: people,
                                  squads: squads,
                                  selectedPersonnelIds:
                                      _draft.selectedPersonnelIds,
                                  onToggleSquad: (ids) =>
                                      setState(() => _draft.toggleSquad(ids)),
                                  preferredTimId: widget.isAdmin
                                      ? null
                                      : session?.timId,
                                  disabledReasons: {
                                    ...snapshot.data!,
                                    for (final id
                                        in widget.existingPersonnelIds)
                                      id: context.l10n.addPersonnelAlreadyRegistered,
                                  },
                                  onSelected: _select,
                                );
                              },
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_details) ...[
                          Text(context.l10n.addPersonnelSelectedCount(selected.length)),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            if (_details) ...[
                              OutlinedButton(
                                onPressed: _saving ? null : _back,
                                child: Text(context.l10n.commonBack),
                              ),
                              const SizedBox(width: 12),
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
                                child: Text(
                                  _saving
                                      ? context.l10n.commonSaving
                                      : _details
                                      ? context.l10n.addPersonnelAddToActivity
                                      : context.l10n.addPersonnelContinue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
