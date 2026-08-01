class ParsedPersonnelItem {
  // 1.0: exact, 0.7-0.9: fuzzy, 0.0: none

  ParsedPersonnelItem({
    required this.rawIndex,
    required this.rawRank,
    required this.rawName,
    this.matchedPersonnelId,
    this.matchedAdSoyad,
    this.matchedRutbe,
    this.matchedTimId,
    this.matchConfidence = 0.0,
    this.teamMismatch = false,
    this.reviewConfirmed = false,
    this.sourceLineNumber,
  });
  final int rawIndex;
  final String rawRank;
  final String rawName;
  final int? matchedPersonnelId;
  final String? matchedAdSoyad;
  final String? matchedRutbe;
  final int? matchedTimId;
  final double matchConfidence;
  final bool teamMismatch;
  final bool reviewConfirmed;
  final int? sourceLineNumber;

  bool get isMatched => matchedPersonnelId != null;
  bool get needsReview =>
      !isMatched || (matchConfidence < 1.0 && !reviewConfirmed);

  ParsedPersonnelItem copyWith({
    int? rawIndex,
    String? rawRank,
    String? rawName,
    int? matchedPersonnelId,
    String? matchedAdSoyad,
    String? matchedRutbe,
    int? matchedTimId,
    double? matchConfidence,
    bool? teamMismatch,
    bool? reviewConfirmed,
    int? sourceLineNumber,
  }) {
    return ParsedPersonnelItem(
      rawIndex: rawIndex ?? this.rawIndex,
      rawRank: rawRank ?? this.rawRank,
      rawName: rawName ?? this.rawName,
      matchedPersonnelId: matchedPersonnelId ?? this.matchedPersonnelId,
      matchedAdSoyad: matchedAdSoyad ?? this.matchedAdSoyad,
      matchedRutbe: matchedRutbe ?? this.matchedRutbe,
      matchedTimId: matchedTimId ?? this.matchedTimId,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      teamMismatch: teamMismatch ?? this.teamMismatch,
      reviewConfirmed: reviewConfirmed ?? this.reviewConfirmed,
      sourceLineNumber: sourceLineNumber ?? this.sourceLineNumber,
    );
  }
}

class ParsedActivityBlock {
  ParsedActivityBlock({
    required this.rawTitle,
    required this.parsedTimName,
    required this.parsedActivityType,
    required this.parsedDate,
    required this.personnelList,
    this.parsedTimeRange,
  });
  final String rawTitle;
  final String parsedTimName; // e.g. "6/B"
  final String
      parsedActivityType; // e.g. "Gülüşkür", "Hazır Kıta", "Heybet", "İhtiyat"
  final String parsedDate; // YYYY-AA-DD
  final String? parsedTimeRange; // e.g. "08:00 - 19:30"
  final List<ParsedPersonnelItem> personnelList;

  ParsedActivityBlock copyWith({
    String? rawTitle,
    String? parsedTimName,
    String? parsedActivityType,
    String? parsedDate,
    String? parsedTimeRange,
    List<ParsedPersonnelItem>? personnelList,
  }) {
    return ParsedActivityBlock(
      rawTitle: rawTitle ?? this.rawTitle,
      parsedTimName: parsedTimName ?? this.parsedTimName,
      parsedActivityType: parsedActivityType ?? this.parsedActivityType,
      parsedDate: parsedDate ?? this.parsedDate,
      parsedTimeRange: parsedTimeRange ?? this.parsedTimeRange,
      personnelList: personnelList ?? this.personnelList,
    );
  }
}
