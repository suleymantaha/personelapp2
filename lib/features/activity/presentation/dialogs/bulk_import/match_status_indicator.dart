import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class MatchStatusIndicator extends StatelessWidget {
  const MatchStatusIndicator({required this.item, super.key});

  final ParsedPersonnelItem item;

  @override
  Widget build(BuildContext context) {
    final (label, color, background, icon) = switch (item) {
      ParsedPersonnelItem(reviewConfirmed: true, isMatched: true) => (
          'Kullanıcı onayladı',
          context.approvedColor,
          context.customColors.statusDutyBg,
          Icons.verified_rounded,
        ),
      ParsedPersonnelItem(teamMismatch: true) => (
          'Tim disi gorev',
          context.warningColor,
          context.warningBgColor,
          Icons.account_tree_outlined,
        ),
      ParsedPersonnelItem(matchConfidence: < 0.9, isMatched: true) => (
          item.matchConfidence > 0
              ? 'Eşleşmeyi kontrol edin (%${(item.matchConfidence * 100).toInt()})'
              : 'Eşleşmeyi kontrol edin',
          context.warningColor,
          context.warningBgColor,
          Icons.help_rounded,
        ),
      ParsedPersonnelItem(matchConfidence: >= 0.9, isMatched: true) => (
          'Eşleşti',
          context.approvedColor,
          context.customColors.statusDutyBg,
          Icons.check_circle_rounded,
        ),
      _ => (
          'Eşleşmedi',
          context.rejectedColor,
          context.rejectedBgColor,
          Icons.warning_amber_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
