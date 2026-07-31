import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class PersonnelMatchCard extends StatelessWidget {
  const PersonnelMatchCard({
    required this.item,
    required this.teamName,
    required this.onSelect,
    required this.onDelete,
    this.duplicateAssignments,
    this.isFocused = false,
    super.key,
  });

  final ParsedPersonnelItem item;
  final String teamName;
  final List<String>? duplicateAssignments;
  final bool isFocused;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final duplicate = duplicateAssignments?.isNotEmpty == true;
    final problem = duplicate || item.needsReview;
    final borderColor = isFocused
        ? Colors.amber.shade800
        : (problem ? Colors.red.shade300 : context.cardBorderColor);
    final bgColor = isFocused
        ? Colors.amber.shade100
        : (problem
            ? Colors.red.withValues(alpha: 0.045)
            : Theme.of(context).cardColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isFocused ? 2.5 : 1.0),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Satır 1: Avatar + raw isim + sil butonu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: context.accentOrOlive.withValues(alpha: 0.14),
                child: Text(
                  '${item.rawIndex}',
                  style: TextStyle(
                    color: context.accentOrOlive,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${item.rawRank} ${item.rawName}'.trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                key: const Key('bulk-person-delete'),
                tooltip: 'Personeli kaldır',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
            ],
          ),
          // Satır 2: kaynak satır bilgisi
          if (item.sourceLineNumber != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.segment_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '📍 Satır ${item.sourceLineNumber}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          // Rozet satırı: durum + tim uyuşmazlığı
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              MatchStatusIndicator(item: item),
              if (duplicate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Aynı tarihte ayrıca: ${duplicateAssignments!.join(', ')}',
                    key: const Key('bulk-duplicate-warning'),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (item.teamMismatch && !item.reviewConfirmed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.shade300,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Tim uyuşmazlığı; onaylamak için dokunun',
                          key: const Key('bulk-team-mismatch-warning'),
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Eşleşen personel + değiştir butonu
          InkWell(
            key: const Key('bulk-person-select'),
            borderRadius: BorderRadius.circular(10),
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledValue(
                          label: 'EŞLEŞEN PERSONEL',
                          value: item.isMatched
                              ? '${item.matchedRutbe ?? ''} ${item.matchedAdSoyad}'
                                  .trim()
                              : 'Personel seçilmedi',
                          valueColor:
                              item.isMatched ? null : Colors.red.shade700,
                        ),
                        if (item.isMatched) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                teamName,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentOrOlive.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Değiştir',
                          style: TextStyle(
                            color: context.accentOrOlive,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: context.accentOrOlive,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledValue extends StatelessWidget {
  const LabeledValue({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class MatchStatusIndicator extends StatelessWidget {
  const MatchStatusIndicator({required this.item, super.key});

  final ParsedPersonnelItem item;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (item) {
      ParsedPersonnelItem(reviewConfirmed: true, isMatched: true) => (
          'Kullanıcı onayladı',
          context.approvedColor,
          Icons.verified_rounded,
        ),
      ParsedPersonnelItem(teamMismatch: true) => (
          'Tim onayı gerekli',
          Colors.orange.shade800,
          Icons.account_tree_outlined,
        ),
      ParsedPersonnelItem(matchConfidence: < 0.9, isMatched: true) => (
          'Eşleşmeyi kontrol edin',
          Colors.orange.shade800,
          Icons.help_rounded,
        ),
      ParsedPersonnelItem(matchConfidence: >= 0.9, isMatched: true) => (
          'Eşleşti',
          context.approvedColor,
          Icons.check_circle_rounded,
        ),
      _ => (
          'Eşleşmedi',
          Colors.red.shade700,
          Icons.warning_amber_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
