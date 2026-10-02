import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class PersonnelMatchHeader extends StatelessWidget {
  const PersonnelMatchHeader({
    required this.item,
    required this.onDelete,
    super.key,
  });

  final ParsedPersonnelItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rawRankText = item.rawRank.trim();
    final rawNameText = item.rawName.trim();
    final matchedName = item.isMatched
        ? '${item.matchedRutbe ?? ''} ${item.matchedAdSoyad}'.trim()
        : 'Personel seçilmedi';

    final hasNameDiff = item.isMatched &&
        (rawNameText.toLowerCase() !=
                (item.matchedAdSoyad ?? '').toLowerCase() ||
            (rawRankText.isNotEmpty &&
                item.matchedRutbe != null &&
                rawRankText.toLowerCase() != item.matchedRutbe!.toLowerCase()));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: context.accentOrOlive.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${item.rawIndex}',
            style: TextStyle(
              color: context.accentOrOlive,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.isMatched ? matchedName : rawNameText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: item.isMatched ? null : context.rejectedColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.fade,
                      softWrap: true,
                    ),
                  ),
                  if (item.isMatched &&
                      item.reviewConfirmed &&
                      item.matchConfidence == 1.0 &&
                      hasNameDiff) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Hafızadan Otomatik Eşleşti',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.warningBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.warningColor,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 11,
                              color: context.warningColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Hafızadan',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.warningColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasNameDiff || item.sourceLineNumber != null) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (hasNameDiff)
                      'Metinde: $rawRankText $rawNameText'.trim(),
                    if (item.sourceLineNumber != null)
                      '📍 Satır ${item.sourceLineNumber}',
                  ].join(' • '),
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          key: const Key('bulk-person-delete'),
          tooltip: 'Personeli kaldır',
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: context.rejectedColor,
            size: 18,
          ),
        ),
      ],
    );
  }
}
