import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
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
  int? _selectedFilterTimId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddPersonnelDialog() async {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'Asayiş Timi');
    final customRankController = TextEditingController();
    var selectedRank = kAskeriRutbeler.first;
    int? selectedSquadId;

    await showDialog<void>(
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

                    if (ctx.mounted) Navigator.of(ctx).pop();
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

  Future<void> _showEditPersonnelDialog(PersonelTableData p) async {
    final nameController = TextEditingController(text: p.adSoyad);
    final unitController = TextEditingController(text: p.birlik);
    var selectedRank = kAskeriRutbeler.contains(p.rutbe) ? p.rutbe : 'DİĞER / ÖZEL RÜTBE';
    final customRankController = TextEditingController(text: kAskeriRutbeler.contains(p.rutbe) ? '' : p.rutbe);
    var selectedSquadId = p.timId;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final squadsAsync = ref.watch(allSquadsProvider);

            return AlertDialog(
              title: Text('${p.rutbe} ${p.adSoyad} - Düzenle'),
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
                        decoration: const InputDecoration(labelText: 'Özel Rütbe Adı'),
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
                          decoration: const InputDecoration(labelText: 'Tim Ataması'),
                          items: [
                            const DropdownMenuItem<int?>(
                              child: Text('BOŞTA (Kadro Dışı)', style: TextStyle(color: Colors.red)),
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
                    final updated = p.copyWith(
                      adSoyad: name,
                      rutbe: finalRank.isEmpty ? 'ER' : finalRank,
                      birlik: unitController.text.trim(),
                      timId: Value(selectedSquadId),
                    );

                    await repo.updatePersonnel(updated);

                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('GÜNCELLE'),
                ),
              ],
            );
          },
        );
      },
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
                    const Text(
                      'Bu personeli bir Time Komutan olarak atayabilir ve giriş yetkisi verebilirsiniz.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
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
                          initialValue: selectedSquadId,
                          decoration: const InputDecoration(labelText: 'Komutanı Olacağı Tim'),
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
                    const Text(
                      '💡 Personel ilk girişinde kendi parolasını belirleyecektir.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    backgroundColor: AppColors.militaryOlive,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final u = userCtrl.text.trim();
                    if (u.isEmpty || selectedSquadId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen kullanıcı adı ve tim seçiniz.')),
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
                          content: Text('${p.adSoyad} Tim Komutanı olarak yetkilendirildi!'),
                          backgroundColor: AppColors.approvedGreen,
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
                                padding: const EdgeInsets.all(8),
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
            TextButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('YENİ KOMUTAN YETKİLENDİR'),
              onPressed: () async {
                final userCtrl = TextEditingController();
                await showDialog<void>(
                  context: ctx,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Yeni Komutan Yetkilendirme'),
                    content: Column(
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
                        const Text(
                          '💡 Şifre istenmez. Kullanıcı ilk girişinde kendi parolasını belirler.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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
                            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
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

  Future<void> _showAddSquadDialog() async {
    final squadNameController = TextEditingController();
    final commanderUserController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Yeni Tim & Komutan Yetkilendirme'),
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
                    labelText: 'Tim Komutanı Kullanıcı Adı (Opsiyonel)',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '💡 Atanan Tim Komutanı ilk girişinde kendi parolasını belirleyecektir.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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

                if (name.isEmpty) return;

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
            // 1. Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Personel ad, rütbe veya birlik ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
            const SizedBox(height: 16),

            // 2. Tim Filter / Info Header
            if (isAdmin) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tim Filtresi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.group_add, size: 18),
                    label: const Text('Yeni Tim'),
                    onPressed: _showAddSquadDialog,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              squadsAsync.when(
                data: (squads) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: const Icon(Icons.groups, size: 16),
                            label: const Text('Tüm Personel'),
                            selected: _selectedFilterTimId == null,
                            onSelected: (selected) {
                              setState(() => _selectedFilterTimId = null);
                            },
                            selectedColor: AppColors.militaryOlive,
                            labelStyle: TextStyle(
                              color: _selectedFilterTimId == null ? Colors.white : Colors.black87,
                              fontWeight: _selectedFilterTimId == null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        ...squads.map((sq) {
                          final isSelected = _selectedFilterTimId == sq.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              avatar: Icon(
                                Icons.shield,
                                size: 16,
                                color: isSelected ? Colors.white : AppColors.militaryOlive,
                              ),
                              label: Text(sq.timAdi),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilterTimId = selected ? sq.id : null;
                                });
                              },
                              selectedColor: AppColors.militaryOlive,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: Icon(
                              Icons.person_off,
                              size: 16,
                              color: _selectedFilterTimId == -1 ? Colors.white : Colors.red,
                            ),
                            label: const Text('Boşta / Kadro Dışı'),
                            selected: _selectedFilterTimId == -1,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilterTimId = selected ? -1 : null;
                              });
                            },
                            selectedColor: Colors.red.shade700,
                            labelStyle: TextStyle(
                              color: _selectedFilterTimId == -1 ? Colors.white : Colors.black87,
                              fontWeight: _selectedFilterTimId == -1 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, st) => Text('Hata: $err'),
              ),
            ] else ...[
              squadsAsync.when(
                data: (squads) {
                  final squadMap = {for (final s in squads) s.id: s.timAdi};
                  final timName = session?.timId != null ? squadMap[session?.timId] ?? 'Tüm Birlik' : 'Abonelik Yok';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lightOlive,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.militaryOlive.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield, color: AppColors.darkOlive, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Yetkili Olduğunuz Tim: $timName',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkOlive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, st) => const SizedBox.shrink(),
              ),
            ],

            const SizedBox(height: 20),

            // 3. Personnel List with Rank Sorting
            personnelAsync.when(
              data: (rawPersonnelList) {
                final squads = squadsAsync.value ?? [];
                final squadMap = {for (final s in squads) s.id: s.timAdi};

                // Filter by squad & commander permissions & search query
                final personnelList = rawPersonnelList.where((p) {
                  // If Commander, restrict to commander's squad
                  if (!isAdmin && session?.timId != null && p.timId != session?.timId) {
                    return false;
                  }

                  // Squad filter chip selection
                  if (_selectedFilterTimId != null) {
                    if (_selectedFilterTimId == -1) {
                      if (p.timId != null) return false;
                    } else {
                      if (p.timId != _selectedFilterTimId) return false;
                    }
                  }

                  // Search query filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final nameMatch = p.adSoyad.toLowerCase().contains(q);
                    final rankMatch = p.rutbe.toLowerCase().contains(q);
                    final unitMatch = p.birlik.toLowerCase().contains(q);
                    if (!nameMatch && !rankMatch && !unitMatch) return false;
                  }

                  return true;
                }).toList()
                  ..sort(
                    (a, b) => getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe)),
                  );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Personel Listesi (${personnelList.length} Kişi)',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Kıdem Sıralı',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.militaryOlive,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (personnelList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Kriterlere uygun personel bulunamadı.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: personnelList.length,
                        itemBuilder: (context, index) {
                          final p = personnelList[index];
                          final squadName = p.timId != null ? squadMap[p.timId] : null;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.militaryOlive,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${p.rutbe} ${p.adSoyad}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (squadName != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightOlive,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        squadName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkOlive,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Kadro Dışı',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Birlik: ${p.birlik} | Kayıt: ${p.kayitTarihi}'),
                              ),
                              trailing: isAdmin
                                  ? PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      tooltip: 'İşlemler',
                                      onSelected: (action) async {
                                        if (action == 'edit') {
                                          await _showEditPersonnelDialog(p);
                                        } else if (action == 'commander') {
                                          await _showMakeCommanderDialog(p);
                                        } else if (action == 'delete') {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Personeli Sil'),
                                              content: Text(
                                                '${p.rutbe} ${p.adSoyad} isimli personel sistemden silinecektir. Emin misiniz?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  child: const Text('İPTAL'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.rejectedRed,
                                                  ),
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  child: const Text('SİL'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            final repo = ref.read(personnelRepositoryProvider);
                                            await repo.deletePersonnel(p.id);
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Düzenle / Tim Değiştir'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'commander',
                                          child: Row(
                                            children: [
                                              Icon(Icons.star, size: 20, color: Colors.amber),
                                              SizedBox(width: 8),
                                              Text('Tim Komutanı Yap / Yetki Ver'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 20, color: AppColors.rejectedRed),
                                              SizedBox(width: 8),
                                              Text('Personeli Sil', style: TextStyle(color: AppColors.rejectedRed)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                  ],
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
