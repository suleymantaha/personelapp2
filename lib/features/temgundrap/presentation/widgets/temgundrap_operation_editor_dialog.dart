import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/view_models/temgundrap_operation_draft.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_commander_picker.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_operation_area_picker.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_strength_editor.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_time_section.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_vehicle_editor.dart';

class TemgundrapOperationEditorDialog extends ConsumerStatefulWidget {
  const TemgundrapOperationEditorDialog({super.key, this.initialOperation});

  final TemgundrapOperation? initialOperation;
  @override
  ConsumerState<TemgundrapOperationEditorDialog> createState() =>
      _TemgundrapOperationEditorDialogState();
}

class _TemgundrapOperationEditorDialogState
    extends ConsumerState<TemgundrapOperationEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TemgundrapOperationDraft _draft;
  final _descriptionController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _draft = TemgundrapOperationDraft(initial: widget.initialOperation);
    _descriptionController.text = _draft.description;
    _draft.addListener(_refresh);
  }

  @override
  void dispose() {
    _draft.removeListener(_refresh);
    _draft.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _draft.description = _descriptionController.text;
    final error = _draft.validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(
      context,
      _draft.buildOperation(id: widget.initialOperation?.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personnel = ref.watch(allPersonnelProvider);
    return Dialog.fullscreen(
        child: Scaffold(
      appBar: AppBar(
        title: Text(widget.initialOperation == null
            ? 'Operasyon Ekle'
            : 'Operasyonu Düzenle'),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
        actions: [
          TextButton.icon(
              key: const Key('operation-save'),
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label:
                  Text(widget.initialOperation == null ? 'EKLE' : 'GÜNCELLE'))
        ],
      ),
      body: Form(
          key: _formKey,
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        DropdownButtonFormField<String>(
                          key: const Key('issuing-unit'),
                          initialValue: _draft.issuingUnit,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Çıkaran birlik'),
                          items: const [
                            DropdownMenuItem(
                                value: defaultTemgundrapIssuingUnit,
                                child: Text(defaultTemgundrapIssuingUnit))
                          ],
                          onChanged: (value) =>
                              _draft.issuingUnit = value ?? '',
                        ),
                        const SizedBox(height: 12),
                        TemgundrapOperationAreaPicker(
                          onChanged: (value) => _draft.operationArea = value,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const Key('operation-purpose'),
                          initialValue: _draft.purpose,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Operasyon maksadı'),
                          items: defaultTemgundrapPurposes
                              .map((item) => DropdownMenuItem(
                                  value: item, child: Text(item)))
                              .toList(),
                          onChanged: (value) => _draft.purpose = value ?? '',
                        ),
                      ]))),
              personnel.when(
                data: (items) => TemgundrapCommanderPicker(
                  initialValue: _draft.commander,
                  options: items
                      .map((item) => TemgundrapCommanderOption(
                          id: item.id,
                          name: item.adSoyad,
                          rank: item.rutbe,
                          phone: item.telefon ?? ''))
                      .toList(),
                  onChanged: _draft.setCommander,
                  onPhoneLearned: (personnelId, phone) async {
                    await PersonnelRepository(ref.read(databaseProvider))
                        .updatePersonnelPhone(personnelId, phone);
                    ref.invalidate(allPersonnelProvider);
                  },
                ),
                loading: () => const Card(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()))),
                error: (error, _) => Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Personel listesi yüklenemedi: $error'))),
              ),
              TemgundrapStrengthEditor(
                  value: _draft.strength, onChanged: _draft.setStrength),
              TemgundrapVehicleEditor(
                catalog: defaultTemgundrapVehicleCatalog,
                vehicles: _draft.vehicles,
                onAdd: (vehicle) {
                  if (!_draft.addVehicle(vehicle)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Bu plaka zaten eklendi.')));
                  }
                },
                onRemove: _draft.removeVehicle,
              ),
              TemgundrapTimeSection(
                startAt: _draft.startAt,
                endAt: _draft.endAt,
                onStartTap: () async {
                  final value = await _pickDateTime(_draft.startAt);
                  if (value != null) _draft.setStart(value);
                },
                onEndTap: () async {
                  final value = await _pickDateTime(_draft.endAt);
                  if (value != null) _draft.setEnd(value);
                },
              ),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        key: const Key('operation-description'),
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration:
                            const InputDecoration(labelText: 'Açıklama'),
                      ))),
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(widget.initialOperation == null
                          ? 'OPERASYONU EKLE'
                          : 'OPERASYONU GÜNCELLE'))),
            ]),
          ))),
    ));
  }
}
