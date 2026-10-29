import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/team_analytics.dart';

class MonthlyPeriodSelector extends StatelessWidget {
  const MonthlyPeriodSelector(
      {super.key, required this.filter, this.onChanged});
  final AnalyticsFilter filter;
  final ValueChanged<AnalyticsFilter>? onChanged;
  void _select(DateTime month) => onChanged?.call(AnalyticsFilter(
      start: DateFormat('yyyy-MM-dd').format(DateTime(month.year, month.month)),
      end: DateFormat('yyyy-MM-dd')
          .format(DateTime(month.year, month.month + 1, 0)),
      teamId: filter.teamId,
      duty: filter.duty,
      status: filter.status));
  @override
  Widget build(BuildContext context) {
    final start = analyticsDate(filter.start);
    final sameMonth =
        filter.start.substring(0, 7) == filter.end.substring(0, 7);
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      IconButton(
          tooltip: 'Önceki ay',
          onPressed: onChanged == null
              ? null
              : () => _select(DateTime(start.year, start.month - 1)),
          icon: const Icon(Icons.chevron_left)),
      TextButton(
          onPressed: onChanged == null
              ? null
              : () async {
                  final chosen = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2200),
                      helpText: 'Görüntülenecek ayı seçin');
                  if (chosen != null) _select(chosen);
                },
          child: Text(sameMonth
              ? DateFormat('MM.yyyy').format(start)
              : 'Seçili dönem')),
      IconButton(
          tooltip: 'Sonraki ay',
          onPressed: onChanged == null
              ? null
              : () => _select(DateTime(start.year, start.month + 1)),
          icon: const Icon(Icons.chevron_right)),
    ]);
  }
}
