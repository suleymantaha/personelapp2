import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/team_analytics.dart';

class TeamAnalyticsDates extends StatelessWidget {
  const TeamAnalyticsDates(
      {super.key, required this.filter, required this.onChanged});
  final AnalyticsFilter filter;
  final ValueChanged<AnalyticsFilter> onChanged;
  void _set(DateTime start, DateTime end) => onChanged(AnalyticsFilter(
      start: DateFormat('yyyy-MM-dd').format(start),
      end: DateFormat('yyyy-MM-dd').format(end),
      teamId: filter.teamId,
      duty: filter.duty,
      status: filter.status));
  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: analyticsDate(filter.start),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        helpText: 'Görev tarihi');
    if (picked != null && context.mounted) _set(picked, picked);
  }

  Future<void> _range(BuildContext context) async {
    final picked = await showDateRangePicker(
        context: context,
        initialDateRange: DateTimeRange(
            start: analyticsDate(filter.start), end: analyticsDate(filter.end)),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        helpText: 'Rapor dönemi · en fazla 366 gün');
    if (picked == null || !context.mounted) return;
    if (picked.duration.inDays > 365) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 366 gün seçin.')));
    } else {
      _set(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = analyticsDate(filter.start);
    final daily = filter.start == filter.end;
    return Column(children: [
      Row(children: [
        IconButton(
            tooltip: 'Önceki gün',
            key: const ValueKey('analytics-previous-day'),
            onPressed: date.isAfter(DateTime(2000))
                ? () {
                    final previous = date.subtract(const Duration(days: 1));
                    _set(previous, previous);
                  }
                : null,
            icon: const Icon(Icons.chevron_left_rounded)),
        Expanded(
            child: TextButton.icon(
          key: const ValueKey('analytics-date'),
          onPressed: () => _pick(context),
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
              daily
                  ? DateFormat('dd.MM.yyyy').format(date)
                  : '${filter.start} — ${filter.end}',
              textAlign: TextAlign.center),
        )),
        IconButton(
            tooltip: 'Sonraki gün',
            key: const ValueKey('analytics-next-day'),
            onPressed: date.isBefore(DateTime(2100))
                ? () {
                    final next = date.add(const Duration(days: 1));
                    _set(next, next);
                  }
                : null,
            icon: const Icon(Icons.chevron_right_rounded)),
      ]),
      Wrap(spacing: 8, children: [
        TextButton(
            onPressed: () {
              final now = DateTime.now();
              _set(now, now);
            },
            key: const ValueKey('analytics-today'),
            child: const Text('Bugün')),
        TextButton(
            onPressed: () => _range(context), child: const Text('Dönem seç')),
      ]),
    ]);
  }
}
