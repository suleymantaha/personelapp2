import 'package:flutter/material.dart';

Future<bool> confirmImportDates({
  required BuildContext context,
  required Iterable<String> dates,
  String? targetDate,
  DateTime? now,
}) async {
  final sourceDates = dates.toSet().toList()..sort();
  final writeDates = targetDate == null ? sourceDates : [targetDate];
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final lastUnconfirmedDay = DateTime(clock.year, clock.month, clock.day + 3);
  final invalid = <String>[];
  final warnings = <String>[];
  for (final raw in {...sourceDates, ...writeDates}) {
    final parsed = DateTime.tryParse(raw);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw) ||
        parsed == null ||
        parsed.toIso8601String().substring(0, 10) != raw) {
      invalid.add(raw.isEmpty ? 'Tarih belirtilmedi' : raw);
    }
  }
  if (invalid.isEmpty) {
    for (final raw in writeDates) {
      final date = DateTime.parse(raw);
      if (date.isBefore(today)) {
        warnings.add('Geçmiş tarih: ${_displayDay(raw)}');
      } else if (date.isAfter(lastUnconfirmedDay)) {
        warnings.add('Bugünden 3 günden fazla ileride: ${_displayDay(raw)}');
      }
    }
  }
  final differentTarget =
      targetDate != null && sourceDates.any((date) => date != targetDate);
  if (invalid.isEmpty && warnings.isEmpty && !differentTarget) return true;
  if (!context.mounted) return false;
  final approved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title:
          Text(invalid.isEmpty ? 'Kayıt tarihini onayla' : 'Tarihi düzeltin'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (invalid.isNotEmpty)
              Text('Geçersiz tarih: ${invalid.join(', ')}. '
                  'Kayıttan önce önizlemede tarihi düzeltin.')
            else ...[
              if (differentTarget) ...[
                Text('Kaynak tarihleri: '
                    '${sourceDates.map(_displayDay).join(', ')}'),
                const SizedBox(height: 8),
                Text('Hedef kartın tarihi: ${_displayDay(targetDate)}. '
                    'Yeni kart oluşturulmayacak; personeller bu karta '
                    've bu tarihe eklenecek. Kaynak tarihlerini korumak '
                    'için iptal edip genel toplu aktarımı kullanın.'),
                const SizedBox(height: 12),
              ],
              for (final warning in warnings)
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(warning)),
              const Text('Onay verirseniz kayıt belirtilen güne yazılacak. '
                  'Henüz hiçbir kayıt yapılmadı.'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('import-date-cancel'),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('İptal'),
        ),
        if (invalid.isEmpty)
          FilledButton(
            key: const Key('import-date-approve'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Onayla ve devam et'),
          ),
      ],
    ),
  );
  return approved == true;
}

String _displayDay(String raw) {
  final parts = raw.split('-');
  return parts.length == 3 ? '${parts[2]}.${parts[1]}.${parts[0]}' : raw;
}
