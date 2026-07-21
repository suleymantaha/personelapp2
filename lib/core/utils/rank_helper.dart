/// Rütbe kıdem ağırlığı hesaplama yardımcı sınıfı.
/// Ağırlığı küçük olan rütbe üsttedir (Kıdemlidir).
int getRankWeight(String rutbe) {
  final r = rutbe.toUpperCase().trim();
  if (r.contains('ALBAY')) return 10;
  if (r.contains('YARBAY') || r.contains('YRB')) return 20;
  if (r.contains('BİNBAŞI') || r.contains('BBN')) return 30;
  if (r.contains('YÜZBAŞI') || r.contains('YZB')) return 40;
  if (r.contains('ÜSTEĞMEN') || r.contains('ÜTĞM')) return 50;
  if (r.contains('TEĞMEN') || r.contains('TĞM')) return 60;
  if (r.contains('ASTEĞMEN') || r.contains('ASTĞ')) return 70;

  if (r.contains('ASB.KD.BÇVŞ') || r.contains('KD.BÇVŞ')) return 90;
  if (r.contains('ASB.BÇVŞ') || r.contains('BÇVŞ')) return 100;
  if (r.contains('ASB.KD.ÜÇVŞ') || r.contains('KD.ÜÇVŞ')) return 110;
  if (r.contains('ASB.ÜÇVŞ') || r.contains('ÜÇVŞ')) return 120;
  if (r.contains('ASB.KD.ÇVŞ') || r.contains('KD.ÇVŞ')) return 130;
  if (r.contains('ASB.ÇVŞ') || r.contains('ASTSUBAY')) return 140;

  if (r.contains('UZM.J.KAD.ÇVŞ') || r.contains('UZM.J.KD.ÇVŞ')) return 150;
  if (r.contains('UZM.J.ÇVŞ')) return 160;
  if (r.contains('UZM.ÇVŞ') || r.contains('UZMAN ÇAVUŞ')) return 170;
  if (r.contains('UZM.ONB') || r.contains('UZMAN ONBAŞI')) return 180;

  if (r.contains('SÖZ.ER') || r.contains('SÖZLEŞMELİ ER')) return 190;
  if (r.contains('ER')) return 200;
  return 300; // Tanımlanamayan rütbeler en sona gider.
}

/// Standart askeri rütbe seçenekleri listesi
const List<String> kAskeriRutbeler = [
  'ALBAY',
  'YARBAY',
  'BİNBAŞI',
  'YÜZBAŞI',
  'ÜSTEĞMEN',
  'TEĞMEN',
  'ASTEĞMEN',
  'ASB.KD.BÇVŞ',
  'ASB.BÇVŞ',
  'ASB.KD.ÜÇVŞ',
  'ASB.ÜÇVŞ',
  'ASB.KD.ÇVŞ',
  'ASB.ÇVŞ',
  'UZM.J.KAD.ÇVŞ',
  'UZM.J.ÇVŞ',
  'UZM.ÇVŞ',
  'UZM.ONB',
  'SÖZ.ER',
  'ER',
  'DİĞER / ÖZEL RÜTBE',
];
