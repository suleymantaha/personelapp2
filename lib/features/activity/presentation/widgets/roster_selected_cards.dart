import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';

class RosterSelectedCards extends StatelessWidget {
  const RosterSelectedCards({
    super.key,
    required this.title,
    required this.cards,
    required this.startNumber,
    required this.onRemove,
    required this.onReorder,
    required this.enabled,
  });
  final String title;
  final List<GunlukFaaliyetTableData> cards;
  final int startNumber;
  final ValueChanged<int> onRemove;
  final void Function(int, int) onReorder;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      if (cards.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Henüz kart eklenmedi.'),
        ),
      ReorderableListView.builder(
        key: ValueKey('selected-$title'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: cards.length,
        onReorderItem: (oldIndex, newIndex) {
          if (enabled) onReorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            key: ValueKey('selected-card-${card.id}'),
            child: ListTile(
              leading: CircleAvatar(child: Text('${startNumber + index}')),
              title: Text(card.faaliyetAdi),
              subtitle: Text(card.tarih),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: Key('remove-card-${card.id}'),
                    tooltip: 'Çıktıdan çıkar',
                    icon: const Icon(Icons.close),
                    onPressed: enabled ? () => onRemove(card.id) : null,
                  ),
                  if (enabled)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_indicator_rounded),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}
