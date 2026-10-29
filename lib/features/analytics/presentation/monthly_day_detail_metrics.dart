import 'package:flutter/material.dart';
import '../domain/monthly_analytics_report.dart';
import 'monthly_personnel_summary.dart';

class MonthlyDayDetailMetrics extends StatelessWidget {
  const MonthlyDayDetailMetrics({super.key, required this.day});
  final MonthlyAnalyticsDay day;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final compact = size.maxWidth < 350 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.4;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _card(context, compact, people: true)),
          const SizedBox(width: 8),
          Expanded(child: _card(context, compact, people: false)),
        ]);
      });

  Widget _card(BuildContext context, bool compact, {required bool people}) {
    final title = people ? 'Görev alan farklı kişi' : 'Toplam görevlendirme';
    final count = monthlyCount(people ? day.uniquePersonnel : day.assignments);
    final unit = people ? 'kişi' : 'atama';
    final theme = Theme.of(context);
    final numberStyle = theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.primary, fontWeight: FontWeight.w700);
    return Semantics(
        container: true,
        excludeSemantics: true,
        label: '$title: $count $unit',
        child: Card(
            key: ValueKey(people
                ? 'monthly-detail-people-count'
                : 'monthly-detail-assignment-count'),
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceContainerHigh,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          compact
                              ? (people ? 'Farklı kişi' : 'Atama sayısı')
                              : title,
                          style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      if (compact) ...[
                        Text(count, style: numberStyle),
                        Text(unit, style: theme.textTheme.labelSmall),
                      ] else
                        Text('$count $unit', style: numberStyle),
                    ]))));
  }
}
