import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
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
                  ? context.warningColor
                  : context.approvedColor,
            ),
            const SizedBox(height: 12),
            Text(
              hasBlockingParseIssue
                  ? context.l10n.bulkImportEmptyNoCardIssues
                  : context.l10n.bulkImportEmptyAllIssuesResolved,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasBlockingParseIssue
                  ? context.l10n.bulkImportEmptyCheckNoticePanel
                  : context.l10n.bulkImportEmptyReturnToAllCards,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('bulk-filter-show-all'),
              onPressed: onShowAll,
              icon: const Icon(Icons.view_list_outlined),
              label: Text(context.l10n.bulkImportEmptyShowAllCards),
            ),
          ],
        ),
      ),
    );
  }
}
