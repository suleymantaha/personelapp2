import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/services/personnel_backup_service.dart';

Future<bool> showBackupRestoreSurface({
  required BuildContext context,
  required AppDatabase database,
}) async {
  final useBottomSheet = MediaQuery.sizeOf(context).width < 600;
  if (useBottomSheet) {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BackupRestoreDialog(
            database: database,
            isBottomSheet: true,
          ),
        ) ??
        false;
  }

  return await showDialog<bool>(
        context: context,
        builder: (context) => BackupRestoreDialog(database: database),
      ) ??
      false;
}

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({
    required this.database,
    this.isBottomSheet = false,
    super.key,
  });

  final AppDatabase database;
  final bool isBottomSheet;

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  final TextEditingController _textController = TextEditingController();
  _BackupMode _mode = _BackupMode.export;
  _BackupNotice? _notice;
  bool _isLoading = false;
  bool _didImport = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _close() => Navigator.pop(context, _didImport);

  Future<void> _exportBackup() async {
    setState(() {
      _isLoading = true;
      _notice = null;
    });

    try {
      final service = PersonnelBackupService(widget.database);
      final json = await service.exportBackupJson();
      if (!mounted) return;
      setState(() {
        _textController.text = json;
        _notice = const _BackupNotice(
          type: _BackupNoticeType.success,
          message: 'Personel ve tim yedeği başarıyla oluşturuldu.',
        );
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = const _BackupNotice(
          type: _BackupNoticeType.error,
          message: 'Yedek oluşturulamadı. Lütfen tekrar deneyin.',
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importBackup() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _notice = const _BackupNotice(
          type: _BackupNoticeType.warning,
          message: 'Önce yedek metnini kutuya yapıştırın.',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _notice = null;
    });

    try {
      final service = PersonnelBackupService(widget.database);
      final count = await service.importBackupJson(input);
      if (!mounted) return;
      setState(() {
        _didImport = true;
        _notice = _BackupNotice(
          type: _BackupNoticeType.success,
          message: count == 0
              ? 'Yedek kontrol edildi; eklenecek yeni kayıt bulunamadı.'
              : '$count yeni personel ve tim kaydı içe aktarıldı.',
        );
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = _BackupNotice(
          type: _BackupNoticeType.error,
          message: error.message,
        );
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() {
        _notice = const _BackupNotice(
          type: _BackupNoticeType.error,
          message:
              'Yedek içe aktarılamadı. Veritabanı işlemini tekrar deneyin.',
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyBackup() async {
    if (_textController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (!mounted) return;
    setState(() {
      _notice = const _BackupNotice(
        type: _BackupNoticeType.success,
        message: 'Yedek metni panoya kopyalandı.',
      );
    });
  }

  Future<void> _pasteBackup() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      setState(() {
        _notice = const _BackupNotice(
          type: _BackupNoticeType.warning,
          message: 'Panoda yapıştırılabilecek bir yedek metni bulunamadı.',
        );
      });
      return;
    }

    setState(() {
      _textController.text = text;
      _notice = const _BackupNotice(
        type: _BackupNoticeType.success,
        message: 'Panodaki metin kutuya yapıştırıldı.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final verticalReservedSpace = widget.isBottomSheet ? 12.0 : 48.0;
    final maxHeightFactor = widget.isBottomSheet ? 0.94 : 0.88;
    final availableHeight = (mediaQuery.size.height -
            mediaQuery.viewInsets.bottom -
            mediaQuery.padding.top -
            verticalReservedSpace)
        .clamp(280.0, mediaQuery.size.height * maxHeightFactor);

    final surface = Material(
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(24),
          bottom: Radius.circular(widget.isBottomSheet ? 0 : 24),
        ),
      ),
      child: SizedBox(
        width: widget.isBottomSheet ? double.infinity : 620,
        height: availableHeight,
        child: Column(
          children: [
            _buildHeader(keyboardVisible),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildScrollableContent(keyboardVisible)),
          ],
        ),
      ),
    );

    if (widget.isBottomSheet) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: surface,
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: surface,
    );
  }

  Widget _buildHeader(bool keyboardVisible) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, keyboardVisible ? 10 : 16, 12, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.cloud_sync_outlined,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yedekleme ve geri yükleme',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (!keyboardVisible) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Personel ve tim verilerinizi güvenle taşıyın.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kapat',
            icon: const Icon(Icons.close_rounded),
            onPressed: _close,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(bool keyboardVisible) {
    final readOnly = _mode == _BackupMode.export;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 6, 20, keyboardVisible ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_BackupMode>(
              segments: const [
                ButtonSegment(
                  value: _BackupMode.export,
                  icon: Icon(Icons.file_download_outlined),
                  label: Text('Yedek oluştur'),
                ),
                ButtonSegment(
                  value: _BackupMode.import,
                  icon: Icon(Icons.file_upload_outlined),
                  label: Text('Geri yükle'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _isLoading
                  ? null
                  : (selection) {
                      setState(() {
                        _mode = selection.first;
                        _notice = null;
                      });
                    },
            ),
          ),
          if (_notice != null) ...[
            const SizedBox(height: 12),
            _NoticeCard(notice: _notice!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  readOnly ? 'Oluşturulan yedek' : 'İçe aktarılacak yedek',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (readOnly && _textController.text.isNotEmpty)
                TextButton.icon(
                  key: const Key('backup-copy'),
                  onPressed: _isLoading ? null : _copyBackup,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Kopyala'),
                ),
              if (!readOnly)
                TextButton.icon(
                  key: const Key('backup-paste'),
                  onPressed: _isLoading ? null : _pasteBackup,
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('Panodan yapıştır'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: keyboardVisible ? 150 : 230,
            child: TextField(
              key: const Key('backup-text-field'),
              controller: _textController,
              readOnly: readOnly,
              showCursor: !readOnly,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: readOnly
                    ? 'Yedek oluşturduğunuzda veri burada görünür.'
                    : 'Daha önce kopyaladığınız yedek metnini buraya '
                        'yapıştırın.',
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLowest,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yedek metni personel bilgileri içerir. Yalnızca güvenilir '
                  'yerlerde saklayın ve paylaşın.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              key: Key(
                readOnly ? 'backup-create' : 'backup-restore',
              ),
              onPressed: _isLoading
                  ? null
                  : readOnly
                      ? _exportBackup
                      : _importBackup,
              icon: Icon(
                readOnly ? Icons.file_download_outlined : Icons.restore_rounded,
              ),
              label: Text(
                readOnly ? 'Yedeği oluştur' : 'Yedeği geri yükle',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final _BackupNotice notice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color) = switch (notice.type) {
      _BackupNoticeType.success => (Icons.check_circle_outline, Colors.green),
      _BackupNoticeType.warning => (Icons.warning_amber_rounded, Colors.orange),
      _BackupNoticeType.error => (Icons.error_outline, colors.error),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notice.message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BackupMode { export, import }

enum _BackupNoticeType { success, warning, error }

class _BackupNotice {
  const _BackupNotice({required this.type, required this.message});

  final _BackupNoticeType type;
  final String message;
}
