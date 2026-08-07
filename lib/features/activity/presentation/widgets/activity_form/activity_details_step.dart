import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_form_header.dart';

class ActivityDetailsStep extends StatelessWidget {
  const ActivityDetailsStep({
    required this.draft,
    required this.selectedPersonnel,
    required this.squadNames,
    required this.activityNameController,
    required this.activityTemplates,
    required this.availableDuties,
    required this.showNameError,
    required this.onPickDate,
    required this.onActivityChanged,
    required this.onActivityTemplateSelected,
    required this.onCommonDutyChanged,
    required this.onDutyOverrideChanged,
    required this.onSquadDutyChanged,
    required this.onNoteChanged,
    required this.onRemovePersonnel,
    required this.onEditPersonnel,
    super.key,
  });

  final ActivityFormDraft draft;
  final List<PersonelTableData> selectedPersonnel;
  final Map<int, String> squadNames;
  final TextEditingController activityNameController;
  final List<String> activityTemplates;
  final List<String> availableDuties;
  final bool showNameError;
  final VoidCallback onPickDate;
  final ValueChanged<String> onActivityChanged;
  final ValueChanged<String> onActivityTemplateSelected;
  final ValueChanged<String> onCommonDutyChanged;
  final void Function(int personnelId, String? duty) onDutyOverrideChanged;
  final void Function(Iterable<int> personnelIds, String? duty)
      onSquadDutyChanged;
  final void Function(int personnelId, String? note) onNoteChanged;
  final ValueChanged<int> onRemovePersonnel;
  final VoidCallback onEditPersonnel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('activity-details-step'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        ActivityFormHeader(
          selectedDate: draft.selectedDate,
          onPickDate: onPickDate,
          activityNameController: activityNameController,
          showNameError: showNameError,
          onNameChanged: onActivityChanged,
          templates: activityTemplates,
          onTemplateSelected: onActivityTemplateSelected,
        ),
        const SizedBox(height: 14),
        _ActionCard(
          key: const Key('common-duty-field'),
          icon: Icons.assignment_ind_outlined,
          label: 'Ortak Görev',
          value: draft.commonDuty.isEmpty
              ? 'Seçilen personele görev ata'
              : draft.commonDuty,
          onTap: () async {
            final duty = await _showDutyPicker(
              context,
              title: 'Ortak görev seç',
              duties: availableDuties,
              keyPrefix: 'common-duty',
            );
            if (duty != null) onCommonDutyChanged(duty);
          },
        ),
        const SizedBox(height: 14),
        _SelectedPersonnelCard(
          personnel: selectedPersonnel,
          squadNames: squadNames,
          draft: draft,
          onRemovePersonnel: onRemovePersonnel,
          onEditPersonnel: onEditPersonnel,
          onEditAssignment: (person) =>
              _editPersonnelAssignment(context, person),
          onAssignSquad: (squadName, personnel) =>
              _assignSquadDuty(context, squadName, personnel),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.accentSubtleBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: context.accentOrOlive),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Bilgileri kontrol ettikten sonra görevlendirme önizlemesine geçebilirsiniz.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _assignSquadDuty(
    BuildContext context,
    String squadName,
    List<PersonelTableData> personnel,
  ) async {
    final duty = await _showDutyPicker(
      context,
      title: '$squadName timine görev ata',
      duties: availableDuties,
      keyPrefix: 'squad-duty-$squadName',
      inheritLabel: draft.commonDuty.isEmpty ? null : 'Ortak görevi kullan',
    );
    if (duty == _inheritDutyValue) {
      onSquadDutyChanged(personnel.map((person) => person.id), null);
    } else if (duty != null) {
      onSquadDutyChanged(personnel.map((person) => person.id), duty);
    }
  }

  Future<void> _editPersonnelAssignment(
    BuildContext context,
    PersonelTableData person,
  ) async {
    final action = await showModalBottomSheet<_PersonnelEditAction>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              person.adSoyad,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(person.rutbe, style: sheetContext.textStyleSecondary),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Farklı görev seç'),
              subtitle: Text(draft.dutyFor(person.id) ?? 'Görev seçilmedi'),
              onTap: () => Navigator.pop(
                sheetContext,
                _PersonnelEditAction.duty,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notes_rounded),
              title: const Text('Not ekle veya düzenle'),
              subtitle: Text(draft.notes[person.id] ?? 'Not yok'),
              onTap: () => Navigator.pop(
                sheetContext,
                _PersonnelEditAction.note,
              ),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == _PersonnelEditAction.duty) {
      final duty = await _showDutyPicker(
        context,
        title: '${person.adSoyad} için görev',
        duties: availableDuties,
        keyPrefix: 'personnel-duty-${person.id}',
        inheritLabel: draft.commonDuty.isEmpty ? null : 'Ortak görevi kullan',
      );
      if (duty == _inheritDutyValue) {
        onDutyOverrideChanged(person.id, null);
      } else if (duty != null) {
        onDutyOverrideChanged(person.id, duty);
      }
      return;
    }

    var noteValue = draft.notes[person.id] ?? '';
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${person.adSoyad} için not'),
        content: TextFormField(
          key: ValueKey('personnel-note-${person.id}'),
          initialValue: noteValue,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'İsteğe bağlı not'),
          onChanged: (value) => noteValue = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, noteValue),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    if (note != null) onNoteChanged(person.id, note);
  }
}

enum _PersonnelEditAction { duty, note }

const _inheritDutyValue = '__inherit_common_duty__';

Future<String?> _showDutyPicker(
  BuildContext context, {
  required String title,
  required List<String> duties,
  required String keyPrefix,
  String? inheritLabel,
}) {
  final content = _DutyPickerContent(
    title: title,
    duties: duties,
    keyPrefix: keyPrefix,
    inheritLabel: inheritLabel,
  );
  if (MediaQuery.sizeOf(context).width < AppBreakpoints.mobile) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: .78, child: content),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
        child: content,
      ),
    ),
  );
}

class _DutyPickerContent extends StatelessWidget {
  const _DutyPickerContent({
    required this.title,
    required this.duties,
    required this.keyPrefix,
    required this.inheritLabel,
  });

  final String title;
  final List<String> duties;
  final String keyPrefix;
  final String? inheritLabel;

  @override
  Widget build(BuildContext context) {
    final itemCount = duties.length + (inheritLabel == null ? 0 : 1);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final isInherit = inheritLabel != null && index == 0;
                  final duty = isInherit
                      ? _inheritDutyValue
                      : duties[index - (inheritLabel == null ? 0 : 1)];
                  return ListTile(
                    key: ValueKey('$keyPrefix-$duty'),
                    leading: Icon(
                      isInherit
                          ? Icons.refresh_rounded
                          : Icons.assignment_ind_outlined,
                      color: context.accentOrOlive,
                    ),
                    title: Text(isInherit ? inheritLabel! : duty),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, duty),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.accentSubtleBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: context.accentOrOlive),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.textStyleSecondary),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedPersonnelCard extends StatelessWidget {
  const _SelectedPersonnelCard({
    required this.personnel,
    required this.squadNames,
    required this.draft,
    required this.onRemovePersonnel,
    required this.onEditPersonnel,
    required this.onEditAssignment,
    required this.onAssignSquad,
  });

  final List<PersonelTableData> personnel;
  final Map<int, String> squadNames;
  final ActivityFormDraft draft;
  final ValueChanged<int> onRemovePersonnel;
  final VoidCallback onEditPersonnel;
  final ValueChanged<PersonelTableData> onEditAssignment;
  final void Function(String squadName, List<PersonelTableData> personnel)
      onAssignSquad;

  @override
  Widget build(BuildContext context) {
    final grouped = <int?, List<PersonelTableData>>{};
    for (final person in personnel) {
      grouped.putIfAbsent(person.timId, () => []).add(person);
    }
    final groupIds = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final nameA = squadNames[a] ?? '';
        final nameB = squadNames[b] ?? '';
        final weightA = MilitaryStructureHelper.getSquadOrderWeight(nameA);
        final weightB = MilitaryStructureHelper.getSquadOrderWeight(nameB);
        return weightA != weightB
            ? weightA.compareTo(weightB)
            : nameA.compareTo(nameB);
      });

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.accentOrOlive,
                  foregroundColor: context.onAccentOrOlive,
                  child: const Icon(Icons.groups_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${personnel.length} personel seçildi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('edit-personnel-selection'),
                  onPressed: onEditPersonnel,
                  child: const Text('Düzenle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final timId in groupIds)
              _SelectedSquadGroup(
                squadName: timId == null
                    ? 'Timsiz / Diğer Personeller'
                    : (squadNames[timId] ?? 'Bilinmeyen Tim'),
                personnel: grouped[timId]!,
                draft: draft,
                onRemovePersonnel: onRemovePersonnel,
                onEditAssignment: onEditAssignment,
                onAssignDuty: () => onAssignSquad(
                  timId == null
                      ? 'Timsiz / Diğer Personeller'
                      : (squadNames[timId] ?? 'Bilinmeyen Tim'),
                  grouped[timId]!,
                ),
              ),
            if (personnel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Bir personele farklı görev veya not vermek için adına dokunun.',
                style: context.textStyleSecondary.copyWith(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedSquadGroup extends StatelessWidget {
  const _SelectedSquadGroup({
    required this.squadName,
    required this.personnel,
    required this.draft,
    required this.onRemovePersonnel,
    required this.onEditAssignment,
    required this.onAssignDuty,
  });

  final String squadName;
  final List<PersonelTableData> personnel;
  final ActivityFormDraft draft;
  final ValueChanged<int> onRemovePersonnel;
  final ValueChanged<PersonelTableData> onEditAssignment;
  final VoidCallback onAssignDuty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.accentSubtleBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: ExpansionTile(
        key: ValueKey('selected-squad-group-$squadName'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(Icons.groups_rounded, color: context.accentOrOlive),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 190;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    squadName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    compact
                        ? '${personnel.length}'
                        : '${personnel.length} personel',
                    style: TextStyle(
                      color: context.accentOrOlive,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('assign-squad-duty-$squadName'),
                  tooltip: '$squadName timine toplu görev ata',
                  visualDensity: VisualDensity.compact,
                  onPressed: onAssignDuty,
                  icon: const Icon(Icons.assignment_ind_outlined, size: 20),
                ),
              ],
            );
          },
        ),
        children: [
          DecoratedBox(
            key: ValueKey('selected-squad-list-$squadName'),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var index = 0; index < personnel.length; index++) ...[
                  _CompactPersonnelRow(
                    person: personnel[index],
                    draft: draft,
                    onRemove: () => onRemovePersonnel(personnel[index].id),
                    onTap: () => onEditAssignment(personnel[index]),
                  ),
                  if (index != personnel.length - 1)
                    Divider(
                      height: 1,
                      indent: 12,
                      endIndent: 8,
                      color: context.cardBorderColor,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPersonnelRow extends StatelessWidget {
  const _CompactPersonnelRow({
    required this.person,
    required this.draft,
    required this.onRemove,
    required this.onTap,
  });

  final PersonelTableData person;
  final ActivityFormDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duty = draft.dutyOverrides[person.id];
    final note = draft.notes[person.id];
    final detail = duty ?? (note != null ? 'Not eklendi' : null);

    return Semantics(
      button: true,
      label: '${person.adSoyad} görevini düzenle',
      child: InkWell(
        key: ValueKey('selected-personnel-${person.id}'),
        borderRadius: BorderRadius.circular(10),
        overlayColor: WidgetStatePropertyAll(
          context.accentSubtleBg.withValues(alpha: .65),
        ),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 2),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.adSoyad,
                          key: ValueKey('selected-personnel-name-${person.id}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [person.rutbe, if (detail != null) detail]
                              .join('  •  '),
                          key: ValueKey('selected-personnel-rank-${person.id}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyleSecondary.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  key: ValueKey('edit-personnel-${person.id}'),
                  tooltip: '${person.adSoyad} görevini düzenle',
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onTap,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  tooltip: '${person.adSoyad} seçimini kaldır',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 19),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
