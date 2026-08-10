import 'dart:collection';

import 'package:personelapp2/features/activity/domain/models/activity_create_request.dart';

enum ActivityFormStep { personnelSelection, activityDetails }

class ActivityTaskCardDraft {
  ActivityTaskCardDraft._({
    required this.id,
    required DateTime date,
    required String duty,
    Iterable<int> personnelIds = const [],
  })  : date = DateTime(date.year, date.month, date.day),
        duty = duty.trim(),
        _personnelIds = personnelIds.toSet();

  final int id;
  DateTime date;
  String duty;
  final Set<int> _personnelIds;

  Set<int> get personnelIds => UnmodifiableSetView(_personnelIds);

  void setDate(DateTime value) {
    date = DateTime(value.year, value.month, value.day);
  }

  void setDuty(String value) {
    duty = value.trim();
  }

  void _addPersonnel(int personnelId) {
    _personnelIds.add(personnelId);
  }

  bool _removePersonnel(int personnelId) {
    return _personnelIds.remove(personnelId);
  }
}

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
  final List<ActivityTaskCardDraft> _taskCards = <ActivityTaskCardDraft>[];
  int _nextTaskCardId = 1;

  ActivityFormStep step = ActivityFormStep.personnelSelection;
  DateTime selectedDate;
  String activityName = '';
  String commonDuty = '';

  Set<int> get selectedPersonnelIds => UnmodifiableSetView(_allPersonnelIds);

  Map<int, String> get dutyOverrides => UnmodifiableMapView(_dutyOverrides);

  Map<int, String> get notes => UnmodifiableMapView(_notes);

  List<ActivityTaskCardDraft> get taskCards => UnmodifiableListView(_taskCards);

  Set<int> get _cardPersonnelIds => {
        for (final card in _taskCards) ...card._personnelIds,
      };

  Set<int> get _allPersonnelIds => {
        ..._selectedPersonnelIds,
        ..._cardPersonnelIds,
      };

  int get selectedCount => _allPersonnelIds.length;
  bool get canContinue => _allPersonnelIds.isNotEmpty;

  bool get canPreview =>
      activityName.trim().isNotEmpty &&
      _allPersonnelIds.isNotEmpty &&
      _allPersonnelIds.every((id) => dutyFor(id)?.isNotEmpty ?? false);

  bool get isDirty =>
      _allPersonnelIds.isNotEmpty ||
      activityName.trim().isNotEmpty ||
      commonDuty.trim().isNotEmpty ||
      _dutyOverrides.isNotEmpty ||
      _notes.isNotEmpty ||
      _taskCards.isNotEmpty ||
      selectedDate != _initialDate;

  Map<int, String> get resolvedDuties => UnmodifiableMapView({
        for (final card in _taskCards)
          if (card.duty.isNotEmpty)
            for (final id in card._personnelIds) id: card.duty,
        for (final id in _selectedPersonnelIds.difference(_cardPersonnelIds))
          if (dutyFor(id) case final duty?) id: duty,
      });

  List<PersonnelAssignmentInput> get resolvedPersonnelAssignments =>
      UnmodifiableListView([
        for (final entry in resolvedDuties.entries)
          PersonnelAssignmentInput(
            personnelId: entry.key,
            duty: entry.value,
            note: _notes[entry.key]?.trim().isEmpty ?? true
                ? null
                : _notes[entry.key]!.trim(),
          ),
      ]);

  ActivityTaskCardDraft createTaskCard({
    required DateTime date,
    required String duty,
    Iterable<int> personnelIds = const [],
  }) {
    final card = ActivityTaskCardDraft._(
      id: _nextTaskCardId++,
      date: date,
      duty: duty,
    );
    _taskCards.add(card);
    for (final personnelId in personnelIds) {
      assignPersonnelToTaskCard(card.id, personnelId);
    }
    return card;
  }

  void setTaskCardDate(int cardId, DateTime value) {
    _taskCardById(cardId)?.setDate(value);
  }

  void setTaskCardDuty(int cardId, String value) {
    _taskCardById(cardId)?.setDuty(value);
  }

  void assignPersonnelToTaskCard(int cardId, int personnelId) {
    final target = _taskCardById(cardId);
    if (target == null) return;
    for (final card in _taskCards) {
      card._removePersonnel(personnelId);
    }
    _selectedPersonnelIds.remove(personnelId);
    _dutyOverrides.remove(personnelId);
    target._addPersonnel(personnelId);
  }

  void removePersonnelFromTaskCard(int cardId, int personnelId) {
    final card = _taskCardById(cardId);
    if (card == null || !card._removePersonnel(personnelId)) return;
    if (!_allPersonnelIds.contains(personnelId)) {
      _dutyOverrides.remove(personnelId);
      _notes.remove(personnelId);
    }
  }

  void removeTaskCard(int cardId) {
    final index = _taskCards.indexWhere((card) => card.id == cardId);
    if (index == -1) return;
    final removedPersonnelIds = _taskCards[index]._personnelIds.toSet();
    _taskCards.removeAt(index);
    for (final personnelId in removedPersonnelIds) {
      if (!_allPersonnelIds.contains(personnelId)) {
        _dutyOverrides.remove(personnelId);
        _notes.remove(personnelId);
      }
    }
  }

  ActivityTaskCardDraft? _taskCardById(int cardId) {
    for (final card in _taskCards) {
      if (card.id == cardId) return card;
    }
    return null;
  }

  void togglePersonnel(int personnelId) {
    if (!_selectedPersonnelIds.remove(personnelId)) {
      for (final card in _taskCards) {
        card._removePersonnel(personnelId);
      }
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
    if (!_allPersonnelIds.contains(personnelId)) return;
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
    if (!_allPersonnelIds.contains(personnelId)) return;
    final note = value?.trim() ?? '';
    if (note.isEmpty) {
      _notes.remove(personnelId);
    } else {
      _notes[personnelId] = note;
    }
  }

  String? dutyFor(int personnelId) {
    for (final card in _taskCards) {
      if (card._personnelIds.contains(personnelId)) {
        return card.duty.isEmpty ? null : card.duty;
      }
    }
    if (!_selectedPersonnelIds.contains(personnelId)) return null;
    final duty = _dutyOverrides[personnelId] ?? commonDuty;
    return duty.isEmpty ? null : duty;
  }
}
