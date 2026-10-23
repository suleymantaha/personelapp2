part of 'personnel_management_screen.dart';

extension _PersonnelManagementFilters on _PersonnelManagementScreenState {
  List<Widget> _buildPersonnelFilters({
    required BuildContext context,
    required bool isAdmin,
    required UserSessionState? session,
    required AsyncValue<List<TimTableData>> squadsAsync,
  }) =>
      [
        if (_searchVisible) ...[
          TextField(
              key: const ValueKey('personnel-search-field'),
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                  hintText: 'Personel, rütbe veya tim ara',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Aramayı temizle',
                          onPressed: () {
                            _searchController.clear();
                            _updatePersonnelView(() => _searchQuery = '');
                          }),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: context.colorScheme.surfaceContainerHighest),
              onChanged: (value) =>
                  _updatePersonnelView(() => _searchQuery = value.trim())),
          const SizedBox(height: 16),
        ],
        if (!isAdmin && session != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(session.timId == null
                  ? context.l10n.personnelNoSubscription
                  : context.l10n.personnelAuthorizedSquad(squadsAsync.value
                          ?.where((s) => s.id == session.timId)
                          .firstOrNull
                          ?.timAdi ??
                      context.l10n.personnelAllUnit))),
      ];
}
