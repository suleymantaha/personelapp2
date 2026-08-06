import 'package:flutter/material.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class TemgundrapCommanderOption {
  const TemgundrapCommanderOption(
      {required this.id,
      required this.name,
      required this.rank,
      this.phone = ''});
  final int id;
  final String name;
  final String rank;
  final String phone;
}

class TemgundrapCommanderPicker extends StatefulWidget {
  const TemgundrapCommanderPicker(
      {required this.options, required this.onChanged, super.key});
  final List<TemgundrapCommanderOption> options;
  final ValueChanged<CommanderSnapshot> onChanged;
  @override
  State<TemgundrapCommanderPicker> createState() =>
      _TemgundrapCommanderPickerState();
}

class _TemgundrapCommanderPickerState extends State<TemgundrapCommanderPicker> {
  final _phoneController = TextEditingController();
  TemgundrapCommanderOption? _selected;
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _emit() {
    final selected = _selected;
    if (selected == null) return;
    widget.onChanged(CommanderSnapshot(
        personnelId: selected.id,
        name: selected.name,
        rank: selected.rank,
        phone: TemgundrapFormatters.phone(_phoneController.text)));
  }

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Operasyon Komutanı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const Key('commander-picker'),
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Personel listesinden seçin'),
                items: widget.options
                    .map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.rank} ${item.name}')))
                    .toList(),
                onChanged: (id) {
                  final selected =
                      widget.options.firstWhere((item) => item.id == id);
                  setState(() {
                    _selected = selected;
                    _phoneController.text =
                        TemgundrapFormatters.phone(selected.phone);
                  });
                  _emit();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('commander-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Kullanılacak telefon',
                    hintText: '533 158 35 97'),
                validator: (value) =>
                    TemgundrapFormatters.isValidTurkishMobile(value ?? '')
                        ? null
                        : 'Geçerli bir cep telefonu girin.',
                onChanged: (_) => _emit(),
              ),
            ],
          )));
}
