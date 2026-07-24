class MilitaryStructureHelper {
  /// Maps squad/tim name or raw birlik text to its parent Jandarma Bölük (Company) title
  static String getBolukName(String timOrBirlik) {
    final s = timOrBirlik.toUpperCase().trim();

    // Check for Headquarters (Karargah) units first
    if (s.contains("1'İNCİ BL. K.H") ||
        s.contains('1. BL. K.H') ||
        s.contains('1. BÖLÜK K.H')) {
      return "1'inci Bl. K.H";
    }
    if (s.contains("2'NCİ BL. K.H") ||
        s.contains('2. BL. K.H') ||
        s.contains('2. BÖLÜK K.H')) {
      return "2'nci Bl. K.H";
    }
    if (s.contains("3'ÜNCÜ BL. K.H") ||
        s.contains('3. BL. K.H') ||
        s.contains('3. BÖLÜK K.H')) {
      return "3'üncü Bl. K.H";
    }
    if (s == 'K.H' ||
        s == 'KH' ||
        s.contains('TABUR K.H') ||
        s.contains('KARARGAH')) {
      return 'K.H';
    }

    // Extract numbers like 1, 2, 3, 4 -> 1'inci Bl.
    if (s.contains('1-B') ||
        s.contains('2-B') ||
        s.contains('3-B') ||
        s.contains('4-B') ||
        s.contains('1. BÖLÜK') ||
        s.contains("1'İNCİ")) {
      return "1'inci Bl.";
    } else if (s.contains('5-B') ||
        s.contains('6-B') ||
        s.contains('7-B') ||
        s.contains('8-B') ||
        s.contains('2. BÖLÜK') ||
        s.contains("2'NCİ")) {
      return "2'nci Bl.";
    } else if (s.contains('9-B') ||
        s.contains('10-B') ||
        s.contains('11-B') ||
        s.contains('12-B') ||
        s.contains('3. BÖLÜK') ||
        s.contains("3'ÜNCÜ")) {
      return "3'üncü Bl.";
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
