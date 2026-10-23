part of 'personnel_management_screen.dart';

extension _PersonnelMemberTile on _PersonnelManagementScreenState {
  Widget _buildMemberTile(
    PersonelTableData person,
    int index,
    bool isAdmin, [
    Color? teamColor,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}.',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  person.adSoyad,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  person.rutbe,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin) _buildMemberMenu(person),
        ],
      ),
    );
  }
}
