import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

void main() {
  group('ConflictChecker tests', () {
    test('Should return onaylandi when no report and no duplicate duty', () {
      final status = ConflictChecker.evaluateAssignmentStatus(
        personelId: 1,
        targetDate: '2026-07-21',
        targetDuty: DutyOrLeaveType.gorevli,
        reports: [],
        existingAssignments: [],
      );
      expect(status, equals(AssignmentStatus.onaylandi));
    });

    test(
      'Should return beklemede when personnel has active report on target date',
      () {
        final reports = [
          const PersonnelReport(
            id: 1,
            personelId: 1,
            raporBaslangic: '2026-07-20',
            raporBitis: '2026-07-25',
          ),
        ];

        final status = ConflictChecker.evaluateAssignmentStatus(
          personelId: 1,
          targetDate: '2026-07-21',
          targetDuty: DutyOrLeaveType.gorevli,
          reports: reports,
          existingAssignments: [],
        );

        expect(status, equals(AssignmentStatus.beklemede));
      },
    );

    test(
      'Should return beklemede when personnel has duplicate approved duty on target date',
      () {
        final existingAssignments = [
          const ExistingDutyAssignment(
            id: 1,
            faaliyetId: 10,
            personelId: 1,
            tarih: '2026-07-21',
            gorevVeyaIzin: 'GÖREVLİ',
            durum: AssignmentStatus.onaylandi,
          ),
        ];

        final status = ConflictChecker.evaluateAssignmentStatus(
          personelId: 1,
          targetDate: '2026-07-21',
          targetDuty: DutyOrLeaveType.gorevli,
          reports: [],
          existingAssignments: existingAssignments,
        );

        expect(status, equals(AssignmentStatus.beklemede));
      },
    );

    test('pending leave also reserves the covered day', () {
      final status = ConflictChecker.evaluateAssignmentStatus(
        personelId: 1,
        targetDate: '2026-07-21',
        targetDuty: DutyOrLeaveType.sevk,
        reports: [],
        existingAssignments: [
          const ExistingDutyAssignment(
            id: 1,
            faaliyetId: 10,
            personelId: 1,
            tarih: '2026-07-21',
            gorevVeyaIzin: DutyOrLeaveType.izinli,
            durum: AssignmentStatus.beklemede,
          ),
        ],
      );

      expect(status, AssignmentStatus.beklemede);
    });

    test('rejected record does not reserve the day', () {
      final status = ConflictChecker.evaluateAssignmentStatus(
        personelId: 1,
        targetDate: '2026-07-21',
        targetDuty: DutyOrLeaveType.gorevli,
        reports: [],
        existingAssignments: [
          const ExistingDutyAssignment(
            id: 1,
            faaliyetId: 10,
            personelId: 1,
            tarih: '2026-07-21',
            gorevVeyaIzin: DutyOrLeaveType.izinli,
            durum: AssignmentStatus.reddedildi,
          ),
        ],
      );

      expect(status, AssignmentStatus.onaylandi);
    });

    test(
      'isOperationalDuty should return false for leave, rest, report, referral and true for active duties',
      () {
        expect(DutyOrLeaveType.isOperationalDuty('İZİNLİ'), isFalse);
        expect(DutyOrLeaveType.isOperationalDuty('İSTİRAHATLİ'), isFalse);
        expect(DutyOrLeaveType.isOperationalDuty('RAPORLU'), isFalse);
        expect(DutyOrLeaveType.isOperationalDuty('SEVK'), isFalse);
        expect(DutyOrLeaveType.isOperationalDuty('HAZIR KITA'), isTrue);
        expect(DutyOrLeaveType.isOperationalDuty('GÜLÜŞKÜR'), isTrue);
        expect(DutyOrLeaveType.isOperationalDuty('NÖBETÇİ'), isTrue);
      },
    );
  });
}
