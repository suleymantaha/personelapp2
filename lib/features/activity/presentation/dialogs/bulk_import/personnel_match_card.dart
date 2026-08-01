import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class PersonnelMatchCard extends StatelessWidget {
  const PersonnelMatchCard({
    required this.item,
    required this.teamName,
    required this.onSelect,
    required this.onDelete,
    this.onConfirmSuggestion,
    this.onAddNewPerson,
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
  final VoidCallback? onConfirmSuggestion;
  final VoidCallback? onAddNewPerson;

  @override
  Widget build(BuildContext context) {
    final duplicate = duplicateAssignments?.isNotEmpty == true;
    final problem = duplicate || item.hasWarning || !item.isMatched;

    final accentColor = !item.isMatched
        ? Colors.red.shade600
        : (item.hasWarning ? Colors.orange.shade800 : context.approvedColor);

    final borderColor = isFocused
        ? Colors.amber.shade800
        : (problem ? accentColor.withValues(alpha: 0.4) : context.cardBorderColor);

    final bgColor = isFocused
        ? Colors.amber.shade50
        : (problem
            ? accentColor.withValues(alpha: 0.035)
            : Theme.of(context).cardColor);

    final rawRankText = item.rawRank.trim();
    final rawNameText = item.rawName.trim();
    final matchedName = item.isMatched
        ? '${item.matchedRutbe ?? ''} ${item.matchedAdSoyad}'.trim()
        : 'Personel seçilmedi';

    final hasNameDiff = item.isMatched &&
        (rawNameText.toLowerCase() != (item.matchedAdSoyad ?? '').toLowerCase() ||
            (rawRankText.isNotEmpty &&
                item.matchedRutbe != null &&
                rawRankText.toLowerCase() != item.matchedRutbe!.toLowerCase()));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isFocused ? 2.5 : 1.0),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sol durum renk şeridi (Left Accent Indicator Bar)
              Container(
                width: 5,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst Satır: Sıra No + Rütbe + Ana Personel Başlığı + Sil Butonu
                      Row(
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
                          if (isFocused) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: !item.isMatched ? Colors.red.shade800 : Colors.amber.shade900,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.east_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    !item.isMatched ? 'SEÇİLİ HATA' : 'İNCELENEN PERSONEL',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.isMatched ? matchedName : rawNameText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: item.isMatched
                                        ? null
                                        : Colors.red.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                      color: Colors.grey.shade600,
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
                              color: Colors.redAccent.shade200,
                              size: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Rozetler Satırı: Eşleşme durumu + Mükerrer / Tim Uyuşmazlığı
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          MatchStatusIndicator(item: item),
                          if (duplicate)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
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
                            InkWell(
                              onTap: onConfirmSuggestion,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
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
                                      size: 13,
                                      color: Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tim uyuşmazlığı (Onayla)',
                                      key: const Key('bulk-team-mismatch-warning'),
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Alt Aksiyon Satırı
                      if (item.isMatched)
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
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (item.hasWarning && onConfirmSuggestion != null) ...[
                              FilledButton.icon(
                                key: const Key('bulk-person-confirm-suggestion'),
                                onPressed: onConfirmSuggestion,
                                icon: const Icon(Icons.done_rounded, size: 14),
                                label: const Text(
                                  '✓ Onayla',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            InkWell(
                              key: const Key('bulk-person-select'),
                              onTap: onSelect,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.accentOrOlive
                                      .withValues(alpha: 0.12),
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
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('bulk-person-select-btn'),
                                onPressed: onSelect,
                                icon: const Icon(Icons.search, size: 14),
                                label: const Text(
                                  'Personel Seç',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            if (onAddNewPerson != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  key: const Key('bulk-person-add-new'),
                                  onPressed: onAddNewPerson,
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 14,
                                  ),
                                  label: Text(
                                    '+ ${teamName.toLowerCase().contains('tim') ? teamName : '$teamName Timine'} Ekle',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: context.accentOrOlive,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          item.matchConfidence > 0
              ? 'Eşleşmeyi kontrol edin (%${(item.matchConfidence * 100).toInt()})'
              : 'Eşleşmeyi kontrol edin',
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Flutter Widget Previews (@Preview)
// -----------------------------------------------------------------------------

@Preview(name: 'Tam Eşleşmiş Personel Kartı', group: 'Bulk Import')
Widget personnelMatchCardMatchedPreview() {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: PersonnelMatchCard(
          item: ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'J.Asb.Çvş.',
            rawName: 'Ahmet TINAS',
            matchedPersonnelId: 1,
            matchedAdSoyad: 'Ahmet TINAS',
            matchedRutbe: 'J.Asb.Çvş.',
            matchedTimId: 1,
            matchConfidence: 1.0,
          ),
          teamName: '9-B Timi',
          onSelect: () {},
          onDelete: () {},
        ),
      ),
    ),
  );
}

@Preview(name: 'Kısmi Eşleşmiş Onay Bekleyen Personel Kartı', group: 'Bulk Import')
Widget personnelMatchCardReviewPreview() {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: PersonnelMatchCard(
          item: ParsedPersonnelItem(
            rawIndex: 2,
            rawRank: 'J.Uzm.Çvş.',
            rawName: 'Ramazan',
            matchedPersonnelId: 2,
            matchedAdSoyad: 'Ramazan BOSTAN',
            matchedRutbe: 'J.Uzm.Çvş.',
            matchedTimId: 2,
            matchConfidence: 0.85,
          ),
          teamName: '9-B Timi',
          onSelect: () {},
          onDelete: () {},
          onConfirmSuggestion: () {},
        ),
      ),
    ),
  );
}

@Preview(name: 'Eşleşmemiş Hızlı Ekle Butonlu Personel Kartı', group: 'Bulk Import')
Widget personnelMatchCardUnmatchedPreview() {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: PersonnelMatchCard(
          item: ParsedPersonnelItem(
            rawIndex: 3,
            rawRank: 'J.Uzm.Çvş.',
            rawName: 'Hakan KAYA',
          ),
          teamName: '6-B Timi',
          onSelect: () {},
          onDelete: () {},
          onAddNewPerson: () {},
        ),
      ),
    ),
  );
}

