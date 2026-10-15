import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

/// Review all source cards before committing. The summary is part of the
/// scrollable content, so cards can reach the top of the available viewport
/// while the confirmation actions remain safely fixed at the bottom.
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
    if (date == null) {
      return rawDate.trim().isEmpty ? 'Tarih belirtilmedi' : rawDate;
    }
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasBlocking = issues.any((issue) => issue.isBlocking) ||
        unresolvedPersonnelCount > 0 ||
        blocks.isEmpty ||
        blocks.any(
          (block) =>
              block.personnelList.isEmpty ||
              block.parsedDate.trim().isEmpty ||
              block.parsedActivityType.trim().isEmpty,
        );
    final totalDays = blocks.map((block) => block.parsedDate).toSet().length;
    final totalAssignments = blocks.fold<int>(
      0,
      (count, block) => count + block.personnelList.length,
    );
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomScrollView(
            key: const Key('bulk-import-confirm-record-list'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 14, horizontalPadding, 12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        hasBlocking
                            ? context.l10n.bulkImportConfirmCannotSave
                            : context.l10n.bulkImportConfirmReadyToSave,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: hasBlocking
                                  ? context.rejectedColor
                                  : context.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasBlocking
                            ? context.l10n.bulkImportConfirmResolveIssues
                            : 'Hangi takımın hangi tarihe ekleneceğini kontrol edin.',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.cardBorderColor),
                        ),
                        child: Row(
                          children: [
                            _SummaryMetric(
                              value: '${blocks.length}',
                              label: 'kart',
                              icon: Icons.description_outlined,
                            ),
                            _SummaryMetric(
                              value: '$totalAssignments',
                              label: 'personel kaydı',
                              icon: Icons.groups_rounded,
                            ),
                            _SummaryMetric(
                              value: '$totalDays',
                              label: 'gün',
                              icon: Icons.calendar_month_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 0, horizontalPadding, 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final block = blocks[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == blocks.length - 1 ? 0 : 8,
                        ),
                        child: _ConfirmRecordRow(
                          key: Key('bulk-import-confirm-record-$index'),
                          block: block,
                        ),
                      );
                    },
                    childCount: blocks.length,
                  ),
                ),
              ),
            ],
          ),
        ),
        _ConfirmationActions(
          isSaving: isSaving,
          hasBlocking: hasBlocking,
          onReturnToPreview: onReturnToPreview,
          onSave: onSave,
          horizontalPadding: horizontalPadding,
        ),
      ],
    );
  }
}

class _ConfirmRecordRow extends StatelessWidget {
  const _ConfirmRecordRow({required this.block, super.key});

  final ParsedActivityBlock block;

  @override
  Widget build(BuildContext context) {
    final hasTeam = block.parsedTimName.trim().isNotEmpty;
    final color = hasTeam ? context.accentOrOlive : context.pendingColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasTeam ? context.cardBorderColor : context.pendingColor,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.09),
            child: Icon(
              hasTeam ? Icons.groups_rounded : Icons.info_outline_rounded,
              size: 21,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasTeam ? block.parsedTimName : 'Takım belirtilmedi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  '${block.personnelList.length} personel • ${block.parsedActivityType.isEmpty ? 'Görev belirtilmedi' : block.parsedActivityType}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.calendar_month_rounded, color: color, size: 17),
          const SizedBox(width: 4),
          Text(
            BulkImportConfirmSection.displayDate(block.parsedDate),
            maxLines: 1,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Use a fixed-height action surface. Fitted labels never wrap into tall,
/// narrow buttons at 320dp or at larger system text sizes.
class _ConfirmationActions extends StatelessWidget {
  const _ConfirmationActions({
    required this.isSaving,
    required this.hasBlocking,
    required this.onReturnToPreview,
    required this.onSave,
    required this.horizontalPadding,
  });

  final bool isSaving;
  final bool hasBlocking;
  final VoidCallback onReturnToPreview;
  final VoidCallback onSave;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.cardBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 46,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                key: const Key('bulk-import-confirm-back-button'),
                onPressed: isSaving ? null : onReturnToPreview,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: context.accentOrOlive,
                  side: BorderSide(color: context.accentOrOlive),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 19),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.bulkImportConfirmReturnButton,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 54,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('bulk-import-save-button'),
                onPressed: isSaving || hasBlocking ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: context.approvedColor,
                  foregroundColor: context.onStatusColor(context.approvedColor),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.bulkImportConfirmSaveButton,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 19, color: context.accentOrOlive),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
