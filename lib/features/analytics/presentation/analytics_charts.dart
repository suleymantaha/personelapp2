import 'package:flutter/material.dart';
import '../domain/team_analytics.dart';

class AnalyticsMetricsView extends StatelessWidget {
  const AnalyticsMetricsView({super.key, required this.metrics});
  final AnalyticsMetrics metrics;
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 12, runSpacing: 12, children: [
        _metric(
            context, 'Katılım', metrics.participations, Icons.flag_outlined),
        _metric(context, 'Görev günü', metrics.dutyDays,
            Icons.calendar_today_outlined),
        _metric(context, 'Benzersiz personel', metrics.uniquePersonnel,
            Icons.people_outline),
        _metric(context, 'Personel–görev', metrics.personnelTasks,
            Icons.assignment_ind_outlined),
        _metric(context, 'Personel–gün', metrics.personnelDays,
            Icons.event_available_outlined),
      ]);
  Widget _metric(
          BuildContext context, String label, int count, IconData icon) =>
      SizedBox(
          width: 190,
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('$count',
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text(label),
                      ]))));
}

class AnalyticsCharts extends StatelessWidget {
  const AnalyticsCharts({super.key, required this.data});
  final TeamAnalytics data;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final comparison = _panel(context, 'Görev karşılaştırması · Katılım', [
          for (final duty in data.duties)
            (duty, data.forDuty(duty).metrics.participations),
        ]);
        final trend = _panel(context, 'Aylık trend · Katılım / Görev günü', [
          for (final month in data.monthly)
            (
              '${month.month} · ${month.metrics.participations} katılım / ${month.metrics.dutyDays} gün',
              month.metrics.participations
            ),
        ]);
        if (constraints.maxWidth < 800) {
          return Column(children: [comparison, trend]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: comparison),
          Expanded(child: trend),
        ]);
      });
  Widget _panel(BuildContext context, String title, List<(String, int)> rows) {
    final max = rows.fold<int>(0, (m, row) => row.$2 > m ? row.$2 : m);
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              if (rows.isEmpty) const Text('Gösterilecek veri yok.'),
              for (final row in rows)
                Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Semantics(
                        label: '${row.$1}: ${row.$2}',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${row.$1}   ${row.$2}'),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                  value: max == 0 ? 0 : row.$2 / max,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4)),
                            ]))),
            ])));
  }
}
