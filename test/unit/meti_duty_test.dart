import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/duty_abbreviation_mapper.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';

void main() {
  test('admin duty picker swaps Heybet and Kule and adds METİ below Kule', () {
    expect(DutyOrLeaveType.dutiesForRole(isAdmin: true), [
      'HEYBET KOMUTANI',
      'NÖB. SB.',
      'MEBS NÖB.',
      'GARAJ NÖB.',
      'TTZA NÖB.',
      'HEYBET',
      'HAZIR KITA',
      'GÜLÜŞKÜR',
      'KULE NÖB.',
      'METİ',
      'GÖREVLİ',
      'NÖBETÇİ',
      'İZİNLİ',
      'İSTİRAHATLİ',
      'RAPORLU',
      'SEVK',
      'DİĞER',
    ]);
  });

  test('general duties retain restrictions and offer METİ', () {
    final duties = DutyOrLeaveType.dutiesForRole(isAdmin: false);
    expect(duties, contains('METİ'));
    expect(duties, contains('HEYBET'));
    expect(duties.toSet().intersection(DutyOrLeaveType.adminOnlyDuties.toSet()),
        isEmpty);
    expect(DutyOrLeaveType.adminOnlyDuties, [
      'HEYBET KOMUTANI',
      'NÖB. SB.',
      'MEBS NÖB.',
      'GARAJ NÖB.',
      'TTZA NÖB.',
      'KULE NÖB.',
    ]);
    expect(DutyOrLeaveType.allDuties.toSet().length,
        DutyOrLeaveType.allDuties.length);
  });

  test('METİ covers only its date and is an operational duty', () {
    expect(DutyCoverage.coveredDates(startDate: '2026-10-31', duty: 'METİ'),
        ['2026-10-31']);
    expect(
        DutyOrLeaveType.isApprovedOperationalDuty(
            'METİ', AssignmentStatus.onaylandi),
        isTrue);
    expect(DutyAbbreviationMapper.getAbbreviation('METİ'), 'METİ');
  });
}
