import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

class BulkImportEmptyState extends StatelessWidget {
  const BulkImportEmptyState({
    required this.issues,
    required this.onShowAll,
    super.key,
  });

  final List<BulkParseIssue> issues;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final hasBlockingParseIssue = issues.any((issue) => issue.isBlocking);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasBlockingParseIssue
                  ? Icons.rule_folder_outlined
                  : Icons.task_alt_rounded,
              size: 52,
              color: hasBlockingParseIssue
                  ? Colors.orange.shade800
                  : context.approvedColor,
            ),
            const SizedBox(height: 12),
            Text(
              hasBlockingParseIssue
                  ? 'Kartlara bağlı sorun kalmadı'
                  : 'Tüm kart sorunları çözüldü',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasBlockingParseIssue
                  ? 'Kalan kritik ayrıştırma sorunlarını yukarıdaki uyarı panelinden inceleyin.'
                  : 'İsterseniz tüm faaliyet kartlarına geri dönebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('bulk-filter-show-all'),
              onPressed: onShowAll,
              icon: const Icon(Icons.view_list_outlined),
              label: const Text('TÜM KARTLARI GÖSTER'),
            ),
          ],
        ),
      ),
    );
  }
}
