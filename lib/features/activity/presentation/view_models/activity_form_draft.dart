import 'dart:collection';

enum ActivityFormStep { personnelSelection, activityDetails }

class ActivityFormDraft {
  ActivityFormDraft({required DateTime initialDate})
      : _initialDate = DateTime(
          initialDate.year,
          initialDate.month,
          initialDate.day,
        ),
        selectedDate = DateTime(
          initialDate.year,
          initialDate.month,
          initialDate.day,
        );

  final DateTime _initialDate;
  final Set<int> _selectedPersonnelIds = <int>{};
  final Map<int, String> _dutyOverrides = <int, String>{};
  final Map<int, String> _notes = <int, String>{};

  ActivityFormStep step = ActivityFormStep.personnelSelection;
  DateTime selectedDate;
  String activityName = '';
  String commonDuty = '';

  Set<int> get selectedPersonnelIds =>
      UnmodifiableSetView(_selectedPersonnelIds);

  Map<int, String> get dutyOverrides => UnmodifiableMapView(_dutyOverrides);

  Map<int, String> get notes => UnmodifiableMapView(_notes);

  int get selectedCount => _selectedPersonnelIds.length;
  bool get canContinue => _selectedPersonnelIds.isNotEmpty;

  bool get canPreview =>
      activityName.trim().isNotEmpty &&
      _selectedPersonnelIds.isNotEmpty &&
      _selectedPersonnelIds.every((id) => dutyFor(id)?.isNotEmpty ?? false);

  bool get isDirty =>
      _selectedPersonnelIds.isNotEmpty ||
      activityName.trim().isNotEmpty ||
      commonDuty.trim().isNotEmpty ||
      _dutyOverrides.isNotEmpty ||
      _notes.isNotEmpty ||
      selectedDate != _initialDate;

  Map<int, String> get resolvedDuties => UnmodifiableMapView({
        for (final id in _selectedPersonnelIds)
          if (dutyFor(id) case final duty?) id: duty,
      });

  void togglePersonnel(int personnelId) {
    if (!_selectedPersonnelIds.remove(personnelId)) {
      _selectedPersonnelIds.add(personnelId);
      return;
    }
    _dutyOverrides.remove(personnelId);
    _notes.remove(personnelId);
  }

  void toggleSquad(Iterable<int> personnelIds) {
    final ids = personnelIds.toSet();
    if (ids.isEmpty) return;
    if (isSquadSelected(ids)) {
      _selectedPersonnelIds.removeAll(ids);
      _dutyOverrides.removeWhere((id, _) => ids.contains(id));
      _notes.removeWhere((id, _) => ids.contains(id));
    } else {
      _selectedPersonnelIds.addAll(ids);
    }
  }

  bool isSquadSelected(Iterable<int> personnelIds) {
    final ids = personnelIds.toSet();
    return ids.isNotEmpty && ids.every(_selectedPersonnelIds.contains);
  }

  bool goToDetails() {
    if (!canContinue) return false;
    step = ActivityFormStep.activityDetails;
    return true;
  }

  void goToPersonnelSelection() {
    step = ActivityFormStep.personnelSelection;
  }

  void setDate(DateTime value) {
    selectedDate = DateTime(value.year, value.month, value.day);
  }

  void setActivityName(String value) {
    activityName = value.trim();
  }

  void setCommonDuty(String value) {
    commonDuty = value.trim();
  }

  void setDutyOverride(int personnelId, String? value) {
    if (!_selectedPersonnelIds.contains(personnelId)) return;
    final duty = value?.trim() ?? '';
    if (duty.isEmpty || duty == commonDuty) {
      _dutyOverrides.remove(personnelId);
    } else {
      _dutyOverrides[personnelId] = duty;
    }
  }

  void setDutyForPersonnel(Iterable<int> personnelIds, String? value) {
    for (final personnelId in personnelIds) {
      setDutyOverride(personnelId, value);
    }
  }

  void setNote(int personnelId, String? value) {
    if (!_selectedPersonnelIds.contains(personnelId)) return;
    final note = value?.trim() ?? '';
    if (note.isEmpty) {
      _notes.remove(personnelId);
    } else {
      _notes[personnelId] = note;
    }
  }

  String? dutyFor(int personnelId) {
    if (!_selectedPersonnelIds.contains(personnelId)) return null;
    final duty = _dutyOverrides[personnelId] ?? commonDuty;
    return duty.isEmpty ? null : duty;
  }
}
