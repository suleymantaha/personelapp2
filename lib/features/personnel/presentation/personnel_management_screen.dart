import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

class PersonnelManagementScreen extends ConsumerStatefulWidget {
  const PersonnelManagementScreen({super.key});

  @override
  ConsumerState<PersonnelManagementScreen> createState() =>
      _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState
    extends ConsumerState<PersonnelManagementScreen> {
  void _showAddPersonnelDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'Asayiş Timi');
    final customRankController = TextEditingController();
    String selectedRank = kAskeriRutbeler.first;
    int? selectedSquadId;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final squadsAsync = ref.watch(allSquadsProvider);

            return AlertDialog(
              title: const Text('Yeni Personel Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Ad Soyad'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRank,
                      decoration: const InputDecoration(labelText: 'Rütbe'),
                      items: kAskeriRutbeler.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRank = val);
                        }
                      },
                    ),
                    if (selectedRank == 'DİĞER / ÖZEL RÜTBE') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customRankController,
                        decoration: const InputDecoration(
                          labelText: 'Özel Rütbe Giriniz',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Birlik'),
                    ),
                    const SizedBox(height: 12),
                    squadsAsync.when(
                      data: (squads) {
                        return DropdownButtonFormField<int?>(
                          initialValue: selectedSquadId,
                          decoration:
                              const InputDecoration(labelText: 'Tim Ataması'),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'BOŞTA (Kadro Dışı)',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            ...squads.map((s) => DropdownMenuItem<int?>(
                                  value: s.id,
                                  child: Text(s.timAdi),
                                )),
                          ],
                          onChanged: (val) {
                            setDialogState(() => selectedSquadId = val);
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, st) => Text('Hata: $err'),
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final finalRank = (selectedRank == 'DİĞER / ÖZEL RÜTBE')
                        ? customRankController.text.trim()
                        : selectedRank;

                    final repo = ref.read(personnelRepositoryProvider);
                    await repo.addPersonnel(
                      adSoyad: name,
                      rutbe: finalRank.isEmpty ? 'ER' : finalRank,
                      birlik: unitController.text.trim(),
                      timId: selectedSquadId,
                      kayitTarihi: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    );

                    if (mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('KAYDET'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCommanderDelegationDialog() {
    showDialog<void>(
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
                      return const Text('Kayıtlı Tim Komutanı hesabı bulunamadı.');
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
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Komutan: ${cmd.kullaniciAdi}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<int?>(
                                      initialValue: cmd.timId,
                                      decoration: const InputDecoration(
                                        labelText: 'Atanan Tim',
                                        isDense: true,
                                      ),
                                      items: [
                                        const DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text('BOŞTA / Yetkisiz', style: TextStyle(color: Colors.red)),
                                        ),
                                        ...squads.map((s) => DropdownMenuItem<int?>(
                                              value: s.id,
                                              child: Text(s.timAdi),
                                            )),
                                      ],
                                      onChanged: (newTimId) async {
                                        final repo = ref.read(personnelRepositoryProvider);
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Text('Hata: $err'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('KAPAT'),
            ),
          ],
        );
      },
    );
  }

  void _showAddSquadDialog() {
    final squadNameController = TextEditingController();
    final commanderUserController = TextEditingController();
    final commanderPassController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Yeni Tim & Komutan Hesabı Oluştur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: squadNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tim Adı (Örn: 1. Asayiş Timi)',
                    prefixIcon: Icon(Icons.shield),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commanderUserController,
                  decoration: const InputDecoration(
                    labelText: 'Tim Komutanı Kullanıcı Adı',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commanderPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Tim Komutanı Şifre',
                    prefixIcon: Icon(Icons.lock),
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
              onPressed: () async {
                final name = squadNameController.text.trim();
                final cUser = commanderUserController.text.trim();
                final cPass = commanderPassController.text.trim();

                if (name.isEmpty) return;

                final repo = ref.read(personnelRepositoryProvider);
                final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

                if (cUser.isNotEmpty && cPass.isNotEmpty) {
                  await repo.addSquadWithCommander(
                    timAdi: name,
                    olusturmaTarihi: today,
                    komutanKullaniciAdi: cUser,
                    komutanSifre: cPass,
                  );
                } else {
                  await repo.addSquad(
                    timAdi: name,
                    olusturmaTarihi: today,
                  );
                }

                if (mounted) Navigator.of(ctx).pop();
              },
              child: const Text('OLUŞTUR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;

    final personnelAsync = ref.watch(allPersonnelProvider);
    final squadsAsync = ref.watch(allSquadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel & Tim Yönetimi'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Komutan Yetki Devri',
              onPressed: _showCommanderDelegationDialog,
            ),
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: 'Tim Ekle',
              onPressed: _showAddSquadDialog,
            ),
          ],
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddPersonnelDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('PERSONEL EKLE'),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Squad List Summary
            const Text(
              'Mevcut Timler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            squadsAsync.when(
              data: (squads) {
                if (squads.isEmpty) {
                  return const Text('Henüz eklenmiş tim bulunmuyor.');
                }
                return SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: squads.length,
                    itemBuilder: (context, index) {
                      final sq = squads[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(Icons.shield, size: 18),
                          label: Text(sq.timAdi),
                          backgroundColor: AppColors.lightOlive,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, st) => Text('Hata: $err'),
            ),

            const SizedBox(height: 24),
            const Text(
              'Personel Listesi (Kıdem Sıralı)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            personnelAsync.when(
              data: (rawPersonnelList) {
                // If Commander, filter by their squad
                final personnelList = (!isAdmin && session?.timId != null)
                    ? rawPersonnelList.where((p) => p.timId == session?.timId).toList()
                    : rawPersonnelList;

                if (personnelList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Görüntülenecek personel kaydı yok.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: personnelList.length,
                  itemBuilder: (context, index) {
                    final p = personnelList[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.militaryOlive,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          '${p.rutbe} ${p.adSoyad}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Birlik: ${p.birlik} | Kayıt: ${p.kayitTarihi}'),
                        trailing: isAdmin
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.rejectedRed),
                                onPressed: () async {
                                  final repo = ref.read(personnelRepositoryProvider);
                                  await repo.deletePersonnel(p.id);
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Text('Hata: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
