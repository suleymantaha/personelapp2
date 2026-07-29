import 'package:flutter/material.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

Future<PersonelTableData?> showPersonnelPicker({
  required BuildContext context,
  required List<PersonelTableData> personnel,
  required List<TimTableData> squads,
  int? selectedPersonnelId,
  int? preferredTimId,
  Map<int, String> disabledReasons = const {},
}) {
  return showModalBottomSheet<PersonelTableData>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PersonnelPickerSheet(
      personnel: personnel,
      squads: squads,
      selectedPersonnelId: selectedPersonnelId,
      preferredTimId: preferredTimId,
      disabledReasons: disabledReasons,
    ),
  );
}

class PersonnelPickerSheet extends StatefulWidget {
  const PersonnelPickerSheet({
    required this.personnel,
    required this.squads,
    this.selectedPersonnelId,
    this.preferredTimId,
    this.disabledReasons = const {},
    super.key,
  });

  final List<PersonelTableData> personnel;
  final List<TimTableData> squads;
  final int? selectedPersonnelId;
  final int? preferredTimId;
  final Map<int, String> disabledReasons;

  @override
  State<PersonnelPickerSheet> createState() => _PersonnelPickerSheetState();
}

class _PersonnelPickerSheetState extends State<PersonnelPickerSheet> {
  static int? _lastSelectedTimId;
  static final List<int> _recentPersonnelIds = <int>[];

  final _searchController = TextEditingController();
  final Set<int?> _expandedTimIds = <int?>{};
  String _query = '';

  @override
  void initState() {
    super.initState();
    final initialTimId = widget.preferredTimId ?? _lastSelectedTimId;
    if (initialTimId != null &&
        widget.personnel.any((person) => person.timId == initialTimId)) {
      _expandedTimIds.add(initialTimId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  void _select(PersonelTableData person) {
    if (widget.disabledReasons.containsKey(person.id)) return;
    _lastSelectedTimId = person.timId;
    _recentPersonnelIds
      ..remove(person.id)
      ..insert(0, person.id);
    if (_recentPersonnelIds.length > 5) {
      _recentPersonnelIds.removeRange(5, _recentPersonnelIds.length);
    }
    Navigator.of(context).pop(person);
  }

  @override
  Widget build(BuildContext context) {
    final squadNames = {
      for (final squad in widget.squads) squad.id: squad.timAdi,
    };
    final normalizedQuery = _normalize(_query);
    final filtered = widget.personnel.where((person) {
      if (normalizedQuery.isEmpty) return true;
      final teamName = squadNames[person.timId] ?? 'Tim Dışı';
      return _normalize(
        '${person.rutbe} ${person.adSoyad} ${person.birlik} $teamName',
      ).contains(normalizedQuery);
    }).toList();
    final suggested = filtered
        .where((person) => person.id == widget.selectedPersonnelId)
        .firstOrNull;

    final grouped = <int?, List<PersonelTableData>>{};
    if (normalizedQuery.isEmpty) {
      for (final squad in widget.squads) {
        grouped[squad.id] = <PersonelTableData>[];
      }
    }
    for (final person in filtered) {
      grouped.putIfAbsent(person.timId, () => []).add(person);
    }
    for (final group in grouped.values) {
      group.sort((a, b) {
        final rankComparison =
            getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe));
        if (rankComparison != 0) return rankComparison;
        return a.adSoyad.compareTo(b.adSoyad);
      });
    }

    final groupIds = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final nameA = squadNames[a] ?? '';
        final nameB = squadNames[b] ?? '';
        final weightA = MilitaryStructureHelper.getSquadOrderWeight(nameA);
        final weightB = MilitaryStructureHelper.getSquadOrderWeight(nameB);
        if (weightA != weightB) return weightA.compareTo(weightB);
        return nameA.compareTo(nameB);
      });

    final recent = _recentPersonnelIds
        .map(
          (id) =>
              widget.personnel.where((person) => person.id == id).firstOrNull,
        )
        .whereType<PersonelTableData>()
        .where(filtered.contains)
        .where((person) => person.id != suggested?.id)
        .toList();

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(
              children: [
                Icon(Icons.groups_rounded, color: context.accentOrOlive),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Personel Seç',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('personnel-search-field'),
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'İsim, soyisim veya rütbe ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty && normalizedQuery.isNotEmpty
                ? const _EmptySearchResult()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    children: [
                      if (suggested != null) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 10, 8, 6),
                          child: Text(
                            'Önerilen Eşleşme',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          margin: EdgeInsets.zero,
                          child: _PersonnelTile(
                            person: suggested,
                            teamName: squadNames[suggested.timId] ?? 'Tim Dışı',
                            selected: true,
                            disabledReason:
                                widget.disabledReasons[suggested.id],
                            onTap: () => _select(suggested),
                          ),
                        ),
                        const Divider(height: 20),
                      ],
                      if (recent.isNotEmpty && normalizedQuery.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 10, 8, 6),
                          child: Text(
                            'Son Seçilenler',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...recent.map(
                          (person) => _PersonnelTile(
                            person: person,
                            teamName: squadNames[person.timId] ?? 'Tim Dışı',
                            selected: person.id == widget.selectedPersonnelId,
                            disabledReason: widget.disabledReasons[person.id],
                            onTap: () => _select(person),
                          ),
                        ),
                        const Divider(height: 20),
                      ],
                      ...groupIds.map((timId) {
                        final members = grouped[timId]!;
                        final visibleMembers = members
                            .where((person) => person.id != suggested?.id)
                            .toList();
                        final teamName = timId == null
                            ? 'Tim Dışı'
                            : (squadNames[timId] ?? 'Bilinmeyen Tim');
                        final expanded = normalizedQuery.isNotEmpty ||
                            _expandedTimIds.contains(timId);
                        final selectedCount = members
                            .where(
                              (person) =>
                                  person.id == widget.selectedPersonnelId,
                            )
                            .length;

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              ListTile(
                                key: Key('personnel-team-$timId'),
                                onTap: normalizedQuery.isNotEmpty
                                    ? null
                                    : () => setState(() {
                                          if (expanded) {
                                            _expandedTimIds.remove(timId);
                                          } else {
                                            _expandedTimIds.add(timId);
                                          }
                                        }),
                                leading: Icon(
                                  Icons.shield_outlined,
                                  color: context.accentOrOlive,
                                ),
                                title: Text(
                                  '$teamName — ${members.length} kişi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: selectedCount == 0
                                    ? null
                                    : Text('$selectedCount kişi seçili'),
                                trailing: Icon(
                                  expanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                              ),
                              if (expanded)
                                if (members.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Eklenebilecek personel kalmadı.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  ...visibleMembers.map(
                                    (person) => _PersonnelTile(
                                      person: person,
                                      teamName: teamName,
                                      selected: person.id ==
                                          widget.selectedPersonnelId,
                                      disabledReason:
                                          widget.disabledReasons[person.id],
                                      onTap: () => _select(person),
                                    ),
                                  ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PersonnelTile extends StatelessWidget {
  const _PersonnelTile({
    required this.person,
    required this.teamName,
    required this.selected,
    this.disabledReason,
    required this.onTap,
  });

  final PersonelTableData person;
  final String teamName;
  final bool selected;
  final String? disabledReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('personnel-option-${person.id}'),
      selected: selected,
      selectedTileColor: context.accentOrOlive.withValues(alpha: 0.1),
      enabled: disabledReason == null,
      leading: CircleAvatar(
        backgroundColor: context.accentOrOlive.withValues(alpha: 0.12),
        child: Icon(Icons.person_outline, color: context.accentOrOlive),
      ),
      title: Text(
        '${person.rutbe} ${person.adSoyad}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        disabledReason == null
            ? '${person.rutbe} • $teamName'
            : '$teamName • Kayıtlı: $disabledReason',
      ),
      trailing: disabledReason != null
          ? const Icon(Icons.block, color: Colors.redAccent)
          : selected
              ? Icon(Icons.check_circle, color: context.accentOrOlive)
              : null,
      onTap: disabledReason == null ? onTap : null,
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Aramanızla eşleşen personel bulunamadı.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Yeni bir kayıt gerekiyorsa Personel Yönetimi ekranını kullanın.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
