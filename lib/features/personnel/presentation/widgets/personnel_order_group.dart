import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:personelapp2/core/database/database.dart';

class PersonnelOrderGroup extends StatelessWidget {
  const PersonnelOrderGroup(
      {super.key,
      required this.teamId,
      required this.name,
      required this.people,
      required this.expanded,
      required this.teamIndex,
      required this.enabled,
      required this.onToggle,
      required this.onReorder,
      this.onDragChanged});
  final int? teamId;
  final String name;
  final List<PersonelTableData> people;
  final bool expanded, enabled;
  final int? teamIndex;
  final VoidCallback onToggle;
  final ValueChanged<bool>? onDragChanged;
  final void Function(int, int) onReorder;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(14)),
        child: Material(
            type: MaterialType.transparency,
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: ListTile(
                        key: ValueKey('order-team-$teamId'),
                        onTap: enabled ? onToggle : null,
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${people.length} personel'),
                        trailing: Icon(
                            expanded ? Icons.expand_less : Icons.expand_more))),
                if (teamIndex != null)
                  ReorderableDragStartListener(
                      index: teamIndex!,
                      enabled: enabled,
                      child: Semantics(
                          label: '$name timini sırala',
                          child: Padding(
                              key: ValueKey('order-team-handle-$teamId'),
                              padding: const EdgeInsets.all(14),
                              child: const Icon(Icons.drag_indicator)))),
              ]),
              if (expanded && people.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Bu timde personel yok.')),
              if (expanded && people.isNotEmpty)
                ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: people.length,
                    onReorderItem: onReorder,
                    onReorderStart: (_) => onDragChanged?.call(true),
                    onReorderEnd: (_) => onDragChanged?.call(false),
                    itemBuilder: (context, index) {
                      final person = people[index];
                      return Semantics(
                          key: ValueKey('order-person-${person.id}'),
                          customSemanticsActions: {
                            if (enabled && index > 0)
                              const CustomSemanticsAction(label: 'Yukarı taşı'):
                                  () => onReorder(index, index - 1),
                            if (enabled && index < people.length - 1)
                              const CustomSemanticsAction(label: 'Aşağı taşı'):
                                  () => onReorder(index, index + 1),
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: theme
                                              .colorScheme.outlineVariant
                                              .withValues(alpha: .5)))),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${index + 1}.',
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          person.adSoyad,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.15,
                                          ),
                                          softWrap: true,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          person.rutbe,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ReorderableDragStartListener(
                                    index: index,
                                    enabled: enabled,
                                    child: Semantics(
                                        label:
                                            '${person.adSoyad} sırasını değiştir',
                                        child: Padding(
                                            key: ValueKey(
                                                'order-person-handle-${person.id}'),
                                            padding: const EdgeInsets.all(14),
                                            child: const Icon(
                                                Icons.drag_indicator)))),
                              ])));
                    }),
            ])));
  }
}
