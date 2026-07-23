/// Rütbe kıdem ağırlığı hesaplama yardımcı sınıfı.
/// Ağırlığı küçük olan rütbe üsttedir (Kıdemlidir).
int getRankWeight(String rutbe) {
  final r = rutbe.toUpperCase().trim();

  // Subaylar
  if (r.contains('ALBAY') || r.contains('ALB')) {
    return 10;
  }
  if (r.contains('YARBAY') || r.contains('YRB')) {
    return 20;
  }
  if (r.contains('BİNBAŞI') || r.contains('BNB') || r.contains('BBN')) {
    return 30;
  }
  if (r.contains('YÜZBAŞI') || r.contains('YZB')) {
    return 40;
  }
  if (r.contains('ÜSTEĞMEN') || r.contains('ÜTĞM')) {
    return 50;
  }
  if (r.contains('TEĞMEN') || r.contains('TĞM')) {
    return 60;
  }
  if (r.contains('ASTEĞMEN') || r.contains('ASTĞ')) {
    return 70;
  }

  // Astsubaylar
  if (r.contains('KD.BÇVŞ') || r.contains('KD. BÇVŞ')) {
    return 90;
  }
  if (r.contains('BÇVŞ')) {
    return 100;
  }
  if (r.contains('KD.ÜÇVŞ') || r.contains('KD. ÜÇVŞ')) {
    return 110;
  }
  if (r.contains('ÜÇVŞ')) {
    return 120;
  }
  if (r.contains('ASB.KD.ÇVŞ') ||
      (r.contains('KD.ÇVŞ') && (r.contains('ASB') || r.contains('ASTSUBAY')))) {
    return 130;
  }
  if (r.contains('ASB.ÇVŞ') ||
      r.contains('ASTSUBAY') ||
      (r.contains('ÇVŞ') && r.contains('ASB'))) {
    return 140;
  }

  // Uzman Erbaş / Uzman Çavuş / Uzman Onbaşı
  if (r.contains('UZM.ÇVŞ') ||
      r.contains('UZM.J') ||
      r.contains('UZMAN ÇAVUŞ')) {
    return 170;
  }
  if (r.contains('UZM.ONB') || r.contains('UZMAN ONBAŞI')) {
    return 180;
  }

  // Erbaş / Er
  if (r.contains('SÖZ.ER') || r.contains('SÖZLEŞMELİ ER')) {
    return 190;
  }
  if (r.contains('ER')) {
    return 200;
  }
  return 300; // Tanımlanamayan rütbeler en sona gider.
}

/// Eski veya tam isim rütbeleri yeni kısaltmalı ve J. önekli rütbeye dönüştürür.
String normalizeRank(String rawRutbe) {
  final trimmed = rawRutbe.trim();
  if (kAskeriRutbeler.contains(trimmed)) return trimmed;
  final upper = trimmed.toUpperCase();
  switch (upper) {
    case 'ALBAY':
    case 'J.ALBAY':
      return 'J.Alb.';
    case 'YARBAY':
    case 'J.YARBAY':
      return 'J.Yrb.';
    case 'BİNBAŞI':
    case 'J.BİNBAŞI':
      return 'J.Bnb.';
    case 'YÜZBAŞI':
    case 'J.YÜZBAŞI':
      return 'J.Yzb.';
    case 'ÜSTEĞMEN':
    case 'J.ÜSTEĞMEN':
      return 'J.Ütğm.';
    case 'TEĞMEN':
    case 'J.TEĞMEN':
      return 'J.Tğm.';
    case 'ASTEĞMEN':
    case 'J.ASTEĞMEN':
      return 'J.Astğm.';
    case 'ASB.KD.BÇVŞ':
    case 'J.ASB.KD.BÇVŞ':
      return 'J.Asb.Kd.Bçvş.';
    case 'ASB.BÇVŞ':
    case 'J.ASB.BÇVŞ':
      return 'J.Asb.Bçvş.';
    case 'ASB.KD.ÜÇVŞ':
    case 'J.ASB.KD.ÜÇVŞ':
      return 'J.Asb.Kd.Üçvş.';
    case 'ASB.ÜÇVŞ':
    case 'J.ASB.ÜÇVŞ':
      return 'J.Asb.Üçvş.';
    case 'ASB.KD.ÇVŞ':
    case 'J.ASB.KD.ÇVŞ':
      return 'J.Asb.Kd.Çvş.';
    case 'ASB.ÇVŞ':
    case 'J.ASB.ÇVŞ':
      return 'J.Asb.Çvş.';
    case 'UZM.J.KAD.ÇVŞ':
    case 'UZM.J.KD.ÇVŞ':
    case 'UZM.J.ÇVŞ':
    case 'UZM.KD.ÇVŞ':
    case 'UZM.ÇVŞ':
    case 'J.UZM.ÇVŞ':
      return 'J.Uzm.Çvş.';
    case 'UZM.ONB':
    case 'J.UZM.ONB':
      return 'J.Uzm.Onb.';
    case 'SÖZ.ER':
    case 'J.SÖZ.ER':
      return 'J.Söz.Er';
    case 'ER':
    case 'J.ER':
      return 'J.Er';
    default:
      return trimmed;
  }
}

/// Standart askeri rütbe seçenekleri listesi (Jandarma kısaltmalı format)
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
  'J.Uzm.Onb.',
  'J.Söz.Er',
  'J.Er',
  'DİĞER / ÖZEL RÜTBE',
];
