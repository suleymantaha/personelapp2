class TemgundrapFormatters {
  const TemgundrapFormatters._();

  static const _months = <String>[
    'OCA',
    'ŞUB',
    'MAR',
    'NİS',
    'MAY',
    'HAZ',
    'TEM',
    'AGU',
    'EYL',
    'EKİ',
    'KAS',
    'ARA',
  ];

  static String militaryDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final year = (value.year % 100).toString().padLeft(2, '0');
    return '$day $hour$minute ${_months[value.month - 1]} $year';
  }

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
