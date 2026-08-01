import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
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
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_rounded),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Faaliyetleri Kaydet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            '${blocks.length} blok → '
            '${blocks.map((block) => block.parsedDate).toSet().length} günlük faaliyet',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.approvedColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}

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
    super.key,
  });

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
    final isBlocked = issues.any((issue) => issue.isBlocking);
    final criticalLocs = problemLocs.where((l) => l.isCritical).toList();
    final warningLocs = problemLocs.where((l) => !l.isCritical).toList();

    final blockingIssues = issues.where((i) => i.isBlocking).toList();
    final criticalCount = blockingIssues.length +
        (problemLocs.isNotEmpty ? criticalLocs.length : problemCount);
    final reviewWarningCount = problemLocs.isNotEmpty ? warningLocs.length : 0;

    final hasCritical = isBlocked || criticalCount > 0;
    final canSave = blocks.isNotEmpty &&
        !isSaving &&
        !hasCritical &&
        !hasUnresolvedProblems;

    final displayTotal = problemLocs.isNotEmpty
        ? problemLocs.length
        : (criticalCount + reviewWarningCount);
    final displayIndex = activeIssueFocusIndex < 0
        ? 1
        : (displayTotal > 0 ? (activeIssueFocusIndex % displayTotal) + 1 : 1);

    Color wizardButtonColor;
    String wizardButtonText;

    if (hasCritical) {
      wizardButtonColor = const Color(0xFFD32F2F);
      wizardButtonText = activeIssueFocusIndex < 0
          ? 'Soruna Git ($displayIndex/$displayTotal)'
          : 'Sonraki Sorun ($displayIndex/$displayTotal)';
    } else {
      wizardButtonColor = Colors.orange.shade800;
      wizardButtonText = activeIssueFocusIndex < 0
          ? 'İncelemeye Git ($displayIndex/$displayTotal)'
          : 'Sonraki İnceleme ($displayIndex/$displayTotal)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canSave) ...[
            AnimatedScale(
              scale: isSaving ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: FilledButton.icon(
                key: const Key('bulk-import-save-button'),
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  isSaving
                      ? 'Kaydediliyor...'
                      : 'Faaliyetleri Kaydet (${blocks.length} Kart)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.approvedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (reviewWarningCount > 0) ...[
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const Key('bulk-wizard-next'),
                onPressed: onGotoProblem,
                icon: Icon(Icons.info_outline_rounded, size: 16, color: wizardButtonColor),
                label: Text(
                  wizardButtonText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: wizardButtonColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: wizardButtonColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    key: const Key('bulk-wizard-prev'),
                    onPressed: onGotoPrevious,
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                    label: const Text(
                      'Önceki',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: wizardButtonColor,
                      side: BorderSide(color: wizardButtonColor.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    key: activeIssueFocusIndex < 0
                        ? const Key('bulk-goto-problem')
                        : const Key('bulk-wizard-next'),
                    onPressed: onGotoProblem,
                    icon: const Icon(Icons.build_circle_outlined, size: 18),
                    label: Text(
                      wizardButtonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: wizardButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FilledButton(
              key: const Key('bulk-import-save-button'),
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Kaydedilemiyor ($displayTotal Hata / İnceleme)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
