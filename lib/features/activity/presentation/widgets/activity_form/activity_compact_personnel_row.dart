import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';

class ActivityCompactPersonnelRow extends StatelessWidget {
  const ActivityCompactPersonnelRow({
    required this.person,
    required this.draft,
    required this.onRemove,
    required this.onTap,
    super.key,
  });

  final PersonelTableData person;
  final ActivityFormDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duty = draft.dutyOverrides[person.id];
    final note = draft.notes[person.id];
    final detail = duty ?? (note != null ? context.l10n.activityNoteAdded : null);

    return Semantics(
      button: true,
      label: context.l10n.activityFormEditDutyLabel(person.adSoyad),
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
                  tooltip: context.l10n.activityFormEditDutyLabel(person.adSoyad),
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
                  tooltip: context.l10n.activityFormRemoveSelectionTooltip(person.adSoyad),
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
