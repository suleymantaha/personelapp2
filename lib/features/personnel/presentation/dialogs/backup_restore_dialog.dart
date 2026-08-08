import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:personelapp2/core/services/backup_file_gateway.dart';
import 'package:personelapp2/core/services/session_storage.dart';

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

class BackupRestoreDialog extends ConsumerStatefulWidget {
  const BackupRestoreDialog({
    required this.database,
    this.isBottomSheet = false,
    this.backupService,
    this.fileGateway,
    super.key,
  });

  final AppDatabase database;
  final bool isBottomSheet;
  final AppBackupService? backupService;
  final BackupFileGateway? fileGateway;

  @override
  ConsumerState<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends ConsumerState<BackupRestoreDialog> {
  late final AppBackupService _service =
      widget.backupService ?? AppBackupService(widget.database);
  late final BackupFileGateway _fileGateway =
      widget.fileGateway ?? DeviceBackupFileGateway();
  final TextEditingController _textController = TextEditingController();
  _BackupMode _mode = _BackupMode.export;
  _BackupNotice? _notice;
  AppBackupPreview? _preview;
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
      final json = await _service.exportBackupJson();
      _textController.text = json;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final saved = await _fileGateway.saveBackup(
        json,
        shareOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
      if (!mounted) return;
      setState(() {
        _notice = _BackupNotice(
          type: saved ? _BackupNoticeType.success : _BackupNoticeType.warning,
          message: saved
              ? 'Tam uygulama yedeği dışa aktarıldı.'
              : 'Kaydetme işlemi iptal edildi.',
        );
      });
    } on Object catch (error, stackTrace) {
      _reportBackupError('Yedek oluşturulamadı', error, stackTrace);
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

  Future<void> _pickBackup() async {
    setState(() {
      _isLoading = true;
      _notice = null;
      _preview = null;
    });
    try {
      final contents = await _fileGateway.openBackup();
      if (contents == null || !mounted) return;
      await _loadBackupText(contents);
    } on FormatException catch (error) {
      if (mounted) _showError(error.message);
    } on Object catch (error, stackTrace) {
      _reportBackupError('Yedek dosyası okunamadı', error, stackTrace);
      if (mounted) _showError('Yedek dosyası okunamadı.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBackupText(String contents) async {
    final preview = await _service.inspectBackupJson(contents);
    if (!mounted) return;
    setState(() {
      _textController.text = contents;
      _preview = preview;
      _notice = const _BackupNotice(
        type: _BackupNoticeType.success,
        message: 'Yedek doğrulandı ve geri yüklemeye hazır.',
      );
    });
  }

  Future<void> _importBackup() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      _showError('Önce bir yedek dosyası seçin.');
      return;
    }
    try {
      final preview = _preview ?? await _service.inspectBackupJson(input);
      if (!mounted) return;
      final confirmed = await _confirmRestore(preview);
      if (!confirmed || !mounted) return;
      setState(() {
        _isLoading = true;
        _notice = null;
      });
      final result = await _service.restoreBackupJson(input);
      final updatedSession =
          await SessionStorage.loadValidatedSession(widget.database);
      if (mounted) {
        ref.read(userSessionProvider.notifier).state = updatedSession;
        ref.invalidate(allPersonnelProvider);
        ref.invalidate(allSquadsProvider);
        ref.invalidate(allCommandersProvider);
        ref.invalidate(filteredActivitiesProvider);
        ref.invalidate(pendingAssignmentsProvider);
      }
      if (!mounted) return;
      setState(() {
        _didImport = true;
        _notice = _BackupNotice(
          type: _BackupNoticeType.success,
          message: result.legacy
              ? '${result.importedPersonnel} yeni personel eski yedekten aktarıldı.'
              : 'Geri yükleme tamamlandı: ${result.importedPersonnel} personel, '
                  '${result.importedActivities} faaliyet ve '
                  '${result.importedTemgundrapDocuments} TEMGÜNDRAP belgesi.',
        );
      });
    } on FormatException catch (error) {
      if (mounted) _showError(error.message);
    } on Object catch (error, stackTrace) {
      _reportBackupError('Yedek geri yüklenemedi', error, stackTrace);
      if (mounted) {
        _showError('Yedek geri yüklenemedi; mevcut veriler korunmuştur.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _confirmRestore(AppBackupPreview preview) async {
    if (preview.legacy) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mevcut veriler değiştirilsin mi?'),
            content: const Text(
              'Tam geri yükleme mevcut personel, görev, matris ve '
              'TEMGÜNDRAP kayıtlarının yerine yedekteki verileri koyar. '
              'Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                key: const Key('backup-confirm-restore'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Geri yükle'),
              ),
            ],
          ),
        ) ??
        false;
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
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (mounted) _showError('Panoda yedek metni bulunamadı.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _loadBackupText(text);
    } on FormatException catch (error) {
      if (mounted) _showError(error.message);
    } on Object catch (error, stackTrace) {
      _reportBackupError('Panodaki yedek okunamadı', error, stackTrace);
      if (mounted) _showError('Panodaki yedek okunamadı.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() {
      _notice = _BackupNotice(type: _BackupNoticeType.error, message: message);
    });
  }

  void _reportBackupError(
    String context,
    Object error,
    StackTrace stackTrace,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Nizam yedekleme',
        context: ErrorDescription(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final maxHeight = (mediaQuery.size.height -
            mediaQuery.viewInsets.bottom -
            mediaQuery.padding.top -
            (widget.isBottomSheet ? 12 : 48))
        .clamp(
            360.0, mediaQuery.size.height * (widget.isBottomSheet ? .94 : .88));
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
        height: maxHeight,
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildContent(keyboardVisible)),
          ],
        ),
      ),
    );
    if (widget.isBottomSheet) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
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

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.storage_rounded, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tam yedekleme ve geri yükleme',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text('Bulut gerekmez; dosya sizin seçtiğiniz yerde kalır.'),
              ],
            ),
          ),
          IconButton(onPressed: _close, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }

  Widget _buildContent(bool keyboardVisible) {
    final isExport = _mode == _BackupMode.export;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 6, 20, keyboardVisible ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_BackupMode>(
            segments: const [
              ButtonSegment(
                value: _BackupMode.export,
                icon: Icon(Icons.save_alt_rounded),
                label: Text('Yedekle'),
              ),
              ButtonSegment(
                value: _BackupMode.import,
                icon: Icon(Icons.restore_rounded),
                label: Text('Geri yükle'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: _isLoading
                ? null
                : (selection) => setState(() {
                      _mode = selection.first;
                      _notice = null;
                    }),
          ),
          if (_notice != null) ...[
            const SizedBox(height: 12),
            _NoticeCard(notice: _notice!),
          ],
          const SizedBox(height: 16),
          if (isExport) _buildExportContent() else _buildRestoreContent(),
        ],
      ),
    );
  }

  Widget _buildExportContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _InfoCard(
          icon: Icons.inventory_2_outlined,
          title: 'Yedekte neler var?',
          text: 'İsimler, timler, kullanıcılar, telefonlar, görevler, aylık '
              'matris, faaliyet arşivi, raporlar, takma adlar, toplu aktarım '
              'geçmişi ve TEMGÜNDRAP belgeleri.',
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          icon: Icons.folder_outlined,
          title: 'Uygulama silinse de koruyun',
          text: 'Açılan kaydet ekranından İndirilenler gibi cihazın yerel '
              'bir klasörünü seçin. Uygulamanın kendi klasörüne bırakmayın.',
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          icon: Icons.privacy_tip_outlined,
          title: 'Dosyayı güvenli tutun',
          text: 'Yedek kişisel bilgiler içerir. Yalnızca güvenilir bir yerel '
              'klasörde saklayın ve başkalarıyla paylaşmayın.',
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('backup-create'),
          onPressed: _isLoading ? null : _exportBackup,
          icon: const Icon(Icons.save_alt_rounded),
          label: const Text('Tam yedeği cihazda sakla'),
        ),
        if (_textController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('backup-copy'),
            onPressed: _copyBackup,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Yedek metnini de kopyala'),
          ),
        ],
      ],
    );
  }

  Widget _buildRestoreContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('backup-pick-file'),
          onPressed: _isLoading ? null : _pickBackup,
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Yedek dosyası seç'),
        ),
        TextButton.icon(
          key: const Key('backup-paste'),
          onPressed: _isLoading ? null : _pasteBackup,
          icon: const Icon(Icons.content_paste_rounded),
          label: const Text('Panodaki eski yedeği kullan'),
        ),
        SizedBox(
          height: 1,
          child: Opacity(
            opacity: 0,
            child: TextField(
              key: const Key('backup-text-field'),
              controller: _textController,
            ),
          ),
        ),
        if (_preview != null) ...[
          const SizedBox(height: 12),
          _BackupPreviewCard(preview: _preview!),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('backup-restore'),
            onPressed: _isLoading ? null : _importBackup,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Yedeği geri yükle'),
          ),
        ],
      ],
    );
  }
}

class _BackupPreviewCard extends StatelessWidget {
  const _BackupPreviewCard({required this.preview});

  final AppBackupPreview preview;

  @override
  Widget build(BuildContext context) {
    final date = preview.exportedAt.millisecondsSinceEpoch == 0
        ? 'Eski yedek'
        : DateFormat('dd.MM.yyyy HH:mm').format(preview.exportedAt.toLocal());
    return _InfoCard(
      icon: Icons.fact_check_outlined,
      title: preview.legacy ? 'Eski personel yedeği' : 'Doğrulanmış tam yedek',
      text: '$date • ${preview.personnelCount} personel • '
          '${preview.activityCount} faaliyet • '
          '${preview.assignmentCount} görev kaydı • '
          '${preview.temgundrapDocumentCount} TEMGÜNDRAP',
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(text),
              ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(notice.message)),
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
