class MilitaryStructureHelper {
  static int? _teamNumber(String value) {
    final normalized = value.toUpperCase().replaceAll('İ', 'I').trim();
    final match = RegExp(
      r'(?:^|\D)(1[0-2]|[1-9])\s*(?:[-/]|\.?\s*TIM)',
    ).firstMatch(normalized);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

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

    final teamNumber = _teamNumber(s);
    if (teamNumber != null) {
      if (teamNumber <= 4) return "1'inci Bl.";
      if (teamNumber <= 8) return "2'nci Bl.";
      return "3'üncü Bl.";
    }

    // Extract legacy company/team labels.
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
      final explanation = aciklama?.trim() ?? '';
      return explanation.isNotEmpty ? explanation : duty.trim();
    }
    return ''; // Operasyonel görevler için DİĞER kısmına yazı yazılmayacak (BOŞ)
  }

  /// Returns the stable grouping code shared by PDF and Excel exporters.
  static String getRosterGroupCode(String duty) {
    final upper = duty.toUpperCase().trim();
    if (upper.contains('HAZIR KITA') || upper.contains('HAZIRKITA')) {
      return 'HAZIR_KITA';
    }
    if (upper.contains('GÜLÜŞKÜR') || upper.contains('GULUSKUR')) {
      return 'GULUSKUR';
    }
    if (isNobetciHeyetiDuty(duty)) {
      return 'NOBET_HEYETI';
    }
    return 'DIGER';
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
    if (d.contains('HAZIR KITA') ||
        d.contains('GÜLÜŞKÜR') ||
        d.contains('GULUSKUR')) {
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

    // 4. Tim matches (1-B, 1/B, "1 / B", "1. Tim", etc.)
    final teamNumber = _teamNumber(upper);
    if (teamNumber != null) return '$teamNumber-B Timi';

    // 5. Exact match fallback with officialSquadOrder
    for (final official in officialSquadOrder) {
      if (official.toLowerCase() == s.toLowerCase()) {
        return official;
      }
    }

    return timOrBirlik;
  }

  /// Returns the unit label used in PDF/Excel rosters.
  ///
  /// Regular duties are listed by team. Hazır Kıta and Gülüşkür are the only
  /// duty groups that are listed by their parent company.
  static String getRosterBirlikName({
    required String timName,
    required String birlik,
    required String duty,
  }) {
    if (isNobetciHeyetiDuty(duty)) return 'Nöbet Heyeti';

    final dutyUpper = duty.toUpperCase().trim();
    final isCompanyDuty = dutyUpper.contains('HAZIR KITA') ||
        dutyUpper.contains('HAZIRKITA') ||
        dutyUpper.contains('GÜLÜŞKÜR') ||
        dutyUpper.contains('GULUSKUR');
    final teamOrFallback = timName.trim().isNotEmpty ? timName : birlik;

    if (isCompanyDuty) {
      return getBolukName(teamOrFallback);
    }
    return getOfficialBirlikName(teamOrFallback, duty: duty);
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

    // Special-duty rows use parent-company labels. These labels previously all
    // fell through to 999, so rank sorting could interleave companies and split
    // the consecutive blocks required by PDF/Excel cell merging.
    final companyIndex = const {
      "1'inci Bl.": 2,
      "2'nci Bl.": 7,
      "3'üncü Bl.": 12,
    }[officialName];
    if (companyIndex != null) return companyIndex;

    final idx = officialSquadOrder.indexOf(officialName);
    if (idx != -1) return idx;

    // Fallback search
    for (var i = 0; i < officialSquadOrder.length; i++) {
      if (officialSquadOrder[i].toLowerCase() ==
          squadName.trim().toLowerCase()) {
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
    return List<T>.from(squads)
      ..sort((a, b) {
        final wA = getSquadOrderWeight(nameExtractor(a));
        final wB = getSquadOrderWeight(nameExtractor(b));
        if (wA != wB) return wA.compareTo(wB);
        return nameExtractor(a).compareTo(nameExtractor(b));
      });
  }
}
