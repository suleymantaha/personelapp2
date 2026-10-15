part of 'bulk_import_preview_section.dart';

enum _PreviewFilter { problems, all, ready }

/// Single compact overview: detailed problems are displayed in the issue card,
/// instead of duplicating a dashboard of five independent metrics.
class _CorrectnessPanel extends StatelessWidget {
  const _CorrectnessPanel({
    required this.cardCount,
    required this.personnelCount,
    required this.dayCount,
    required this.criticalCount,
    required this.reviewCount,
    required this.actionCount,
    required this.hasBlocking,
    required this.compact,
    required this.onClearAll,
    required this.onStartWizard,
    this.onConfirmAllSuggestions,
  });

  final int cardCount;
  final int personnelCount;
  final int dayCount;
  final int criticalCount;
  final int reviewCount;
  final int actionCount;
  final bool hasBlocking;
  final bool compact;
  final VoidCallback onClearAll;
  final VoidCallback? onStartWizard;
  final VoidCallback? onConfirmAllSuggestions;

  @override
  Widget build(BuildContext context) {
    final status = actionCount == 0
        ? context.l10n.bulkImportAllChecksPassed
        : hasBlocking
            ? context.l10n.bulkImportActionsRequiredBeforeSave(actionCount)
            : context.l10n.bulkImportOptionalReviewsCount(actionCount);
    final statusColor = hasBlocking
        ? context.rejectedColor
        : actionCount > 0
            ? context.pendingColor
            : context.approvedColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.bulkImportCorrectnessPanelTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: onClearAll,
                icon: Icon(Icons.delete_outline_rounded,
                    size: 19, color: context.textSecondary),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                hasBlocking ? Icons.error_outline_rounded :
                    actionCount > 0 ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              if (hasBlocking)
                InkWell(
                  onTap: onStartWizard,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Text(
                      context.l10n.bulkImportCannotSaveStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$personnelCount personel  •  $cardCount kart  •  $dayCount gün'
            '${criticalCount > 0 ? '  •  $criticalCount kritik' : ''}'
            '${reviewCount > 0 ? '  •  $reviewCount inceleme' : ''}',
            style: TextStyle(fontSize: 12, color: context.textSecondary),
          ),
          if (onConfirmAllSuggestions != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('bulk-confirm-all-suggestions'),
                onPressed: onConfirmAllSuggestions,
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: Text(context.l10n.bulkImportConfirmAllAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
