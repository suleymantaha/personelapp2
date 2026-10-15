import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

/// Last review before writing: every source block remains an individual
/// assignment card, including blocks sharing the same date and team.
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

  static String displayDate(String rawDate) {
    final date = DateTime.tryParse(rawDate.trim());
    if (date == null) return rawDate.trim().isEmpty ? 'Tarih belirtilmedi' : rawDate;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasBlocking = issues.any((issue) => issue.isBlocking) ||
        unresolvedPersonnelCount > 0 ||
        blocks.isEmpty ||
        blocks.any((block) =>
            block.personnelList.isEmpty ||
            block.parsedDate.trim().isEmpty ||
            block.parsedActivityType.trim().isEmpty);
    final totalDays = blocks.map((block) => block.parsedDate).toSet().length;
    final totalAssignments = blocks.fold<int>(
      0,
      (count, block) => count + block.personnelList.length,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasBlocking
                ? context.l10n.bulkImportConfirmCannotSave
                : context.l10n.bulkImportConfirmReadyToSave,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: hasBlocking ? context.rejectedColor : context.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            hasBlocking
                ? context.l10n.bulkImportConfirmResolveIssues
                : 'Lütfen hangi takımın hangi tarihe ekleneceğini kontrol edin.',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Row(
              children: [
                _SummaryMetric(value: '${blocks.length}', label: 'kart'),
                _SummaryMetric(value: '$totalAssignments', label: 'personel kaydı'),
                _SummaryMetric(value: '$totalDays', label: 'gün'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Eklenecek kayıtlar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                '${blocks.length} kart',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              key: const Key('bulk-import-confirm-record-list'),
              itemCount: blocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final block = blocks[index];
                final hasTeam = block.parsedTimName.trim().isNotEmpty;
                return Container(
                  key: Key('bulk-import-confirm-record-$index'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasTeam ? context.cardBorderColor : context.pendingColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasTeam ? Icons.groups_rounded : Icons.info_outline_rounded,
                        size: 22,
                        color: hasTeam ? context.accentOrOlive : context.pendingColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasTeam ? block.parsedTimName : 'Takım belirtilmedi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${block.personnelList.length} personel • ${block.parsedActivityType.isEmpty ? 'Görev belirtilmedi' : block.parsedActivityType}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: context.accentOrOlive, size: 17),
                          const SizedBox(height: 4),
                          Text(
                            displayDate(block.parsedDate),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onReturnToPreview,
                  child: Text(context.l10n.bulkImportConfirmReturnButton),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const Key('bulk-import-save-button'),
                  onPressed: isSaving || hasBlocking ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(context.l10n.bulkImportConfirmSaveButton),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.approvedColor,
                    foregroundColor: context.onStatusColor(context.approvedColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
