import 'package:flutter/material.dart';
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class TemgundrapFormScreen extends StatefulWidget {
  const TemgundrapFormScreen({super.key, this.initialDocument});

  final TemgundrapDocument? initialDocument;

  @override
  State<TemgundrapFormScreen> createState() => _TemgundrapFormScreenState();
}

class _TemgundrapFormScreenState extends State<TemgundrapFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = TemgundrapRepository();
  late DateTime _date;
  late final TextEditingController _unitTitle;
  late final TextEditingController _approverName;
  late final TextEditingController _approverRank;
  late final TextEditingController _approverDuty;
  late List<TemgundrapOperation> _operations;
  bool _saving = false;
  bool _isDraft = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDocument;
    _date = initial?.date ?? DateTime.now();
    _unitTitle = TextEditingController(text: initial?.unitTitle ?? 'KOVANCILAR J.KOMDÖZHRT.TB.K.LIĞI');
    _approverName = TextEditingController(text: initial?.approverName ?? '');
    _approverRank = TextEditingController(text: initial?.approverRank ?? '');
    _approverDuty = TextEditingController(text: initial?.approverDuty ?? '');
    _operations = [...?initial?.operations];
    _isDraft = initial?.isDraft ?? true;
  }

  @override
  void dispose() {
    _unitTitle.dispose();
    _approverName.dispose();
    _approverRank.dispose();
    _approverDuty.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _addOperation() async {
    final operation = await showDialog<TemgundrapOperation>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _OperationDialog(),
    );
    if (operation != null) setState(() => _operations.add(operation));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En az bir operasyon ekleyin.')));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final document = TemgundrapDocument(
      id: widget.initialDocument?.id ?? now.microsecondsSinceEpoch.toString(),
      date: _date,
      unitTitle: _unitTitle.text.trim(),
      approverName: _approverName.text.trim(),
      approverRank: _approverRank.text.trim(),
      approverDuty: _approverDuty.text.trim(),
      operations: _operations,
      isDraft: _isDraft,
      updatedAt: now,
    );
    await _repository.save(document);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialDocument == null ? 'Yeni TEMGÜNDRAP' : 'Çizelgeyi Düzenle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _unitTitle,
              decoration: const InputDecoration(labelText: 'Birlik başlığı', prefixIcon: Icon(Icons.account_balance)),
              validator: _required,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Çizelge tarihi'),
              subtitle: Text('${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDate,
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Expanded(child: Text('Operasyonlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                FilledButton.icon(onPressed: _addOperation, icon: const Icon(Icons.add), label: const Text('Operasyon Ekle')),
              ],
            ),
            const SizedBox(height: 8),
            if (_operations.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Henüz operasyon eklenmedi.')))
            else
              ..._operations.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(item.operationArea, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.commander} • ${item.totalStrength} personel\n${item.purpose}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _operations.removeAt(index)),
                    ),
                  ),
                );
              }),
            const Divider(height: 32),
            const Text('Onay Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(controller: _approverName, decoration: const InputDecoration(labelText: 'Onaylayan ad soyad')),
            const SizedBox(height: 12),
            TextFormField(controller: _approverRank, decoration: const InputDecoration(labelText: 'Rütbe')),
            const SizedBox(height: 12),
            TextFormField(controller: _approverDuty, decoration: const InputDecoration(labelText: 'Görevi')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Taslak olarak kaydet'),
              value: _isDraft,
              onChanged: (value) => setState(() => _isDraft = value),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('ÇİZELGEYİ KAYDET')),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Bu alan zorunludur.' : null;
}

class _OperationDialog extends StatefulWidget {
  const _OperationDialog();

  @override
  State<_OperationDialog> createState() => _OperationDialogState();
}

class _OperationDialogState extends State<_OperationDialog> {
  final _key = GlobalKey<FormState>();
  final _issuingUnit = TextEditingController();
  final _area = TextEditingController();
  final _force = TextEditingController();
  final _commander = TextEditingController();
  final _purpose = TextEditingController(text: 'GÖREVLENDİRME');
  final _description = TextEditingController();
  final _sb = TextEditingController(text: '0');
  final _asb = TextEditingController(text: '0');
  final _uzm = TextEditingController(text: '0');
  final _other = TextEditingController(text: '0');
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 8));

  @override
  void dispose() {
    for (final controller in [_issuingUnit, _area, _force, _commander, _purpose, _description, _sb, _asb, _uzm, _other]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitiş zamanı başlangıçtan önce olamaz.')));
      return;
    }
    Navigator.pop(
      context,
      TemgundrapOperation(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        issuingUnit: _issuingUnit.text.trim(),
        operationArea: _area.text.trim(),
        forceDescription: _force.text.trim(),
        commander: _commander.text.trim(),
        strength: {'SB': int.tryParse(_sb.text) ?? 0, 'ASB': int.tryParse(_asb.text) ?? 0, 'UZM': int.tryParse(_uzm.text) ?? 0, 'DİĞER': int.tryParse(_other.text) ?? 0},
        startAt: _start,
        endAt: _end,
        purpose: _purpose.text.trim(),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Operasyon Ekle'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _issuingUnit, decoration: const InputDecoration(labelText: 'Çıkaran birlik'), validator: _required),
                const SizedBox(height: 10),
                TextFormField(controller: _area, decoration: const InputDecoration(labelText: 'Operasyon bölgesi'), validator: _required),
                const SizedBox(height: 10),
                TextFormField(controller: _force, decoration: const InputDecoration(labelText: 'Kuvveti'), validator: _required),
                const SizedBox(height: 10),
                TextFormField(controller: _commander, decoration: const InputDecoration(labelText: 'Operasyon komutanı'), validator: _required),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(controller: _sb, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'SB'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _asb, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ASB'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _uzm, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'UZM'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _other, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diğer'))),
                ]),
                const SizedBox(height: 10),
                ListTile(title: const Text('Başlama zamanı'), subtitle: Text(_start.toString().substring(0, 16)), onTap: () async { final v = await _pickDateTime(_start); if (v != null) setState(() => _start = v); }),
                ListTile(title: const Text('Bitiş zamanı'), subtitle: Text(_end.toString().substring(0, 16)), onTap: () async { final v = await _pickDateTime(_end); if (v != null) setState(() => _end = v); }),
                TextFormField(controller: _purpose, decoration: const InputDecoration(labelText: 'Operasyon maksadı'), validator: _required),
                const SizedBox(height: 10),
                TextFormField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Açıklama')),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İPTAL')),
        FilledButton(onPressed: _submit, child: const Text('EKLE')),
      ],
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Zorunlu alan' : null;
}
