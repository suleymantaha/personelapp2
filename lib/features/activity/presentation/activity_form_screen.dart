import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  DateTime _selectedDate = DateTime.now();

  // Maps personelId to selected DutyType
  final Map<int, String> _assignments = {};
  // Maps personelId to custom notes
  final Map<int, String> _notes = {};

  Future<void> _submitActivity() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final name = 'Günlük Faaliyet ($dateStr)';
    final userSession = ref.read(userSessionProvider);

    final payload = _assignments.entries.where((e) => e.value.isNotEmpty).map((
      e,
    ) {
      final note = _notes[e.key]?.trim();
      return {
        'personelId': e.key,
        'gorevVeyaIzin': e.value,
        'aciklama': (note != null && note.isNotEmpty) ? note : null,
      };
    }).toList();

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir personel için görev seçiniz.'),
        ),
      );
      return;
    }

    final repo = ref.read(activityRepositoryProvider);
    final isCommander = !(userSession?.isAdmin ?? true);

    await repo.createActivityWithAssignments(
      faaliyetAdi: name,
      tarih: dateStr,
      olusturanKullanici: userSession?.username ?? 'admin',
      personnelAssignments: payload,
      isCommander: isCommander,
    );

    if (mounted) {
      final msg = isCommander
          ? 'Faaliyet Kaydedildi! Admin onayına gönderildi.'
          : 'Faaliyet Çizelgesi Kaydedildi & Çakışma Denetimi Yapıldı!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isCommander
              ? context.pendingColor
              : context.approvedColor,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;

    final personnelAsync = ref.watch(allPersonnelProvider);
    final squadsAsync = ref.watch(allSquadsProvider);
    final dateFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);

    const adminOnlyDuties = [
      DutyOrLeaveType.heybetKomutani,
      DutyOrLeaveType.nobSb,
      DutyOrLeaveType.mebsNob,
      DutyOrLeaveType.garajNob,
      DutyOrLeaveType.ttzaNob,
      DutyOrLeaveType.kuleNob,
    ];

    const generalDuties = [
      DutyOrLeaveType.hazirKita,
      DutyOrLeaveType.guluskur,
      DutyOrLeaveType.heybet,
      DutyOrLeaveType.gorevli,
      DutyOrLeaveType.nobetci,
      DutyOrLeaveType.izinli,
      DutyOrLeaveType.istirahatli,
      DutyOrLeaveType.raporlu,
      DutyOrLeaveType.sevk,
      DutyOrLeaveType.diger,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faaliyet Çizelgesi Oluştur'),
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxWidth: 1000,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker Card
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: context.accentOrOlive,
                  ),
                  title: Text('Faaliyet Tarihi: $dateFormatted'),
                  subtitle: const Text('Değiştirmek için dokunun'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isAdmin
                    ? 'Tüm Birlik Personel Görevlendirme Listesi'
                    : 'Tim Personel Görevlendirme Listesi',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              personnelAsync.when(
                data: (rawPersonnelList) {
                  // If Commander, strictly filter by their squad
                  final personnelList = (!isAdmin && session?.timId != null)
                      ? rawPersonnelList
                            .where((p) => p.timId == session?.timId)
                            .toList()
                      : (!isAdmin && session?.timId == null)
                      ? <PersonelTableData>[]
                      : rawPersonnelList;

                  if (!isAdmin && session?.timId == null) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Henüz bir time atamadınız. Lütfen yöneticinizle (Admin) iletişime geçiniz.',
                        style: TextStyle(
                          color: context.rejectedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  if (personnelList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Görevlendirilecek kayıtlı personel bulunamadı.',
                      ),
                    );
                  }

                  if (isAdmin) {
                    return squadsAsync.when(
                      data: (squads) {
                        final squadMap = {
                          for (final s in squads) s.id: s.timAdi,
                        };

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
                            final wA =
                                MilitaryStructureHelper.getSquadOrderWeight(
                                  nameA,
                                );
                            final wB =
                                MilitaryStructureHelper.getSquadOrderWeight(
                                  nameB,
                                );
                            if (wA != wB) return wA.compareTo(wB);
                            return nameA.compareTo(nameB);
                          });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sortedTimIds.map((timId) {
                            final members = grouped[timId]!
                              ..sort(
                                (a, b) => getRankWeight(
                                  a.rutbe,
                                ).compareTo(getRankWeight(b.rutbe)),
                              );

                            final squadName = timId == null
                                ? 'Timsiz / Diğer Personeller'
                                : (squadMap[timId] ?? 'Bilinmeyen Tim');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: context.cardBorderColor,
                                ),
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  squadName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.accentOrOlive,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.bolt,
                                        color: context.accentOrOlive,
                                        size: 22,
                                      ),
                                      tooltip: 'Time Toplu Görev Ata',
                                      onSelected: (duty) {
                                        setState(() {
                                          for (final p in members) {
                                            if (duty == 'CLEAR') {
                                              _assignments.remove(p.id);
                                            } else {
                                              _assignments[p.id] = duty;
                                            }
                                          }
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              duty == 'CLEAR'
                                                  ? '$squadName görevleri temizlendi.'
                                                  : '$squadName personelinin tümüne "$duty" atandı.',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          enabled: false,
                                          child: Text(
                                            '⚡ TIME TOPLU GÖREV ATA',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: context.accentOrOlive,
                                            ),
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        ...generalDuties.map(
                                          (d) => PopupMenuItem<String>(
                                            value: d,
                                            child: Text('Tümüne "$d" Ata'),
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        PopupMenuItem<String>(
                                          value: 'CLEAR',
                                          child: Text(
                                            'Görevleri Sıfırla',
                                            style: TextStyle(
                                              color: context.rejectedColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
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
                                  ],
                                ),
                                children: [
                                  Divider(
                                    height: 1,
                                    color: context.cardBorderColor,
                                  ),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: members.length,
                                    separatorBuilder: (_, _) => Divider(
                                      height: 1,
                                      color: context.cardBorderColor,
                                    ),
                                    itemBuilder: (context, index) {
                                      final p = members[index];
                                      final currentSelection =
                                          _assignments[p.id];

                                      final availableDuties = [
                                        if (isAdmin) ...adminOnlyDuties,
                                        ...generalDuties,
                                        if (!isAdmin &&
                                            currentSelection != null &&
                                            adminOnlyDuties.contains(
                                              currentSelection,
                                            ))
                                          currentSelection,
                                      ];

                                      return Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${p.rutbe} ${p.adSoyad}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Birlik: ${p.birlik}',
                                                    style: TextStyle(
                                                      color:
                                                          context.textSecondary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: context
                                                    .responsiveValue(
                                                      mobile: 135,
                                                      tablet: 180,
                                                      desktop: 220,
                                                    ),
                                              ),
                                              child: DropdownButton<String>(
                                                value: currentSelection,
                                                isDense: true,
                                                isExpanded: true,
                                                hint: Text(
                                                  'SEÇİNİZ',
                                                  style: TextStyle(
                                                    color:
                                                        context.accentOrOlive,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                items: availableDuties.map((d) {
                                                  final isAdminOnly =
                                                      adminOnlyDuties.contains(
                                                        d,
                                                      );
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: d,
                                                    child: Text(
                                                      d,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: isAdminOnly
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isAdminOnly
                                                            ? context
                                                                  .accentOrOlive
                                                            : context
                                                                  .textPrimary,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() {
                                                      _assignments[p.id] = val;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) => Text('Tim verileri alınamadı: $err'),
                    );
                  }

                  // If not admin (Team Commander), render a flat list (their own team sorted by rank weight)
                  personnelList.sort(
                    (a, b) => getRankWeight(
                      a.rutbe,
                    ).compareTo(getRankWeight(b.rutbe)),
                  );

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: personnelList.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: context.cardBorderColor),
                    itemBuilder: (context, index) {
                      final p = personnelList[index];
                      final currentSelection = _assignments[p.id];

                      final availableDuties = [
                        if (isAdmin) ...adminOnlyDuties,
                        ...generalDuties,
                        if (!isAdmin &&
                            currentSelection != null &&
                            adminOnlyDuties.contains(currentSelection))
                          currentSelection,
                      ];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.cardBorderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${p.rutbe} ${p.adSoyad}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'Birlik: ${p.birlik}',
                                          style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: currentSelection,
                                    hint: Text(
                                      'SEÇİNİZ',
                                      style: TextStyle(
                                        color: context.accentOrOlive,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    items: availableDuties.map((d) {
                                      final isAdminOnly = adminOnlyDuties
                                          .contains(d);
                                      return DropdownMenuItem<String>(
                                        value: d,
                                        child: Text(
                                          d,
                                          style: TextStyle(
                                            fontWeight: isAdminOnly
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isAdminOnly
                                                ? context.accentOrOlive
                                                : context.textPrimary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _assignments[p.id] = val;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Hata: $err'),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('FAALİYET ÇİZELGESİNİ KAYDET'),
                  onPressed: _submitActivity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
