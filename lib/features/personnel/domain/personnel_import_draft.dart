class PersonnelImportDraft {
  const PersonnelImportDraft({
    required this.name,
    required this.rank,
    required this.unit,
    this.squadId,
    this.sourceLineNumber,
    this.existingPersonnelId,
    this.allowDuplicate = false,
    this.skip = false,
  });

  final String name;
  final String rank;
  final String unit;
  final int? squadId;
  final int? sourceLineNumber;
  final int? existingPersonnelId;
  final bool allowDuplicate;
  final bool skip;

  bool get isValid => name.trim().isNotEmpty && rank.trim().isNotEmpty;

  PersonnelImportDraft copyWith({
    String? name,
    String? rank,
    String? unit,
    int? squadId,
    bool clearSquad = false,
    int? existingPersonnelId,
    bool clearIdentity = false,
    bool? allowDuplicate,
    bool? skip,
  }) {
    return PersonnelImportDraft(
      name: name ?? this.name,
      rank: rank ?? this.rank,
      unit: unit ?? this.unit,
      squadId: clearSquad ? null : squadId ?? this.squadId,
      sourceLineNumber: sourceLineNumber,
      existingPersonnelId:
          clearIdentity
              ? null
              : existingPersonnelId ?? this.existingPersonnelId,
      allowDuplicate: allowDuplicate ?? this.allowDuplicate,
      skip: skip ?? this.skip,
    );
  }
}
