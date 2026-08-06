part of 'personnel_management_screen.dart';

extension _PersonnelManagementActions on _PersonnelManagementScreenState {
  Future<void> _showAddPersonnelDialog() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
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
                'Personel Ekle',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                key: const Key('add-single-personnel-option'),
                leading: const Icon(Icons.person_add_alt_1_rounded),
                title: const Text('Tek Personel Ekle'),
                subtitle: const Text('Bilgileri form üzerinden girin'),
                onTap: () => Navigator.of(context).pop('single'),
              ),
              ListTile(
                key: const Key('add-personnel-from-text-option'),
                leading: const Icon(Icons.content_paste_go_rounded),
                title: const Text('Metinden Toplu Ekle'),
                subtitle: const Text('Listeyi yapıştırıp önizleyin'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.addedCount} personel eklendi, '
          '${result.skippedCount} mükerrer kayıt atlandı.',
        ),
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
                title: Text('⭐ Tim Komutanı Yap: ${p.rutbe} ${p.adSoyad}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bu personeli bir Time Komutan olarak atayabilir ve giriş yetkisi verebilirsiniz.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: userCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı (Giriş için)',
                          prefixIcon: Icon(Icons.person),
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
                            decoration: const InputDecoration(
                              labelText: 'Komutanı Olacağı Tim',
                            ),
                            items: squads.map((s) {
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
                        error: (err, st) => Text('Hata: $err'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '💡 Personel ilk girişinde kendi parolasını belirleyecektir.',
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
                    child: const Text('İPTAL'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentOrOlive,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final u = userCtrl.text.trim();
                      if (u.isEmpty || selectedSquadId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lütfen kullanıcı adı ve tim seçiniz.',
                            ),
                          ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${p.adSoyad} Tim Komutanı olarak yetkilendirildi!',
                            ),
                            backgroundColor: context.approvedColor,
                          ),
                        );
                      }
                    },
                    child: const Text('KOMUTAN YAP VE YETKİLENDİR'),
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
          title: const Text('Tim Komutanı Yetki Devri / Atama'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final commandersAsync = ref.watch(allCommandersProvider);
                final squadsAsync = ref.watch(allSquadsProvider);

                return commandersAsync.when(
                  data: (commanders) {
                    if (commanders.isEmpty) {
                      return const Text(
                        'Kayıtlı Tim Komutanı hesabı bulunamadı.',
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
                                      'Komutan: ${cmd.kullaniciAdi}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<int?>(
                                      menuMaxHeight:
                                          modernDropdownMenuMaxHeight(context),
                                      borderRadius: modernDropdownBorderRadius,
                                      dropdownColor:
                                          modernDropdownColor(context),
                                      initialValue: cmd.timId,
                                      decoration: const InputDecoration(
                                        labelText: 'Atanan Tim',
                                        isDense: true,
                                      ),
                                      items: [
                                        DropdownMenuItem<int?>(
                                          child: Text(
                                            'BOŞTA / Yetkisiz',
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
                          error: (err, st) => Text('Hata: $err'),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Text('Hata: $err'),
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('YENİ KOMUTAN YETKİLENDİR'),
              onPressed: () async {
                final userCtrl = TextEditingController();
                await showDialog<void>(
                  context: ctx,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Yeni Komutan Yetkilendirme'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: userCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Kullanıcı Adı (Örn: ahmet.kaya)',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '💡 Şifre istenmez. Kullanıcı ilk girişinde kendi parolasını belirler.',
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
                        child: const Text('İPTAL'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final u = userCtrl.text.trim();
                          if (u.isNotEmpty) {
                            final repo = ref.read(personnelRepositoryProvider);
                            await repo.createUserAccount(
                              kullaniciAdi: u,
                              rol: 'tim_komutani',
                            );
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                          }
                        },
                        child: const Text('YETKİLENDİR'),
                      ),
                    ],
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('KAPAT'),
            ),
          ],
        );
      },
    );
  }
}
