part of 'personnel_management_screen.dart';

extension _PersonnelManagementActions on _PersonnelManagementScreenState {
  Future<void> _showAddPersonnelDialog() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.pagePadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.personnelAddModalTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    key: const Key('add-single-personnel-option'),
                    leading: const Icon(Icons.person_add_alt_1_rounded),
                    title: Text(context.l10n.personnelAddSingleOptionTitle),
                    subtitle: Text(context.l10n.personnelAddSingleOptionSubtitle),
                    onTap: () => Navigator.of(context).pop('single'),
                  ),
                  ListTile(
                    key: const Key('add-personnel-from-text-option'),
                    leading: const Icon(Icons.content_paste_go_rounded),
                    title: Text(context.l10n.personnelAddBulkOptionTitle),
                    subtitle: Text(context.l10n.personnelAddBulkOptionSubtitle),
                    onTap: () => Navigator.of(context).pop('bulk'),
                  ),
                ],
              ),
            ),
          ),
    );
    if (!mounted || action == null) return;

    if (action == 'single') {
      await showDialog<void>(
        context: context,
        builder: (context) => const PersonnelFormDialog(),
      );
      return;
    }

    final result = await showBulkPersonnelImportDialog(context);
    if (!mounted || result == null) return;
    AppNotifications.success(
      context.l10n.personnelBulkImportSuccess(
        result.addedCount,
        result.updatedCount,
        result.skippedCount,
      ),
    );
  }

  Future<void> _showEditPersonnelDialog(PersonelTableData p) async {
    await showDialog<void>(
      context: context,
      builder: (context) => PersonnelFormDialog(personnelToEdit: p),
    );
  }

  Future<void> _showMakeCommanderDialog(PersonelTableData p) async {
    final suggestedUser = p.adSoyad
        .toLowerCase()
        .replaceAll(' ', '.')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');

    final userCtrl = TextEditingController(text: suggestedUser);
    var selectedSquadId = p.timId;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final squadsAsync = ref.watch(allSquadsProvider);

              return AlertDialog(
                title: Text(
                  context.l10n.personnelMakeCommanderTitle(p.rutbe, p.adSoyad),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.personnelMakeCommanderDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: userCtrl,
                        decoration: InputDecoration(
                          labelText: context.l10n.personnelUsernameLabel,
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      squadsAsync.when(
                        data: (squads) {
                          return DropdownButtonFormField<int?>(
                            menuMaxHeight: modernDropdownMenuMaxHeight(context),
                            borderRadius: modernDropdownBorderRadius,
                            dropdownColor: modernDropdownColor(context),
                            initialValue: selectedSquadId,
                            decoration: InputDecoration(
                              labelText: context.l10n.personnelTargetSquadLabel,
                            ),
                            items:
                                squads.map((s) {
                                  return DropdownMenuItem<int?>(
                                    value: s.id,
                                    child: Text(s.timAdi),
                                  );
                                }).toList(),
                            onChanged: (val) {
                              setDialogState(() => selectedSquadId = val);
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (err, st) => Text(
                          context.l10n.commonErrorWithDetails(err.toString()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.personnelFirstLoginPasswordHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(context.l10n.commonCancel),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentOrOlive,
                      foregroundColor: context.onAccentOrOlive,
                    ),
                    onPressed: () async {
                      final u = userCtrl.text.trim();
                      if (u.isEmpty || selectedSquadId == null) {
                        AppNotifications.warning(
                          context.l10n.personnelUsernameAndSquadWarning,
                        );
                        return;
                      }

                      final repo = ref.read(personnelRepositoryProvider);
                      await repo.assignPersonnelAsCommander(
                        kullaniciAdi: u,
                        timId: selectedSquadId!,
                        personnelId: p.id,
                      );

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        AppNotifications.success(
                          context.l10n.personnelCommanderSuccess(p.adSoyad),
                        );
                      }
                    },
                    child: Text(context.l10n.personnelMakeCommanderAction),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      userCtrl.dispose();
    }
  }

  Future<void> _showCommanderDelegationDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.l10n.personnelCommanderDelegationTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final commandersAsync = ref.watch(allCommandersProvider);
                final squadsAsync = ref.watch(allSquadsProvider);

                return commandersAsync.when(
                  data: (commanders) {
                    if (commanders.isEmpty) {
                      return Text(
                        context.l10n.personnelNoCommandersFound,
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: commanders.length,
                      itemBuilder: (context, index) {
                        final cmd = commanders[index];
                        return squadsAsync.when(
                          data: (squads) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.personnelCommanderLabel(cmd.kullaniciAdi),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<int?>(
                                      menuMaxHeight:
                                          modernDropdownMenuMaxHeight(context),
                                      borderRadius: modernDropdownBorderRadius,
                                      dropdownColor: modernDropdownColor(
                                        context,
                                      ),
                                      initialValue: cmd.timId,
                                      decoration: InputDecoration(
                                        labelText: context.l10n.personnelAssignedSquadLabel,
                                        isDense: true,
                                      ),
                                      items: [
                                        DropdownMenuItem<int?>(
                                          child: Text(
                                            context.l10n.personnelUnassignedOrUnauthorized,
                                            style: TextStyle(
                                              color: context.rejectedColor,
                                            ),
                                          ),
                                        ),
                                        ...squads.map(
                                          (s) => DropdownMenuItem<int?>(
                                            value: s.id,
                                            child: Text(s.timAdi),
                                          ),
                                        ),
                                      ],
                                      onChanged: (newTimId) async {
                                        final repo = ref.read(
                                          personnelRepositoryProvider,
                                        );
                                        await repo.assignCommanderToSquad(
                                          userId: cmd.id,
                                          timId: newTimId,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (err, st) => Text(
                            context.l10n.commonErrorWithDetails(err.toString()),
                          ),
                        );
                      },
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Text(
                    context.l10n.commonErrorWithDetails(err.toString()),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(context.l10n.personnelAuthorizeNewCommander),
              onPressed: () async {
                final userCtrl = TextEditingController();
                await showDialog<void>(
                  context: ctx,
                  builder:
                      (dialogCtx) => AlertDialog(
                        title: Text(context.l10n.personnelNewCommanderDialogTitle),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: userCtrl,
                                decoration: InputDecoration(
                                  labelText: context.l10n.personnelUsernameExampleLabel,
                                  prefixIcon: const Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.personnelNoPasswordNeededHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: Text(context.l10n.commonCancel),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final u = userCtrl.text.trim();
                              if (u.isNotEmpty) {
                                final repo = ref.read(
                                  personnelRepositoryProvider,
                                );
                                await repo.createUserAccount(
                                  kullaniciAdi: u,
                                  rol: 'tim_komutani',
                                );
                                if (dialogCtx.mounted) {
                                  Navigator.of(dialogCtx).pop();
                                }
                              }
                            },
                            child: Text(context.l10n.personnelAuthorizeAction),
                          ),
                        ],
                      ),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.l10n.commonClose),
            ),
          ],
        );
      },
    );
  }
}
