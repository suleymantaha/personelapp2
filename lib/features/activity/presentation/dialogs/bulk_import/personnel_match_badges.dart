import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'match_status_indicator.dart';

class PersonnelMatchBadges extends StatelessWidget {
  const PersonnelMatchBadges({
    required this.item,
    required this.duplicateAssignments,
    required this.isFocused,
    required this.onConfirmSuggestion,
    super.key,
  });

  final ParsedPersonnelItem item;
  final List<String>? duplicateAssignments;
  final bool isFocused;
  final VoidCallback? onConfirmSuggestion;

  @override
  Widget build(BuildContext context) {
    final duplicate = duplicateAssignments?.isNotEmpty == true;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isFocused)
          Container(
            key: const Key('bulk-focused-person-badge'),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: !item.isMatched
                  ? context.rejectedColor
                  : context.warningColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.east_rounded,
                  size: 10,
                  color: context.onStatusColor(!item.isMatched
                      ? context.rejectedColor
                      : context.warningColor),
                ),
                const SizedBox(width: 3),
                Text(
                  !item.isMatched ? context.l10n.bulkImportSelectedError : context.l10n.bulkImportReviewedPersonnel,
                  style: TextStyle(
                    color: context.onStatusColor(!item.isMatched
                        ? context.rejectedColor
                        : context.warningColor),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        MatchStatusIndicator(item: item),
        if (duplicate)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: context.rejectedColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.l10n.bulkImportDuplicateOnSameDate(duplicateAssignments!.join(', ')),
              key: const Key('bulk-duplicate-warning'),
              style: TextStyle(
                color: context.rejectedColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (item.teamMismatch && !item.reviewConfirmed)
          InkWell(
            onTap: onConfirmSuggestion,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: context.warningBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.warningColor,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: context.warningColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      context.l10n.bulkImportTeamMismatchAccept,
                      key: const Key('bulk-team-mismatch-warning'),
                      style: TextStyle(
                        color: context.warningColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
