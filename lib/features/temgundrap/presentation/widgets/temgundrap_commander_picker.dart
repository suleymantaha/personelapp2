import 'package:flutter/material.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/device_contact_picker.dart';

class TemgundrapCommanderOption {
  const TemgundrapCommanderOption({
    required this.id,
    required this.name,
    required this.rank,
    this.phone = '',
  });

  final int id;
  final String name;
  final String rank;
  final String phone;
}

class TemgundrapCommanderPicker extends StatefulWidget {
  const TemgundrapCommanderPicker({
    required this.options,
    required this.onChanged,
    this.initialValue,
    this.onPhoneLearned,
    this.contactPicker = const FlutterDeviceContactPicker(),
    super.key,
  });

  final List<TemgundrapCommanderOption> options;
  final ValueChanged<CommanderSnapshot> onChanged;
  final CommanderSnapshot? initialValue;
  final Future<void> Function(int personnelId, String phone)? onPhoneLearned;
  final DeviceContactPicker contactPicker;

  @override
  State<TemgundrapCommanderPicker> createState() =>
      _TemgundrapCommanderPickerState();
}

class _TemgundrapCommanderPickerState extends State<TemgundrapCommanderPicker> {
  final _phoneController = TextEditingController();
  TemgundrapCommanderOption? _selected;
  bool _pickingContact = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null) {
      for (final option in widget.options) {
        if (option.id == initial.personnelId) _selected = option;
      }
      _phoneController.text = TemgundrapFormatters.phone(initial.phone);
    }
  }

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
      phone: TemgundrapFormatters.phone(_phoneController.text),
    ));
  }

  Future<void> _rememberPhone(String value) async {
    final selected = _selected;
    final phone = TemgundrapFormatters.phone(value);
    if (selected != null && TemgundrapFormatters.isValidTurkishMobile(phone)) {
      await widget.onPhoneLearned?.call(selected.id, phone);
    }
  }

  Future<void> _pickFromContacts() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce operasyon komutanını seçin.')),
      );
      return;
    }
    setState(() => _pickingContact = true);
    try {
      final phones = await widget.contactPicker.pickPhoneNumbers();
      if (phones.isEmpty || !mounted) return;
      final rawPhone = phones.length == 1
          ? phones.single
          : await showModalBottomSheet<String>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text(
                        'Kullanılacak numarayı seçin',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...phones.map(
                      (phone) => ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: Text(TemgundrapFormatters.phone(phone)),
                        onTap: () => Navigator.pop(context, phone),
                      ),
                    ),
                  ],
                ),
              ),
            );
      if (rawPhone == null || !mounted) return;
      final phone = TemgundrapFormatters.phone(rawPhone);
      if (!TemgundrapFormatters.isValidTurkishMobile(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seçilen kişide geçerli cep telefonu bulunamadı.'),
          ),
        );
        return;
      }
      _phoneController.text = phone;
      _emit();
      await _rememberPhone(phone);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon personelle eşleştirildi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingContact = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Operasyon Komutanı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const Key('commander-picker'),
                initialValue: _selected?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Personel listesinden seçin',
                ),
                items: widget.options
                    .map((item) => DropdownMenuItem(
                          value: item.id,
                          child: Text('${item.rank} ${item.name}'),
                        ))
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
                decoration: InputDecoration(
                  labelText: 'Kullanılacak telefon',
                  hintText: '533 158 35 97',
                  helperText:
                      'Bir kez eşleştirilince sonraki seçimlerde otomatik gelir.',
                  suffixIcon: IconButton(
                    key: const Key('pick-commander-contact'),
                    tooltip: 'Telefon rehberinden seç',
                    onPressed: _pickingContact ? null : _pickFromContacts,
                    icon: _pickingContact
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.contact_phone_outlined),
                  ),
                ),
                validator: (value) =>
                    TemgundrapFormatters.isValidTurkishMobile(value ?? '')
                        ? null
                        : 'Geçerli bir cep telefonu girin.',
                onChanged: (value) {
                  _emit();
                  _rememberPhone(value);
                },
              ),
            ],
          ),
        ),
      );
}
