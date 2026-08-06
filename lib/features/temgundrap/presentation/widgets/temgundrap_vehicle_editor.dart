import 'package:flutter/material.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class TemgundrapVehicleEditor extends StatefulWidget {
  const TemgundrapVehicleEditor(
      {required this.catalog,
      required this.vehicles,
      required this.onAdd,
      required this.onRemove,
      super.key});
  final Map<String, List<String>> catalog;
  final List<TemgundrapVehicleAssignment> vehicles;
  final ValueChanged<TemgundrapVehicleAssignment> onAdd;
  final ValueChanged<int> onRemove;
  @override
  State<TemgundrapVehicleEditor> createState() =>
      _TemgundrapVehicleEditorState();
}

class _TemgundrapVehicleEditorState extends State<TemgundrapVehicleEditor> {
  String? _model;
  String? _plate;
  @override
  Widget build(BuildContext context) {
    final plates = _model == null
        ? const <String>[]
        : widget.catalog[_model] ?? const <String>[];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Araçlar',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final fields = <Widget>[
                    DropdownButtonFormField<String>(
                      key: const Key('vehicle-model'),
                      initialValue: _model,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Araç modeli'),
                      items: widget.catalog.keys
                          .map((item) =>
                              DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _model = value;
                        _plate = null;
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      key: const Key('vehicle-plate'),
                      initialValue: _plate,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Plaka'),
                      items: plates
                          .map((item) =>
                              DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) => setState(() => _plate = value),
                    ),
                    FilledButton.icon(
                      key: const Key('vehicle-add'),
                      onPressed: _model == null || _plate == null
                          ? null
                          : () => widget.onAdd(TemgundrapVehicleAssignment(
                              model: _model!, plate: _plate!)),
                      icon: const Icon(Icons.add),
                      label: const Text('Ekle'),
                    ),
                  ];
                  if (compact) {
                    return Column(children: [
                      fields[0],
                      const SizedBox(height: 12),
                      fields[1],
                      const SizedBox(height: 12),
                      fields[2]
                    ]);
                  }
                  return Row(children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 12),
                    Expanded(child: fields[1]),
                    const SizedBox(width: 12),
                    fields[2]
                  ]);
                }),
                if (_model != null && plates.isEmpty)
                  const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                          'Bu model için kayıtlı plaka yok. Araç ayarlarından plaka ekleyin.')),
                ...widget.vehicles.asMap().entries.map((entry) => ListTile(
                      key: Key('vehicle-${entry.value.plate}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.value.model),
                      subtitle: Text(entry.value.plate),
                      trailing: IconButton(
                          onPressed: () => widget.onRemove(entry.key),
                          icon: const Icon(Icons.delete_outline)),
                    )),
              ],
            )));
  }
}
