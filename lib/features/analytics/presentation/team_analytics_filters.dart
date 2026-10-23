import 'package:flutter/material.dart';
import '../domain/team_analytics.dart';

class TeamAnalyticsFilters extends StatelessWidget {
  const TeamAnalyticsFilters(
      {super.key,
      required this.data,
      required this.onChanged,
      required this.expanded,
      required this.onToggle});
  final TeamAnalytics data;
  final ValueChanged<AnalyticsFilter> onChanged;
  final bool expanded;
  final VoidCallback onToggle;
  AnalyticsFilter get filter => data.filter;
  void _update(
          {int? team,
          String? duty,
          String? status,
          bool clearTeam = false,
          bool clearDuty = false}) =>
      onChanged(AnalyticsFilter(
          start: filter.start,
          end: filter.end,
          teamId: clearTeam ? null : team ?? filter.teamId,
          duty: clearDuty ? null : duty ?? filter.duty,
          status: status ?? filter.status));
  @override
  Widget build(BuildContext context) => Column(children: [
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('analytics-filters-toggle'),
              onPressed: onToggle,
              icon: const Icon(Icons.tune_rounded),
              label: Text(expanded
                  ? 'Filtreleri gizle'
                  : 'Tim, görev ve onay filtreleri'),
            )),
        if (!expanded &&
            (filter.teamId != null ||
                filter.duty != null ||
                filter.status != 'onaylandi'))
          Text(
              'Aktif filtre: ${filter.teamId == null ? "Tüm timler" : data.teams[filter.teamId] ?? "Seçili tim"} · '
              '${filter.duty ?? "Tüm görevler"} · ${_statusLabel(filter.status)}'),
        if (expanded)
          LayoutBuilder(
              builder: (context, constraints) =>
                  _buildDropdowns(context, data, constraints.maxWidth)),
      ]);
  Widget _buildDropdowns(
      BuildContext context, TeamAnalytics data, double maxWidth) {
    final isNarrow = maxWidth < 720;
    final fieldWidth = isNarrow ? maxWidth : (maxWidth - 24) / 3;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: fieldWidth,
          child: DropdownButtonFormField<int>(
            key: ValueKey('team-${filter.teamId}'),
            initialValue: filter.teamId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tim',
              prefixIcon: Icon(Icons.shield_outlined, size: 18),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<int>(
                child: Text('Tüm yetkili timler'),
              ),
              if (filter.teamId != null &&
                  !data.teams.containsKey(filter.teamId))
                DropdownMenuItem(
                  value: filter.teamId,
                  child: const Text('Seçili tim kullanılamıyor'),
                ),
              for (final teamId in data.orderedAvailableTeamIds)
                DropdownMenuItem(
                  value: teamId,
                  child: Text(data.teams[teamId] ?? 'Tim #$teamId'),
                )
            ],
            onChanged: (id) => _update(team: id, clearTeam: id == null),
          ),
        ),
        SizedBox(
          width: fieldWidth,
          child: DropdownButtonFormField<String>(
            key: ValueKey('duty-${filter.duty}'),
            initialValue: filter.duty,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Görev',
              prefixIcon: Icon(Icons.military_tech_outlined, size: 18),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<String>(
                child: Text('Tüm görevler'),
              ),
              for (final duty in {
                ...data.availableDuties,
                if (filter.duty != null) filter.duty!
              })
                DropdownMenuItem(value: duty, child: Text(duty))
            ],
            onChanged: (duty) => _update(duty: duty, clearDuty: duty == null),
          ),
        ),
        SizedBox(
          width: fieldWidth,
          child: DropdownButtonFormField<String>(
            key: const ValueKey('analytics-status'),
            initialValue: filter.status,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Onay durumu',
              prefixIcon: Icon(Icons.verified_outlined, size: 18),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              for (final status in ['onaylandi', 'beklemede', 'reddedildi'])
                DropdownMenuItem(
                  value: status,
                  child: Text(_statusLabel(status)),
                )
            ],
            onChanged: (status) => _update(status: status),
          ),
        ),
      ],
    );
  }

  String _statusLabel(String status) => switch (status) {
        'beklemede' => 'Bekleyen',
        'reddedildi' => 'Reddedilen',
        _ => 'Onaylı',
      };
}
