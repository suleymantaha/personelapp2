import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/services/personnel_backup_service.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({required this.database, super.key});
  final AppDatabase database;

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final service = PersonnelBackupService(widget.database);
      final jsonStr = await service.exportBackupJson();
      if (!mounted) return;

      setState(() {
        _textController.text = jsonStr;
        _statusMessage = '✅ Personel ve Tim yedeği başarıyla oluşturuldu!';
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = '❌ Yedek oluşturulamadı. Lütfen tekrar deneyin.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _importBackup() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _statusMessage =
            '⚠️ Lütfen aktarılacak yedek metnini kutuya yapıştırın.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final service = PersonnelBackupService(widget.database);
      final count = await service.importBackupJson(input);
      if (!mounted) return;

      setState(() {
        _statusMessage =
            '🎉 Başarılı! $count adet yeni personel ve tim veritabanına aktarıldı.';
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = '❌ Yedek doğrulanamadı veya içe aktarılamadı.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.cloud_sync_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yedekleme ve geri yükleme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Personel ve tim verilerinizi güvenle taşıyın.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useRow = constraints.maxWidth >= 500;
                  final exportButton = _ActionButton(
                    icon: Icons.file_download_outlined,
                    title: 'Yedek oluştur',
                    subtitle: 'Verileri dışa aktar',
                    color: colorScheme.primary,
                    onPressed: _isLoading ? null : _exportBackup,
                  );
                  final importButton = _ActionButton(
                    icon: Icons.file_upload_outlined,
                    title: 'Yedeği geri yükle',
                    subtitle: 'Kutudaki verileri içe aktar',
                    color: colorScheme.secondary,
                    onPressed: _isLoading ? null : _importBackup,
                  );

                  if (useRow) {
                    return Row(
                      children: [
                        Expanded(child: exportButton),
                        const SizedBox(width: 12),
                        Expanded(child: importButton),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      exportButton,
                      const SizedBox(height: 10),
                      importButton,
                    ],
                  );
                },
              ),
              if (_isLoading) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(),
              ],
              if (_statusMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Yedek verisi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_textController.text.isNotEmpty)
                    TextButton.icon(
                      onPressed: _copyBackup,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Kopyala'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: TextField(
                  controller: _textController,
                  onChanged: (_) => setState(() {}),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    hintText:
                        'Yedek oluşturduğunuzda veri burada görünür. Geri yüklemek için daha önce kopyaladığınız yedek metnini buraya yapıştırın.',
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyBackup() async {
    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yedek panoya kopyalandı.')),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
