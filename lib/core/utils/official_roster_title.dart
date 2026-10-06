class OfficialRosterTitle {
  const OfficialRosterTitle._();

  static const unitName = 'KOVANCILAR JÖH TB.K.LIĞI';
  static const defaultActivityName = 'HEYBET TEPE PUSU FAALİYETİ';

  static String format(
    String _,
    String rawDate, {
    String? timeRange,
  }) {
    final formattedDate = _formatDate(rawDate);
    final cleanTime = timeRange?.trim();
    final timePart =
        (cleanTime != null && cleanTime.isNotEmpty)
            ? ' ($cleanTime SAATLERİ ARASI)'
            : '';
    return '$unitName $formattedDate TARİHİ$timePart $defaultActivityName PERSONEL İSİM LİSTESİ';
  }

  static String _formatDate(String rawDate) {
    final date = rawDate.trim().split('T').first;
    final parts = date.split('-');
    if (parts.length == 3 &&
        parts[0].length == 4 &&
        parts.every((part) => int.tryParse(part) != null)) {
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    }
    return date;
  }
}
