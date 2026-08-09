import 'package:flutter/material.dart';
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_operation_editor_dialog.dart';

class TemgundrapFormScreen extends StatefulWidget {
  const TemgundrapFormScreen({
    super.key,
    this.initialDocument,
    this.initialDate,
  });
  final TemgundrapDocument? initialDocument;
  final DateTime? initialDate;
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
    _date = initial?.date ?? widget.initialDate ?? DateTime.now();
    _unitTitle = TextEditingController(text: initial?.unitTitle ?? '');
    _approverName = TextEditingController(text: initial?.approverName ?? '');
    _approverRank = TextEditingController(text: initial?.approverRank ?? '');
    _approverDuty = TextEditingController(text: initial?.approverDuty ?? '');
    _operations = [...?initial?.operations];
    _isDraft = initial?.isDraft ?? true;

    if (initial == null) {
      _loadDefaults();
    }
  }

  Future<void> _loadDefaults() async {
    final defaults = await _repository.getApproverDefaults();
    if (!mounted) return;
    setState(() {
      if (_unitTitle.text.isEmpty) _unitTitle.text = defaults.unitTitle;
      if (_approverName.text.isEmpty) _approverName.text = defaults.name;
      if (_approverRank.text.isEmpty) _approverRank.text = defaults.rank;
      if (_approverDuty.text.isEmpty) _approverDuty.text = defaults.duty;
    });
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
        lastDate: DateTime(2100));
    if (value != null) setState(() => _date = value);
  }

  Future<void> _addOperation() async {
    final operation = await showDialog<TemgundrapOperation>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TemgundrapOperationEditorDialog(),
    );
    if (operation != null) setState(() => _operations.add(operation));
  }

  Future<void> _editOperation(int index) async {
    final operation = await showDialog<TemgundrapOperation>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TemgundrapOperationEditorDialog(
        initialOperation: _operations[index],
      ),
    );
    if (operation != null) {
      setState(() => _operations[index] = operation);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En az bir operasyon ekleyin.')));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    await _repository.save(TemgundrapDocument(
      id: widget.initialDocument?.id ?? now.microsecondsSinceEpoch.toString(),
      date: _date,
      unitTitle: _unitTitle.text.trim(),
      approverName: _approverName.text.trim(),
      approverRank: _approverRank.text.trim(),
      approverDuty: _approverDuty.text.trim(),
      operations: _operations,
      isDraft: _isDraft,
      updatedAt: now,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.initialDocument == null
                ? 'Yeni TEMGÜNDRAP'
                : 'Çizelgeyi Düzenle')),
        body: Form(
            key: _formKey,
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(padding: const EdgeInsets.all(16), children: [
                TextFormField(
                  key: const Key('document-unit-title'),
                  controller: _unitTitle,
                  decoration: const InputDecoration(
                      labelText: 'Birlik başlığı',
                      hintText: 'Örn: KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
                      prefixIcon: Icon(Icons.account_balance)),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                ListTile(
                  key: const Key('document-date'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Çizelge tarihi'),
                  subtitle: Text(
                      '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}'),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _pickDate,
                ),
                const Divider(height: 32),
                Row(children: [
                  const Expanded(
                      child: Text('Operasyonlar',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  FilledButton.icon(
                      key: const Key('add-operation'),
                      onPressed: _addOperation,
                      icon: const Icon(Icons.add),
                      label: const Text('Operasyon Ekle')),
                ]),
                const SizedBox(height: 8),
                if (_operations.isEmpty)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Henüz operasyon eklenmedi.')))
                else
                  ..._operations.asMap().entries.map((entry) => Card(
                          child: ListTile(
                        leading: CircleAvatar(child: Text('${entry.key + 1}')),
                        title: Text(entry.value.operationArea,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${entry.value.commander.name} • ${entry.value.totalStrength} personel\n${entry.value.purpose}'),
                        isThreeLine: true,
                        onTap: () => _editOperation(entry.key),
                        trailing: Wrap(
                          spacing: 2,
                          children: [
                            IconButton(
                              key: Key('edit-operation-${entry.key}'),
                              tooltip: 'Operasyonu düzenle',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editOperation(entry.key),
                            ),
                            IconButton(
                                key: Key('delete-operation-${entry.key}'),
                                tooltip: 'Operasyonu sil',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => setState(
                                    () => _operations.removeAt(entry.key))),
                          ],
                        ),
                      ))),
                const Divider(height: 32),
                const Text('Onay Bilgileri',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _approverName,
                    decoration: const InputDecoration(
                        labelText: 'Onaylayan ad soyad',
                        hintText: 'Örn: İhsan DAĞLI')),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _approverRank,
                    decoration: const InputDecoration(
                        labelText: 'Rütbe', hintText: 'Örn: J.Ütğm.')),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _approverDuty,
                    decoration: const InputDecoration(
                        labelText: 'Görevi', hintText: 'Örn: Tb. K. V.')),
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Taslak olarak kaydet'),
                    value: _isDraft,
                    onChanged: (value) => setState(() => _isDraft = value)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('save-document'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('ÇİZELGEYİ KAYDET')),
                ),
              ]),
            ))),
      );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bu alan zorunludur.' : null;
}
