import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      key: cardKey,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: warningCount > 0
              ? context.pendingColor.withValues(alpha: 0.7)
              : context.cardBorderColor,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            key: headerKey,
            dense: true,
            leading: Icon(
              warningCount > 0
                  ? Icons.warning_amber_rounded
                  : Icons.shield_outlined,
              size: 19,
              color: warningCount > 0
                  ? context.pendingColor
                  : context.accentOrOlive,
            ),
            title: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (warningCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '$warningCount uyarı',
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
            onTap: onToggle,
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
