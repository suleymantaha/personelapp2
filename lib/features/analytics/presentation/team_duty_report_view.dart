import 'package:flutter/material.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import '../domain/team_analytics.dart';

/// Read-only, team-first summary of the activity cards already entered.
/// No new task/team records or inferred "full-team duty" state are created.
class TeamDutyReportView extends StatelessWidget {
  const TeamDutyReportView({super.key, required this.data});

  final TeamAnalytics data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = data.metrics;
    final teamIds = data.orderedAvailableTeamIds;
    final activeIds = data.orderedTeamIds;
    // Historical teams may no longer exist in the authorized team map.
    final ids = [...teamIds, ...activeIds.where((id) => !teamIds.contains(id))];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.assessment_outlined,
                color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Tim Görev Raporu',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Mevcut faaliyet kartlarından oluşturuldu. Bir timden tek kişi '
          'katılmış olsa bile bu, tam tim görevi olarak sayılmaz.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 630 ? 2 : 4;
            final gap = 8.0;
            final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                _metric(context, width, 'Görev alan tim',
                    activeIds.length, Icons.groups_outlined),
                _metric(context, width, 'Tim katılımı',
                    metrics.participations, Icons.flag_outlined),
                _metric(context, width, 'Kişi-görev',
                    metrics.personnelTasks, Icons.assignment_ind_outlined),
                _metric(context, width, 'Görev günü',
                    metrics.dutyDays, Icons.calendar_today_outlined),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (ids.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Seçilen dönemde görüntülenecek tim yok.')),
          )
        else
          for (final id in ids)
            _TeamDutyCard(
              key: ValueKey('report-team-$id'),
              teamId: id,
              teamName: data.teams[id] ?? 'Tim #$id',
              data: data,
            ),
        if (data.unknownEntries.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Timi belirlenemeyen atamalar'),
              subtitle: Text('${data.unknownEntries.length} kayıt; '
                  'herhangi bir time otomatik eklenmedi.'),
            ),
          ),
      ],
    );
  }

  Widget _metric(BuildContext context, double width, String label,
      int value, IconData icon) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text('$value', style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label,
                  maxLines: 2,
                  style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamDutyCard extends StatefulWidget {
  const _TeamDutyCard({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.data,
  });

  final int teamId;
  final String teamName;
  final TeamAnalytics data;

  @override
  State<_TeamDutyCard> createState() => _TeamDutyCardState();
}

class _TeamDutyCardState extends State<_TeamDutyCard> {
  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slice = widget.data.forTeam(widget.teamId);
    final metrics = slice.metrics;
    final duties = slice.duties.toList()
      ..sort((a, b) {
        final result = MilitaryStructureHelper.getDutyCategoryOrder(a)
            .compareTo(MilitaryStructureHelper.getDutyCategoryOrder(b));
        return result != 0 ? result : a.compareTo(b);
      });
    final visible = showAll ? duties : duties.take(3).toList();
    final hasMore = duties.length > 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(Icons.shield_outlined, size: 21,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.teamName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (metrics.personnelTasks > 0)
                  Tooltip(
                    message: 'Tekil kişi-faaliyet-görev ataması',
                    child: Text('${metrics.personnelTasks} kişi-görev',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              duties.isEmpty
                  ? 'Bu dönemde görev kaydı yok'
                  : '${metrics.participations} tim katılımı · '
                    '${metrics.uniquePersonnel} farklı kişi · '
                    '${metrics.dutyDays} gün',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (duties.isNotEmpty) ...[
              const Divider(height: 20),
              for (final duty in visible)
                _duty(context, duty, slice.forDuty(duty)),
              if (hasMore)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: ValueKey('report-more-${widget.teamId}'),
                    onPressed: () => setState(() => showAll = !showAll),
                    icon: Icon(showAll
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded),
                    label: Text(showAll
                        ? 'Daha az göster'
                        : '${duties.length - 3} görev daha göster'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _duty(BuildContext context, String duty, TeamAnalytics slice) {
    final metrics = slice.metrics;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey('report-duty-${widget.teamId}-$duty'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showActivityDetails(context, duty, slice),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(duty, maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${metrics.participations} katılım · '
                        '${metrics.uniquePersonnel} kişi · '
                        '${metrics.dutyDays} gün',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActivityDetails(
      BuildContext context, String duty, TeamAnalytics slice) {
    final activities = <int, List<AnalyticsEntry>>{};
    for (final entry in slice.entries) {
      activities.putIfAbsent(entry.activityId, () => []).add(entry);
    }
    final groups = activities.values.toList()
      ..sort((a, b) {
        final date = b.first.sourceDate.compareTo(a.first.sourceDate);
        return date != 0
            ? date
            : b.first.activityId.compareTo(a.first.activityId);
      });

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text('${widget.teamName} · $duty',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 5),
              Text(
                '${slice.metrics.participations} katılım · '
                '${slice.metrics.personnelTasks} kişi-görev · '
                '${slice.metrics.dutyDays} gün',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              for (final group in groups) _activity(context, group),
              if (groups.isEmpty)
                const Text('Bu görev için kayıt bulunamadı.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activity(BuildContext context, List<AnalyticsEntry> group) {
    final first = group.first;
    final unique = <int, AnalyticsEntry>{
      for (final e in group) e.personnelId: e,
    };
    final people = unique.values.toList()
      ..sort((a, b) => a.personnelName.compareTo(b.personnelName));
    final dates = group.expand((e) => e.coveredDates).toSet().toList()
      ..sort();
    final rangeText = dates.isEmpty
        ? first.sourceDate
        : dates.length == 1
            ? dates.first
            : '${dates.first} – ${dates.last}';
    final startedInWindow = first.sourceDate.compareTo(widget.data.filter.start) >= 0 &&
        first.sourceDate.compareTo(widget.data.filter.end) <= 0;
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('report-activity-${widget.teamId}-${first.activityId}-${first.duty}'),
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(first.activityName,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$rangeText · ${people.length} kişi'
                '${startedInWindow ? '' : ' · Önceki günden devam'}',
                style: theme.textTheme.bodySmall),
            const Divider(height: 14),
            for (final person in people)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 16,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(person.personnelName,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
