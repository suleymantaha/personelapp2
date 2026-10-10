import 'package:flutter/material.dart';
import 'package:personelapp2/core/extensions/l10n_extension.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/widgets/app_card.dart';

class CollapsibleSquadCard extends StatelessWidget {
  const CollapsibleSquadCard({
    required this.cardKey,
    required this.headerKey,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.warningCount = 0,
    this.actions = const [],
    this.isSelected = false,
    this.selectionMode = false,
    this.onLongPress,
    this.onTap,
    super.key,
  });

  final Key cardKey;
  final Key headerKey;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final int warningCount;
  final List<Widget> actions;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    Color? effectiveBorderColor;
    if (isSelected) {
      effectiveBorderColor = primaryColor;
    } else if (warningCount > 0) {
      effectiveBorderColor = context.pendingColor.withValues(alpha: 0.7);
    }

    final effectiveBgColor = isSelected
        ? primaryColor.withValues(alpha: context.isDarkMode ? 0.16 : 0.08)
        : null;

    Widget leadingIcon;
    if (isSelected) {
      leadingIcon = Icon(
        Icons.check_circle_rounded,
        size: 20,
        color: primaryColor,
      );
    } else if (selectionMode) {
      leadingIcon = Icon(
        Icons.circle_outlined,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      );
    } else {
      leadingIcon = Icon(
        warningCount > 0
            ? Icons.warning_amber_rounded
            : Icons.shield_outlined,
        size: 19,
        color: warningCount > 0
            ? context.pendingColor
            : context.accentOrOlive,
      );
    }

    return AppCard(
      key: cardKey,
      padding: EdgeInsets.zero,
      borderColor: effectiveBorderColor,
      backgroundColor: effectiveBgColor,
      child: Column(
        children: [
          ListTile(
            key: headerKey,
            dense: true,
            leading: leadingIcon,
            title: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.bold,
                color: isSelected ? primaryColor : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (warningCount > 0 && !selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      context.l10n.collapsibleSquadCardWarningCount(warningCount),
                      style: TextStyle(
                        color: context.pendingColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ...actions,
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: onTap ?? onToggle,
            onLongPress: onLongPress,
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.cardGap,
                0,
                AppSpacing.cardGap,
                AppSpacing.sm,
              ),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }
}
