import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';

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
            matchConfidence: 1,
          ),
          teamName: '9-B Timi',
          onSelect: () {},
          onDelete: () {},
        ),
      ),
    ),
  );
}

@Preview(
    name: 'Kısmi Eşleşmiş Onay Bekleyen Personel Kartı', group: 'Bulk Import')
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

@Preview(
    name: 'Eşleşmemiş Hızlı Ekle Butonlu Personel Kartı', group: 'Bulk Import')
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
