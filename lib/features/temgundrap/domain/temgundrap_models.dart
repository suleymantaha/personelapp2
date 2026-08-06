class TemgundrapOperation {
  const TemgundrapOperation({
    required this.id,
    required this.issuingUnit,
    required this.operationArea,
    required this.forceDescription,
    required this.commander,
    required this.strength,
    required this.startAt,
    required this.endAt,
    required this.purpose,
    required this.description,
  });

  final String id;
  final String issuingUnit;
  final String operationArea;
  final String forceDescription;
  final String commander;
  final Map<String, int> strength;
  final DateTime startAt;
  final DateTime endAt;
  final String purpose;
  final String description;

  int get totalStrength => strength.values.fold(0, (sum, value) => sum + value);

  Map<String, Object?> toJson() => {
        'id': id,
        'issuingUnit': issuingUnit,
        'operationArea': operationArea,
        'forceDescription': forceDescription,
        'commander': commander,
        'strength': strength,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'purpose': purpose,
        'description': description,
      };

  factory TemgundrapOperation.fromJson(Map<String, Object?> json) {
    final rawStrength = (json['strength'] as Map?)?.cast<String, Object?>() ?? const {};
    return TemgundrapOperation(
      id: json['id'] as String,
      issuingUnit: json['issuingUnit'] as String? ?? '',
      operationArea: json['operationArea'] as String? ?? '',
      forceDescription: json['forceDescription'] as String? ?? '',
      commander: json['commander'] as String? ?? '',
      strength: rawStrength.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      purpose: json['purpose'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class TemgundrapDocument {
  const TemgundrapDocument({
    required this.id,
    required this.date,
    required this.unitTitle,
    required this.approverName,
    required this.approverRank,
    required this.approverDuty,
    required this.operations,
    required this.isDraft,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final String unitTitle;
  final String approverName;
  final String approverRank;
  final String approverDuty;
  final List<TemgundrapOperation> operations;
  final bool isDraft;
  final DateTime updatedAt;

  TemgundrapDocument copyWith({
    List<TemgundrapOperation>? operations,
    bool? isDraft,
    DateTime? updatedAt,
  }) =>
      TemgundrapDocument(
        id: id,
        date: date,
        unitTitle: unitTitle,
        approverName: approverName,
        approverRank: approverRank,
        approverDuty: approverDuty,
        operations: operations ?? this.operations,
        isDraft: isDraft ?? this.isDraft,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'unitTitle': unitTitle,
        'approverName': approverName,
        'approverRank': approverRank,
        'approverDuty': approverDuty,
        'operations': operations.map((item) => item.toJson()).toList(),
        'isDraft': isDraft,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TemgundrapDocument.fromJson(Map<String, Object?> json) => TemgundrapDocument(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        unitTitle: json['unitTitle'] as String? ?? '',
        approverName: json['approverName'] as String? ?? '',
        approverRank: json['approverRank'] as String? ?? '',
        approverDuty: json['approverDuty'] as String? ?? '',
        operations: ((json['operations'] as List?) ?? const [])
            .map((item) => TemgundrapOperation.fromJson((item as Map).cast<String, Object?>()))
            .toList(),
        isDraft: json['isDraft'] as bool? ?? true,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
