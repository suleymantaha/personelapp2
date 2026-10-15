import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_duty_picker.dart';

/// Reassigns a duty to people who already belong to the archived activity.
/// It changes existing assignment rows rather than inserting duplicates.
class ReassignExistingPersonnelDialog extends ConsumerStatefulWidget {
  const ReassignExistingPersonnelDialog({
    required this.activity,
    required this.assignments,
    required this.personnelById,
    super.key,
  });

  final GunlukFaaliyetTableData activity;
  final List<FaaliyetPersonelAtamaTableData> assignments;
  final Map<int, PersonelTableData> personnelById;

  @override
  ConsumerState<ReassignExistingPersonnelDialog> createState() =>
      _ReassignExistingPersonnelDialogState();
}

class _ReassignExistingPersonnelDialogState
    extends ConsumerState<ReassignExistingPersonnelDialog> {
  final Set<int> _selectedIds = <int>{};
  String _duty = DutyOrLeaveType.gorevli;
  bool _saving = false;

  Future<void> _selectDuty() async {
    if (_saving) return;
    final duty = await showActivityDutyPicker(
      context,
      title: context.l10n.activityCommonDuty,
      duties: DutyOrLeaveType.dutiesForRole(isAdmin: true),
      selectedDuty: _duty,
      keyPrefix: 'archive-existing-duty',
    );
    if (mounted && duty != null) setState(() => _duty = duty);
  }

  Future<void> _save() async {
    if (_saving || _selectedIds.isEmpty) return;
    final actor = ref.read(userSessionProvider);
    if (actor == null || !actor.isAdmin) {
      AppNotifications.error('Görev değiştirmek için yönetici yetkisi gerekli.');
      return;
    }

    setState(() => _saving = true);
    try {
      final changed = await ref
          .read(activityRepositoryProvider)
          .updateExistingAssignmentDuties(
            activityId: widget.activity.id,
            assignmentIds: _selectedIds,
            duty: _duty,
            actor: actor,
          );
      if (!mounted) return;
      if (changed == 0) {
        AppNotifications.info('Seçilen personelin görevi zaten aynı.');
        return;
      }
      AppNotifications.success('$changed personelin görevi güncellendi.');
      Navigator.of(context).pop(true);
    } on AssignmentConflictException catch (error) {
      if (mounted) AppNotifications.error(error.localizedMessage(context.l10n));
    } on Object catch (_) {
      if (mounted) {
        AppNotifications.error(
          'Görevler değiştirilemedi. Güncel listeyi açıp tekrar deneyin.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = widget.assignments;
    final allSelected =
        rows.isNotEmpty && rows.every((row) => _selectedIds.contains(row.id));
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Mevcut personele görev ata',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_selectedIds.length} / ${rows.length} personel seçildi',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        TextButton(
                          key: const Key('archive-existing-select-all'),
                          onPressed: _saving || rows.isEmpty
                              ? null
                              : () => setState(() {
                                  if (allSelected) {
                                    _selectedIds.clear();
                                  } else {
                                    _selectedIds.addAll(rows.map((row) => row.id));
                                  }
                                }),
                          child: Text(allSelected ? 'Seçimi kaldır' : 'Tümünü seç'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      key: const Key('archive-existing-personnel-list'),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final person = widget.personnelById[row.personelId];
                        return CheckboxListTile(
                          key: Key('archive-existing-assignment-${row.id}'),
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selectedIds.contains(row.id),
                          onChanged: _saving
                              ? null
                              : (selected) => setState(() {
                                  if (selected == true) {
                                    _selectedIds.add(row.id);
                                  } else {
                                    _selectedIds.remove(row.id);
                                  }
                                }),
                          title: Text(
                            person?.adSoyad ?? 'Personel #${row.personelId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              if (person?.rutbe.isNotEmpty == true) person!.rutbe,
                              row.gorevVeyaIzin,
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: colors.surfaceContainerLow,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('archive-existing-duty-picker'),
                          onPressed: _saving ? null : _selectDuty,
                          icon: const Icon(Icons.assignment_ind_outlined),
                          label: Text('Yeni görev: $_duty'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          key: const Key('archive-existing-save'),
                          onPressed: _saving || _selectedIds.isEmpty ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  '${_selectedIds.length} kişinin görevini güncelle',
                                ),
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
