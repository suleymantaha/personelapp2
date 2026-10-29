import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/monthly_analytics_report.dart';

String monthlyCount(num value) =>
    NumberFormat.decimalPattern('tr_TR').format(value);
String monthlyPercent(double value) =>
    NumberFormat('0.0', 'tr_TR').format(value * 100);

class MonthlyPersonnelSummary extends StatelessWidget {
  const MonthlyPersonnelSummary({super.key, required this.report});
  final MonthlyAnalyticsReport report;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
          final columns = largeText
              ? 1
              : constraints.maxWidth >= 800
                  ? 3
                  : constraints.maxWidth >= 360
                      ? 2
                      : 1;
          final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
          final stats = [
            (
              'Personel mevcudu (güncel)',
              report.currentHeadcount == null
                  ? 'Bilinmiyor'
                  : '${monthlyCount(report.currentHeadcount!)} kişi'
            ),
            (
              'Görev alan farklı kişi',
              '${monthlyCount(report.uniquePersonnel)} kişi'
            ),
            (
              'Toplam görevlendirme',
              '${monthlyCount(report.assignmentCount)} atama'
            ),
          ];
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final stat in stats)
              SizedBox(
                  width: width,
                  child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stat.$1),
                                Text(stat.$2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)),
                              ]))))
          ]);
        }),
        const SizedBox(height: 8),
        Text(
            report.currentHeadcount == null
                ? 'Güncel personel mevcudu bilinmiyor; görev kayıtlarından türetilmez.'
                : 'Güncel mevcut${report.headcountAsOf == null ? '' : ' (${DateFormat('dd.MM.yyyy').format(report.headcountAsOf!)})'}: yetkili aktif, demo olmayan personel. Ay, görev ve durum filtresinden bağımsızdır.',
            style: Theme.of(context).textTheme.bodySmall),
        const Text('Bir kişinin atanması tam tim görevi anlamına gelmez.'),
        const SizedBox(height: 8),
        Text(
            'Kayıt bulunan gün: ${monthlyCount(report.recordedDays)} / ${monthlyCount(report.totalDays)} · Tim bilgisi kapsaması: %${monthlyPercent(report.teamCoverage)}',
            style: Theme.of(context).textTheme.bodySmall),
      ]);
}
