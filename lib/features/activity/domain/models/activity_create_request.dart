class PersonnelAssignmentInput {
  const PersonnelAssignmentInput({
    required this.personnelId,
    required this.duty,
    this.note,
    this.teamId,
    this.isOutsideTeam = false,
  });

  final int personnelId;
  final String duty;
  final String? note;
  final int? teamId;

  /// Explicitly confirmed task outside any team, distinct from missing evidence.
  final bool isOutsideTeam;
}

class ActivityCreateRequest {
  const ActivityCreateRequest({
    required this.faaliyetAdi,
    required this.tarih,
    required this.olusturanKullanici,
    required this.personnelAssignments,
  });

  final String faaliyetAdi;
  final String tarih;
  final String olusturanKullanici;
  final List<PersonnelAssignmentInput> personnelAssignments;
}
