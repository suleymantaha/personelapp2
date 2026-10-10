/// Türkçe tarih, ay ve gün işlemlerini, askeri DTG formatlamalarını ve
/// kullanıcı/OCR metinlerindeki varyasyonları standartlaştıran merkezi yardımcı sınıfı.
class TurkishDateHelper {
  const TurkishDateHelper._();

  /// Standart Türkçe ay isimleri (1-indeksli erişim: 1 = Ocak, 12 = Aralık).
  static const List<String> months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  /// Resmi evrak ve çizelge başlıklarında kullanılan büyük harf formatı.
  static const List<String> monthsUpper = [
    'OCAK',
    'ŞUBAT',
    'MART',
    'NİSAN',
    'MAYIS',
    'HAZİRAN',
    'TEMMUZ',
    'AĞUSTOS',
    'EYLÜL',
    'EKİM',
    'KASIM',
    'ARALIK',
  ];

  /// 3 harfli kısa ay kısaltmaları.
  static const List<String> monthsShort = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  /// Askeri Tarih-Saat Grubu (DTG) için 3 harfli standart büyük harf kodları.
  static const List<String> militaryMonthCodes = [
    'OCA',
    'ŞUB',
    'MAR',
    'NİS',
    'MAY',
    'HAZ',
    'TEM',
    'AGU',
    'EYL',
    'EKİ',
    'KAS',
    'ARA',
  ];

  /// Standart Türkçe gün isimleri ([DateTime.weekday] uyumlu: 1 = Pazartesi, 7 = Pazar).
  static const List<String> days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  /// Büyük harf gün isimleri.
  static const List<String> daysUpper = [
    'PAZARTESİ',
    'SALI',
    'ÇARŞAMBA',
    'PERŞEMBE',
    'CUMA',
    'CUMARTESİ',
    'PAZAR',
  ];

  /// Kısa gün isimleri.
  static const List<String> daysShort = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  /// Harf katlama ve yumuşatma tablosu ile OCR/kullanıcı varyasyon eşlemeleri.
  static const Map<String, int> monthAliases = {
    // 1 - Ocak
    '1': 1, '01': 1, 'ocak': 1, 'oca': 1,
    // 2 - Şubat
    '2': 2, '02': 2, 'şubat': 2, 'subat': 2, 'şub': 2, 'sub': 2,
    // 3 - Mart
    '3': 3, '03': 3, 'mart': 3, 'mar': 3,
    // 4 - Nisan
    '4': 4, '04': 4, 'nisan': 4, 'nis': 4,
    // 5 - Mayıs
    '5': 5, '05': 5, 'mayıs': 5, 'mayis': 5, 'may': 5,
    // 6 - Haziran
    '6': 6, '06': 6, 'haziran': 6, 'haz': 6,
    // 7 - Temmuz
    '7': 7, '07': 7, 'temmuz': 7, 'tem': 7,
    // 8 - Ağustos
    '8': 8, '08': 8, 'ağustos': 8, 'agustos': 8, 'ağu': 8, 'agu': 8,
    // 9 - Eylül
    '9': 9, '09': 9, 'eylül': 9, 'eylul': 9, 'eyl': 9,
    // 10 - Ekim
    '10': 10, 'ekim': 10, 'eki': 10,
    // 11 - Kasım
    '11': 11, 'kasım': 11, 'kasim': 11, 'kas': 11,
    // 12 - Aralık
    '12': 12, 'aralık': 12, 'aralik': 12, 'ara': 12,
  };

  /// Gün isimleri eşleme haritası (1 = Pazartesi, 7 = Pazar).
  static const Map<String, int> dayAliases = {
    'pazartesi': 1, 'pzt': 1,
    'salı': 2, 'sali': 2, 'sal': 2,
    'çarşamba': 3, 'carsamba': 3, 'çar': 3, 'car': 3,
    'perşembe': 4, 'persembe': 4, 'per': 4,
    'cuma': 5, 'cum': 5,
    'cumartesi': 6, 'cmt': 6,
    'pazar': 7, 'paz': 7,
  };

  /// Gelen metni küçük harfe ve Türkçe harf benzerliklerine göre temizler.
  static String fold(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('.', '')
        .replaceAll('-', '');
  }

  /// Verilen metni (örn: "Ağustos", "agustos", "AGU", "08") ay numarasına (1..12) dönüştürür.
  /// Tanınamazsa null döner.
  static int? parseMonthNumber(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final trimmed = input.trim().toLowerCase();

    // Doğrudan alias kontrolü
    final direct = monthAliases[trimmed];
    if (direct != null) return direct;

    // Folded kontrol (Türkçe karakter ve noktalama yumuşatması)
    final foldedKey = fold(trimmed);
    for (final entry in monthAliases.entries) {
      if (fold(entry.key) == foldedKey) {
        return entry.value;
      }
    }

    return null;
  }

  /// Ay numarasından (1..12) standart ay ismini getirir.
  static String getMonthName(
    int month, {
    bool uppercase = false,
    bool short = false,
    bool military = false,
  }) {
    if (month < 1 || month > 12) return '';
    final index = month - 1;

    if (military) return militaryMonthCodes[index];
    if (short) return monthsShort[index];
    if (uppercase) return monthsUpper[index];
    return months[index];
  }

  /// Ham bir ay metnini standart biçime dönüştürür.
  /// Örn: "agustos" -> "Ağustos" (veya uppercase ise "AĞUSTOS").
  static String normalizeMonth(
    String input, {
    bool uppercase = false,
    bool short = false,
    bool military = false,
  }) {
    final monthNumber = parseMonthNumber(input);
    if (monthNumber == null) return input.trim();
    return getMonthName(
      monthNumber,
      uppercase: uppercase,
      short: short,
      military: military,
    );
  }

  /// Verilen gün adını (1..7) [DateTime.weekday] standartına göre döner.
  static String getDayName(
    int weekday, {
    bool uppercase = false,
    bool short = false,
  }) {
    if (weekday < 1 || weekday > 7) return '';
    final index = weekday - 1;

    if (short) return daysShort[index];
    if (uppercase) return daysUpper[index];
    return days[index];
  }

  /// Ham gün metnini (örn: "Carsamba", "cars", "Pzt") gün numarasına (1..7) çevirir.
  static int? parseDayOfWeek(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final trimmed = input.trim().toLowerCase();

    final direct = dayAliases[trimmed];
    if (direct != null) return direct;

    final foldedKey = fold(trimmed);
    for (final entry in dayAliases.entries) {
      if (fold(entry.key) == foldedKey) {
        return entry.value;
      }
    }

    return null;
  }

  /// Resmi evrak ve PDF başlıkları için standart tarih formatı:
  /// Örnek (büyük harf): `15 AĞUSTOS 2026`
  /// Örnek (gün dahil): `15 AĞUSTOS 2026 CUMARTESİ`
  static String formatOfficialDate(
    DateTime date, {
    bool includeDayName = false,
    bool uppercase = true,
  }) {
    final day = date.day.toString().padLeft(2, '0');
    final month = getMonthName(date.month, uppercase: uppercase);
    final year = date.year.toString();

    if (includeDayName) {
      final dayName = getDayName(date.weekday, uppercase: uppercase);
      return '$day $month $year $dayName';
    }

    return '$day $month $year';
  }

  /// Askeri Tarih-Saat Grubu (DTG) standart formatı:
  /// `GG SSAA AY YY` -> Örn: `24 1430 AĞU 26`
  static String formatMilitaryDtg(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final year = (value.year % 100).toString().padLeft(2, '0');
    final monthCode = getMonthName(value.month, military: true);

    return '$day $hour$minute $monthCode $year';
  }

  /// Standart nokta ayrılmış tarih: `GG.AA.YYYY` -> `15.08.2026`
  static String formatDateDotted(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  /// Standart ISO tarih: `YYYY-AA-GG` -> `2026-08-15`
  static String formatDateIso(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }
}
