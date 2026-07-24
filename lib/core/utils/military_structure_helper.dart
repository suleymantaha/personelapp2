class MilitaryStructureHelper {
  /// Maps squad/tim name or raw birlik text to its parent Jandarma Bölük (Company) title
  static String getBolukName(String timOrBirlik) {
    final s = timOrBirlik.toUpperCase().trim();

    // Extract numbers like 1, 2, 3, 4 -> 1'inci İşt. Bl.
    if (s.contains('1-B') ||
        s.contains('2-B') ||
        s.contains('3-B') ||
        s.contains('4-B') ||
        s.contains('1. BÖLÜK') ||
        s.contains('1\'İNCİ')) {
      return '1\'inci İşt. Bl.';
    } else if (s.contains('5-B') ||
        s.contains('6-B') ||
        s.contains('7-B') ||
        s.contains('8-B') ||
        s.contains('2. BÖLÜK') ||
        s.contains('2\'NCİ')) {
      return '2\'nci İşt. Bl.';
    } else if (s.contains('9-B') ||
        s.contains('10-B') ||
        s.contains('11-B') ||
        s.contains('12-B') ||
        s.contains('3. BÖLÜK') ||
        s.contains('3\'ÜNCÜ')) {
      return '3\'üncü İşt. Bl.';
    }

    return timOrBirlik.isNotEmpty ? timOrBirlik : 'Asayiş Timi';
  }

  /// Returns full Birlik display text including Squad and parent Bölük
  static String getFullBirlikDisplay(String birlik, String timAdi) {
    final boluk = getBolukName(timAdi.isNotEmpty ? timAdi : birlik);
    if (timAdi.isNotEmpty && timAdi != boluk) {
      return '$boluk ($timAdi)';
    }
    return boluk;
  }
}
