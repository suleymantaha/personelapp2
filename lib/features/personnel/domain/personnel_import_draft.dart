class PersonnelImportDraft {
  const PersonnelImportDraft({
    required this.name,
    required this.rank,
    required this.unit,
    this.squadId,
    this.sourceLineNumber,
  });

  final String name;
  final String rank;
  final String unit;
  final int? squadId;
  final int? sourceLineNumber;

  bool get isValid => name.trim().isNotEmpty && rank.trim().isNotEmpty;

  PersonnelImportDraft copyWith({
    String? name,
    String? rank,
    String? unit,
    int? squadId,
    bool clearSquad = false,
  }) {
    return PersonnelImportDraft(
      name: name ?? this.name,
      rank: rank ?? this.rank,
      unit: unit ?? this.unit,
      squadId: clearSquad ? null : squadId ?? this.squadId,
      sourceLineNumber: sourceLineNumber,
    );
  }
}
