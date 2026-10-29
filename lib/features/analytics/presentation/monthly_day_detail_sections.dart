import 'package:flutter/material.dart';
import '../domain/monthly_analytics_report.dart';
import 'monthly_personnel_summary.dart';

class MonthlyDayDutySection extends StatelessWidget {
  const MonthlyDayDutySection({super.key, required this.day});
  final MonthlyAnalyticsDay day;
  @override
  Widget build(BuildContext context) =>
      _section(context, 'Görevler', Icons.assignment_outlined, [
        for (final duty in day.duties)
          Semantics(
              container: true,
              key: ValueKey('monthly-detail-duty-${duty.duty}'),
              label: '${duty.duty}: ${monthlyCount(duty.count)} atama',
              excludeSemantics: true,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(duty.duty,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _pill(
                                  context, '${monthlyCount(duty.count)} atama'),
                              Text(
                                  '%${monthlyPercent(day.assignments == 0 ? 0 : duty.count / day.assignments)}',
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
                            ]),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                            value: day.assignments == 0
                                ? 0
                                : duty.count / day.assignments,
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(8)),
                      ]))),
      ]);
}

class MonthlyDayTeamSection extends StatelessWidget {
  const MonthlyDayTeamSection({super.key, required this.day});
  final MonthlyAnalyticsDay day;
  @override
  Widget build(BuildContext context) =>
      _section(context, 'Timler', Icons.groups_outlined, [
        if (day.teams.isEmpty) const Text('Tim bilgisi bulunan kayıt yok.'),
        for (final team in day.teams)
          Semantics(
              container: true,
              key: ValueKey('monthly-detail-team-${team.teamId}'),
              label:
                  '${team.name}: ${monthlyCount(team.uniquePersonnel)} farklı kişi · ${monthlyCount(team.total)} görevlendirme',
              excludeSemantics: true,
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(team.name,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          _pill(context,
                              '${monthlyCount(team.uniquePersonnel)} farklı kişi'),
                          _pill(context, '${monthlyCount(team.total)} atama'),
                        ]),
                      ]))),
        const Padding(
            padding: EdgeInsets.only(top: 6),
            child:
                Text('Bir kişinin atanması tam tim görevi anlamına gelmez.')),
      ]);
}

Widget _section(
        BuildContext context, String title, IconData icon, List<Widget> rows) =>
    Card(
        margin: EdgeInsets.zero,
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(icon,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)))
                  ]),
                  const SizedBox(height: 4),
                  ...rows,
                ])));

Widget _pill(BuildContext context, String text) => DecoratedBox(
    decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: .45),
        borderRadius: BorderRadius.circular(10)),
    child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge)));
