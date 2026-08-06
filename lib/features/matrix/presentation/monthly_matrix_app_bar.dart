part of 'monthly_matrix_screen.dart';

extension _MonthlyMatrixAppBar on _MonthlyMatrixScreenState {
  Widget _buildMobileMatrixAppBar({
    required BuildContext context,
    required int totalPersonnelCount,
    required int visiblePersonnelCount,
    required VoidCallback? onExport,
  }) {
    final monthLabel = DateFormat('MMM yyyy', 'tr_TR').format(_selectedMonth);

    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: 64,
      titleSpacing: 8,
      title: _isMobileSearchOpen
          ? TextField(
              key: const ValueKey('matrix-personnel-search'),
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => _updateState(() => _searchQuery = value),
              textInputAction: TextInputAction.search,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              decoration: InputDecoration(
                hintText: 'Personel veya rütbe ara',
                hintStyle: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        onPressed: _clearSearch,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.14),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          : Row(
              children: [
                IconButton(
                  tooltip: 'Önceki ay',
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectMonthYear(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              monthLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sonraki ay',
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
      actions: [
        IconButton(
          key: const ValueKey('matrix-mobile-search-button'),
          tooltip: _isMobileSearchOpen ? 'Aramayı kapat' : 'Personel ara',
          onPressed: () {
            FocusScope.of(context).unfocus();
            _updateState(() => _isMobileSearchOpen = !_isMobileSearchOpen);
          },
          icon: Icon(
            _isMobileSearchOpen
                ? Icons.arrow_back_rounded
                : Icons.search_rounded,
          ),
        ),
        if (!_isMobileSearchOpen)
          IconButton(
            key: const ValueKey('matrix-export-button'),
            tooltip: "Excel'e aktar",
            onPressed: onExport,
            icon: const Icon(Icons.file_download_outlined),
          ),
        const SizedBox(width: 4),
      ],
      bottom: _searchQuery.trim().isEmpty
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Container(
                width: double.infinity,
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '“$_searchQuery” · $visiblePersonnelCount/$totalPersonnelCount kişi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _clearSearch,
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildMatrixAppBar({
    required BuildContext context,
    required int totalPersonnelCount,
    required int visiblePersonnelCount,
    required VoidCallback? onExport,
  }) {
    final isCompact = MediaQuery.sizeOf(context).width < 680;
    final bottomHeight = isCompact ? 126.0 : 78.0;

    return AppBar(
      centerTitle: false,
      toolbarHeight: 64,
      titleSpacing: 20,
      title: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aylık Matris',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            'Personel görev ve durum çizelgesi',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        IconButton.filledTonal(
          key: const ValueKey('matrix-export-button'),
          tooltip: "Excel'e aktar",
          onPressed: onExport,
          icon: const Icon(Icons.file_download_outlined),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white38,
          ),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomHeight),
        child: Container(
          height: bottomHeight,
          padding: EdgeInsets.fromLTRB(16, 8, 16, isCompact ? 10 : 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final monthPicker = _MonthPicker(
                label: DateFormat('MMMM yyyy', 'tr_TR').format(_selectedMonth),
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
                onSelect: () => _selectMonthYear(context),
              );
              final search = _PersonnelSearchField(
                controller: _searchController,
                query: _searchQuery,
                totalCount: totalPersonnelCount,
                visibleCount: visiblePersonnelCount,
                onChanged: (value) => _updateState(() => _searchQuery = value),
                onClear: _clearSearch,
              );

              if (constraints.maxWidth < 648) {
                return Column(
                  children: [
                    monthPicker,
                    const SizedBox(height: 8),
                    Expanded(child: search),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 286, child: monthPicker),
                  const SizedBox(width: 12),
                  Expanded(child: search),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<PersonelTableData> _personnelAvailableToSession(
    List<PersonelTableData> personnel,
    UserSessionState? session,
  ) {
    if (session == null || session.isAdmin) return personnel;
    if (session.timId == null) return <PersonelTableData>[];
    return personnel.where((person) => person.timId == session.timId).toList();
  }

  bool _matchesPersonnelSearch(PersonelTableData person) {
    final query = _normalizeSearchText(_searchQuery.trim());
    if (query.isEmpty) return true;
    final searchable = _normalizeSearchText(
      '${person.adSoyad} ${person.rutbe}',
    );
    return searchable.contains(query);
  }

  String _normalizeSearchText(String value) => value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u');

  void _changeMonth(int offset) {
    _updateState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _updateState(() => _searchQuery = '');
  }

  void _exportMatrix({
    required List<PersonelTableData> personnel,
    required Map<int, Map<int, MatrixDayCell>> matrixData,
  }) {
    unawaited(
      ExcelXmlGenerator.exportAndShareXml(
        personnel: personnel,
        matrixData: matrixData,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      ),
    );
  }

  Widget _buildEmptyPersonnelState(BuildContext context) {
    final hasQuery = _searchQuery.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery
                  ? Icons.person_search_outlined
                  : Icons.group_off_outlined,
              size: 46,
              color: context.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'Aramanızla eşleşen personel bulunamadı'
                  : 'Gösterilecek kayıtlı personel bulunmuyor.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hasQuery) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Aramayı temizle'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.accentSubtleBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Önceki ay',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              onTap: onSelect,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: context.accentOrOlive,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sonraki ay',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _PersonnelSearchField extends StatelessWidget {
  const _PersonnelSearchField({
    required this.controller,
    required this.query,
    required this.totalCount,
    required this.visibleCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final int totalCount;
  final int visibleCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        key: const ValueKey('matrix-personnel-search'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Personel adı veya rütbe ara',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  tooltip: 'Aramayı temizle',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '$visibleCount/$totalCount',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.cardBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.cardBorderColor),
          ),
        ),
      ),
    );
  }
}
