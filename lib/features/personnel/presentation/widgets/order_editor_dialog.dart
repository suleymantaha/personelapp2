import 'package:flutter/material.dart';

class OrderEditorItem {
  const OrderEditorItem(this.id, this.label);
  final int id;
  final String label;
}

/// Edits a complete list in memory, persisting only after explicit Save.
class OrderEditorDialog extends StatefulWidget {
  const OrderEditorDialog({
    super.key,
    required this.title,
    required this.items,
    required this.onSave,
  });
  final String title;
  final List<OrderEditorItem> items;
  final Future<void> Function(List<int>) onSave;
  @override
  State<OrderEditorDialog> createState() => _OrderEditorDialogState();
}

class _OrderEditorDialogState extends State<OrderEditorDialog> {
  late final List<OrderEditorItem> _items = [...widget.items];
  bool _saving = false;
  String? _error;

  void _move(int from, int to) {
    if (_saving || from == to) return;
    setState(() {
      _items.insert(to, _items.removeAt(from));
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_items.map((item) => item.id).toList());
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Kaydedilemedi. Liste veya yetkiniz değişmiş olabilir. '
              'İptal edip listeyi yeniden açın.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: AlertDialog(
          title: Text(widget.title),
          content: SizedBox(
            width: 520,
            height: 380,
            child: Column(children: [
              const Text(
                  'Sürükleyin veya oklarla taşıyın. Kaydet ile uygulayın.'),
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
              Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('Sıralanacak kayıt yok.'))
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: _items.length,
                          onReorderItem: _move,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              key: ValueKey('order-item-${item.id}'),
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.label,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      key: ValueKey('move-up-${item.id}'),
                                      tooltip: 'Yukarı taşı',
                                      onPressed: _saving || index == 0
                                          ? null
                                          : () => _move(index, index - 1),
                                      icon: const Icon(Icons.arrow_upward,
                                          size: 20),
                                    ),
                                    IconButton(
                                      key: ValueKey('move-down-${item.id}'),
                                      tooltip: 'Aşağı taşı',
                                      onPressed:
                                          _saving || index == _items.length - 1
                                              ? null
                                              : () => _move(index, index + 1),
                                      icon: const Icon(Icons.arrow_downward,
                                          size: 20),
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      enabled: !_saving,
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(Icons.drag_handle),
                                      ),
                                    ),
                                  ]),
                            );
                          },
                        )),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('İptal')),
            FilledButton(
                onPressed: _saving || _items.isEmpty ? null : _save,
                child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet')),
          ],
        ),
      );
}
