import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/backup_file_gateway.dart';
import 'package:personelapp2/core/services/task_team_repair_service.dart';
import 'task_team_repair_preview.dart';

part 'task_team_repair_actions.dart';

Future<bool> showTaskTeamRepairDialog({
  required BuildContext context,
  required AppDatabase database,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskTeamRepairDialog(database: database),
    ) ??
    false;

class TaskTeamRepairDialog extends ConsumerStatefulWidget {
  const TaskTeamRepairDialog(
      {required this.database, this.service, this.fileGateway, super.key});
  final AppDatabase database;
  final TaskTeamRepairService? service;
  final BackupFileGateway? fileGateway;

  @override
  ConsumerState<TaskTeamRepairDialog> createState() =>
      _TaskTeamRepairDialogState();
}

class _TaskTeamRepairDialogState extends ConsumerState<TaskTeamRepairDialog>
    with _TaskTeamRepairActions {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(userSessionProvider)?.isAdmin ?? false;
    final hasCandidates = _preview?.candidates.isNotEmpty ?? false;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Görev timi geçmişini onar'),
        scrollable: true,
        content: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isAdmin)
                  const Text('Bu işlem için yönetici yetkisi gerekir.')
                else if (_repaired != null)
                  Text('$_repaired kayıt onarıldı.')
                else if (_preview != null)
                  TaskTeamRepairPreviewContent(preview: _preview!),
                if (_busy)
                  const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator())),
                if (_notice != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_notice!, key: const Key('repair-notice'))),
              ],
            )),
        actions: [
          TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.pop(context, _repaired != null),
              child: const Text('Kapat')),
          if (isAdmin && _repaired == null) ...[
            TextButton(
                onPressed: _busy ? null : _prepare,
                child: const Text('Önizlemeyi yenile')),
            if (hasCandidates) ...[
              TextButton(
                  key: const Key('repair-save'),
                  onPressed: _busy ? null : _save,
                  child: const Text('Yedeği kaydet')),
              TextButton(
                  key: const Key('repair-verify'),
                  onPressed: _busy || !_saved ? null : _verify,
                  child: const Text('Kaydedilen yedeği doğrula')),
              FilledButton(
                  key: const Key('repair-apply'),
                  onPressed: _busy || _verified == null ? null : _apply,
                  child: const Text('Uygula')),
            ],
          ],
        ],
      ),
    );
  }
}
