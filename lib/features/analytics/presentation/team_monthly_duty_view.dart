import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/team_analytics.dart';

/// Compares *team participation* and *personnel workload* without presenting
/// a single person's assignment as an assignment of the entire team.
class TeamMonthlyDutyView extends StatelessWidget {
  const TeamMonthlyDutyView({super.key, required this.data});

  final TeamAnalytics data;

  @override
  Widget build(BuildContext context) {
    final teamIds = data.entries.map((e) => e.teamId).whereType<int>().toSet()
        .toList()
      ..sort((a, b) =>
          (data.teams[a] ?? '').compareTo(data.teams[b] ?? ''));

    if (teamIds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Seçilen filtrelerde aylık tim görev kaydı bulunamadı.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Timler Arası Görev Denge Analizi',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Katılım, timden en az bir kişinin yer aldığı faaliyet demektir. '
          'Tam tim görevi anlamına gelmez. Kişi-görev sayısı gerçek '
          'görevlendirme yükünü gösterir.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final teamId in teamIds) _teamCard(context, teamId),
        const SizedBox(height: 14),
        Text('Aylık Tim Görev Dağılım Tablosu',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final month in data.monthly.reversed)
          _monthCard(context, month, teamIds,
              month.month == data.monthly.last.month),
      ],
    );
  }

  Widget _teamCard(BuildContext context, int teamId) {
    final theme = Theme.of(context);
    final team = data.forTeam(teamId);
    final metrics = team.metrics;
    final name = data.teams[teamId] ?? 'Tim #$teamId';
    final dutyMetrics = {
      for (final duty in team.duties) duty: team.forDuty(duty).metrics,
    };
    final sortedDuties = dutyMetrics.keys.toList()
      ..sort((a, b) =>
          dutyMetrics[b]!.personnelTasks.compareTo(dutyMetrics[a]!.personnelTasks));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.groups_2_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),
            _stats(context, metrics),
            const Divider(height: 22),
            for (final duty in sortedDuties)
              _dutyRow(
                context,
                teamId: teamId,
                teamName: name,
                duty: duty,
                metrics: dutyMetrics[duty]!,
                entries: team.forDuty(duty).entries,
                maxPersonnelTasks: dutyMetrics.values.fold<int>(
                    0, (max, item) =>
                        item.personnelTasks > max ? item.personnelTasks : max),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stats(BuildContext context, AnalyticsMetrics metrics) {
    final theme = Theme.of(context);
    Widget stat(int count, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        );

    return Wrap(spacing: 16, runSpacing: 8, children: [
      stat(metrics.participations, 'görev katılımı'),
      stat(metrics.personnelTasks, 'kişi-görev'),
      stat(metrics.dutyDays, 'görev günü'),
      stat(metrics.uniquePersonnel, 'farklı kişi'),
    ]);
  }

  Widget _dutyRow(
    BuildContext context, {
    required int teamId,
    required String teamName,
    required String duty,
    required AnalyticsMetrics metrics,
    required List<AnalyticsEntry> entries,
    required int maxPersonnelTasks,
  }) {
    final theme = Theme.of(context);
    final ratio = maxPersonnelTasks == 0
        ? 0.0
        : metrics.personnelTasks / maxPersonnelTasks;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        key: ValueKey('team-duty-$teamId-$duty'),
        borderRadius: BorderRadius.circular(9),
        onTap: () => _showPersonnel(
          context,
          teamName: teamName,
          duty: duty,
          entries: entries,
          metrics: metrics,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(duty,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                Text('${metrics.participations} katılım',
                    style: theme.textTheme.labelMedium),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ]),
              const SizedBox(height: 3),
              Text(
                '${metrics.personnelTasks} kişi-görev · '
                '${metrics.uniquePersonnel} farklı kişi · '
                '${metrics.dutyDays} gün',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthCard(BuildContext context, AnalyticsMonth month,
      List<int> teamIds, bool latest) {
    final theme = Theme.of(context);
    final parts = month.month.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final startOfMonth = '${month.month}-01';
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    final endOfMonth =
        '${month.month}-${lastDay.toString().padLeft(2, '0')}';
    final start = startOfMonth.compareTo(data.filter.start) < 0
        ? data.filter.start
        : startOfMonth;
    final end = endOfMonth.compareTo(data.filter.end) > 0
        ? data.filter.end
        : endOfMonth;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: ValueKey('team-month-${month.month}'),
        initiallyExpanded: latest,
        title: Text(DateFormat('MMMM yyyy', 'tr_TR').format(date),
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${month.metrics.participations} katılım · '
          '${month.metrics.personnelTasks} kişi-görev · '
          '${month.metrics.dutyDays} gün',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          for (final id in teamIds)
            _monthTeamRow(context, id, start, end),
        ],
      ),
    );
  }

  Widget _monthTeamRow(
      BuildContext context, int teamId, String start, String end) {
    final teamEntries = data.entries
        .where((entry) =>
            entry.teamId == teamId &&
            entry.coveredDates.any(
                (date) => date.compareTo(start) >= 0 && date.compareTo(end) <= 0))
        .toList();
    if (teamEntries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final teamName = data.teams[teamId] ?? 'Tim #$teamId';
    final metrics = AnalyticsMetrics(teamEntries, start, end);
    final duties = teamEntries.map((entry) => entry.duty).toSet().toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(teamName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '${metrics.participations} katılım · '
                '${metrics.personnelTasks} kişi-görev · '
                '${metrics.dutyDays} gün',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 3),
          for (final duty in duties)
            Builder(builder: (context) {
              final entries =
                  teamEntries.where((entry) => entry.duty == duty).toList();
              final count = AnalyticsMetrics(entries, start, end);
              return ListTile(
                key: ValueKey('team-month-duty-$teamId-$duty-$start'),
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
                title: Text(duty, style: theme.textTheme.bodySmall),
                subtitle: Text(
                  '${count.participations} katılım · '
                  '${count.personnelTasks} kişi-görev · '
                  '${count.uniquePersonnel} kişi · '
                  '${count.dutyDays} gün',
                  style: theme.textTheme.labelSmall,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => _showPersonnel(
                  context,
                  teamName: teamName,
                  duty: duty,
                  entries: entries,
                  metrics: count,
                ),
              );
            }),
          const Divider(height: 1),
        ],
      ),
    );
  }

  void _showPersonnel(
    BuildContext context, {
    required String teamName,
    required String duty,
    required List<AnalyticsEntry> entries,
    required AnalyticsMetrics metrics,
  }) {
    final ordered = entries.toList()
      ..sort((a, b) {
        final date = b.sourceDate.compareTo(a.sourceDate);
        return date != 0 ? date : a.personnelName.compareTo(b.personnelName);
      });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text('Görevdeki Personel',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('$teamName · $duty'),
              const SizedBox(height: 4),
              Text(
                '${metrics.participations} faaliyet katılımı · '
                '${metrics.personnelTasks} kişi-görev · '
                '${metrics.uniquePersonnel} farklı kişi',
              ),
              const SizedBox(height: 8),
              for (final entry in ordered)
                ListTile(
                  dense: true,
                  title: Text(entry.personnelName),
                  subtitle: Text(
                    '${entry.sourceDate} · ${entry.activityName}',
                  ),
                ),
              if (ordered.isEmpty)
                const Text('Bu dönemde yeni görev katılımı yok.'),
            ],
          ),
        ),
      ),
    );
  }
}
