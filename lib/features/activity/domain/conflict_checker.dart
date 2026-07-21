/// Personnel assignment status enum string representation
class AssignmentStatus {
  static const String onaylandi = 'onaylandi';
  static const String beklemede = 'beklemede';
  static const String reddedildi = 'reddedildi';
}

/// Duty or leave types
class DutyOrLeaveType {
  static const String gorevli = 'GÖREVLİ';
  static const String nobetci = 'NÖBETÇİ';
  static const String izinli = 'İZİNLİ';
  static const String istirahatli = 'İSTİRAHATLİ';
  static const String raporlu = 'RAPORLU';
  static const String sevk = 'SEVK';
}

/// Simplified Report Data Model for Domain Logic
class PersonnelReport {
  final int id;
  final int personelId;
  final String raporBaslangic; // YYYY-MM-DD
  final String raporBitis; // YYYY-MM-DD
  final String? aciklama;

  const PersonnelReport({
    required this.id,
    required this.personelId,
    required this.raporBaslangic,
    required this.raporBitis,
    this.aciklama,
  });

  bool coversDate(String dateStr) {
    return dateStr.compareTo(raporBaslangic) >= 0 &&
        dateStr.compareTo(raporBitis) <= 0;
  }
}

/// Simplified Existing Duty Assignment for Domain Logic
class ExistingDutyAssignment {
  final int id;
  final int faaliyetId;
  final int personelId;
  final String tarih; // YYYY-MM-DD
  final String gorevVeyaIzin;
  final String durum; // 'onaylandi', 'beklemede', 'reddedildi'

  const ExistingDutyAssignment({
    required this.id,
    required this.faaliyetId,
    required this.personelId,
    required this.tarih,
    required this.gorevVeyaIzin,
    required this.durum,
  });
}

/// Conflict Checker Domain Logic
class ConflictChecker {
  /// Evaluates an assignment for a given personnel on a date.
  /// Returns 'beklemede' if conflict or active report exists, otherwise 'onaylandi'.
  static String evaluateAssignmentStatus({
    required int personelId,
    required String targetDate, // YYYY-MM-DD
    required List<PersonnelReport> reports,
    required List<ExistingDutyAssignment> existingAssignments,
  }) {
    // 1. Raporlu kontrolü
    final hasActiveReport = reports.any(
      (report) =>
          report.personelId == personelId && report.coversDate(targetDate),
    );

    if (hasActiveReport) {
      return AssignmentStatus.beklemede;
    }

    // 2. Mükerrer onaylı görev kontrolü
    final hasDuplicateApprovedDuty = existingAssignments.any(
      (assignment) =>
          assignment.personelId == personelId &&
          assignment.tarih == targetDate &&
          assignment.durum == AssignmentStatus.onaylandi,
    );

    if (hasDuplicateApprovedDuty) {
      return AssignmentStatus.beklemede;
    }

    return AssignmentStatus.onaylandi;
  }
}
