import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'activity_metadata_label.dart';

class ActivityBlockHeader extends StatelessWidget {
  const ActivityBlockHeader({
    required this.block,
    required this.blockIdx,
    required this.visiblePersonnelIndexes,
    required this.problemCount,
    required this.unmatchedCount,
    required this.warningCount,
    required this.isBlockFocused,
    required this.effectiveIsExpanded,
    required this.onToggleExpand,
    required this.onEditBlock,
    required this.onRemoveBlock,
    super.key,
  });

  final ParsedActivityBlock block;
  final int blockIdx;
  final List<int>? visiblePersonnelIndexes;
  final int problemCount;
  final int unmatchedCount;
  final int warningCount;
  final bool isBlockFocused;
  final bool effectiveIsExpanded;
  final VoidCallback onToggleExpand;
  final void Function(int) onEditBlock;
  final void Function(int) onRemoveBlock;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('bulk-card-header-$blockIdx'),
      onTap: onToggleExpand,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(12),
        bottom: Radius.circular(effectiveIsExpanded ? 0 : 12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (block.parsedTimName.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                context.accentOrOlive.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            block.parsedTimName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: context.accentOrOlive,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.accentOrOlive.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.accentOrOlive.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            context.l10n.bulkImportDefaultSquad,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: context.accentOrOlive,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          block.parsedActivityType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ActivityMetadataLabel(
                        icon: Icons.calendar_today_rounded,
                        text: block.parsedDate,
                      ),
                      if (block.parsedTimeRange?.trim().isNotEmpty == true)
                        ActivityMetadataLabel(
                          icon: Icons.schedule_rounded,
                          text: block.parsedTimeRange!,
                        ),
                      _PersonnelCountPill(
                        text: visiblePersonnelIndexes == null
                            ? context.l10n.bulkImportBlockPersonnelCount(
                                block.personnelList.length,
                              )
                            : '$problemCount sorun / ${block.personnelList.length} p.',
                      ),
                      if (isBlockFocused)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (unmatchedCount > 0 ||
                                    block.personnelList.isEmpty)
                                ? context.rejectedColor
                                : context.warningColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (unmatchedCount > 0 ||
                                          block.personnelList.isEmpty)
                                      ? Icons.push_pin_rounded
                                      : Icons.search_rounded,
                                  size: 11,
                                  color: context.onStatusColor(
                                      unmatchedCount > 0 ||
                                              block.personnelList.isEmpty
                                          ? context.rejectedColor
                                          : context.warningColor),
                                ),
                                const SizedBox(width: 4),
                                 Text(
                                  (unmatchedCount > 0 ||
                                          block.personnelList.isEmpty)
                                      ? context.l10n.bulkImportFocusedError
                                      : context.l10n.bulkImportInspectedCard,
                                  style: TextStyle(
                                    color: context.onStatusColor(
                                        unmatchedCount > 0 ||
                                                block.personnelList.isEmpty
                                            ? context.rejectedColor
                                            : context.warningColor),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (block.personnelList.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                context.rejectedColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.l10n.bulkImportEmptyCard,
                            style: TextStyle(
                              color: context.rejectedColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (unmatchedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                context.rejectedColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.l10n.bulkImportUnmatchedCount(unmatchedCount),
                            style: TextStyle(
                              color: context.rejectedColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (warningCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.warningBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.l10n.bulkImportWarningCount(warningCount),
                            style: TextStyle(
                              color: context.warningColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.check_circle_rounded,
                          color: context.approvedColor,
                          size: 18,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // Genişletme / Daraltma Oku (Expand Chevron)
            Icon(
              effectiveIsExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: context.textSecondary,
              size: 22,
            ),

            PopupMenuButton<String>(
              key: Key('bulk-card-menu-$blockIdx'),
              tooltip: context.l10n.bulkImportCardActionsTooltip,
              elevation: 5,
              shadowColor: context.shadowColor,
              surfaceTintColor: context.colorScheme.surface,
              shape: modernPopupShape(context),
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
              onSelected: (value) {
                if (value == 'edit') {
                  onEditBlock(blockIdx);
                } else if (value == 'delete') {
                  onRemoveBlock(blockIdx);
                }
              },
              itemBuilder: (context) => [
                ModernMenuHeader<String>(
                  title: context.l10n.bulkImportCardActionsTitle,
                  subtitle: context.l10n.bulkImportCardActionsSubtitle,
                  icon: Icons.view_agenda_outlined,
                ),
                const PopupMenuDivider(),
                ModernPopupMenuItem(
                  option: ModernActionOption(
                    value: 'edit',
                    title: context.l10n.bulkImportEditCardTitle,
                    subtitle: context.l10n.bulkImportEditCardSubtitle,
                    icon: Icons.edit_outlined,
                  ),
                ),
                const PopupMenuDivider(),
                ModernPopupMenuItem(
                  option: ModernActionOption(
                    value: 'delete',
                    title: context.l10n.bulkImportDeleteCardTitle,
                    subtitle: context.l10n.bulkImportDeleteCardSubtitle,
                    icon: Icons.delete_outline_rounded,
                    isDestructive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonnelCountPill extends StatelessWidget {
  const _PersonnelCountPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.accentOrOlive,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: context.customColors.onAccentOrOlive,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
