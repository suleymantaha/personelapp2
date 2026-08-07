import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_form_controls.dart';

class ActivityPersonnelSelectionStep extends StatelessWidget {
  const ActivityPersonnelSelectionStep({
    required this.personnel,
    required this.squads,
    required this.isAdmin,
    required this.selectedPersonnelIds,
    required this.searchController,
    required this.filter,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onFilterChanged,
    required this.onTogglePersonnel,
    required this.onToggleSquad,
    super.key,
  });

  final List<PersonelTableData> personnel;
  final List<TimTableData> squads;
  final bool isAdmin;
  final Set<int> selectedPersonnelIds;
  final TextEditingController searchController;
  final PersonnelFilter filter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<PersonnelFilter> onFilterChanged;
  final ValueChanged<int> onTogglePersonnel;
  final ValueChanged<List<int>> onToggleSquad;

  bool _matchesFilter(PersonelTableData person) => switch (filter) {
        PersonnelFilter.all => true,
        PersonnelFilter.selected => selectedPersonnelIds.contains(person.id),
        PersonnelFilter.unassigned => !selectedPersonnelIds.contains(person.id),
        PersonnelFilter.unsquadded => person.timId == null,
      };

  bool _matchesQuery(PersonelTableData person, String squadName, String query) {
    if (query.isEmpty) return true;
    return person.adSoyad.toLowerCase().contains(query) ||
        person.birlik.toLowerCase().contains(query) ||
        squadName.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final squadNames = {for (final squad in squads) squad.id: squad.timAdi};

    if (!isAdmin) {
      final visible = personnel
          .where(_matchesFilter)
          .where((person) => _matchesQuery(person, person.birlik, query))
          .toList()
        ..sort(
            (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)));
      return _SelectionScrollView(
        controls: _buildControls(),
        children: visible
            .map(
              (person) => _PersonnelSelectionRow(
                person: person,
                selected: selectedPersonnelIds.contains(person.id),
                onToggle: () => onTogglePersonnel(person.id),
              ),
            )
            .toList(),
      );
    }

    final grouped = <int?, List<PersonelTableData>>{};
    for (final person in personnel) {
      grouped.putIfAbsent(person.timId, () => []).add(person);
    }
    final timIds = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final nameA = squadNames[a] ?? '';
        final nameB = squadNames[b] ?? '';
        final weightA = MilitaryStructureHelper.getSquadOrderWeight(nameA);
        final weightB = MilitaryStructureHelper.getSquadOrderWeight(nameB);
        return weightA != weightB
            ? weightA.compareTo(weightB)
            : nameA.compareTo(nameB);
      });

    final tiles = <Widget>[];
    for (final timId in timIds) {
      final squadName = timId == null
          ? 'Timsiz / Diğer Personeller'
          : (squadNames[timId] ?? 'Bilinmeyen Tim');
      final allMembers = grouped[timId]!
        ..sort(
            (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)));
      final visibleMembers = allMembers
          .where(_matchesFilter)
          .where((person) => _matchesQuery(person, squadName, query))
          .toList();
      if (visibleMembers.isEmpty) continue;
      tiles.add(
        _SquadSelectionTile(
          key: ValueKey('selection-squad-$squadName-${query.isNotEmpty}'),
          squadName: squadName,
          allMembers: allMembers,
          visibleMembers: visibleMembers,
          selectedPersonnelIds: selectedPersonnelIds,
          forceExpanded: query.isNotEmpty,
          onToggleSquad: () =>
              onToggleSquad(allMembers.map((person) => person.id).toList()),
          onTogglePersonnel: onTogglePersonnel,
        ),
      );
    }

    return _SelectionScrollView(
      controls: _buildControls(),
      children: tiles,
    );
  }

  Widget _buildControls() {
    return ActivityFormControls(
      selectedCount: selectedPersonnelIds.length,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      onSearchCleared: onSearchCleared,
      currentFilter: filter,
      onFilterChanged: onFilterChanged,
      showUnsquaddedFilter: isAdmin,
    );
  }
}

class _SelectionScrollView extends StatelessWidget {
  const _SelectionScrollView({required this.controls, required this.children});

  final Widget controls;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const Key('personnel-selection-step'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(child: controls),
        ),
        if (children.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Aramaya uygun personel bulunamadı.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            sliver: SliverList.builder(
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
            ),
          ),
      ],
    );
  }
}

class _SquadSelectionTile extends StatelessWidget {
  const _SquadSelectionTile({
    required this.squadName,
    required this.allMembers,
    required this.visibleMembers,
    required this.selectedPersonnelIds,
    required this.forceExpanded,
    required this.onToggleSquad,
    required this.onTogglePersonnel,
    super.key,
  });

  final String squadName;
  final List<PersonelTableData> allMembers;
  final List<PersonelTableData> visibleMembers;
  final Set<int> selectedPersonnelIds;
  final bool forceExpanded;
  final VoidCallback onToggleSquad;
  final ValueChanged<int> onTogglePersonnel;

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        allMembers.where((p) => selectedPersonnelIds.contains(p.id)).length;
    final allSelected = selectedCount == allMembers.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: forceExpanded,
        leading: Checkbox(
          key: ValueKey('squad-select-$squadName'),
          value: selectedCount == 0 ? false : (allSelected ? true : null),
          tristate: selectedCount > 0 && !allSelected,
          onChanged: (_) => onToggleSquad(),
        ),
        title: Text(
          squadName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle:
            selectedCount == 0 ? null : Text('$selectedCount personel seçildi'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.accentSubtleBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${allMembers.length} personel',
                style: TextStyle(
                  color: context.accentOrOlive,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
        children: [
          for (final person in visibleMembers)
            _PersonnelSelectionRow(
              person: person,
              selected: selectedPersonnelIds.contains(person.id),
              onToggle: () => onTogglePersonnel(person.id),
            ),
        ],
      ),
    );
  }
}

class _PersonnelSelectionRow extends StatelessWidget {
  const _PersonnelSelectionRow({
    required this.person,
    required this.selected,
    required this.onToggle,
  });

  final PersonelTableData person;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.accentSubtleBg : Colors.transparent,
      child: InkWell(
        key: ValueKey('personnel-select-${person.id}'),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
          child: Row(
            children: [
              Checkbox(value: selected, onChanged: (_) => onToggle()),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${person.rutbe} ${person.adSoyad}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      person.birlik,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyleSecondary.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
