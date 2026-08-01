import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

class MakeCommanderDialog extends ConsumerStatefulWidget {
  const MakeCommanderDialog({
    super.key,
    required this.personnel,
  });

  final PersonelTableData personnel;

  @override
  ConsumerState<MakeCommanderDialog> createState() => _MakeCommanderDialogState();
}

class _MakeCommanderDialogState extends ConsumerState<MakeCommanderDialog> {
  late final TextEditingController _userCtrl;
  int? _selectedSquadId;

  @override
  void initState() {
    super.initState();
    final p = widget.personnel;
    final suggestedUser = p.adSoyad
        .toLowerCase()
        .replaceAll(' ', '.')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    _userCtrl = TextEditingController(text: suggestedUser);
    _selectedSquadId = p.timId;
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.personnel;
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
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı (Giriş için)',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            squadsAsync.when(
              data: (squads) {
                return DropdownButtonFormField<int?>(
                  initialValue: _selectedSquadId,
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
                    setState(() => _selectedSquadId = val);
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İPTAL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.accentOrOlive,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final u = _userCtrl.text.trim();
            if (u.isEmpty || _selectedSquadId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Lütfen kullanıcı adı ve tim seçiniz.',
                  ),
                ),
              );
              return;
            }

            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final accentColor = context.accentOrOlive;

            final repo = ref.read(personnelRepositoryProvider);
            await repo.assignPersonnelAsCommander(
              kullaniciAdi: u,
              timId: _selectedSquadId!,
              personnelId: p.id,
            );

            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  '${p.adSoyad} başarıyla Tim Komutanı yapıldı.',
                ),
                backgroundColor: accentColor,
              ),
            );
          },
          child: const Text('KOMUTAN YAP VE KAYDET'),
        ),
      ],
    );
  }
}
