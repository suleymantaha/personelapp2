import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class TemgundrapActivityConverter {
  const TemgundrapActivityConverter._();

  static String sourceId(GunlukFaaliyetTableData activity) =>
      'activity-${activity.tarih}-${activity.id}';

  static bool isAlreadyImported(
    GunlukFaaliyetTableData activity,
    Iterable<TemgundrapOperation> operations,
  ) =>
      operations.any((operation) =>
          operation.id == sourceId(activity) ||
          // Earlier imports used <activity id>_<timestamp>; edits retain that id.
          RegExp('^${activity.id}_[0-9]+\$').hasMatch(operation.id));

  static final RegExp _timeRangePattern = RegExp(
    r'(?<!\d)(\d{1,2})[.:](\d{2})(?:\s*[-/]\s*|\s+to\s+|\s+)(\d{1,2})[.:](\d{2})(?!\d)',
    caseSensitive: false,
  );

  static final RegExp _platePattern = RegExp(
    r'\b(\d{2}\s*[A-ZÇĞİÖŞÜ]{1,3}\s*\d{2,4})\b',
    caseSensitive: false,
  );

  /// Converts multiple activities into [TemgundrapOperation] objects.
  static List<TemgundrapOperation> convertAll({
    required List<GunlukFaaliyetTableData> activities,
    required List<FaaliyetPersonelAtamaTableData> allAssignments,
    required Map<int, PersonelTableData> personnelMap,
    String? issuingUnit,
  }) {
    final assignmentsByActivity = <int, List<FaaliyetPersonelAtamaTableData>>{};
    for (final a in allAssignments) {
      assignmentsByActivity.putIfAbsent(a.faaliyetId, () => []).add(a);
    }

    return activities.map((activity) {
      return convert(
        activity: activity,
        assignments: assignmentsByActivity[activity.id] ?? const [],
        personnelMap: personnelMap,
        issuingUnit: issuingUnit,
      );
    }).toList();
  }

  /// Converts a [GunlukFaaliyetTableData] along with its assigned personnel into
  /// an editable [TemgundrapOperation].
  static TemgundrapOperation convert({
    required GunlukFaaliyetTableData activity,
    required List<FaaliyetPersonelAtamaTableData> assignments,
    required Map<int, PersonelTableData> personnelMap,
    String? issuingUnit,
  }) {
    // 1. Calculate Strength
    var officer = 0;
    var nco = 0;
    var specJ = 0;
    var specSgt = 0;

    PersonelTableData? commanderCandidate;
    var bestRankWeight = 9999;

    for (final assignment in assignments) {
      final person = personnelMap[assignment.personelId];
      if (person == null) continue;

      final norm = normalizeRank(person.rutbe);
      final weight = getRankWeight(norm);

      if (weight <= 70) {
        officer++;
      } else if (weight <= 130) {
        nco++;
      } else if (norm.contains('Uzm.J') || weight == 140) {
        specJ++;
      } else {
        specSgt++;
      }

      // Check highest rank for commander
      if (weight < bestRankWeight) {
        bestRankWeight = weight;
        commanderCandidate = person;
      }
    }

    final strength = TemgundrapStrength(
      officer: officer,
      nco: nco,
      specialistGendarmerie: specJ,
      specialistSergeant: specSgt,
    );

    // 2. Commander Snapshot
    final commander = commanderCandidate != null
        ? CommanderSnapshot(
            personnelId: commanderCandidate.id,
            name: commanderCandidate.adSoyad,
            rank: commanderCandidate.rutbe,
            phone: commanderCandidate.telefon ?? '',
          )
        : const CommanderSnapshot(
            personnelId: null,
            name: '',
            rank: '',
            phone: '',
          );

    // 3. Operation Area
    final titleUpper = activity.faaliyetAdi.toUpperCase();
    String operationArea = activity.faaliyetAdi.trim();
    for (final area in defaultTemgundrapOperationAreas) {
      if (area == customTemgundrapOperationArea) continue;
      final keyword = area.split(' ').first;
      if (titleUpper.contains(keyword) || titleUpper.contains(area)) {
        operationArea = area;
        break;
      }
    }

    // 4. Purpose
    String purpose = 'GÖREVLENDİRME';
    if (titleUpper.contains('YOL EMNİYET') ||
        (titleUpper.contains('YOL') && titleUpper.contains('EMNİYET'))) {
      purpose = 'YOL EMNİYETİ';
    } else if (titleUpper.contains('KONTROL NOKTA') ||
        (titleUpper.contains('KONTROL') && titleUpper.contains('NOKTA'))) {
      purpose = 'KONTROL NOKTASI';
    } else if (titleUpper.contains('NAKİL')) {
      purpose = 'NAKİL EMNİYETİ';
    } else if (titleUpper.contains('DEVRİYE')) {
      purpose = 'DEVRİYE';
    } else if (titleUpper.contains('ASAYİŞ')) {
      purpose = 'ASAYİŞ';
    } else if (titleUpper.contains('KORUMA')) {
      purpose = 'KORUMA';
    } else if (titleUpper.contains('ARAMA') || titleUpper.contains('TARAMA')) {
      purpose = 'ARAMA / TARAMA';
    } else {
      for (final p in defaultTemgundrapPurposes) {
        if (p == 'DİĞER' || p == 'GÖREVLENDİRME') continue;
        if (titleUpper.contains(p)) {
          purpose = p;
          break;
        }
      }
    }

    // 5. Start and End Times
    final dateParts = activity.tarih.split('-');
    final baseYear = int.tryParse(dateParts[0]) ?? DateTime.now().year;
    final baseMonth =
        int.tryParse(dateParts.length > 1 ? dateParts[1] : '1') ?? 1;
    final baseDay =
        int.tryParse(dateParts.length > 2 ? dateParts[2] : '1') ?? 1;

    DateTime startAt = DateTime(baseYear, baseMonth, baseDay, 8, 0);
    DateTime endAt = DateTime(baseYear, baseMonth, baseDay, 17, 0);

    final timeMatch = _timeRangePattern.firstMatch(activity.faaliyetAdi);
    if (timeMatch != null) {
      final h1 = int.parse(timeMatch.group(1)!);
      final m1 = int.parse(timeMatch.group(2)!);
      final h2 = int.parse(timeMatch.group(3)!);
      final m2 = int.parse(timeMatch.group(4)!);

      startAt = DateTime(baseYear, baseMonth, baseDay, h1, m1);
      endAt = DateTime(baseYear, baseMonth, baseDay, h2, m2);
      if (endAt.isBefore(startAt) || endAt.isAtSameMomentAs(startAt)) {
        endAt = endAt.add(const Duration(days: 1));
      }
    }

    // 6. Vehicles
    final vehicles = <TemgundrapVehicleAssignment>[];
    final combinedNotes = [
      activity.faaliyetAdi,
      ...assignments.map((a) => a.aciklama ?? ''),
    ].join(' ').toUpperCase();

    for (final catalogModel in defaultTemgundrapVehicleCatalog.keys) {
      if (combinedNotes.contains(catalogModel)) {
        // Try to find a nearby plate
        final plateMatch = _platePattern.firstMatch(combinedNotes);
        final plate = plateMatch != null ? plateMatch.group(1)!.trim() : '';
        vehicles.add(
          TemgundrapVehicleAssignment(
            model: catalogModel,
            plate: plate,
          ),
        );
        break; // Add matched vehicle
      }
    }

    return TemgundrapOperation(
      id: sourceId(activity),
      issuingUnit: issuingUnit ?? defaultTemgundrapIssuingUnit,
      operationArea: operationArea,
      commander: commander,
      strength: strength,
      vehicles: vehicles,
      startAt: startAt,
      endAt: endAt,
      purpose: purpose,
      description: activity.faaliyetAdi.trim(),
    );
  }
}
