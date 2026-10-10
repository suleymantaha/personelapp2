import 'package:personelapp2/core/utils/turkish_date_helper.dart';

class TemgundrapFormatters {
  const TemgundrapFormatters._();

  static String militaryDateTime(DateTime value) =>
      TurkishDateHelper.formatMilitaryDtg(value);

  static String normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90') && digits.length == 12) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits;
  }

  static bool isValidTurkishMobile(String input) {
    final digits = normalizePhone(input);
    return RegExp(r'^5\d{9}$').hasMatch(digits);
  }

  static String phone(String input) {
    final digits = normalizePhone(input);
    if (digits.length != 10) return input.trim();
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} '
        '${digits.substring(6, 8)} ${digits.substring(8, 10)}';
  }
}
