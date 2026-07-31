import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

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
    required this.onSave,
    required this.isSaving,
    required this.blocks,
    required this.issues,
    required this.hasUnresolvedProblems,
    super.key,
  });

  final int problemCount;
  final List<({int blockIndex, int? personIndex})> problemLocs;
  final int activeIssueFocusIndex;
  final VoidCallback onGotoProblem;
  final VoidCallback onSave;
  final bool isSaving;
  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final bool hasUnresolvedProblems;

  @override
  Widget build(BuildContext context) {
    final isBlocked = issues.any((issue) => issue.isBlocking);
    final canSave = blocks.isNotEmpty &&
        !isSaving &&
        !isBlocked &&
        !hasUnresolvedProblems;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (problemCount > 0) ...[
            Row(
              children: [
                Icon(
                  Icons.error_rounded,
                  color: const Color(0xFFD32F2F),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$problemCount sorun çözülmeden kayıt yapılamaz.',
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (problemLocs.isNotEmpty)
              OutlinedButton.icon(
                key: const Key('bulk-goto-problem'),
                onPressed: onGotoProblem,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: Text(
                  'Soruna Git (${(activeIssueFocusIndex < 0 ? 1 : activeIssueFocusIndex + 1)}/${problemLocs.length})',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            const SizedBox(height: 10),
          ],
          AnimatedScale(
            scale: isSaving ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: FilledButton.icon(
              key: const Key('bulk-import-save-button'),
              onPressed: canSave ? onSave : null,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      canSave
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                    ),
              label: Text(
                canSave ? 'Faaliyetleri Kaydet' : 'Önce Sorunları Çözün',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: canSave
                    ? const Color(0xFF16A34A)
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
