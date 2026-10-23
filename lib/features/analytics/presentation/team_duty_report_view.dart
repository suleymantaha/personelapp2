import 'package:flutter/material.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import '../domain/team_analytics.dart';
import 'team_report_details.dart';
import 'team_report_records.dart';

class TeamDutyReportView extends StatelessWidget {
  const TeamDutyReportView({super.key, required this.data});
  final TeamAnalytics data;
  @override
  Widget build(BuildContext context) {
    final activeIds = data.orderedTeamIds;
    final inactiveIds = data.orderedAvailableTeamIds
        .where((id) =>
            !activeIds.contains(id) &&
            (data.filter.teamId == null || data.filter.teamId == id))
        .toList();
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          data.filter.start == data.filter.end
              ? 'Günlük Tim Görevleri'
              : 'Tim Görev Raporu',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(
          'Görev alan tim: ${activeIds.length} · '
          '${reportPeople(data.entries)} farklı kişi',
          style: theme.textTheme.bodyMedium),
      const SizedBox(height: 12),
      if (activeIds.isEmpty)
        const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Seçilen dönemde görevlendirme kaydı yok.')),
      for (final id in activeIds) _team(context, id),
      if (inactiveIds.isNotEmpty)
        Card(
            child: ExpansionTile(
          key: const ValueKey('report-inactive-teams'),
          title: Text('Kaydı olmayan timler (${inactiveIds.length})'),
          children: [
            for (final id in inactiveIds)
              ListTile(
                  title: Text(data.teams[id] ?? 'Tim #$id'),
                  trailing: const Text('0 kayıt'))
          ],
        )),
    ]);
  }

  Widget _team(BuildContext context, int id) {
    final slice = data.forTeam(id);
    final name = data.teams[id] ?? 'Tim #$id';
    final theme = Theme.of(context);
    final duties = slice.duties
      ..sort((a, b) {
        final order = MilitaryStructureHelper.getDutyCategoryOrder(a)
            .compareTo(MilitaryStructureHelper.getDutyCategoryOrder(b));
        return order != 0 ? order : a.compareTo(b);
      });
    return Card(
      key: ValueKey('report-team-$id'),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: ExpansionTile(
          key: ValueKey('report-team-toggle-$id'),
          leading:
              Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
          title: Text(name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          trailing: Builder(builder: (context) {
            final controller = ExpansibleController.of(context);
            return Row(mainAxisSize: MainAxisSize.min, children: [
              ListenableBuilder(
                  listenable: controller,
                  builder: (context, child) => AnimatedRotation(
                      turns: controller.isExpanded ? .5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: child),
                  child: const Icon(Icons.expand_more)),
              IconButton(
                  key: ValueKey('report-team-details-$id'),
                  tooltip: 'Tim detayları',
                  onPressed: () => showTeamReportDetails(context,
                      title: name, data: slice, teamId: id),
                  icon: Icon(Icons.list_alt_outlined,
                      color: theme.colorScheme.primary)),
            ]);
          }),
          subtitle: Text('${reportRecords(slice.entries).length} görev kaydı · '
              '${reportPeople(slice.entries)} farklı kişi'),
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Column(children: [
                  for (final duty in duties)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Material(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          key: ValueKey('report-duty-$id-$duty'),
                          dense: true,
                          title: Text(duty),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                                '${reportRecords(slice.forDuty(duty).entries).length} görev'),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded),
                          ]),
                          onTap: () => showTeamReportDetails(context,
                              title: '$name · $duty',
                              data: slice.forDuty(duty),
                              teamId: id),
                        ),
                      ),
                    ),
                ])),
          ]),
    );
  }
}
