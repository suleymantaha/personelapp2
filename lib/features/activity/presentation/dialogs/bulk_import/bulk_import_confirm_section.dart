import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

class BulkImportConfirmSection extends StatelessWidget {
  const BulkImportConfirmSection({
    required this.blocks,
    required this.issues,
    required this.unresolvedPersonnelCount,
    required this.isSaving,
    required this.isMobile,
    required this.onSave,
    required this.onReturnToPreview,
    super.key,
  });

  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final int unresolvedPersonnelCount;
  final bool isSaving;
  final bool isMobile;
  final VoidCallback onSave;
  final VoidCallback onReturnToPreview;

  @override
  Widget build(BuildContext context) {
    final hasBlocking =
        issues.any((issue) => issue.isBlocking) || unresolvedPersonnelCount > 0;
    final totalDays = blocks.map((b) => b.parsedDate).toSet().length;
    final totalPersonnel =
        blocks.fold<int>(0, (c, b) => c + b.personnelList.length);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 24 : 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasBlocking ? Icons.error_rounded : Icons.task_alt_rounded,
            size: 64,
            color: hasBlocking ? context.rejectedColor : context.approvedColor,
          ),
          const SizedBox(height: 20),
          Text(
            hasBlocking ? context.l10n.bulkImportConfirmCannotSave : context.l10n.bulkImportConfirmReadyToSave,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  hasBlocking ? context.rejectedColor : context.approvedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasBlocking
                ? context.l10n.bulkImportConfirmResolveIssues
                : context.l10n.bulkImportConfirmSummary(
                    blocks.length,
                    totalPersonnel,
                    totalDays,
                  ),
            style: TextStyle(fontSize: 16, color: context.textMuted),
          ),
          const SizedBox(height: 24),
          if (!hasBlocking)
            AnimatedScale(
              scale: isSaving ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: FilledButton.icon(
                key: const Key('bulk-import-save-button'),
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.onStatusColor(context.approvedColor),
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  context.l10n.bulkImportSaveActivitiesButton,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.approvedColor,
                  foregroundColor: context.onStatusColor(context.approvedColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              key: const Key('bulk-goto-problem'),
              onPressed: onReturnToPreview,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(context.l10n.bulkImportConfirmReturnButton),
            ),
        ],
      ),
    );
  }
}
