import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';

class RosterSignerDialog extends StatefulWidget {
  const RosterSignerDialog(
      {super.key, required this.signer, required this.onSave});
  final RosterSigner signer;
  final Future<void> Function(RosterSigner) onSave;
  @override
  State<RosterSignerDialog> createState() => _RosterSignerDialogState();
}

class _RosterSignerDialogState extends State<RosterSignerDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.signer.name);
  late final _rank = TextEditingController(text: widget.signer.rank);
  late final _role = TextEditingController(text: widget.signer.role);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _rank.dispose();
    _role.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(RosterSigner(widget.signer.title, _name.text.trim(),
          _rank.text.trim(), _role.text.trim()));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.rosterSignaturesSaveError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: AlertDialog(
          title: Text('${widget.signer.title} — ${context.l10n.commonEdit}'),
          content: SingleChildScrollView(
              child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                          key: const Key('signer-name'),
                          controller: _name,
                          enabled: !_saving,
                          decoration: InputDecoration(
                              labelText: context.l10n.personnelFullName),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? context.l10n.personnelWarningEnterName
                                  : null),
                      TextFormField(
                          key: const Key('signer-rank'),
                          controller: _rank,
                          enabled: !_saving,
                          decoration: InputDecoration(
                              labelText: context.l10n.personnelRank)),
                      TextFormField(
                          key: const Key('signer-role'),
                          controller: _role,
                          enabled: !_saving,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                              labelText: context.l10n.activityDuty)),
                      if (_error != null)
                        Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                    ],
                  ))),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: Text(context.l10n.commonCancel)),
            FilledButton(
                key: const Key('save-roster-signer'),
                onPressed: _saving ? null : _save,
                child: Text(context.l10n.commonSave)),
          ],
        ),
      );
}
