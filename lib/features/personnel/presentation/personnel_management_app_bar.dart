part of 'personnel_management_screen.dart';

extension _PersonnelManagementAppBar on _PersonnelManagementScreenState {
  PreferredSizeWidget _buildPersonnelAppBar({
    required BuildContext context,
    required bool isAdmin,
  }) {
    return AppBar(
      leading: const AppBackButton(),
      centerTitle: false,
      titleSpacing: 0,
      title: Text(
        context.l10n.personnelPageTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (isAdmin && !context.isMobile)
          IconButton(
            icon: const Icon(Icons.import_export_rounded),
            tooltip: context.l10n.personnelBackupRestoreTooltip,
            onPressed: () async {
              final db = ref.read(databaseProvider);
              final res = await showBackupRestoreSurface(
                context: context,
                database: db,
              );
              if (res == true) {
                ref
                  ..invalidate(allPersonnelProvider)
                  ..invalidate(allSquadsProvider);
              }
            },
          ),
        if (isAdmin && !context.isMobile)
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: context.l10n.personnelCommanderDelegationTooltip,
            onPressed: _showCommanderDelegationDialog,
          ),
        if (isAdmin && !context.isMobile)
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: context.l10n.personnelNewSquadTooltip,
            onPressed: _showAddSquadDialog,
          ),
        if (isAdmin && context.isMobile)
          PopupMenuButton<String>(
            tooltip: context.l10n.personnelManagementActionsTooltip,
            icon: const Icon(Icons.more_vert_rounded),
            elevation: 5,
            shadowColor: context.shadowColor,
            surfaceTintColor: context.colorScheme.surface,
            shape: modernPopupShape(context),
            constraints: const BoxConstraints(minWidth: 290, maxWidth: 330),
            onSelected: (action) async {
              if (action == 'squad') {
                await _showAddSquadDialog();
              } else if (action == 'commander') {
                await _showCommanderDelegationDialog();
              } else if (action == 'backup') {
                final db = ref.read(databaseProvider);
                final res = await showBackupRestoreSurface(
                  context: context,
                  database: db,
                );
                if (res == true) {
                  ref
                    ..invalidate(allPersonnelProvider)
                    ..invalidate(allSquadsProvider);
                }
              }
            },
            itemBuilder: (context) => [
              ModernMenuHeader<String>(
                title: context.l10n.personnelManagementActionsTitle,
                subtitle: context.l10n.personnelManagementActionsSubtitle,
                icon: Icons.admin_panel_settings_outlined,
              ),
              const PopupMenuDivider(),
              ModernPopupMenuItem(
                option: ModernActionOption(
                  value: 'squad',
                  title: context.l10n.personnelCreateSquadOptionTitle,
                  subtitle: context.l10n.personnelCreateSquadOptionSubtitle,
                  icon: Icons.group_add_rounded,
                ),
              ),
              ModernPopupMenuItem(
                option: ModernActionOption(
                  value: 'commander',
                  title: context.l10n.personnelCommanderOptionTitle,
                  subtitle: context.l10n.personnelCommanderOptionSubtitle,
                  icon: Icons.manage_accounts_outlined,
                ),
              ),
              ModernPopupMenuItem(
                option: ModernActionOption(
                  value: 'backup',
                  title: context.l10n.personnelBackupOptionTitle,
                  subtitle: context.l10n.personnelBackupOptionSubtitle,
                  icon: Icons.import_export_rounded,
                ),
              ),
            ],
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}
