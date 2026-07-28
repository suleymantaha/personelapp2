class PersonnelAssignmentInput {
  const PersonnelAssignmentInput({
    required this.personnelId,
    required this.duty,
    this.note,
  });

  final int personnelId;
  final String duty;
  final String? note;
}

class ActivityCreateRequest {
  const ActivityCreateRequest({
    required this.faaliyetAdi,
    required this.tarih,
    required this.olusturanKullanici,
    required this.personnelAssignments,
    this.isCommander = false,
  });

  final String faaliyetAdi;
  final String tarih;
  final String olusturanKullanici;
  final List<PersonnelAssignmentInput> personnelAssignments;
  final bool isCommander;
}
