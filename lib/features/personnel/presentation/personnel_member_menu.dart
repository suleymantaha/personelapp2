part of 'personnel_management_screen.dart';

extension _PersonnelMemberMenu on _PersonnelManagementScreenState {
  Widget _buildMemberMenu(PersonelTableData p) => PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: context.l10n.commonActions,
        elevation: 5,
        shadowColor: context.shadowColor,
        surfaceTintColor: context.colorScheme.surface,
        shape: modernPopupShape(context),
        constraints: const BoxConstraints(
          minWidth: 300,
          maxWidth: 340,
        ),
        onSelected: (action) async {
          if (action == 'edit') {
            await _showEditPersonnelDialog(
              p,
            );
          } else if (action == 'commander') {
            await _showMakeCommanderDialog(
              p,
            );
          } else if (action == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(
                  context.l10n.personnelDeactivateTitle,
                ),
                content: Text(
                  context.l10n.personnelDeactivateConfirm(
                    p.rutbe,
                    p.adSoyad,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(
                      ctx,
                    ).pop(false),
                    child: Text(
                      context.l10n.commonCancel,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.rejectedColor,
                    ),
                    onPressed: () => Navigator.of(
                      ctx,
                    ).pop(true),
                    child: Text(
                      context.l10n.personnelDeactivateAction,
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              final repo = ref.read(
                personnelRepositoryProvider,
              );
              await repo.deletePersonnel(
                p.id,
              );
            }
          }
        },
        itemBuilder: (context) => [
          ModernMenuHeader<String>(
            title: context.l10n.personnelActionsMenuTitle,
            subtitle: '${p.rutbe} ${p.adSoyad}',
            icon: Icons.person_outline,
          ),
          const PopupMenuDivider(),
          ModernPopupMenuItem(
            option: ModernActionOption(
              value: 'edit',
              title: context.l10n.personnelEditOptionTitle,
              subtitle: context.l10n.personnelEditOptionSubtitle,
              icon: Icons.edit_outlined,
            ),
          ),
          ModernPopupMenuItem(
            option: ModernActionOption(
              value: 'commander',
              title: context.l10n.personnelCommanderOptionTitle,
              subtitle: context.l10n.personnelCommanderOptionSubtitle,
              icon: Icons.star_outline,
            ),
          ),
          const PopupMenuDivider(),
          ModernPopupMenuItem(
            option: ModernActionOption(
              value: 'delete',
              title: context.l10n.personnelDeleteOptionTitle,
              subtitle: context.l10n.personnelDeleteOptionSubtitle,
              icon: Icons.delete_outline_rounded,
              isDestructive: true,
            ),
          ),
        ],
      );
}
