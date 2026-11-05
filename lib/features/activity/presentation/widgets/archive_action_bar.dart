import 'package:flutter/material.dart';

class ArchiveActionBar extends StatelessWidget {
  const ArchiveActionBar({
    required this.onSelect,
    required this.onCombine,
    required this.onReorder,
    super.key,
  });

  final VoidCallback onSelect;
  final VoidCallback onCombine;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
                flex: 3,
                child: _action('archive-select-visible', Icons.checklist,
                    'Faaliyet seç', onSelect)),
            Expanded(
                flex: 4,
                child: _action('archive-prepare-cards',
                    Icons.playlist_add_check, 'Kartları birleştir', onCombine)),
            Expanded(
                flex: 2,
                child: _action('archive-reorder-visible', Icons.swap_vert,
                    'Sırala', onReorder)),
          ],
        ),
      );

  Widget _action(
          String key, IconData icon, String label, VoidCallback onPressed) =>
      TextButton(
        key: Key(key),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      );
}
