import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import '../domain/team_analytics.dart';
import 'analytics_details.dart';
import 'team_analytics_settings.dart';
import 'team_analytics_notice.dart';
import 'team_analytics_provider.dart';
import 'team_duty_report_view.dart';
import 'team_monthly_duty_view.dart';
import 'monthly_analytics_view.dart';

class TeamAnalyticsScreen extends ConsumerStatefulWidget {
  const TeamAnalyticsScreen(
      {super.key, this.initialFilter, this.initialTab = 0});
  final AnalyticsFilter? initialFilter;
  final int initialTab;
  @override
  ConsumerState<TeamAnalyticsScreen> createState() =>
      _TeamAnalyticsScreenState();
}

class _TeamAnalyticsScreenState extends ConsumerState<TeamAnalyticsScreen> {
  late AnalyticsFilter filter;
  late int selectedTab;
  AnalyticsFilter? dailyReturnFilter;
  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab.clamp(0, 2);
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');
    filter = widget.initialFilter ??
        AnalyticsFilter(
            start: format.format(DateTime(now.year, now.month)),
            end: format.format(DateTime(now.year, now.month + 1, 0)));
  }

  void _change(AnalyticsFilter value) => setState(() {
        final previousDay = dailyReturnFilter;
        dailyReturnFilter = previousDay != null &&
                value.start == filter.start &&
                value.end == filter.end
            ? AnalyticsFilter(
                start: previousDay.start,
                end: previousDay.end,
                teamId: value.teamId,
                duty: value.duty,
                status: value.status)
            : null;
        filter = value;
      });
  void _selectTab(int tab) => setState(() {
        if (tab == 1 && filter.start == filter.end) {
          dailyReturnFilter = filter;
          final date = analyticsDate(filter.start);
          filter = AnalyticsFilter(
              start: DateFormat('yyyy-MM-dd')
                  .format(DateTime(date.year, date.month)),
              end: DateFormat('yyyy-MM-dd')
                  .format(DateTime(date.year, date.month + 1, 0)),
              teamId: filter.teamId,
              duty: filter.duty,
              status: filter.status);
        } else if (tab == 0 && dailyReturnFilter != null) {
          filter = dailyReturnFilter!;
          dailyReturnFilter = null;
        }
        selectedTab = tab;
      });
  void _settings() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          TeamAnalyticsSettings(initialFilter: filter, onChanged: _change));
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamAnalyticsProvider(filter));
    return Scaffold(
      appBar: AppBar(title: const Text('Tim Görev Analizi'), actions: [
        IconButton(
            key: const ValueKey('analytics-settings'),
            tooltip: 'Analiz ayarları',
            onPressed: _settings,
            icon: const Icon(Icons.settings_outlined)),
      ]),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Analiz yüklenemedi.'),
          FilledButton.tonal(
              onPressed: () => ref.invalidate(teamAnalyticsProvider(filter)),
              child: const Text('Tekrar dene')),
        ])),
        data: (data) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(padding: const EdgeInsets.all(12), children: [
              Text(
                  filter.start == filter.end
                      ? DateFormat('dd.MM.yyyy')
                          .format(analyticsDate(filter.start))
                      : '${filter.start} — ${filter.end}',
                  key: const ValueKey('analytics-selected-period'),
                  style: Theme.of(context).textTheme.labelLarge),
              if (filter.teamId != null ||
                  filter.duty != null ||
                  filter.status != 'onaylandi')
                Text(
                    [
                      if (filter.teamId != null)
                        data.teams[filter.teamId] ?? 'Seçili tim',
                      if (filter.duty != null) filter.duty!,
                      if (filter.status != 'onaylandi')
                        filter.status == 'beklemede'
                            ? 'Bekleyen'
                            : 'Reddedilen',
                    ].join(' · '),
                    key: const ValueKey('analytics-active-filters')),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  key: const ValueKey('analytics-watch-roster'),
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('NÖBET'),
                  subtitle: const Text('Aylık nöbet çizelgesi'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AppNavigator.toWatchRoster(context,
                      initialMonth: analyticsDate(filter.start)),
                ),
              ),
              const SizedBox(height: 8),
              _tabs(),
              const SizedBox(height: 16),
              if (selectedTab == 0) ...[
                TeamDutyReportView(data: data),
                TeamAnalyticsNotice(data: data),
                Card(
                    child: ExpansionTile(
                  key: const ValueKey('report-advanced-charts'),
                  title: const Text('Grafikler ve aylık eğilimler'),
                  childrenPadding: const EdgeInsets.all(12),
                  children: [
                    MonthlyAnalyticsView(data: data, onFilterChanged: _change)
                  ],
                )),
              ] else if (selectedTab == 1) ...[
                MonthlyAnalyticsView(data: data, onFilterChanged: _change),
                Card(
                    child: ExpansionTile(
                  key: const ValueKey('monthly-legacy-detail'),
                  title: const Text('Tim bazında faaliyet ayrıntıları'),
                  childrenPadding: const EdgeInsets.all(12),
                  children: [TeamMonthlyDutyView(data: data)],
                )),
              ] else
                AnalyticsDetails(data: data),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tabs() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final tab in [
          (0, 'overview', 'Timler'),
          (1, 'monthly', 'Aylık Döküm'),
          (2, 'details', 'Kayıt Ayrıntısı')
        ])
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  key: ValueKey('tab-${tab.$2}'),
                  label: Text(tab.$3),
                  selected: selectedTab == tab.$1,
                  onSelected: (_) => _selectTab(tab.$1))),
      ]));
}
