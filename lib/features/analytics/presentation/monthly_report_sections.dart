import 'package:flutter/material.dart';
import '../domain/monthly_analytics_report.dart';
import 'monthly_personnel_summary.dart';

class MonthlyReportSections extends StatelessWidget {
  const MonthlyReportSections({super.key, required this.report});
  final MonthlyAnalyticsReport report;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Görev dağılımı', style: Theme.of(context).textTheme.titleMedium),
        const Text(
            'Yüzdeler, seçili dönemdeki tüm görevlendirmelerin payıdır.'),
        for (final duty in report.duties)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        '${duty.duty} · ${monthlyCount(duty.count)} atama · %${monthlyPercent(report.assignmentCount == 0 ? 0 : duty.count / report.assignmentCount)}'),
                    LinearProgressIndicator(
                        value: report.assignmentCount == 0
                            ? 0
                            : duty.count / report.assignmentCount,
                        semanticsLabel: duty.duty),
                  ])),
        const SizedBox(height: 16),
        Text('Tim × görev matrisi',
            style: Theme.of(context).textTheme.titleMedium),
        const Text(
            'Her hücre farklı kişi / atama sayısıdır. Satır toplamındaki kişiler görevler arasında tekilleştirilir. Yana kaydırın.'),
        if (report.teams.isEmpty)
          const Text('Yetkili tim kaydı bulunamadı.')
        else
          SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: _matrix(context)),
      ]);

  Widget _matrix(BuildContext context) {
    final maxCell = report.teams
        .expand((team) => team.duties.values)
        .fold<int>(1, (max, value) => value > max ? value : max);
    return DataTable(
        dataRowMinHeight: 48,
        dataRowMaxHeight: double.infinity,
        columns: [
          const DataColumn(label: Text('Tim')),
          for (final duty in report.duties)
            DataColumn(label: SizedBox(width: 150, child: Text(duty.duty))),
          const DataColumn(label: Text('Toplam'), numeric: true)
        ],
        rows: [
          for (final team in report.teams)
            DataRow(cells: [
              DataCell(SizedBox(width: 120, child: Text(team.name))),
              for (final duty in report.duties)
                DataCell(Container(
                    width: 150,
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).colorScheme.primary.withValues(
                        alpha: (team.duties[duty.duty] ?? 0) / maxCell * 0.3),
                    child: Text(
                        '${monthlyCount(team.uniquePersonnelByDuty[duty.duty] ?? 0)} kişi / ${monthlyCount(team.duties[duty.duty] ?? 0)} atama'))),
              DataCell(Text(
                  '${monthlyCount(team.uniquePersonnel)} kişi / ${monthlyCount(team.total)} atama')),
            ])
        ]);
  }
}
