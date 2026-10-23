part of 'personnel_management_screen.dart';

extension _PersonnelMemberTile on _PersonnelManagementScreenState {
  Widget _buildMemberTile(
    PersonelTableData person,
    int index,
    bool isAdmin, [
    Color? teamColor,
  ]) {
    final theme = Theme.of(context);
    final accent = teamColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    person.rutbe,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Text(
                  person.adSoyad,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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
