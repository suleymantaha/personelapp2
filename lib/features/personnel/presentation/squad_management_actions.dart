part of 'personnel_management_screen.dart';

extension _SquadManagementActions on _PersonnelManagementScreenState {
  Future<void> _showAddSquadDialog() async {
    final squadNameController = TextEditingController();
    final commanderUserController = TextEditingController();
    var showNameError = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            icon: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.accentSubtleBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.add_moderator_rounded,
                color: context.accentOrOlive,
              ),
            ),
            title: const Text(
              'Yeni Tim Oluştur',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tim bilgilerini girin. Komutan hesabını şimdi veya daha '
                    'sonra atayabilirsiniz.',
                    style: context.textStyleSecondary,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: const Key('new-squad-name-field'),
                    controller: squadNameController,
                    onChanged: (_) {
                      if (showNameError) {
                        setDialogState(() => showNameError = false);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Tim adı',
                      hintText: 'Örn. 1-B Timi',
                      prefixIcon: const Icon(Icons.shield_outlined),
                      errorText: showNameError ? 'Tim adı zorunludur' : null,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commanderUserController,
                    decoration: const InputDecoration(
                      labelText: 'Komutan kullanıcı adı',
                      hintText: 'İsteğe bağlı',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.accentSubtleBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: context.accentOrOlive,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Komutan ilk girişinde kendi parolasını belirler.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
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
              FilledButton.icon(
                key: const Key('create-squad-button'),
                icon: const Icon(Icons.check_rounded),
                onPressed: () async {
                  final name = squadNameController.text.trim();
                  final cUser = commanderUserController.text.trim();

                  if (name.isEmpty) {
                    setDialogState(() => showNameError = true);
                    return;
                  }

                  final repo = ref.read(personnelRepositoryProvider);
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

                  if (cUser.isNotEmpty) {
                    await repo.addSquadWithCommander(
                      timAdi: name,
                      olusturmaTarihi: today,
                      komutanKullaniciAdi: cUser,
                    );
                  } else {
                    await repo.addSquad(
                      timAdi: name,
                      olusturmaTarihi: today,
                    );
                  }

                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                label: const Text('Tim Oluştur'),
              ),
            ],
          ),
        ),
      );
    } finally {
      squadNameController.dispose();
      commanderUserController.dispose();
    }
  }
}
