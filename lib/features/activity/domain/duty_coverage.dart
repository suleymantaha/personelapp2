import 'package:intl/intl.dart';

class DutyCoverage {
  const DutyCoverage._();

  static const Set<String> twoDayDuties = {
    'HAZIR KITA',
    'GÜLÜŞKÜR',
    'NÖB. SB.',
    'GARAJ NÖB.',
    'TTZA NÖB.',
    'MEBS NÖB.',
  };

  static bool spansTwoDays(String duty) =>
      twoDayDuties.contains(duty.toUpperCase().trim());

  static List<String> coveredDates({
    required String startDate,
    required String duty,
  }) {
    final parsed = DateTime.tryParse(startDate);
    if (parsed == null) return [startDate];
    final dates = [DateFormat('yyyy-MM-dd').format(parsed)];
    if (spansTwoDays(duty)) {
      dates.add(
        DateFormat('yyyy-MM-dd').format(parsed.add(const Duration(days: 1))),
      );
    }
    return dates;
  }

  static bool overlaps({
    required String firstDate,
    required String firstDuty,
    required String secondDate,
    required String secondDuty,
  }) {
    final first = coveredDates(startDate: firstDate, duty: firstDuty).toSet();
    final second = coveredDates(
      startDate: secondDate,
      duty: secondDuty,
    );
    return second.any(first.contains);
  }
}
