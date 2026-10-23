import 'package:flutter/material.dart';
import '../domain/team_analytics.dart';
import 'team_report_records.dart';

void showTeamReportDetails(
  BuildContext context, {
  required String title,
  required TeamAnalytics data,
  int? teamId,
  String? explanation,
}) {
  final groups = reportRecords(data.entries);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      minChildSize: .35,
      maxChildSize: .95,
      builder: (context, controller) => CustomScrollView(
        controller: controller,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            sliver: SliverToBoxAdapter(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${groups.length} görev kaydı · '
                    '${reportPeople(data.entries)} farklı kişi'),
                if (explanation != null) ...[
                  const SizedBox(height: 12),
                  Text(explanation),
                ],
              ],
            )),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) => _ActivityCard(
                group: groups[index],
                teamId: teamId,
                start: data.filter.start,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard(
      {required this.group, required this.teamId, required this.start});
  final List<AnalyticsEntry> group;
  final int? teamId;
  final String start;

  @override
  Widget build(BuildContext context) {
    final first = group.first;
    final people = {for (final entry in group) entry.personnelId: entry}
        .values
        .toList()
      ..sort((a, b) => a.personnelName.compareTo(b.personnelName));
    final theme = Theme.of(context);
    return Card(
      key:
          ValueKey('report-activity-$teamId-${first.activityId}-${first.duty}'),
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(first.duty,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (first.activityName != first.duty) ...[
            const SizedBox(height: 4),
            Text(first.activityName),
          ],
          const SizedBox(height: 8),
          Text('${first.sourceDate} · ${people.length} kişi',
              style: theme.textTheme.bodyMedium),
          if (first.sourceDate.compareTo(start) < 0) ...[
            const SizedBox(height: 8),
            Text('Önceki günden devam',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
          ],
          const Divider(height: 24),
          for (final person in people)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(Icons.person_outline_rounded,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(person.personnelName)),
                ])),
        ]),
      ),
    );
  }
}
