/// Standart askeri rütbe seçenekleri listesi (Jandarma kısaltmalı format, kıdem sırasına göre).
const List<String> kAskeriRutbeler = [
  'J.Alb.',
  'J.Yrb.',
  'J.Bnb.',
  'J.Yzb.',
  'J.Ütğm.',
  'J.Tğm.',
  'J.Astğm.',
  'J.Asb.Kd.Bçvş.',
  'J.Asb.Bçvş.',
  'J.Asb.Kd.Üçvş.',
  'J.Asb.Üçvş.',
  'J.Asb.Kd.Çvş.',
  'J.Asb.Çvş.',
  'Uzm.J.',
  'J.Uzm.Çvş.',
  'J.Söz.Er',
  'J.Er',
  'DİĞER / ÖZEL RÜTBE',
];

/// Rütbe metnini standart formata dönüştürür.
String normalizeRank(String rawRutbe) {
  final trimmed = rawRutbe.trim();
  if (kAskeriRutbeler.contains(trimmed)) return trimmed;

  final upper = trimmed.toUpperCase().replaceAll(' ', '').replaceAll('.', '');
  for (final rank in kAskeriRutbeler) {
    final rankUpper = rank
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('.', '');
    if (rankUpper == upper || rankUpper.replaceFirst('J', '') == upper) {
      return rank;
    }
  }

  // Fallback matching without 'J'
  if (upper.contains('ALB')) return 'J.Alb.';
  if (upper.contains('YRB')) return 'J.Yrb.';
  if (upper.contains('BNB')) return 'J.Bnb.';
  if (upper.contains('YZB') || upper.contains('YÜZBAŞI')) return 'J.Yzb.';
  if (upper.contains('ÜTĞM')) return 'J.Ütğm.';
  if (upper.contains('TĞM') || upper.contains('TEĞMEN')) return 'J.Tğm.';
  if (upper.contains('ASTĞM')) return 'J.Astğm.';
  if (upper.contains('KDBÇVŞ')) return 'J.Asb.Kd.Bçvş.';
  if (upper.contains('BÇVŞ')) return 'J.Asb.Bçvş.';
  if (upper.contains('KDÜÇVŞ')) return 'J.Asb.Kd.Üçvş.';
  if (upper.contains('ÜÇVŞ')) return 'J.Asb.Üçvş.';
  if (upper.contains('KDÇVŞ')) return 'J.Asb.Kd.Çvş.';
  if (upper.contains('ASB') || upper.contains('ASTSB')) return 'J.Asb.Çvş.';
  if (upper.contains('UZMJ') ||
      upper.contains('UZM.J') ||
      upper == 'UZMJANDARMA') {
    return 'Uzm.J.';
  }
  if (upper.contains('UZM')) return 'J.Uzm.Çvş.';
  if (upper.contains('SÖZER')) return 'J.Söz.Er';
  if (upper == 'ER') return 'J.Er';

  return trimmed;
}

/// Rütbe kıdem ağırlığı hesaplama yardımcı fonksiyonu.
/// Ağırlığı küçük olan rütbe üsttedir (Kıdemlidir).
int getRankWeight(String rutbe) {
  final normalized = normalizeRank(rutbe);
  final index = kAskeriRutbeler.indexOf(normalized);

  if (index != -1) {
    return (index + 1) * 10;
  }

  return 300; // Tanımlanamayan rütbeler en sona gider.
}

/// Evrak özet tabloları için rütbe gruplaması ve sayım yardımcısı.
class RankSummaryCounts {
  const RankSummaryCounts({
    required this.subayCount,
    required this.astsubayCount,
    required this.uzmanJandarmaCount,
    required this.uzmanErbasCount,
    required this.erCount,
    required this.totalCount,
  });

  factory RankSummaryCounts.calculate(List<String> rawRanks) {
    var subay = 0;
    var astsubay = 0;
    var uzmJ = 0;
    var uzmErbas = 0;
    var er = 0;

    for (final raw in rawRanks) {
      final norm = normalizeRank(raw);
      final weight = getRankWeight(norm);

      if (weight <= 70) {
        subay++;
      } else if (weight <= 130) {
        astsubay++;
      } else if (norm == 'Uzm.J.' || norm.contains('Uzm.J')) {
        uzmJ++;
      } else if (norm == 'J.Uzm.Çvş.' || norm.contains('Uzm')) {
        uzmErbas++;
      } else {
        er++;
      }
    }

    return RankSummaryCounts(
      subayCount: subay,
      astsubayCount: astsubay,
      uzmanJandarmaCount: uzmJ,
      uzmanErbasCount: uzmErbas,
      erCount: er,
      totalCount: rawRanks.length,
    );
  }

  final int subayCount;
  final int astsubayCount;
  final int uzmanJandarmaCount;
  final int uzmanErbasCount;
  final int erCount;
  final int totalCount;
}
