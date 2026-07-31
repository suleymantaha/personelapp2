import 'package:flutter/material.dart';
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
            color: hasBlocking ? const Color(0xFFD32F2F) : const Color(0xFF16A34A),
          ),
          const SizedBox(height: 20),
          Text(
            hasBlocking ? 'Kaydedilemiyor' : 'Kayda Hazır',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: hasBlocking ? const Color(0xFFD32F2F) : const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasBlocking
                ? 'Lütfen önizleme adımına dönüp sorunları çözün.'
                : '${blocks.length} kart, $totalPersonnel personel, $totalDays gün',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'Faaliyetleri Kaydet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
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
              label: const Text('Önizlemeye Dön'),
            ),
        ],
      ),
    );
  }
}
