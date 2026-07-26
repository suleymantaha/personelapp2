import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class BulkTextParser {
  static const List<String> knownRanks = [
    'J.Asb.Kd.Üçvş.',
    'J.Asb.Kd.Çvş.',
    'J.Asb.Üçvş.',
    'J.Asb.Çvş.',
    'J.Uzm.Çvş.',
    'J. Uzm. Çvş',
    'J.Uzm Çvş.',
    'J.Uzm.Çvş',
  ];

  static List<ParsedActivityBlock> parse(String rawText) {
    if (rawText.trim().isEmpty) return [];

    // Clean markdown characters like *, _
    final cleanText = rawText.replaceAll('*', '').replaceAll('_', '');
    final lines = cleanText.split(RegExp(r'\r?\n'));

    final blocks = <ParsedActivityBlock>[];

    var currentTim = 'Genel';
    var currentActivityType = 'GÖREVLİ';
    var currentDate = _formatDate(DateTime.now());
    String? currentTimeRange;
    final currentPersonnel = <ParsedPersonnelItem>[];
    var currentRawTitle = '';

    var defaultDate = _formatDate(DateTime.now());

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if line is a date (e.g. 25.07.2026, 26.07.2026 Cumartesi)
      final dateMatch = RegExp(r'(\d{1,2})[\.\/](\d{1,2})[\.\/](\d{4})').firstMatch(line);
      if (dateMatch != null && !_isPersonnelLine(line)) {
        final day = dateMatch.group(1)!.padLeft(2, '0');
        final month = dateMatch.group(2)!.padLeft(2, '0');
        final year = dateMatch.group(3)!;
        defaultDate = '$year-$month-$day';
        currentDate = defaultDate;
        continue;
      }

      // Check if line is a Header/Title line (e.g. 6 / B Gülüşkür isim listesi, 7-B Hazır Kıta Listesi)
      final titleMatch = RegExp(
        r'(\d{1,2}\s*[\/-]?\s*[A-ZÇĞİÖŞÜ]+)\s+(.*?)(?:isim|İsim)?\s*(?:listesi|Listesi)?',
        caseSensitive: false,
      ).firstMatch(line);

      final isHeaderKeyword = line.toLowerCase().contains('listesi') ||
          line.toLowerCase().contains('timi') ||
          line.toLowerCase().contains('hazır kıta') ||
          line.toLowerCase().contains('heybet') ||
          line.toLowerCase().contains('gülüşkür') ||
          line.toLowerCase().contains('ihtiyat');

      if ((titleMatch != null || isHeaderKeyword) && !_isPersonnelLine(line)) {
        // Save previous block if exists
        if (currentPersonnel.isNotEmpty) {
          blocks.add(ParsedActivityBlock(
            rawTitle: currentRawTitle,
            parsedTimName: currentTim,
            parsedActivityType: currentActivityType,
            parsedDate: currentDate,
            parsedTimeRange: currentTimeRange,
            personnelList: List.from(currentPersonnel),
          ));
          currentPersonnel.clear();
          currentTimeRange = null;
        }

        currentRawTitle = line;
        currentDate = defaultDate; // fallback

        // Extract date from header line if present
        if (dateMatch != null) {
          final day = dateMatch.group(1)!.padLeft(2, '0');
          final month = dateMatch.group(2)!.padLeft(2, '0');
          final year = dateMatch.group(3)!;
          currentDate = '$year-$month-$day';
        }

        // Extract Tim name (e.g. 6/B, 7-B, 11-B)
        final timReg = RegExp(r'(\d{1,2}\s*[\/-]?\s*[A-ZÇĞİÖŞÜ]+)', caseSensitive: false).firstMatch(line);
        if (timReg != null) {
          currentTim = timReg.group(1)!.replaceAll(' ', '').toUpperCase();
          if (!currentTim.contains('/') && currentTim.contains('-')) {
            currentTim = currentTim.replaceAll('-', '/');
          }
        }

        // Extract Activity Type
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('gülüşkür')) {
          currentActivityType = 'Gülüşkür';
        } else if (lowerLine.contains('hazır kıta')) {
          currentActivityType = 'Hazır Kıta';
        } else if (lowerLine.contains('heybet')) {
          currentActivityType = 'Heybet';
        } else if (lowerLine.contains('ihtiyat')) {
          currentActivityType = 'İhtiyat';
        } else if (lowerLine.contains('devriye')) {
          currentActivityType = 'Devriye';
        } else {
          currentActivityType = 'Görev';
        }

        continue;
      }

      // Check if line is a Time Range line (e.g. 08.00-19.30, 08:00/20:00)
      final timeMatch = RegExp(r'(\d{2}[\.:]\d{2})\s*[-\/]\s*(\d{2}[\.:]\d{2})').firstMatch(line);
      if (timeMatch != null) {
        // If previous personnel exists before new shift time, push previous block
        if (currentPersonnel.isNotEmpty) {
          blocks.add(ParsedActivityBlock(
            rawTitle: currentRawTitle,
            parsedTimName: currentTim,
            parsedActivityType: currentActivityType,
            parsedDate: currentDate,
            parsedTimeRange: currentTimeRange,
            personnelList: List.from(currentPersonnel),
          ));
          currentPersonnel.clear();
        }

        final start = timeMatch.group(1)!.replaceAll('.', ':');
        final end = timeMatch.group(2)!.replaceAll('.', ':');
        currentTimeRange = '$start - $end';
        continue;
      }

      // Parse personnel line
      if (_isPersonnelLine(line)) {
        final item = _parsePersonnelLine(line, currentPersonnel.length + 1);
        if (item != null) {
          currentPersonnel.add(item);
        }
      }
    }

    // Add last block
    if (currentPersonnel.isNotEmpty) {
      blocks.add(ParsedActivityBlock(
        rawTitle: currentRawTitle.isEmpty ? 'Ayrıştırılan Faaliyet' : currentRawTitle,
        parsedTimName: currentTim,
        parsedActivityType: currentActivityType,
        parsedDate: currentDate,
        parsedTimeRange: currentTimeRange,
        personnelList: currentPersonnel,
      ));
    }

    return blocks;
  }

  static bool _isPersonnelLine(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('j.asb') ||
        lower.contains('j.uzm') ||
        lower.contains('uzm.çvş') ||
        lower.contains('asb.') ||
        lower.contains('çvş')) {
      return true;
    }
    // Check if line starts with index number followed by rank or capital name: "1- Erdem BUYAR" or "1) J.Asb"
    if (RegExp(r'^\d+[\.\)-]\s*(?:J\.|[A-ZÇĞİÖŞÜ])').hasMatch(line.trim()) && !lower.contains('listesi')) {
      return true;
    }
    return false;
  }

  static ParsedPersonnelItem? _parsePersonnelLine(String line, int defaultIndex) {
    // Clean leading index like 1-, 1), 1., 10.
    var content = line.trim();
    var index = defaultIndex;

    final indexMatch = RegExp(r'^(\d+)[\.\)-]?\s*').firstMatch(content);
    if (indexMatch != null) {
      index = int.tryParse(indexMatch.group(1)!) ?? defaultIndex;
      content = content.substring(indexMatch.group(0)!.length).trim();
    }

    // Extract rank
    var rank = 'J.Uzm.Çvş.';
    var name = content;

    final rankRegex = RegExp(
      r'^(J\.\s*Asb\.\s*(?:Kd\.\s*)?(?:Üçvş\.|Çvş\.)|J\.\s*Uzm\.\s*Çvş\.|J\.\s*Uzm\s*Çvş\.|J\.\s*Uzm\.\s*Çvş|J\.\s*Asb\.\s*Çvş\.)',
      caseSensitive: false,
    );

    final rankMatch = rankRegex.firstMatch(content);
    if (rankMatch != null) {
      rank = rankMatch.group(0)!.trim();
      name = content.substring(rankMatch.group(0)!.length).trim();
    }

    // Normalize rank string
    rank = _normalizeRank(rank);

    if (name.isEmpty) return null;

    return ParsedPersonnelItem(
      rawIndex: index,
      rawRank: rank,
      rawName: name,
    );
  }

  static String _normalizeRank(String rank) {
    final clean = rank.replaceAll(' ', '').toLowerCase();
    if (clean.contains('kd.üçvş') || clean.contains('kd.üçvş.')) return 'J.Asb.Kd.Üçvş.';
    if (clean.contains('üçvş')) return 'J.Asb.Üçvş.';
    if (clean.contains('kd.çvş')) return 'J.Asb.Kd.Çvş.';
    if (clean.contains('asb.çvş')) return 'J.Asb.Çvş.';
    if (clean.contains('uzm')) return 'J.Uzm.Çvş.';
    return rank;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
