import 'package:flutter/material.dart';
import '../domain/team_analytics.dart';

class AnalyticsDetails extends StatelessWidget {
  const AnalyticsDetails({super.key, required this.data});
  final TeamAnalytics data;
  @override
  Widget build(BuildContext context) {
    final ids = data.entries.map((e) => e.teamId!).toSet().toList()
      ..sort((a, b) => (data.teams[a] ?? '').compareTo(data.teams[b] ?? ''));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Tim → görev → tarih → faaliyet → personel',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final id in ids)
        Card(
            child: ExpansionTile(
          key: ValueKey('analytics-team-$id'),
          title: Text(data.teams[id] ?? 'Tim #$id'),
          subtitle: Text(_summary(data.forTeam(id).metrics)),
          children: [
            for (final duty in data.forTeam(id).duties) _duty(id, duty)
          ],
        )),
      if (data.unknownEntries.isNotEmpty)
        Card(
            child: ExpansionTile(
          title: const Text('Timi bilinmeyen geçmiş atamalar'),
          subtitle: const Text('Tim toplamlarına dahil edilmedi.'),
          children: [
            for (final entry in data.unknownEntries)
              ListTile(
                title: Text('${entry.sourceDate} · ${entry.duty}'),
                subtitle: Text(
                    '${entry.activityName} (#${entry.activityId}) · ${entry.personnelName}\n${entry.teamName}'),
              )
          ],
        )),
    ]);
  }

  String _summary(AnalyticsMetrics m) =>
      '${m.participations} katılım · ${m.dutyDays} gün · ${m.uniquePersonnel} kişi · ${m.personnelTasks} personel–görev';
  Widget _duty(int team, String duty) {
    final slice = data.forTeam(team).forDuty(duty);
    final dates = slice.entries.expand((e) => e.coveredDates).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return ExpansionTile(
      key: ValueKey('analytics-duty-$team-$duty'),
      title: Text(duty),
      subtitle: Text(_summary(slice.metrics)),
      children: [
        for (final date in dates) _date(team, duty, date, slice.entries)
      ],
    );
  }

  Widget _date(
      int team, String duty, String date, List<AnalyticsEntry> entries) {
    final day = entries.where((e) => e.coveredDates.contains(date)).toList();
    final activities = day.map((e) => e.activityId).toSet();
    return ExpansionTile(
      key: ValueKey('analytics-date-$team-$duty-$date'),
      title: Text(date),
      subtitle: Text('${activities.length} faaliyet'),
      children: [
        for (final id in activities) _activity(team, duty, date, id, day)
      ],
    );
  }

  Widget _activity(
      int team, String duty, String date, int id, List<AnalyticsEntry> day) {
    final entries = day.where((e) => e.activityId == id).toList();
    final source = entries.first;
    return ExpansionTile(
      key: ValueKey('analytics-activity-$team-$duty-$date-$id'),
      title: Text('${source.activityName} (#$id)'),
      subtitle: Text('${entries.length} kişi · ${source.status}'
          '${source.sourceDate == date ? '' : ' · Devam, başlangıç: ${source.sourceDate}'}'),
      children: [
        for (final entry in entries)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(entry.personnelName),
            subtitle: Text('Personel #${entry.personnelId} · ${entry.duty}'),
          )
      ],
    );
  }
}
