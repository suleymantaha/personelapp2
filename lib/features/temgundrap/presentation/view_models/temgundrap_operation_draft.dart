import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_defaults.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/l10n/generated/app_localizations.dart';

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

  String? validate([AppLocalizations? l10n]) {
    final localizations = l10n ?? lookupAppLocalizations(const Locale('tr'));
    if (issuingUnit.trim().isEmpty) {
      return localizations.temgundrapIssuingUnitRequired;
    }
    if (operationArea.trim().isEmpty) {
      return localizations.temgundrapOperationAreaRequired;
    }
    if (commander == null) {
      return localizations.temgundrapCommanderRequired;
    }
    if (commander!.phone.trim().isEmpty) {
      return localizations.temgundrapCommanderPhoneRequired;
    }
    if (!endAt.isAfter(startAt)) {
      return localizations.temgundrapEndTimeMustBeAfterStart;
    }
    if (purpose.trim().isEmpty) {
      return localizations.temgundrapPurposeRequired;
    }
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
