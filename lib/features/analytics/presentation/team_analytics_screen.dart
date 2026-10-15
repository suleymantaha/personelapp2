import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/providers/providers.dart';
import '../domain/team_analytics.dart';
import 'analytics_charts.dart';
import 'analytics_details.dart';
import 'team_analytics_provider.dart';

class TeamAnalyticsScreen extends ConsumerStatefulWidget {
  const TeamAnalyticsScreen({super.key, this.initialFilter});
  final AnalyticsFilter? initialFilter;
  @override
  ConsumerState<TeamAnalyticsScreen> createState() =>
      _TeamAnalyticsScreenState();
}

class _TeamAnalyticsScreenState extends ConsumerState<TeamAnalyticsScreen> {
  late AnalyticsFilter filter;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    filter = widget.initialFilter ??
        AnalyticsFilter(
            start: '${now.year}-01-01',
            end: DateFormat('yyyy-MM-dd').format(now));
  }

  void _update(
          {int? team,
          String? duty,
          String? status,
          bool clearTeam = false,
          bool clearDuty = false}) =>
      setState(() => filter = AnalyticsFilter(
          start: filter.start,
          end: filter.end,
          teamId: clearTeam ? null : team ?? filter.teamId,
          duty: clearDuty ? null : duty ?? filter.duty,
          status: status ?? filter.status));

  Future<void> _dates() async {
    final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: DateTimeRange(
            start: analyticsDate(filter.start), end: analyticsDate(filter.end)),
        helpText: 'Analiz aralığı · en fazla 366 gün');
    if (selected == null || !mounted) return;
    if (selected.duration.inDays > 365) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('En fazla 366 gün seçin.')));
      return;
    }
    setState(() => filter = AnalyticsFilter(
        start: DateFormat('yyyy-MM-dd').format(selected.start),
        end: DateFormat('yyyy-MM-dd').format(selected.end),
        teamId: filter.teamId,
        duty: filter.duty,
        status: filter.status));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamAnalyticsProvider(filter));
    return Scaffold(
        appBar: AppBar(title: const Text('Tim Görev Analizi'), actions: [
          IconButton(
              tooltip: 'Temayı değiştir',
              icon: const Icon(Icons.brightness_6_outlined),
              onPressed: () => ref.read(themeModeProvider.notifier).state =
                  Theme.of(context).brightness == Brightness.dark
                      ? ThemeMode.light
                      : ThemeMode.dark),
          IconButton(
              tooltip: 'Yenile',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(teamAnalyticsProvider(filter))),
        ]),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Analiz yüklenemedi.'),
            TextButton(
                onPressed: () => ref.invalidate(teamAnalyticsProvider(filter)),
                child: const Text('Tekrar dene')),
          ])),
          data: (data) => Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Mevcut kayıtlardan salt-okunur analiz',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _filters(data),
                      const SizedBox(height: 12),
                      Text(
                          'Durum: ${_statusLabel(filter.status)} · İzin/istirahat/rapor/sevk hariç'),
                      const SizedBox(height: 8),
                      const Text(
                          'Katılım: görev türü ve faaliyet başına bir kez. Gün: benzersiz takvim günü. '
                          'Personel–görev: faaliyet ve görev başına benzersiz kişi. Devam günleri yeni katılım oluşturmaz.'),
                      const SizedBox(height: 12),
                      AnalyticsMetricsView(metrics: data.metrics),
                      if (data.unknownTeamAssignments > 0 ||
                          data.duplicateAssignments > 0 ||
                          data.possibleDuplicateActivities > 0)
                        Card(
                            color:
                                Theme.of(context).colorScheme.tertiaryContainer,
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                    '${data.unknownTeamAssignments} timi bilinmeyen atama · '
                                    '${data.duplicateAssignments} tekrarlanan atama tekilleştirildi · '
                                    '${data.possibleDuplicateActivities} olası mükerrer faaliyet ayrı tutuldu.'))),
                      if (data.entries.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child:
                                Text('Seçilen filtrelerde görev kaydı yok.')),
                      AnalyticsCharts(data: data),
                      const SizedBox(height: 20),
                      AnalyticsDetails(data: data),
                    ],
                  ))),
        ));
  }

  Widget _filters(TeamAnalytics data) =>
      Wrap(spacing: 12, runSpacing: 12, children: [
        OutlinedButton.icon(
            onPressed: _dates,
            icon: const Icon(Icons.date_range),
            label: Text('${filter.start} — ${filter.end}')),
        SizedBox(
            width: 230,
            child: DropdownButtonFormField<int>(
                key: ValueKey('team-${filter.teamId}'),
                initialValue: filter.teamId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Tim', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int>(
                      child: Text('Tüm yetkili timler')),
                  if (filter.teamId != null &&
                      !data.teams.containsKey(filter.teamId))
                    DropdownMenuItem(
                        value: filter.teamId,
                        child: const Text('Seçili tim kullanılamıyor')),
                  for (final team in data.teams.entries)
                    DropdownMenuItem(value: team.key, child: Text(team.value))
                ],
                onChanged: (id) => _update(team: id, clearTeam: id == null))),
        SizedBox(
            width: 230,
            child: DropdownButtonFormField<String>(
                key: ValueKey('duty-${filter.duty}'),
                initialValue: filter.duty,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Görev', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String>(child: Text('Tüm görevler')),
                  for (final duty in {
                    ...data.availableDuties,
                    if (filter.duty != null) filter.duty!
                  })
                    DropdownMenuItem(value: duty, child: Text(duty))
                ],
                onChanged: (duty) =>
                    _update(duty: duty, clearDuty: duty == null))),
        SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
                key: const ValueKey('analytics-status'),
                initialValue: filter.status,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Onay durumu', border: OutlineInputBorder()),
                items: [
                  for (final status in ['onaylandi', 'beklemede', 'reddedildi'])
                    DropdownMenuItem(
                        value: status, child: Text(_statusLabel(status)))
                ],
                onChanged: (status) => _update(status: status))),
      ]);
  String _statusLabel(String status) => switch (status) {
        'beklemede' => 'Bekleyen',
        'reddedildi' => 'Reddedilen',
        _ => 'Onaylı',
      };
}
