part of 'personnel_management_screen.dart';

extension _PersonnelOrderActions on _PersonnelManagementScreenState {
  void _showOrderOptions() {
    if (ref.read(userSessionProvider)?.isAdmin != true) return;
    _updatePersonnelView(() {
      _searchVisible = false;
      _searchController.clear();
      _searchQuery = '';
      _ordering = true;
    });
  }

  Widget _buildOrderScaffold() => PersonnelInlineOrderEditor(
      onClose: () => _updatePersonnelView(() => _ordering = false),
      onSaved: () {
        ref.invalidate(allSquadsProvider);
        ref.invalidate(allPersonnelProvider);
        ref.invalidate(historicalPersonnelProvider);
        _updatePersonnelView(() => _ordering = false);
        AppNotifications.success('Sıralama kaydedildi.');
      });
}
