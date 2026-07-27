import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/personnel/presentation/dialogs/backup_restore_dialog.dart';
import 'package:personelapp2/features/personnel/presentation/widgets/personnel_form_dialog.dart';

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
    await showDialog<void>(
      context: context,
      builder: (context) => const PersonnelFormDialog(),
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

  Future<void> _showAddSquadDialog() async {
    final squadNameController = TextEditingController();
    final commanderUserController = TextEditingController();

    try {
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
                  Text(
                    '💡 Atanan Tim Komutanı ilk girişinde kendi parolasını belirleyecektir.',
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
    } finally {
      squadNameController.dispose();
      commanderUserController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;

    final personnelAsync = ref.watch(allPersonnelProvider);
    final squadsAsync = ref.watch(allSquadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel & Tim Yönetimi'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.import_export_rounded),
              tooltip: 'Verileri Yedekle & Geri Yükle',
              onPressed: () async {
                final db = ref.read(databaseProvider);
                final res = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => BackupRestoreDialog(database: db),
                );
                if (res == true) {
                  ref
                    ..invalidate(allPersonnelProvider)
                    ..invalidate(allSquadsProvider);
                }
              },
            ),
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
        child: ResponsiveCenter(
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
                  fillColor: context.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                  data: (rawSquads) {
                    final squads = MilitaryStructureHelper.sortSquads(
                      rawSquads,
                      (s) => s.timAdi,
                    );
                    final filterChips = [
                      FilterChip(
                        avatar: const Icon(Icons.groups, size: 16),
                        label: const Text('Tüm Personel'),
                        selected: _selectedFilterTimId == null,
                        onSelected: (selected) {
                          setState(() => _selectedFilterTimId = null);
                        },
                        selectedColor: context.accentOrOlive,
                        labelStyle: TextStyle(
                          color: _selectedFilterTimId == null
                              ? Colors.white
                              : context.textPrimary,
                          fontWeight: _selectedFilterTimId == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      ...squads.map((sq) {
                        final isSelected = _selectedFilterTimId == sq.id;
                        return FilterChip(
                          avatar: Icon(
                            Icons.shield,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : context.accentOrOlive,
                          ),
                          label: Text(sq.timAdi),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilterTimId = selected ? sq.id : null;
                            });
                          },
                          selectedColor: context.accentOrOlive,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : context.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }),
                      FilterChip(
                        avatar: Icon(
                          Icons.person_off,
                          size: 16,
                          color: _selectedFilterTimId == -1
                              ? Colors.white
                              : context.rejectedColor,
                        ),
                        label: const Text('Boşta / Kadro Dışı'),
                        selected: _selectedFilterTimId == -1,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilterTimId = selected ? -1 : null;
                          });
                        },
                        selectedColor: context.rejectedBorderColor,
                        labelStyle: TextStyle(
                          color: _selectedFilterTimId == -1
                              ? Colors.white
                              : context.textPrimary,
                          fontWeight: _selectedFilterTimId == -1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ];

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: filterChips
                            .map(
                              (chip) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: chip,
                              ),
                            )
                            .toList(),
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
                    final timName = session?.timId != null
                        ? squadMap[session?.timId] ?? 'Tüm Birlik'
                        : 'Abonelik Yok';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: context.squadBadgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.cardBorderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: context.squadBadgeText,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Yetkili Olduğunuz Tim: $timName',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.squadBadgeText,
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

              // 3. Personnel List Grouped by Squad (Matching Activity Form layout)
              personnelAsync.when(
                data: (rawPersonnelList) {
                  final squads = squadsAsync.value ?? [];
                  final squadMap = {for (final s in squads) s.id: s.timAdi};

                  // Filter by squad & commander permissions & search query
                  final personnelList = rawPersonnelList.where((p) {
                    // If Commander, restrict to commander's squad
                    if (!isAdmin) {
                      if (session?.timId == null) {
                        return false;
                      }

                      if (p.timId != session?.timId) {
                        return false;
                      }
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
                                          // Use fuzzy matching for better search results
                                          final matches = PersonnelFuzzyMatcher.searchPersonnel(
                                            _searchQuery,
                                            [p],
                                            threshold: 0.3, // Lower threshold for filtering
                                            maxResults: 1,
                                          );
                                          if (matches.isEmpty) return false;
                                        }

                    return true;
                  }).toList();

                  if (personnelList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Kriterlere uygun personel bulunamadı.',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ),
                    );
                  }

                  // Group personnel by Squad (timId)
                  final grouped = <int?, List<PersonelTableData>>{};
                  for (final p in personnelList) {
                    grouped.putIfAbsent(p.timId, () => []).add(p);
                  }

                  final sortedTimIds = grouped.keys.toList()
                    ..sort((a, b) {
                      if (a == null) return 1;
                      if (b == null) return -1;
                      final nameA = squadMap[a] ?? '';
                      final nameB = squadMap[b] ?? '';
                      final wA = MilitaryStructureHelper.getSquadOrderWeight(
                        nameA,
                      );
                      final wB = MilitaryStructureHelper.getSquadOrderWeight(
                        nameB,
                      );
                      if (wA != wB) return wA.compareTo(wB);
                      return nameA.compareTo(nameB);
                    });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Personel Listesi (${personnelList.length} Kişi)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Resmi Tim & Kıdem Sıralı',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ...sortedTimIds.map((timId) {
                        final members = grouped[timId]!
                          ..sort(
                            (a, b) => getRankWeight(
                              a.rutbe,
                            ).compareTo(getRankWeight(b.rutbe)),
                          );

                        final squadName = timId == null
                            ? 'Boşta / Kadro Dışı Personeller'
                            : (squadMap[timId] ?? 'Bilinmeyen Tim');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: context.cardBorderColor),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              squadName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: context.accentOrOlive,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.accentOrOlive,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${members.length} Personel',
                                style: TextStyle(
                                  color: context.onAccentOrOlive,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            children: [
                              Divider(
                                height: 1,
                                color: context.cardBorderColor,
                              ),
                              ListView.separated(
                                                              shrinkWrap: true,
                                                              physics: const NeverScrollableScrollPhysics(),
                                                              itemCount: members.length,
                                                              separatorBuilder: (context, _) => Divider(
                                                                height: 1,
                                                                color: context.cardBorderColor,
                                                              ),
                                                              itemBuilder: (context, index) {
                                  final p = members[index];

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: context.accentOrOlive,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: context.onAccentOrOlive,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${p.rutbe} ${p.adSoyad}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Birlik: ${p.birlik} | Kayıt: ${p.kayitTarihi}',
                                      ),
                                    ),
                                    trailing: isAdmin
                                        ? PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            tooltip: 'İşlemler',
                                            onSelected: (action) async {
                                              if (action == 'edit') {
                                                await _showEditPersonnelDialog(
                                                  p,
                                                );
                                              } else if (action ==
                                                  'commander') {
                                                await _showMakeCommanderDialog(
                                                  p,
                                                );
                                              } else if (action == 'delete') {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                      'Personeli Sil',
                                                    ),
                                                    content: Text(
                                                      '${p.rutbe} ${p.adSoyad} isimli personel sistemden silinecektir. Emin misiniz?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(false),
                                                        child: const Text(
                                                          'İPTAL',
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              context
                                                                  .rejectedColor,
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(true),
                                                        child: const Text(
                                                          'SİL',
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
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      size: 20,
                                                      color:
                                                          context.blueGreyColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Düzenle / Tim Değiştir',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'commander',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      size: 20,
                                                      color:
                                                          context.pendingColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Tim Komutanı Yap / Yetki Ver',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuDivider(),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      size: 20,
                                                      color:
                                                          context.rejectedColor,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Personeli Sil',
                                                      style: TextStyle(
                                                        color: context
                                                            .rejectedColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Hata: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
