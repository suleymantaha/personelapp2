import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/monthly_analytics_report.dart';
import 'monthly_day_detail_sections.dart';
import 'monthly_day_detail_metrics.dart';
import 'monthly_personnel_summary.dart';

Future<void> showMonthlyDayDetail(
        BuildContext context, MonthlyAnalyticsDay day) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        clipBehavior: Clip.antiAlias,
        builder: (_) => MonthlyDayDetailSheet(day: day));

class MonthlyDayDetailSheet extends StatefulWidget {
  const MonthlyDayDetailSheet({super.key, required this.day});
  final MonthlyAnalyticsDay day;
  @override
  State<MonthlyDayDetailSheet> createState() => _MonthlyDayDetailSheetState();
}

class _MonthlyDayDetailSheetState extends State<MonthlyDayDetailSheet> {
  bool showTeams = false;
  final controller = ScrollController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  MonthlyAnalyticsDay get day => widget.day;
  String get _status => day.assignments == 0
      ? 'Kayıt yok'
      : day.isPlanned
          ? 'Planlanan'
          : 'Kayıtlı';
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
      heightFactor: .94,
      child: SafeArea(
          top: false,
          child: Column(key: const ValueKey('monthly-detail-sheet'), children: [
            Column(
                key: const ValueKey('monthly-detail-fixed-header'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MonthlyDayDetailMetrics(day: day)),
                  if (day.teams.isNotEmpty &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.4)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                            '${monthlyCount(day.teams.length)} timden personel görevlendirildi.',
                            style: Theme.of(context).textTheme.bodySmall)),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                                value: false,
                                label: const Text('Görevler',
                                    key:
                                        ValueKey('monthly-detail-tab-duties'))),
                            ButtonSegment(
                                value: true,
                                label: Text(
                                    MediaQuery.textScalerOf(context).scale(1) >=
                                            1.4
                                        ? 'Timler'
                                        : 'Timler (${day.teams.length})',
                                    key: const ValueKey(
                                        'monthly-detail-tab-teams'))),
                          ],
                          selected: {showTeams},
                          onSelectionChanged: (value) {
                            if (controller.hasClients) controller.jumpTo(0);
                            setState(() => showTeams = value.single);
                          })),
                ]),
            Expanded(
                child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                  Text(
                      day.assignments == 0
                          ? 'Bu gün için görev kaydı bulunamadı. Görev yapılmadığı sonucu çıkarılamaz.'
                          : day.isPlanned
                              ? 'İleri tarihli görevlendirmeler planlanandır.'
                              : 'Kayıt bulunması görevin tamamlandığını göstermez.',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (_unknown > 0)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            'Tim bilgisi bulunmayan: ${monthlyCount(_unknown)} atama',
                            style: Theme.of(context).textTheme.bodySmall)),
                  if (day.assignments > 0) ...[
                    const SizedBox(height: 16),
                    if (showTeams)
                      MonthlyDayTeamSection(day: day)
                    else
                      MonthlyDayDutySection(day: day),
                  ],
                ])),
          ])));

  int get _unknown =>
      day.assignments - day.teams.fold<int>(0, (sum, team) => sum + team.total);

  Widget _header(BuildContext context) {
    final date = DateTime.parse(day.date);
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!compact)
            Text('Günlük ayrıntı',
                style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Semantics(
                    label:
                        '${DateFormat('dd.MM.yyyy').format(date)} · $_status',
                    excludeSemantics: true,
                    child: Text(
                        DateFormat(
                                compact ? 'dd.MM.yyyy' : 'd MMMM yyyy', 'tr_TR')
                            .format(date),
                        style: (compact
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.w700)))),
            IconButton(
                tooltip: 'Kapat',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close)),
          ]),
          Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!compact)
                  Text(DateFormat('EEEE', 'tr_TR').format(date),
                      style: Theme.of(context).textTheme.bodyMedium),
                Chip(
                    label: Text(_status),
                    avatar: Icon(
                        day.assignments == 0
                            ? Icons.event_busy_outlined
                            : day.isPlanned
                                ? Icons.schedule
                                : Icons.event_available_outlined,
                        size: 16),
                    backgroundColor:
                        colors.primaryContainer.withValues(alpha: .5),
                    side: BorderSide.none),
              ]),
        ]));
  }
}
