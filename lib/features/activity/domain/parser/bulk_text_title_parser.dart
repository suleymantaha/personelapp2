part of 'bulk_text_parser.dart';

const Map<String, int> _turkishMonths = {
  'ocak': 1,
  'şubat': 2,
  'subat': 2,
  'mart': 3,
  'nisan': 4,
  'mayıs': 5,
  'mayis': 5,
  'haziran': 6,
  'temmuz': 7,
  'ağustos': 8,
  'agustos': 8,
  'eylül': 9,
  'eylul': 9,
  'ekim': 10,
  'kasım': 11,
  'kasim': 11,
  'aralık': 12,
  'aralik': 12,
};

const Set<String> _dayNames = {
  'pazartesi',
  'sali',
  'salı',
  'carsamba',
  'çarşamba',
  'persembe',
  'perşembe',
  'cuma',
  'cumartesi',
  'pazar',
};

final RegExp _datePattern =
    RegExp(r'(?<!\d)(\d{1,2})[./-](\d{1,2})[./-](\d{4})(?!\d)');
final RegExp _textMonthDatePattern = RegExp(
  r'(?<!\d)(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)(?:\s+(\d{4}))?(?!\d)',
  caseSensitive: false,
);
final RegExp _dateOnlyPattern = RegExp(
  r'^\s*(?:\d{1,2}[./-]\d{1,2}[./-]\d{4}|\d{1,2}\s+[A-Za-zÇĞİÖŞÜçğıöşü]+(?:\s+\d{4})?)(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü]+)?\s*$',
  caseSensitive: false,
);
final RegExp _teamPattern = RegExp(
  r'(?<!\d)(\d{1,2})\s*(?:[/\-]\s*([A-Za-zÇĞİÖŞÜçğıöşü]+)|([A-Za-zÇĞİÖŞÜçğıöşü]+))',
  caseSensitive: false,
);
final RegExp _numberedPersonnelPattern = RegExp(
  r'^\s*(\d+)\s*([.)\-:]|(?=J\s*[.]?\s*(?:Asb|Uzm|Ütğm|Utgm|Tğm|Tgm|Astğm|Astgm|Yzb|Bçvş|Bcvs)))\s*(.+)$',
  caseSensitive: false,
);
final RegExp _bulletPattern = RegExp(r'^\s*[•●▪◦]\s*');
final RegExp _timeRangePattern = RegExp(
  r'(?<!\d)(\d{1,2})[.:](\d{2})(?:\s*[-/]\s*|\s+to\s+|\s+)(\d{1,2})[.:](\d{2})(?!\d)',
  caseSensitive: false,
);
final RegExp _timeLikePattern = RegExp(
  r'\d{1,2}[.:]\d{2}(?:\s*[-/]\s*|\s+to\s+|\s+)\d{1,2}[.:]\d{2}',
  caseSensitive: false,
);
final RegExp _messageMetadataPattern = RegExp(
  r'^\s*(?:\[\d{1,2}[.:]\d{2}(?:,\s*\d{1,2}[./]\d{1,2}[./]\d{2,4})?\]|'
  r'\d{1,2}[.:]\d{2}\s*[-–—]\s*[A-Za-zÇĞİÖŞÜçğıöşü][^:]{0,59}:)',
);
final RegExp _rankPattern = RegExp(
  r'^(J\s*[.]?\s*(?:(?:Ütğm|Utgm|Tğm|Tgm|Astğm|Astgm|Yzb|Bçvş|Bcvs)|'
  r'(?:(?:Asb|Uzm)\s*[.]?\s*(?:Kd\s*[.]?\s*)?'
  r'(?:Ü[.]?Çvş|U[.]?Cv[sş]|Üçvş|Ucv[sş]?|Çvş|Cv[sş]?)))\s*[.]?)\s*',
  caseSensitive: false,
);
final RegExp _fullDayAnnotationPattern = RegExp(
  r'\s*\(\s*24\s*saat\s+kalacak\s*\)\s*',
  caseSensitive: false,
);
final RegExp _summaryPattern = RegExp(
  r'^\s*(?:toplam|tolam)\b',
  caseSensitive: false,
);
final RegExp _singleTimePattern = RegExp(
  r'^\s*(?:[01]?\d|2[0-3])[.:][0-5]\d\s*$',
);
final RegExp _shiftWordPattern = RegExp(
  r'\b(?:sabah|akşam|aksam|öğlen|oglen|gece|gündüz|gunduz)\b',
  caseSensitive: false,
);

const Map<String, String> _activityTypes = {
  'gülüşkür': DutyOrLeaveType.guluskur,
  'guluskur': DutyOrLeaveType.guluskur,
  'hazır kıta': DutyOrLeaveType.hazirKita,
  'hazir kita': DutyOrLeaveType.hazirKita,
  'heybet': DutyOrLeaveType.heybet,
  'garaj nöb': DutyOrLeaveType.garajNob,
  'garaj nob': DutyOrLeaveType.garajNob,
  'garaj nöbet': DutyOrLeaveType.garajNob,
  'garaj nobet': DutyOrLeaveType.garajNob,
  'ttza nöb': DutyOrLeaveType.ttzaNob,
  'ttza nob': DutyOrLeaveType.ttzaNob,
  'ttza nöbet': DutyOrLeaveType.ttzaNob,
  'ttza nobet': DutyOrLeaveType.ttzaNob,
  'mebs nöb': DutyOrLeaveType.mebsNob,
  'mebs nob': DutyOrLeaveType.mebsNob,
  'kule nöb': DutyOrLeaveType.kuleNob,
  'kule nob': DutyOrLeaveType.kuleNob,
  'ihtiyat': DutyOrLeaveType.gorevli,
  'devriye': DutyOrLeaveType.gorevli,
  'görev': DutyOrLeaveType.gorevli,
  'gorev': DutyOrLeaveType.gorevli,
  'nöbetçi': DutyOrLeaveType.nobetci,
  'nobetci': DutyOrLeaveType.nobetci,
};

const Map<String, String> _activityDisplayNames = {
  'gülüşkür': 'Gülüşkür',
  'guluskur': 'Gülüşkür',
  'hazır kıta': 'Hazır Kıta',
  'hazir kita': 'Hazır Kıta',
  'heybet': 'Heybet',
  'garaj nöb': 'GARAJ NÖB.',
  'garaj nob': 'GARAJ NÖB.',
  'garaj nöbet': 'GARAJ NÖB.',
  'garaj nobet': 'GARAJ NÖB.',
  'ttza nöb': 'TTZA NÖB.',
  'ttza nob': 'TTZA NÖB.',
  'ttza nöbet': 'TTZA NÖB.',
  'ttza nobet': 'TTZA NÖB.',
  'mebs nöb': 'MEBS NÖB.',
  'mebs nob': 'MEBS NÖB.',
  'kule nöb': 'KULE NÖB.',
  'kule nob': 'KULE NÖB.',
  'ihtiyat': 'İhtiyat',
  'devriye': 'Devriye',
  'görev': 'Görev',
  'gorev': 'Görev',
  'nöbetçi': 'Nöbetçi',
  'nobetci': 'Nöbetçi',
};

String? _extractDateFromLine(String line, [String? defaultDate]) {
  final numMatch = _datePattern.firstMatch(line);
  if (numMatch != null) {
    final parsed = _parseDateMatch(numMatch);
    if (parsed != null) return parsed;
  }

  final textMatch = _textMonthDatePattern.firstMatch(line);
  if (textMatch != null) {
    final day = int.parse(textMatch.group(1)!);
    final monthName = _fold(textMatch.group(2)!);
    if (_turkishMonths.containsKey(monthName)) {
      final month = _turkishMonths[monthName]!;
      int year;
      if (textMatch.group(3) != null) {
        year = int.parse(textMatch.group(3)!);
      } else if (defaultDate != null) {
        final yearPart = defaultDate.split('-').first;
        year = int.tryParse(yearPart) ?? DateTime.now().year;
      } else {
        year = DateTime.now().year;
      }

      try {
        final date = DateTime(year, month, day);
        if (date.year == year && date.month == month && date.day == day) {
          return '${year.toString().padLeft(4, '0')}-'
              '${month.toString().padLeft(2, '0')}-'
              '${day.toString().padLeft(2, '0')}';
        }
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}

bool _isDateOnlyLine(String line, String? defaultDate) {
  if (_dateOnlyPattern.hasMatch(line)) return true;
  final date = _extractDateFromLine(line, defaultDate);
  if (date == null) return false;

  var clean = line.replaceAll(_datePattern, '');
  clean = clean.replaceAll(_textMonthDatePattern, '');
  for (final day in _dayNames) {
    clean = clean.replaceAll(RegExp('\\b$day\\b', caseSensitive: false), '');
  }
  return clean.trim().isEmpty;
}

ParsedActivityTitle _parseBulkTitle(
  String titleLine, [
  String? defaultDate,
]) {
  final normalized = _normalizeLine(titleLine);
  final teamName = _extractTeam(normalized);
  final activity = _extractActivity(normalized);
  final parsedDate = _extractDateFromLine(normalized, defaultDate);
  return (
    timName: teamName,
    activityType: activity.$1,
    date: parsedDate ?? defaultDate,
    activityTypeKnown: activity.$2,
  );
}

String _extractBulkActivityType(String titleLine) =>
    _extractActivity(_normalizeLine(titleLine)).$1;

String _mapBulkActivityTypeToDutyOrLeave(String activityType) =>
    _activityTypes[_fold(activityType).trim()] ?? activityType.trim();

List<String> _splitLineIfMultiplePersonnel(String line) {
  final splitPattern = RegExp(
    r'(?<=\S)\s+(?=\d+\s*[.)\-:]?\s*J\s*[.]?\s*(?:Asb|Uzm|Ütğm|Utgm|Tğm|Tgm|Astğm|Astgm|Yzb|Bçvş|Bcvs))',
    caseSensitive: false,
  );
  final parts = line.split(splitPattern);
  return parts.where((p) => p.trim().isNotEmpty).toList();
}

bool _isCommentOrNoteLine(String line) {
  final trimmed = line.trim();
  if (trimmed.startsWith('(') &&
      trimmed.endsWith(')') &&
      !_rankPattern.hasMatch(trimmed)) {
    return true;
  }
  final folded = _fold(trimmed);
  if (folded.contains('sabit kalinacak') ||
      folded.contains('kalinacaktir') ||
      folded.contains('saat kalacak') ||
      folded.contains('degisimli') ||
      folded.contains('altin kaz') ||
      folded.contains('ciftligi')) {
    if (!_rankPattern.hasMatch(trimmed) &&
        !_numberedPersonnelPattern.hasMatch(trimmed)) {
      return true;
    }
  }
  return false;
}
