import 'dart:convert';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/widgets/confirm_discard_changes.dart';
import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/temgundrap/data/temgundrap_repository.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_operation_editor_dialog.dart';
import 'package:personelapp2/core/widgets/turkish_flag_watermark_background.dart';

class TemgundrapFormScreen extends StatefulWidget {
  const TemgundrapFormScreen({
    super.key,
    this.initialDocument,
    this.initialDate,
    this.repository,
  });
  final TemgundrapDocument? initialDocument;
  final DateTime? initialDate;
  final TemgundrapRepository? repository;
  @override
  State<TemgundrapFormScreen> createState() => _TemgundrapFormScreenState();
}

class _TemgundrapFormScreenState extends State<TemgundrapFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TemgundrapRepository _repository;
  late String _baseline;
  bool _allowExit = false;
  bool _confirming = false;
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
    _repository = widget.repository ?? TemgundrapRepository();
    final initial = widget.initialDocument;
    _date = initial?.date ?? widget.initialDate ?? DateTime.now();
    _unitTitle = TextEditingController(text: initial?.unitTitle ?? '');
    _approverName = TextEditingController(text: initial?.approverName ?? '');
    _approverRank = TextEditingController(text: initial?.approverRank ?? '');
    _approverDuty = TextEditingController(text: initial?.approverDuty ?? '');
    _operations = [...?initial?.operations];
    _isDraft = initial?.isDraft ?? true;

    _baseline = _snapshot();
    for (final controller in [
      _unitTitle,
      _approverName,
      _approverRank,
      _approverDuty,
    ]) {
      controller.addListener(_changed);
    }
    if (initial == null) {
      _loadDefaults();
    }
  }

  String _snapshot() => jsonEncode({
    'date': _date.toIso8601String(),
    'unit': _unitTitle.text,
    'name': _approverName.text,
    'rank': _approverRank.text,
    'duty': _approverDuty.text,
    'draft': _isDraft,
    'operations': _operations.map((operation) => operation.toJson()).toList(),
  });

  bool get _dirty => _snapshot() != _baseline;
  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _leave([bool? saved]) async {
    if (!mounted) return;
    setState(() => _allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) AppNavigator.popOrDashboard(context, saved);
  }

  Future<void> _back() async {
    if (_saving || _confirming) return;
    _confirming = true;
    try {
      if (!_dirty || await confirmDiscardChanges(context)) await _leave();
    } finally {
      _confirming = false;
    }
  }

  Future<void> _loadDefaults() async {
    try {
      final defaults = await _repository.getApproverDefaults();
      if (!mounted || _dirty) return;
      setState(() {
        _unitTitle.text = defaults.unitTitle;
        _approverName.text = defaults.name;
        _approverRank.text = defaults.rank;
        _approverDuty.text = defaults.duty;
        _baseline = _snapshot();
      });
    } catch (error) {
      if (mounted) AppNotifications.error(context.l10n.temgundrapApproverDefaultsLoadFailed('$error'));
    }
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
      builder: (_) => const TemgundrapOperationEditorDialog(),
    );
    if (operation != null) setState(() => _operations.add(operation));
  }

  Future<void> _editOperation(int index) async {
    final operation = await showDialog<TemgundrapOperation>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => TemgundrapOperationEditorDialog(
            initialOperation: _operations[index],
          ),
    );
    if (operation != null) {
      setState(() => _operations[index] = operation);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_operations.isEmpty) {
      AppNotifications.warning(context.l10n.temgundrapAtLeastOneOperationRequired);
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    try {
      await _repository.save(
        TemgundrapDocument(
          id:
              widget.initialDocument?.id ??
              now.microsecondsSinceEpoch.toString(),
          date: _date,
          unitTitle: _unitTitle.text.trim(),
          approverName: _approverName.text.trim(),
          approverRank: _approverRank.text.trim(),
          approverDuty: _approverDuty.text.trim(),
          operations: _operations,
          isDraft: _isDraft,
          updatedAt: now,
        ),
      );
      await _leave(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.temgundrapSaveFailed('$error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: _allowExit || (!_saving && !_dirty),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _saving ? null : _back),
        title: Text(
          widget.initialDocument == null
              ? context.l10n.temgundrapNewDocument
              : context.l10n.temgundrapEditDocument,
        ),
      ),
      body: TurkishFlagWatermarkBackground(
        child: AbsorbPointer(
          absorbing: _saving,
          child: Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      key: const Key('document-unit-title'),
                      controller: _unitTitle,
                      decoration: InputDecoration(
                        labelText: context.l10n.temgundrapUnitTitle,
                        hintText: context.l10n.temgundrapUnitHint,
                        prefixIcon: const Icon(Icons.account_balance),
                      ),
                      validator: (value) => _required(value, context),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      key: const Key('document-date'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: Text(context.l10n.temgundrapDocumentDate),
                      subtitle: Text(
                        '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: _pickDate,
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.temgundrapOperations,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          key: const Key('add-operation'),
                          onPressed: _addOperation,
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.temgundrapAddOperation),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_operations.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(context.l10n.temgundrapNoOperationsAddedYet),
                        ),
                      )
                    else
                      ..._operations.asMap().entries.map(
                        (entry) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${entry.key + 1}'),
                            ),
                            title: Text(
                              entry.value.operationArea,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${entry.value.commander.name} • ${entry.value.totalStrength} personel\n${entry.value.purpose}',
                            ),
                            isThreeLine: true,
                            onTap: () => _editOperation(entry.key),
                            trailing: Wrap(
                              spacing: 2,
                              children: [
                                IconButton(
                                  key: Key('edit-operation-${entry.key}'),
                                  tooltip: context.l10n.temgundrapEditOperationTooltip,
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editOperation(entry.key),
                                ),
                                IconButton(
                                  key: Key('delete-operation-${entry.key}'),
                                  tooltip: context.l10n.temgundrapDeleteOperationTooltip,
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed:
                                      () => setState(
                                        () => _operations.removeAt(entry.key),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const Divider(height: 32),
                    Text(
                      context.l10n.temgundrapApprovalInfo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _approverName,
                      decoration: InputDecoration(
                        labelText: context.l10n.temgundrapApproverName,
                        hintText: context.l10n.temgundrapApproverNameHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _approverRank,
                      decoration: InputDecoration(
                        labelText: context.l10n.personnelRank,
                        hintText: context.l10n.temgundrapApproverRankHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _approverDuty,
                      decoration: InputDecoration(
                        labelText: context.l10n.temgundrapApproverDuty,
                        hintText: context.l10n.temgundrapApproverDutyHint,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.temgundrapSaveAsDraft),
                      value: _isDraft,
                      onChanged: (value) => setState(() => _isDraft = value),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('save-document'),
                      onPressed: _saving ? null : _save,
                      icon:
                          _saving
                              ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(context.l10n.temgundrapSaveDocumentButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  String? _required(String? value, BuildContext context) =>
      value == null || value.trim().isEmpty ? context.l10n.temgundrapRequiredField : null;
}
