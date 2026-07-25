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

  /// Official Jandarma Squad/Tim ordering
  static const List<String> officialSquadOrder = [
    'K.H',
    "1'inci Bl. K.H",
    '1-B Timi',
    '2-B Timi',
    '3-B Timi',
    '4-B Timi',
    "2'nci Bl. K.H",
    '5-B Timi',
    '6-B Timi',
    '7-B Timi',
    '8-B Timi',
    "3'üncü Bl. K.H",
    '9-B Timi',
    '10-B Timi',
    '11-B Timi',
    '12-B Timi',
  ];

  /// Returns weight/index for sorting squads according to official military order
  static int getSquadOrderWeight(String squadName) {
    final s = squadName.trim();
    final idx = officialSquadOrder.indexOf(s);
    if (idx != -1) return idx;

    // Case-insensitive match fallback
    for (var i = 0; i < officialSquadOrder.length; i++) {
      if (officialSquadOrder[i].toLowerCase() == s.toLowerCase()) {
        return i;
      }
    }
    return 999;
  }

  /// Sorts a list of items by squad name according to official military order
  static List<T> sortSquads<T>(
    List<T> squads,
    String Function(T) nameExtractor,
  ) {
    return List<T>.from(squads)..sort((a, b) {
      final wA = getSquadOrderWeight(nameExtractor(a));
      final wB = getSquadOrderWeight(nameExtractor(b));
      if (wA != wB) return wA.compareTo(wB);
      return nameExtractor(a).compareTo(nameExtractor(b));
    });
  }
}
