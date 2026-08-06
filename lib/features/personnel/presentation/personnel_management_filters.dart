part of 'personnel_management_screen.dart';

extension _PersonnelManagementFilters on _PersonnelManagementScreenState {
  List<Widget> _buildPersonnelFilters({
    required BuildContext context,
    required bool isAdmin,
    required UserSessionState? session,
    required AsyncValue<List<TimTableData>> squadsAsync,
  }) {
    return [
      // 1. Search Bar
      TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Personel ad, rütbe veya birlik ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _updatePersonnelView(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: context.colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (val) {
          _updatePersonnelView(() => _searchQuery = val.trim());
        },
      ),
      const SizedBox(height: 16),

      // 2. Tim Filter / Info Header
      if (isAdmin) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tim Filtresi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!context.isMobile)
              TextButton.icon(
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('Yeni Tim'),
                onPressed: _showAddSquadDialog,
              ),
          ],
        ),
        const SizedBox(height: 6),
        squadsAsync.when(
          data: (rawSquads) {
            final squads = MilitaryStructureHelper.sortSquads(
              rawSquads,
              (s) => s.timAdi,
            );
            final filterChips = [
              FilterChip(
                avatar: const Icon(Icons.groups, size: 16),
                label: const Text('Tüm Personel'),
                selected: _selectedFilterTimId == null,
                onSelected: (selected) {
                  _updatePersonnelView(() => _selectedFilterTimId = null);
                },
                selectedColor: context.accentOrOlive,
                labelStyle: TextStyle(
                  color: _selectedFilterTimId == null
                      ? Colors.white
                      : context.textPrimary,
                  fontWeight: _selectedFilterTimId == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              ...squads.map((sq) {
                final isSelected = _selectedFilterTimId == sq.id;
                return FilterChip(
                  avatar: Icon(
                    Icons.shield,
                    size: 16,
                    color: isSelected ? Colors.white : context.accentOrOlive,
                  ),
                  label: Text(sq.timAdi),
                  selected: isSelected,
                  onSelected: (selected) {
                    _updatePersonnelView(() {
                      _selectedFilterTimId = selected ? sq.id : null;
                    });
                  },
                  selectedColor: context.accentOrOlive,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : context.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }),
              FilterChip(
                avatar: Icon(
                  Icons.person_off,
                  size: 16,
                  color: _selectedFilterTimId == -1
                      ? Colors.white
                      : context.rejectedColor,
                ),
                label: const Text('Boşta / Kadro Dışı'),
                selected: _selectedFilterTimId == -1,
                onSelected: (selected) {
                  _updatePersonnelView(() {
                    _selectedFilterTimId = selected ? -1 : null;
                  });
                },
                selectedColor: context.rejectedBorderColor,
                labelStyle: TextStyle(
                  color: _selectedFilterTimId == -1
                      ? Colors.white
                      : context.textPrimary,
                  fontWeight: _selectedFilterTimId == -1
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: filterChips
                    .map(
                      (chip) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: chip,
                      ),
                    )
                    .toList(),
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, st) => Text('Hata: $err'),
        ),
      ] else ...[
        squadsAsync.when(
          data: (squads) {
            final squadMap = {for (final s in squads) s.id: s.timAdi};
            final timName = session?.timId != null
                ? squadMap[session?.timId] ?? 'Tüm Birlik'
                : 'Abonelik Yok';
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: context.squadBadgeBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.cardBorderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield,
                    color: context.squadBadgeText,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Yetkili Olduğunuz Tim: $timName',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.squadBadgeText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, st) => const SizedBox.shrink(),
        ),
      ],

      const SizedBox(height: 20),
    ];
  }
}
