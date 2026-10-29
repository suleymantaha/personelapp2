part of 'task_team_repair_dialog.dart';

mixin _TaskTeamRepairActions on ConsumerState<TaskTeamRepairDialog> {
  late final _service =
      widget.service ?? TaskTeamRepairService(widget.database);
  late final _files = widget.fileGateway ?? DeviceBackupFileGateway();
  TaskTeamRepairPreview? _preview;
  String? _verified;
  String? _notice;
  bool _busy = false;
  bool _saved = false;
  int? _repaired;

  UserSessionState _actor() {
    final actor = ref.read(userSessionProvider);
    if (actor == null || !actor.isAdmin) throw StateError('Unauthorized');
    return actor;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      _actor();
      await action();
    } on Object {
      if (mounted) {
        setState(() {
          _verified = null;
          _saved = false;
          _notice =
              'İşlem tamamlanamadı. Yetkinizi ve verileri kontrol edip önizlemeyi yenileyin.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _prepare() => _run(() async {
        setState(() {
          _preview = null;
          _verified = null;
          _saved = false;
        });
        final preview = await _service.prepare(_actor());
        if (!mounted) return;
        _actor();
        setState(() => _preview = preview);
      });

  Future<void> _save() => _run(() async {
        final preview = _preview!;
        setState(() {
          _verified = null;
          _saved = false;
        });
        final box = context.findRenderObject() as RenderBox?;
        final saved = await _files.saveBackup(preview.backupJson,
            shareOrigin:
                box == null ? null : box.localToGlobal(Offset.zero) & box.size);
        if (!mounted) return;
        _actor();
        setState(() {
          _saved = saved;
          _notice = saved
              ? 'Şimdi kaydettiğiniz yedeği yeniden seçip doğrulayın.'
              : 'Yedek kaydedilmedi. Hiçbir kayıt değiştirilmedi.';
        });
      });

  Future<void> _verify() => _run(() async {
        setState(() => _verified = null);
        if (!_saved) return;
        final contents = await _files.openBackup();
        if (!mounted) return;
        _actor();
        final matches = contents != null && contents == _preview!.backupJson;
        setState(() {
          _verified = matches ? contents : null;
          _notice = matches
              ? 'Yedek doğrulandı. Onarımı Uygula ile başlatabilirsiniz.'
              : 'Yedek doğrulanamadı. Kaydettiğiniz dosyayı seçin. Hiçbir kayıt değiştirilmedi.';
        });
      });

  Future<void> _apply() => _run(() async {
        if (_verified == null || _preview == null) return;
        final count = await _service.apply(
            preview: _preview!,
            verifiedBackupJson: _verified!,
            actor: _actor());
        if (!mounted) return;
        ref.invalidate(filteredActivitiesProvider);
        ref.invalidate(pendingAssignmentsProvider);
        ref.invalidate(monthlyMatrixProvider);
        setState(() {
          _repaired = count;
          _verified = null;
        });
      });
}
