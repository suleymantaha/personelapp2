import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/monthly_analytics_report.dart';
import 'monthly_personnel_summary.dart';
import 'monthly_day_detail_sheet.dart';

class MonthlyDailyChart extends StatelessWidget {
  const MonthlyDailyChart({super.key, required this.report});
  final MonthlyAnalyticsReport report;
  @override
  Widget build(BuildContext context) {
    final maxCount = report.days
        .fold<int>(0, (value, day) => math.max(value, day.assignments));
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Günlük görevlendirmeler',
                            style: Theme.of(context).textTheme.titleMedium),
                        TextButton.icon(
                            onPressed: () => _chooseDay(context),
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 16),
                            label: const Text('Gün seç')),
                      ]),
                  Wrap(spacing: 12, runSpacing: 4, children: [
                    _legend(context, 'Kayıtlı', false),
                    _legend(context, 'Planlanan', true),
                    const Text('— Kayıt yok'),
                  ]),
                  const SizedBox(height: 8),
                  Text('En yüksek: ${monthlyCount(maxCount)} atama',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  LayoutBuilder(builder: (context, constraints) {
                    // One whole month fits on mobile; longer selected periods scroll.
                    final width = math.max(
                        constraints.maxWidth, report.days.length * 8.0);
                    return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                            width: width,
                            child: Column(children: [
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    for (final day in report.days)
                                      Expanded(
                                          child: _bar(context, day, maxCount)),
                                  ]),
                              const Divider(height: 1),
                              Row(children: [
                                for (final day in report.days)
                                  Expanded(
                                      child: SizedBox(
                                          height: 28,
                                          child: OverflowBox(
                                              minWidth: 0,
                                              maxWidth: 64,
                                              alignment: Alignment.topCenter,
                                              child: Text(_tick(day),
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall))))
                              ]),
                            ])));
                  }),
                  const Text(
                      'Günlük personel ataması · Ayrıntı için güne dokunun.'),
                ])));
  }

  String _tick(MonthlyAnalyticsDay day) {
    final date = DateTime.parse(day.date);
    final index = report.days.indexOf(day);
    final last = report.days.length - 1;
    if (last > 7 &&
        index != 0 &&
        index != last &&
        (index < 3 || last - index < 3)) {
      return '';
    }
    return day == report.days.first ||
            day == report.days.last ||
            date.day % 5 == 0
        ? '${date.day}'
        : '';
  }

  Widget _legend(BuildContext context, String label, bool planned) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
                color: planned
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.primary,
                border:
                    Border.all(color: Theme.of(context).colorScheme.primary))),
        Text(label),
      ]);

  Widget _bar(BuildContext context, MonthlyAnalyticsDay day, int maxCount) {
    final colors = Theme.of(context).colorScheme;
    final state = day.assignments == 0
        ? 'Kayıt yok'
        : day.isPlanned
            ? 'Planlanan'
            : 'Kayıtlı';
    final label =
        '${day.date}: ${monthlyCount(day.assignments)} atama · $state';
    return Semantics(
        label: label,
        button: true,
        child: Tooltip(
            message: label,
            child: InkWell(
                key: ValueKey('monthly-day-${day.date}'),
                onTap: () => showMonthlyDayDetail(context, day),
                child: SizedBox(
                  height: 140,
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: day.assignments == 0
                          ? const Text('—', style: TextStyle(fontSize: 9))
                          : FractionallySizedBox(
                              widthFactor: .72,
                              child: Container(
                                  height: 140 * day.assignments / maxCount,
                                  decoration: BoxDecoration(
                                      color: day.isPlanned
                                          ? colors.secondaryContainer
                                          : colors.primary,
                                      border: Border.all(color: colors.primary),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(2)))))),
                ))));
  }

  Future<void> _chooseDay(BuildContext context) async {
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.parse(report.start),
        firstDate: DateTime.parse(report.start),
        lastDate: DateTime.parse(report.end),
        helpText: 'Ayrıntısı görüntülenecek gün');
    if (date == null || !context.mounted) return;
    final label = DateFormat('yyyy-MM-dd').format(date);
    showMonthlyDayDetail(
        context, report.days.firstWhere((day) => day.date == label));
  }
}
