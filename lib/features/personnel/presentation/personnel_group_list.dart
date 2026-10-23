part of 'personnel_management_screen.dart';

extension _PersonnelGroupList on _PersonnelManagementScreenState {
  Widget _buildTeamList(List<PersonelTableData> raw, List<TimTableData> squads,
      UserSessionState? session) {
    final allowed = raw
        .where((p) =>
            session?.isAdmin == true ||
            (session?.timId != null && p.timId == session!.timId))
        .toList();
    final searching = _searchQuery.isNotEmpty;
    String normalize(String value) =>
        value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    final matchedTeams = squads
        .where((t) => normalize(t.timAdi).contains(normalize(_searchQuery)))
        .map((t) => t.id)
        .toSet();
    final matchedPeople = searching
        ? PersonnelFuzzyMatcher.searchPersonnel(_searchQuery, allowed,
                threshold: 0.5, maxResults: allowed.length)
            .map((p) => p.id)
            .toSet()
        : <int>{};
    final people = searching
        ? allowed
            .where((p) =>
                matchedPeople.contains(p.id) || matchedTeams.contains(p.timId))
            .toList()
        : allowed;
    final grouped = <int?, List<PersonelTableData>>{};
    for (final person in people) {
      grouped.putIfAbsent(person.timId, () => []).add(person);
    }
    final visibleSquads = orderDisplaySquads(squads)
        .where((s) => session?.isAdmin == true || s.id == session?.timId)
        .toList();
    final names = {for (final squad in squads) squad.id: squad.timAdi};
    final ids = <int?>[
      ...visibleSquads.map((s) => s.id),
      ...(grouped.keys
          .whereType<int>()
          .where((id) => !names.containsKey(id))
          .toList()
        ..sort()),
      if (grouped.containsKey(null)) null,
    ]
        .where((id) =>
            !searching || grouped.containsKey(id) || matchedTeams.contains(id))
        .toList();
    if (ids.isEmpty) {
      return AppEmptyState(
          icon: Icons.person_search_rounded,
          title: context.l10n.commonSearch,
          description: context.l10n.personnelNoCriteriaMatches);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(context.l10n.personnelListCount(people.length),
              style: Theme.of(context).textTheme.titleMedium)),
      for (final id in ids)
        _buildTeamCard(
            id,
            id == null
                ? context.l10n.personnelUnassignedSquad
                : names[id] ?? context.l10n.personnelUnknownSquad,
            (grouped[id] ?? []).toList()..sort(comparePersonnelWithinTeam),
            session?.isAdmin == true,
            searching),
    ]);
  }

  Widget _buildTeamCard(int? id, String name, List<PersonelTableData> people,
      bool isAdmin, bool searching) {
    const colors = [
      Color(0xFF4E6D86),
      Color(0xFF657D57),
      Color(0xFF88734F),
      Color(0xFF78688E),
      Color(0xFF4C8080),
      Color(0xFF936A60)
    ];
    final color = colors[(id ?? 0).abs() % colors.length];
    final expanded = searching || _expandedTeamIds.contains(id);
    return Container(
        key: ValueKey('team-card-$id'),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Color.alphaBlend(
                color.withValues(alpha: 0.10), context.colorScheme.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.6))),
        clipBehavior: Clip.antiAlias,
        child: Material(
            type: MaterialType.transparency,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                      button: true,
                      expanded: expanded,
                      child: InkWell(
                          key: ValueKey('team-header-$id'),
                          onTap: searching
                              ? null
                              : () => _updatePersonnelView(() {
                                    if (!_expandedTeamIds.add(id)) {
                                      _expandedTeamIds.remove(id);
                                    }
                                  }),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              child: Row(children: [
                                Icon(Icons.shield_outlined,
                                    size: 22, color: color),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text('${people.length} personel',
                                          style: TextStyle(
                                              color: context.textSecondary,
                                              fontSize: 12))
                                    ])),
                                Icon(
                                    expanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 22),
                              ])))),
                  if (expanded) ...[
                    if (people.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Bu timde personel yok.')),
                    for (var index = 0; index < people.length; index++) ...[
                      Divider(height: 1, color: color.withValues(alpha: 0.15)),
                      _buildMemberTile(people[index], index, isAdmin),
                    ],
                  ],
                ])));
  }
}
