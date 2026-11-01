import 'package:flutter/material.dart';

/// The detail route hosts the toolbar outside its scrolling content.
class TeamSelectionNotification extends Notification {
  TeamSelectionNotification(this.toolbar);
  final Widget? toolbar;
}

class TeamSelectionToolbar extends StatelessWidget {
  const TeamSelectionToolbar(
      {super.key,
      required this.teamCount,
      required this.personCount,
      required this.onCancel,
      required this.onSelectAll,
      this.onReassign,
      this.onExport,
      this.onDelete,
      this.onReport});
  final int teamCount;
  final int personCount;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final VoidCallback? onReassign;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  IconButton(
                      tooltip: 'Seçimi kapat',
                      onPressed: onCancel,
                      icon: const Icon(Icons.close)),
                  Expanded(
                      child: Text('$teamCount tim seçildi',
                          style: Theme.of(context).textTheme.titleSmall)),
                  TextButton(
                      key: const Key('team-selection-all'),
                      onPressed: onSelectAll,
                      child: const Text('Tümünü seç')),
                ]),
                Text('$personCount personel'),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  if (onReassign != null)
                    Tooltip(
                        message: 'Görev Değiştir',
                        child: FilledButton.tonalIcon(
                            key: const Key('reassign-selected-teams'),
                            onPressed: teamCount == 0 ? null : onReassign,
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('Görev Değiştir'))),
                  if (onExport != null)
                    FilledButton.tonalIcon(
                        key: const Key('export-selected-teams'),
                        onPressed: teamCount == 0 ? null : onExport,
                        icon: const Icon(Icons.ios_share, size: 18),
                        label: const Text('Çıktı Al')),
                  if (onDelete != null || onReport != null)
                    PopupMenuButton<String>(
                      key: const Key('selected-teams-more'),
                      tooltip: 'Diğer işlemler',
                      enabled: teamCount > 0,
                      onSelected: (value) => value == 'delete'
                          ? onDelete?.call()
                          : onReport?.call(),
                      itemBuilder: (_) => [
                        if (onReport != null)
                          const PopupMenuItem(
                              value: 'report',
                              child: Text('TEMGÜNDRAP taslağı oluştur')),
                        if (onDelete != null)
                          PopupMenuItem(
                              value: 'delete',
                              key: const Key('delete-selected-teams'),
                              child: Text('Faaliyetten çıkar',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error))),
                      ],
                      child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.more_horiz),
                            SizedBox(width: 4),
                            Text('Diğer'),
                          ])),
                    ),
                ]),
              ],
            )),
      ));
}
