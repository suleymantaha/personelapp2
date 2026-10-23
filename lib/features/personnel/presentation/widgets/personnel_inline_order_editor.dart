import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/data/personnel_order_repository.dart';
import 'package:personelapp2/features/personnel/domain/personnel_display_order.dart';
import 'personnel_order_group.dart';
import 'order_scroll_region.dart';
import 'order_save_bar.dart';

class PersonnelInlineOrderEditor extends ConsumerStatefulWidget {
  const PersonnelInlineOrderEditor(
      {super.key, required this.onClose, required this.onSaved});
  final VoidCallback onClose;
  final VoidCallback onSaved;
  @override
  ConsumerState<PersonnelInlineOrderEditor> createState() =>
      _InlineOrderState();
}

class _InlineOrderState extends ConsumerState<PersonnelInlineOrderEditor> {
  List<TimTableData>? _teams;
  final _members = <int?, List<PersonelTableData>>{};
  final _open = <int?>{};
  bool _saving = false;
  bool _dirty = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(databaseProvider);
      final snapshot = await db.transaction(() async => (
            await db.select(db.timTable).get(),
            await db.select(db.personelTable).get()
          ));
      if (!mounted) return;
      setState(() {
        _teams = orderDisplaySquads(snapshot.$1);
        _members.clear();
        for (final t in _teams!) {
          _members[t.id] = [];
        }
        _members[null] = [];
        for (final p in snapshot.$2.where((p) => p.aktif && !p.isDemo)) {
          _members.putIfAbsent(p.timId, () => []).add(p);
        }
        for (final people in _members.values) {
          people.sort(comparePersonnelWithinTeam);
        }
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Liste yüklenemedi. Tekrar deneyin.');
      }
    }
  }

  void _moveTeam(int from, int to) => setState(() {
        if (_saving) return;
        _teams!.insert(to, _teams!.removeAt(from));
        _dirty = true;
      });
  void _movePerson(int? team, int from, int to) => setState(() {
        if (_saving) return;
        final people = _members[team]!;
        people.insert(to, people.removeAt(from));
        _dirty = true;
      });
  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final session = ref.read(userSessionProvider);
      if (session?.isAdmin != true) throw StateError('Yetki değişti');
      await PersonnelOrderRepository(ref.read(databaseProvider))
          .saveDisplayOrder(
              _teams!.map((t) => t.id).toList(),
              {
                for (final entry in _members.entries)
                  entry.key: entry.value.map((p) => p.id).toList()
              },
              username: session!.username);
      if (mounted) widget.onSaved();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Kaydedilemedi. Liste veya yetkiniz değişmiş olabilir. '
              'Taslağınız korunuyor; gerekirse vazgeçip yeniden açın.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teams = _teams;
    final extras = _members.keys
        .where((id) =>
            !(_teams?.any((t) => t.id == id) ?? false) &&
            _members[id]!.isNotEmpty)
        .toList();
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_saving) widget.onClose();
        },
        child: Scaffold(
          appBar: AppBar(
              title: const Text('Sıralamayı düzenle'),
              leading: IconButton(
                  tooltip: 'Vazgeç',
                  onPressed: _saving ? null : widget.onClose,
                  icon: const Icon(Icons.arrow_back))),
          body: Column(children: [
            const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                    'Timleri ve personelleri sağdaki tutamaçtan sürükleyin.')),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            if (teams == null)
              Expanded(
                  child: Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: _load,
                              child: const Text('Tekrar dene'))))
            else
              Expanded(
                  child: AbsorbPointer(
                      absorbing: _saving,
                      child: OrderScrollRegion(
                          builder: (controller, dragChanged) =>
                              ReorderableListView.builder(
                                scrollController: controller,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                buildDefaultDragHandles: false,
                                itemCount: teams.length,
                                onReorderItem: _moveTeam,
                                itemBuilder: (context, index) => _group(
                                    teams[index].id,
                                    teams[index].timAdi,
                                    index,
                                    ValueKey('order-group-${teams[index].id}'),
                                    dragChanged),
                                footer: Column(children: [
                                  for (final id in extras)
                                    _group(
                                        id,
                                        id == null
                                            ? 'Time atanmamış personel'
                                            : 'Bilinmeyen tim',
                                        null,
                                        ValueKey('order-extra-$id'),
                                        dragChanged)
                                ]),
                              )))),
          ]),
          bottomNavigationBar: OrderSaveBar(
              dirty: _dirty,
              saving: _saving,
              onCancel: _saving ? null : widget.onClose,
              onSave: _saving || teams == null || !_dirty ? null : _save),
        ));
  }

  Widget _group(int? id, String name, int? index, Key key,
          ValueChanged<bool> dragChanged) =>
      PersonnelOrderGroup(
          key: key,
          teamId: id,
          name: name,
          people: _members[id]!,
          expanded: _open.contains(id),
          teamIndex: index,
          enabled: !_saving,
          onToggle: () => setState(() {
                if (!_open.add(id)) _open.remove(id);
              }),
          onReorder: (from, to) => _movePerson(id, from, to),
          onDragChanged: dragChanged);
}
