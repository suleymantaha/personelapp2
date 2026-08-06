import 'package:flutter/foundation.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';

class TemgundrapOperationDraft extends ChangeNotifier {
  TemgundrapOperationDraft({DateTime? now, TemgundrapOperation? initial})
      : issuingUnit = initial?.issuingUnit ?? defaultTemgundrapIssuingUnit,
        operationArea = initial?.operationArea ?? '',
        purpose = initial?.purpose ?? defaultTemgundrapPurposes.first,
        description = initial?.description ?? '',
        commander = initial?.commander,
        strength = initial?.strength ?? const TemgundrapStrength(),
        vehicles = [...?initial?.vehicles],
        startAt = initial?.startAt ?? now ?? DateTime.now(),
        endAt = initial?.endAt ??
            (now ?? DateTime.now()).add(const Duration(hours: 1));

  String issuingUnit;
  String operationArea;
  String purpose;
  String description;
  CommanderSnapshot? commander;
  TemgundrapStrength strength;
  final List<TemgundrapVehicleAssignment> vehicles;
  DateTime startAt;
  DateTime endAt;

  void setCommander(CommanderSnapshot value) {
    commander = value;
    notifyListeners();
  }

  void setStrength(TemgundrapStrength value) {
    strength = value;
    notifyListeners();
  }

  void setStart(DateTime value) {
    startAt = value;
    if (!endAt.isAfter(startAt)) {
      endAt = startAt.add(const Duration(hours: 1));
    }
    notifyListeners();
  }

  void setEnd(DateTime value) {
    endAt = value;
    notifyListeners();
  }

  bool addVehicle(TemgundrapVehicleAssignment value) {
    if (vehicles
        .any((item) => item.plate.toUpperCase() == value.plate.toUpperCase())) {
      return false;
    }
    vehicles.add(value);
    notifyListeners();
    return true;
  }

  void removeVehicle(int index) {
    vehicles.removeAt(index);
    notifyListeners();
  }

  String? validate() {
    if (issuingUnit.trim().isEmpty) return 'Çıkaran birlik zorunludur.';
    if (operationArea.trim().isEmpty) return 'Operasyon bölgesi zorunludur.';
    if (commander == null) return 'Operasyon komutanı seçilmelidir.';
    if (commander!.phone.trim().isEmpty) return 'Komutan telefonu zorunludur.';
    if (!endAt.isAfter(startAt)) {
      return 'Bitiş zamanı başlangıçtan sonra olmalıdır.';
    }
    if (purpose.trim().isEmpty) return 'Operasyon maksadı zorunludur.';
    return null;
  }

  TemgundrapOperation buildOperation({String? id}) {
    final error = validate();
    if (error != null) throw StateError(error);
    return TemgundrapOperation(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      issuingUnit: issuingUnit.trim(),
      operationArea: operationArea.trim(),
      commander: commander!,
      strength: strength,
      vehicles: List.unmodifiable(vehicles),
      startAt: startAt,
      endAt: endAt,
      purpose: purpose.trim(),
      description: description.trim(),
    );
  }
}
