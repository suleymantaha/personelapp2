import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

enum ArchiveExportType {
  excel,
  pdf,
  print,
  text,
}

Future<ArchiveExportType?> showArchiveExportSheet(
  BuildContext context, {
  required String subtitle,
}) {
  return showModalBottomSheet<ArchiveExportType>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => ArchiveExportSheet(subtitle: subtitle),
  );
}

class ArchiveExportSheet extends StatelessWidget {
  const ArchiveExportSheet({
    required this.subtitle,
    super.key,
  });

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.ios_share_rounded,
                  color: context.accentOrOlive,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dışa Aktar ve Yazdır',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.accentOrOlive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.table_chart_outlined,
                  color: context.accentOrOlive,
                ),
              ),
              title: const Text(
                'Excel Olarak Aktar (.xlsx)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Hesap tabloları ve dijital arşiv için'),
              onTap: () => Navigator.pop(context, ArchiveExportType.excel),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.pdfButtonBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: context.pdfButtonBg,
                ),
              ),
              title: const Text(
                'PDF Belgesi Paylaş',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Askeri formatta PDF oluşturur ve paylaşır'),
              onTap: () => Navigator.pop(context, ArchiveExportType.pdf),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.print_outlined,
                  color: Colors.blue,
                ),
              ),
              title: const Text(
                'Doğrudan Yazdır',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Bağlı yazıcıdan doğrudan çıktı alır'),
              onTap: () => Navigator.pop(context, ArchiveExportType.print),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.textPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.share_outlined,
                  color: context.textPrimary,
                ),
              ),
              title: const Text(
                'Metin Listesi Paylaş',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('WhatsApp/SMS için hizalı metin çıktısı'),
              onTap: () => Navigator.pop(context, ArchiveExportType.text),
            ),
          ],
        ),
      ),
    );
  }
}
