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

  /// Returns primary roster category order: 10 (Nöbet Heyeti), 20 (Operasyonel), 30 (Hazır Kıta), 40 (Gülüşkür)
  static int getDutyCategoryOrder(String duty) {
    final upper = duty.toUpperCase().trim();
    if (isNobetciHeyetiDuty(duty)) return 10;
    if (upper.contains('HAZIR KITA') || upper.contains('HAZIRKITA')) return 30;
    if (upper.contains('GÜLÜŞKÜR') || upper.contains('GULUSKUR')) return 40;
    return 20; // Operasyonel görevler (HEYBET, Devriye, Pusu vb.)
  }

  /// Returns text for the DİĞER (Görev/Açıklama) column based on duty category
  static String getDigerCellText(String duty, {String? aciklama}) {
    final upper = duty.toUpperCase().trim();
    if (upper.contains('HAZIR KITA') || upper.contains('HAZIRKITA')) {
      return 'HAZIR KITA';
    }
    if (upper.contains('GÜLÜŞKÜR') || upper.contains('GULUSKUR')) {
      return 'GÜLÜŞKÜR';
    }
    if (isNobetciHeyetiDuty(duty)) {
      final text = aciklama ?? duty;
      return text.trim();
    }
    return ''; // Operasyonel görevler için DİĞER kısmına yazı yazılmayacak (BOŞ)
  }

  /// Returns duty group order weight: 1 for operational/guard duties, 2 for Hazır Kıta, 3 for Gülüşkür
  static int getDutyGroupOrder(String duty) {
    final upper = duty.toUpperCase().trim();
    if (upper.contains('HAZIR KITA') || upper.contains('HAZIRKITA')) return 2;
    if (upper.contains('GÜLÜŞKÜR') || upper.contains('GULUSKUR')) return 3;
    return 1;
  }

  /// Checks if a duty string represents a guard duty (Nöbetçiler / Nöbetçi Heyeti)
  static bool isNobetciHeyetiDuty(String duty) {
    final d = duty.toUpperCase().trim();
    if (d.contains('HAZIR KITA') || d.contains('GÜLÜŞKÜR') || d.contains('GULUSKUR')) {
      return false;
    }
    return d.contains('NÖB') ||
        d.contains('NÖBET') ||
        d.contains('NOBET') ||
        d.contains('HEYBET KOMUTANI');
  }

  /// Maps raw squad/tim or birlik text to its official standardized Jandarma squad name
  static String getOfficialBirlikName(String timOrBirlik, {String? duty}) {
    if (duty != null && isNobetciHeyetiDuty(duty)) {
      return 'Nöbet Heyeti';
    }

    final s = timOrBirlik.trim();
    if (s.isEmpty) return 'K.H';

    final upper = s.toUpperCase();

    // 0. Check Nöbet Heyeti directly
    if (upper.contains('NÖBET HEYETİ') || upper.contains('NOBET HEYETI')) {
      return 'Nöbet Heyeti';
    }

    // 1. Direct exact match check
    for (final official in officialSquadOrder) {
      if (official.toLowerCase() == s.toLowerCase()) {
        return official;
      }
    }

    // 2. Specific Company Headquarters (Bölük K.H)
    if (upper.contains("1'İNCİ BL. K.H") ||
        upper.contains("1'İNCİ BÖLÜK K.H") ||
        upper.contains('1. BL. K.H') ||
        upper.contains('1. BL K.H') ||
        upper.contains('1. BÖLÜK K.H') ||
        upper.contains('1.BL.K.H')) {
      return "1'inci Bl. K.H";
    }
    if (upper.contains("2'NCİ BL. K.H") ||
        upper.contains("2'NCİ BÖLÜK K.H") ||
        upper.contains('2. BL. K.H') ||
        upper.contains('2. BL K.H') ||
        upper.contains('2. BÖLÜK K.H') ||
        upper.contains('2.BL.K.H')) {
      return "2'nci Bl. K.H";
    }
    if (upper.contains("3'ÜNCÜ BL. K.H") ||
        upper.contains("3'ÜNCÜ BÖLÜK K.H") ||
        upper.contains('3. BL. K.H') ||
        upper.contains('3. BL K.H') ||
        upper.contains('3. BÖLÜK K.H') ||
        upper.contains('3.BL.K.H')) {
      return "3'üncü Bl. K.H";
    }

    // 3. Main Battalion Headquarters / Karargah / K.H Birliği -> 'K.H'
    if (upper.contains('K.H') ||
        upper.contains('KH') ||
        upper.contains('KARARGAH')) {
      return 'K.H';
    }

    // 4. Tim matches (1-B through 12-B)
    for (var i = 1; i <= 12; i++) {
      if (upper.contains('$i-B') ||
          upper.contains('$i. TİM') ||
          upper.contains('$i.TIM') ||
          upper.contains('$i TİM')) {
        return '$i-B Timi';
      }
    }

    // 5. Exact match fallback with officialSquadOrder
    for (final official in officialSquadOrder) {
      if (official.toLowerCase() == s.toLowerCase()) {
        return official;
      }
    }

    return timOrBirlik;
  }

  /// Official Jandarma Squad/Tim ordering
  static const List<String> officialSquadOrder = [
    'Nöbet Heyeti',
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
  static int getSquadOrderWeight(String squadName, {String? duty}) {
    final officialName = getOfficialBirlikName(squadName, duty: duty);
    final idx = officialSquadOrder.indexOf(officialName);
    if (idx != -1) return idx;

    // Fallback search
    for (var i = 0; i < officialSquadOrder.length; i++) {
      if (officialSquadOrder[i].toLowerCase() == squadName.trim().toLowerCase()) {
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
