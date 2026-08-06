const temgundrapRankLabels = <String>[
  'SB',
  'ASB.',
  'UZM.J.',
  'J.UZM.ÇVŞ.',
];

class TemgundrapStrength {
  const TemgundrapStrength({
    this.officer = 0,
    this.nco = 0,
    this.specialistGendarmerie = 0,
    this.specialistSergeant = 0,
  });

  final int officer;
  final int nco;
  final int specialistGendarmerie;
  final int specialistSergeant;

  int get total => officer + nco + specialistGendarmerie + specialistSergeant;

  Map<String, int> get byLabel => {
        temgundrapRankLabels[0]: officer,
        temgundrapRankLabels[1]: nco,
        temgundrapRankLabels[2]: specialistGendarmerie,
        temgundrapRankLabels[3]: specialistSergeant,
      };

  Map<String, Object?> toJson() => {
        'officer': officer,
        'nco': nco,
        'specialistGendarmerie': specialistGendarmerie,
        'specialistSergeant': specialistSergeant,
      };

  factory TemgundrapStrength.fromJson(Map<String, Object?> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return TemgundrapStrength(
      officer: read('officer'),
      nco: read('nco'),
      specialistGendarmerie: read('specialistGendarmerie'),
      specialistSergeant: read('specialistSergeant'),
    );
  }

  factory TemgundrapStrength.fromLegacy(Map<String, Object?> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return TemgundrapStrength(
      officer: read('SB'),
      nco: read('ASB'),
      specialistGendarmerie: read('UZM'),
      specialistSergeant: read('DİĞER'),
    );
  }
}

class CommanderSnapshot {
  const CommanderSnapshot({
    required this.personnelId,
    required this.name,
    required this.rank,
    required this.phone,
  });

  final int? personnelId;
  final String name;
  final String rank;
  final String phone;

  String get displayText =>
      [name, rank, phone].where((value) => value.trim().isNotEmpty).join('\n');

  Map<String, Object?> toJson() => {
        'personnelId': personnelId,
        'name': name,
        'rank': rank,
        'phone': phone,
      };

  factory CommanderSnapshot.fromJson(Map<String, Object?> json) =>
      CommanderSnapshot(
        personnelId: (json['personnelId'] as num?)?.toInt(),
        name: json['name'] as String? ?? '',
        rank: json['rank'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
      );
}

class TemgundrapVehicleAssignment {
  const TemgundrapVehicleAssignment({required this.model, required this.plate});

  final String model;
  final String plate;

  Map<String, Object?> toJson() => {'model': model, 'plate': plate};

  factory TemgundrapVehicleAssignment.fromJson(Map<String, Object?> json) =>
      TemgundrapVehicleAssignment(
        model: json['model'] as String? ?? '',
        plate: json['plate'] as String? ?? '',
      );
}

class TemgundrapOperation {
  const TemgundrapOperation({
    required this.id,
    required this.issuingUnit,
    required this.operationArea,
    required this.commander,
    required this.strength,
    required this.vehicles,
    required this.startAt,
    required this.endAt,
    required this.purpose,
    required this.description,
  });

  final String id;
  final String issuingUnit;
  final String operationArea;
  final CommanderSnapshot commander;
  final TemgundrapStrength strength;
  final List<TemgundrapVehicleAssignment> vehicles;
  final DateTime startAt;
  final DateTime endAt;
  final String purpose;
  final String description;

  int get totalStrength => strength.total;

  String get forceDescription {
    final lines = <String>['($totalStrength) PERSONEL'];
    final models = <String, List<String>>{};
    for (final vehicle in vehicles) {
      models.putIfAbsent(vehicle.model, () => []).add(vehicle.plate);
    }
    for (final entry in models.entries) {
      lines.add('(${entry.value.length}) ${entry.key.toUpperCase()}');
      lines.addAll(entry.value);
    }
    return lines.join('\n');
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'issuingUnit': issuingUnit,
        'operationArea': operationArea,
        'commander': commander.toJson(),
        'strength': strength.toJson(),
        'vehicles': vehicles.map((item) => item.toJson()).toList(),
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'purpose': purpose,
        'description': description,
      };

  factory TemgundrapOperation.fromJson(Map<String, Object?> json) {
    final rawStrength =
        (json['strength'] as Map?)?.cast<String, Object?>() ?? const {};
    final rawCommander = json['commander'];
    return TemgundrapOperation(
      id: json['id'] as String,
      issuingUnit: json['issuingUnit'] as String? ?? '',
      operationArea: json['operationArea'] as String? ?? '',
      commander: rawCommander is Map
          ? CommanderSnapshot.fromJson(rawCommander.cast<String, Object?>())
          : CommanderSnapshot(
              personnelId: null,
              name: rawCommander as String? ?? '',
              rank: '',
              phone: '',
            ),
      strength: rawStrength.containsKey('officer')
          ? TemgundrapStrength.fromJson(rawStrength)
          : TemgundrapStrength.fromLegacy(rawStrength),
      vehicles: ((json['vehicles'] as List?) ?? const [])
          .map((item) => TemgundrapVehicleAssignment.fromJson(
              (item as Map).cast<String, Object?>()))
          .toList(),
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

  TemgundrapDocument copyWith(
          {List<TemgundrapOperation>? operations,
          bool? isDraft,
          DateTime? updatedAt}) =>
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

  factory TemgundrapDocument.fromJson(Map<String, Object?> json) =>
      TemgundrapDocument(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        unitTitle: json['unitTitle'] as String? ?? '',
        approverName: json['approverName'] as String? ?? '',
        approverRank: json['approverRank'] as String? ?? '',
        approverDuty: json['approverDuty'] as String? ?? '',
        operations: ((json['operations'] as List?) ?? const [])
            .map((item) => TemgundrapOperation.fromJson(
                (item as Map).cast<String, Object?>()))
            .toList(),
        isDraft: json['isDraft'] as bool? ?? true,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
