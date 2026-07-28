import 'package:personelapp2/features/activity/domain/duty_coverage.dart';

/// Personnel assignment status enum string representation
class AssignmentStatus {
  static const String onaylandi = 'onaylandi';
  static const String beklemede = 'beklemede';
  static const String reddedildi = 'reddedildi';
}

/// Duty or leave types
class DutyOrLeaveType {
  static const String heybetKomutani = 'HEYBET KOMUTANI';
  static const String nobSb = 'NÖB. SB.';
  static const String mebsNob = 'MEBS NÖB.';
  static const String garajNob = 'GARAJ NÖB.';
  static const String ttzaNob = 'TTZA NÖB.';
  static const String kuleNob = 'KULE NÖB.';
  static const String hazirKita = 'HAZIR KITA';
  static const String guluskur = 'GÜLÜŞKÜR';
  static const String heybet = 'HEYBET';
  static const String gorevli = 'GÖREVLİ';
  static const String nobetci = 'NÖBETÇİ';
  static const String izinli = 'İZİNLİ';
  static const String istirahatli = 'İSTİRAHATLİ';
  static const String raporlu = 'RAPORLU';
  static const String sevk = 'SEVK';
  static const String diger = 'DİĞER';

  /// Returns true if the assignment is an active operational duty, false if it is a non-duty status (leave, rest, report, referral).
  static bool isOperationalDuty(String dutyOrLeave) {
    final d = dutyOrLeave.toUpperCase().trim();
    if (d.contains('İZİN') ||
        d.contains('İSTİRAHAT') ||
        d.contains('RAPOR') ||
        d.contains('SEVK')) {
      return false;
    }
    return true;
  }
}

/// Simplified Report Data Model for Domain Logic
class PersonnelReport {
  const PersonnelReport({
    required this.id,
    required this.personelId,
    required this.raporBaslangic,
    required this.raporBitis,
    this.aciklama,
  });

  final int id;
  final int personelId;
  final String raporBaslangic; // YYYY-MM-DD
  final String raporBitis; // YYYY-MM-DD
  final String? aciklama;

  bool coversDate(String dateStr) {
    return dateStr.compareTo(raporBaslangic) >= 0 &&
        dateStr.compareTo(raporBitis) <= 0;
  }
}

/// Simplified Existing Duty Assignment for Domain Logic
class ExistingDutyAssignment {
  const ExistingDutyAssignment({
    required this.id,
    required this.faaliyetId,
    required this.personelId,
    required this.tarih,
    required this.gorevVeyaIzin,
    required this.durum,
  });

  final int id;
  final int faaliyetId;
  final int personelId;
  final String tarih; // YYYY-MM-DD
  final String gorevVeyaIzin;
  final String durum; // 'onaylandi', 'beklemede', 'reddedildi'
}

/// Conflict Checker Domain Logic
class ConflictChecker {
  /// Evaluates an assignment for a given personnel on a date.
  /// Returns 'beklemede' if conflict or active report exists, otherwise 'onaylandi'.
  static String evaluateAssignmentStatus({
    required int personelId,
    required String targetDate, // YYYY-MM-DD
    required String targetDuty,
    required List<PersonnelReport> reports,
    required List<ExistingDutyAssignment> existingAssignments,
    int? excludeAssignmentId,
    int? excludeActivityId,
  }) {
    final targetDates = DutyCoverage.coveredDates(
      startDate: targetDate,
      duty: targetDuty,
    );
    final hasActiveReport = reports.any(
      (report) =>
          report.personelId == personelId && targetDates.any(report.coversDate),
    );

    if (hasActiveReport) {
      return AssignmentStatus.beklemede;
    }

    // 2. Mükerrer onaylı görev kontrolü
    final hasDuplicateApprovedDuty =
        DutyOrLeaveType.isOperationalDuty(targetDuty) &&
            existingAssignments.any(
              (assignment) =>
                  assignment.personelId == personelId &&
                  assignment.durum == AssignmentStatus.onaylandi &&
                  DutyOrLeaveType.isOperationalDuty(assignment.gorevVeyaIzin) &&
                  assignment.id != excludeAssignmentId &&
                  assignment.faaliyetId != excludeActivityId &&
                  DutyCoverage.overlaps(
                    firstDate: assignment.tarih,
                    firstDuty: assignment.gorevVeyaIzin,
                    secondDate: targetDate,
                    secondDuty: targetDuty,
                  ),
            );

    if (hasDuplicateApprovedDuty) {
      return AssignmentStatus.beklemede;
    }

    return AssignmentStatus.onaylandi;
  }
}
