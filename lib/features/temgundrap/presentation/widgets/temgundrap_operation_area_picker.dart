import 'package:flutter/material.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';

class TemgundrapOperationAreaPicker extends StatefulWidget {
  const TemgundrapOperationAreaPicker({
    required this.onChanged,
    this.areas = defaultTemgundrapOperationAreas,
    super.key,
  });

  final List<String> areas;
  final ValueChanged<String> onChanged;

  @override
  State<TemgundrapOperationAreaPicker> createState() =>
      _TemgundrapOperationAreaPickerState();
}

class _TemgundrapOperationAreaPickerState
    extends State<TemgundrapOperationAreaPicker> {
  final _customAreaController = TextEditingController();
  String? _selectedArea;

  bool get _isCustom => _selectedArea == customTemgundrapOperationArea;

  @override
  void dispose() {
    _customAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          key: const Key('operation-area-picker'),
          initialValue: _selectedArea,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Operasyon bölgesi',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: widget.areas
              .map((area) => DropdownMenuItem(value: area, child: Text(area)))
              .toList(),
          validator: (_) {
            if (_selectedArea == null) return 'Operasyon bölgesi zorunludur.';
            if (_isCustom && _customAreaController.text.trim().isEmpty) {
              return 'Özel operasyon bölgesini girin.';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedArea = value;
              if (!_isCustom) _customAreaController.clear();
            });
            widget.onChanged(
              value == null || value == customTemgundrapOperationArea
                  ? ''
                  : value,
            );
          },
        ),
        if (_isCustom) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('operation-area-custom'),
            controller: _customAreaController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Operasyon bölgesini yazın',
              hintText: 'Örn: ELAZIĞ ...',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Özel operasyon bölgesini girin.'
                : null,
            onChanged: (value) => widget.onChanged(value.trim()),
          ),
        ],
      ],
    );
  }
}
