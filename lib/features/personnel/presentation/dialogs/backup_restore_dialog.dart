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

      setState(() {
        _textController.text = jsonStr;
        _statusMessage = '✅ Personel ve Tim yedeği başarıyla oluşturuldu!';
      });
    } on Object catch (e) {
      setState(() {
        _statusMessage = '❌ Hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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

      setState(() {
        _statusMessage =
            '🎉 Başarılı! $count adet yeni personel ve tim veritabanına aktarıldı.';
      });
    } on Object catch (e) {
      setState(() {
        _statusMessage = '❌ Geçersiz yedek formatı veya hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.import_export_rounded,
                  color: Colors.teal,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Personel Verilerini Yedekle & Geri Yükle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _exportBackup,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Tüm Personelleri Dışa Aktar (Yedek Al)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _importBackup,
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Yedekten İçe Aktar (Geri Yükle)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Dışa aktarılan yedek koda buradan ulaşabilir veya geri yükleyeceğiniz yedeği buraya yapıştırabilirsiniz...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  if (_textController.text.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _textController.text),
                          );
                          if (!mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Yedek kopyalandı!')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Kopyala'),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
