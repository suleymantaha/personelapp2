part of 'personnel_management_screen.dart';

extension _PersonnelManagementAppBar on _PersonnelManagementScreenState {
  PreferredSizeWidget _buildPersonnelAppBar({
    required BuildContext context,
    required bool isAdmin,
  }) {
    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      title: const Text(
        'Personel ve Timler',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (isAdmin && !context.isMobile)
          IconButton(
            icon: const Icon(Icons.import_export_rounded),
            tooltip: 'Yedekle ve geri yükle',
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
            tooltip: 'Komutan yetkileri',
            onPressed: _showCommanderDelegationDialog,
          ),
        if (isAdmin && !context.isMobile)
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Yeni tim',
            onPressed: _showAddSquadDialog,
          ),
        if (isAdmin && context.isMobile)
          PopupMenuButton<String>(
            tooltip: 'Yönetim işlemleri',
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
              const ModernMenuHeader<String>(
                title: 'Yönetim İşlemleri',
                subtitle: 'Personel ve uygulama yönetimi',
                icon: Icons.admin_panel_settings_outlined,
              ),
              const PopupMenuDivider(),
              ModernPopupMenuItem(
                option: const ModernActionOption(
                  value: 'squad',
                  title: 'Yeni tim',
                  subtitle: 'Yeni bir tim oluştur',
                  icon: Icons.group_add_rounded,
                ),
              ),
              ModernPopupMenuItem(
                option: const ModernActionOption(
                  value: 'commander',
                  title: 'Komutan yetkileri',
                  subtitle: 'Tim komutanlarını ve yetkileri yönet',
                  icon: Icons.manage_accounts_outlined,
                ),
              ),
              ModernPopupMenuItem(
                option: const ModernActionOption(
                  value: 'backup',
                  title: 'Yedekle ve geri yükle',
                  subtitle: 'Uygulama verilerini güvenli şekilde yönet',
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
