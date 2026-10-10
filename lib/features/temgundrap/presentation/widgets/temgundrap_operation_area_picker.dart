import 'package:personelapp2/core/extensions/l10n_extension.dart';
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
          decoration: InputDecoration(
            labelText: context.l10n.temgundrapOperationArea,
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: widget.areas
              .map((area) => DropdownMenuItem(value: area, child: Text(area)))
              .toList(),
          validator: (_) {
            if (_selectedArea == null) return context.l10n.temgundrapOperationAreaRequired;
            if (_isCustom && _customAreaController.text.trim().isEmpty) {
              return context.l10n.temgundrapEnterCustomOperationArea;
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
            decoration: InputDecoration(
              labelText: context.l10n.temgundrapTypeOperationArea,
              hintText: 'Örn: ELAZIĞ ...',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? context.l10n.temgundrapEnterCustomOperationArea
                : null,
            onChanged: (value) => widget.onChanged(value.trim()),
          ),
        ],
      ],
    );
  }
}
