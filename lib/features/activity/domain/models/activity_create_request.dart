class PersonnelAssignmentInput {
  const PersonnelAssignmentInput({
    required this.personnelId,
    required this.duty,
    this.note,
    this.teamId,
  });

  final int personnelId;
  final String duty;
  final String? note;
  final int? teamId;
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
