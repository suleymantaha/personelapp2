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
  'J.Uzm.Çvş.',
  'J.Söz.Er',
  'J.Er',
  'DİĞER / ÖZEL RÜTBE',
];

/// Rütbe metnini standart formata dönüştürür.
String normalizeRank(String rawRutbe) {
  final trimmed = rawRutbe.trim();
  if (kAskeriRutbeler.contains(trimmed)) return trimmed;

  // Harf büyüklüğü veya boşluk farkı varsa listedeki birebir karşılığını bulur
  final upper = trimmed.toUpperCase();
  for (final rank in kAskeriRutbeler) {
    if (rank.toUpperCase() == upper) return rank;
  }

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
