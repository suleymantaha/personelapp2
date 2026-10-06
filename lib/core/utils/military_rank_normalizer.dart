import 'package:personelapp2/core/utils/rank_helper.dart';

class ParsedRankAndName {
  const ParsedRankAndName({
    required this.cleanName,
    this.standardRank,
    this.rawRank,
  });

  final String cleanName;
  final String? standardRank;
  final String? rawRank;

  bool get hasRank => standardRank != null;
}

class MilitaryRankNormalizer {
  const MilitaryRankNormalizer._();

  /// Jandarma ve TSK sınıf ekleri:
  /// Per (Personel), İkm (İkmal), Mu/Mhb (Muhabere), Bkm (Bakım), Asyş (Asayiş),
  /// İst (İstihkam), Uls (Ulaştırma), Mly (Maliye), Tbp (Tabip), Sağ (Sağlık), Hrk (Harekat)
  static final RegExp _rankPattern = RegExp(
    r'^(?:J\s*[.]?\s*)?'
    r'(?:(?:Per|İkm|Ikm|Mu|Mhb|Bkm|Asyş|Asys|İst|Ist|Uls|Mly|Tbp|Sağ|Sag|Hrk)\s*[.]?\s*)?'
    r'(?:'
    r'(?:Alb|Yb|Yrb|Bnb|Yzb|Ütğm|Utgm|Tğm|Tgm|Astğm|Astgm)|'
    r'(?:(?:Asb|Astsb|Asts)\s*[.]?\s*(?:Kd\s*[.]?\s*)?(?:Bçvş|Bcvs|Ü[.]?Çvş|U[.]?Cv[sş]|Üçvş|Ucv[sş]?|Çvş|Cv[sş]?))|'
    r'(?:Uzm\s*[.]?\s*J\s*[.]?)|'
    r'(?:(?:Uzm|Uz)\s*[.]?\s*(?:Çvş|Cv[sş]?|Onb))|'
    r'(?:Söz\s*[.]?\s*Er)|'
    r'Er'
    r')\s*[.]?\s*',
    caseSensitive: false,
  );

  /// Sıra no, sembol ve parantez ön eklerini temizler:
  /// '1.', '01-', '| 02 |', '3)', '#4' vb.
  static String stripLeadingSequence(String input) {
    return input
        .replaceFirst(RegExp(r'^[|#*.\s]*\d+\s*[-.):/|]?\s*'), '')
        .replaceFirst(RegExp(r'^[|#*.\s]+'), '')
        .trim();
  }

  /// OCR okumasında kelime içine karışmış rakamları harf eşleniklerine çevirir:
  /// '0sman' -> 'Osman', 'Y1LMAZ' -> 'YILMAZ', '5alih' -> 'Salih'
  static String cleanOcrDigits(String input) {
    final buffer = StringBuffer();
    final words = input.split(RegExp(r'(?<=\s)|(?=\s)'));
    for (final word in words) {
      if (RegExp(r'^\s*$').hasMatch(word)) {
        buffer.write(word);
        continue;
      }
      // Bağımsız sıra numarası veya tarih gibi tamamen rakam olanlara dokunma
      if (RegExp(r'^\d+[.)\-:]?$').hasMatch(word)) {
        buffer.write(word);
        continue;
      }
      var cleaned = word;
      // Kelime başı veya içi harf kaymaları
      cleaned = cleaned
          .replaceAll('0', 'O')
          .replaceAll('1', 'I')
          .replaceAll('5', 'S')
          .replaceAll('2', 'Z')
          .replaceAll('8', 'B');
      // Küçük harfli kelimelerde küçük harfe uyarla
      if (word.startsWith('0') && word.length > 1 && word[1] == word[1].toLowerCase()) {
        cleaned = 'O${cleaned.substring(1)}';
      }
      if (word.startsWith('5') && word.length > 1 && word[1] == word[1].toLowerCase()) {
        cleaned = 'S${cleaned.substring(1)}';
      }
      buffer.write(cleaned);
    }
    return buffer.toString();
  }

  /// Verilen satırdan rütbeyi sıyırır ve standart rütbe ile saf ismi döner.
  static ParsedRankAndName extractRankAndName(String line) {
    var working = stripLeadingSequence(line);
    if (working.isEmpty) {
      return const ParsedRankAndName(cleanName: '');
    }

    final match = _rankPattern.firstMatch(working);
    if (match == null || match.group(0) == null || match.group(0)!.trim().isEmpty) {
      return ParsedRankAndName(cleanName: working.trim());
    }

    final rawRankMatched = match.group(0)!.trim();
    // Eğer eşleşme sadece 'J.' veya 'J' ise ve devamında rütbe yoksa rütbe sayma
    if (rawRankMatched == 'J.' || rawRankMatched == 'J') {
      return ParsedRankAndName(cleanName: working.trim());
    }

    final standard = normalizeRank(rawRankMatched);
    final remainingName = working.substring(match.end).trim();

    return ParsedRankAndName(
      cleanName: remainingName,
      standardRank: standard,
      rawRank: rawRankMatched,
    );
  }
}
