import 'package:flutter/material.dart';

import 'bulk_import_issue_summary.dart';

import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';

class BulkImportSaveButton extends StatelessWidget {
  const BulkImportSaveButton({
    required this.blocks,
    required this.issues,
    required this.isSaving,
    required this.onPressed,
    this.hasUnresolvedProblems = false,
    super.key,
  });

  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final bool isSaving;
  final VoidCallback onPressed;
  final bool hasUnresolvedProblems;

  @override
  Widget build(BuildContext context) {
    final isBlocked = issues.any((issue) => issue.isBlocking);
    return ElevatedButton.icon(
      key: const Key('bulk-import-save-button'),
      onPressed:
          blocks.isEmpty || isSaving || isBlocked || hasUnresolvedProblems
          ? null
          : onPressed,
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
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.bulkImportSaveActivitiesButton,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            context.l10n.bulkImportSaveSummarySub(
              blocks.length,
              blocks.map((block) => block.parsedDate).toSet().length,
            ),
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.approvedColor,
        foregroundColor: context.onStatusColor(context.approvedColor),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}

/// The footer exposes one active task at a time: resolve blocking issues or
/// continue to date-based confirmation. Optional reviews stay secondary.
class SmartSaveBar extends StatelessWidget {
  const SmartSaveBar({
    required this.problemCount,
    required this.problemLocs,
    required this.activeIssueFocusIndex,
    required this.onGotoProblem,
    required this.onGotoPrevious,
    required this.onSave,
    required this.isSaving,
    required this.blocks,
    required this.issues,
    required this.hasUnresolvedProblems,
    this.actionLabel,
    super.key,
  });

  final String? actionLabel;
  final int problemCount;
  final List<ProblemLocation> problemLocs;
  final int activeIssueFocusIndex;
  final VoidCallback onGotoProblem;
  final VoidCallback onGotoPrevious;
  final VoidCallback onSave;
  final bool isSaving;
  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final bool hasUnresolvedProblems;

  @override
  Widget build(BuildContext context) {
    final summary = BulkImportIssueSummary(
      locations: problemLocs,
      issues: issues,
    );
    final canContinue = blocks.isNotEmpty &&
        !summary.hasBlocking &&
        !hasUnresolvedProblems;
    final outstanding = summary.totalCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: context.cardBorderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canContinue && !isSaving && outstanding > 0) ...[
            FilledButton.icon(
              key: activeIssueFocusIndex < 0
                  ? const Key('bulk-goto-problem')
                  : const Key('bulk-wizard-next'),
              onPressed: onGotoProblem,
              icon: const Icon(Icons.build_circle_outlined, size: 18),
              label: Text(
                summary.hasBlocking
                    ? context.l10n.bulkImportOpenNextProblem
                    : context.l10n.bulkImportNextReview,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: context.rejectedColor,
                foregroundColor: context.onStatusColor(context.rejectedColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 6),
          ],
          FilledButton.icon(
            key: const Key('bulk-import-save-button'),
            onPressed: canContinue && !isSaving ? onSave : null,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              isSaving
                  ? context.l10n.commonSaving
                  : !canContinue && outstanding > 0
                      ? context.l10n.bulkImportActionsRemainingToSave(outstanding)
                      : actionLabel ?? context.l10n.bulkImportSaveWithCardCount(blocks.length),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.approvedColor,
              foregroundColor: context.onStatusColor(context.approvedColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (canContinue && summary.reviewCount > 0 && !isSaving) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              key: const Key('bulk-wizard-next'),
              onPressed: onGotoProblem,
              icon: const Icon(Icons.info_outline_rounded, size: 16),
              label: Text(context.l10n.bulkImportNextReview),
            ),
          ],
        ],
      ),
    );
  }
}
