import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

class ActivityArchiveScreen extends ConsumerStatefulWidget {
  const ActivityArchiveScreen({super.key});

  @override
  ConsumerState<ActivityArchiveScreen> createState() => _ActivityArchiveScreenState();
}

class _ActivityArchiveScreenState extends ConsumerState<ActivityArchiveScreen> {
  String _searchQuery = '';
  DateTime? _selectedDateFilter;
  int? _selectedSquadFilter; // null = Tümü

  Future<void> _exportMasterExcel(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak faaliyet bulunamadı.')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final pMap = {for (final p in personnelList) p.id: p};
    final masterList = <MasterActivityData>[];

    for (final act in activities) {
      final assignments = await (db.select(db.faaliyetPersonelAtamaTable)
            ..where((tbl) => tbl.faaliyetId.equals(act.id)))
          .get();

      final rosterRows = <MilitaryRosterRow>[];
      for (var i = 0; i < assignments.length; i++) {
        final atama = assignments[i];
        final p = pMap[atama.personelId];
        final rutbe = p?.rutbe ?? '';
        final adSoyad = p?.adSoyad ?? 'Personel #${atama.personelId}';
        final birligi = p?.birlik ?? 'Birlik';
        final digerNote = atama.aciklama ?? atama.gorevVeyaIzin;

        rosterRows.add(MilitaryRosterRow(
          sNu: i + 1,
          birligi: birligi,
          rutbe: rutbe,
          adSoyad: adSoyad,
          diger: '$digerNote (${atama.durum})',
        ));
      }

      masterList.add(MasterActivityData(
        faaliyetAdi: act.faaliyetAdi,
        tarih: act.tarih,
        olusturanKullanici: act.olusturanKullanici,
        rows: rosterRows,
      ));
    }

    final dateTitle = _selectedDateFilter != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDateFilter!)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    await MilitaryRosterExporter.shareMasterDailyExcel(
      title: 'TÜM GÜNLÜK FAALİYETLER VE GÖREV İCMAL LİSTESİ',
      dateStr: dateTitle,
      activities: masterList,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;

    final activitiesAsync = ref.watch(filteredActivitiesProvider);
    final squadsAsync = ref.watch(allSquadsProvider);
    final personnelAsync = ref.watch(allPersonnelProvider);
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

    final pendingCount = pendingAsync.value?.length ?? 0;
    final squads = squadsAsync.value ?? [];
    final personnelList = personnelAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      appBar: AppBar(
        title: Text(isAdmin ? 'Faaliyet Arşivi & Onay Merkezi' : 'Tim Faaliyet Arşivi'),
        actions: [
          if (_selectedDateFilter != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Tarih Filtresini Temizle',
              onPressed: () => setState(() => _selectedDateFilter = null),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Tarihe Göre Süz',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDateFilter ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDateFilter = picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Metrics Card & Master Excel Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5A27), Color(0xFF1B365D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.military_tech,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAdmin ? 'YÖNETİCİ KONTROL MERKEZİ' : 'TİM KOMUTANLIĞI SÜZGECİ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              isAdmin
                                  ? 'Tüm timlerin günlük kayıtları burada toplanır'
                                  : 'Sadece timinize ait faaliyetler gösterilmektedir',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isAdmin && pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pendingYellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$pendingCount Onay Bekliyor',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                activitiesAsync.when(
                  data: (activities) {
                    final dateFilterStr = _selectedDateFilter != null
                        ? DateFormat('yyyy-MM-dd').format(_selectedDateFilter!)
                        : null;

                    var filtered = activities;
                    if (dateFilterStr != null) {
                      filtered = filtered.where((a) => a.tarih == dateFilterStr).toList();
                    }

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37), // Military Gold
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.file_download, color: Colors.black87),
                        label: Text(
                          dateFilterStr != null
                              ? "$dateFilterStr TARİHLİ FAALİYETLERİ TEK EXCEL'E AKTAR"
                              : "GÜNLÜK TÜM FAALİYETLERİ TEK EXCEL'E AKTAR",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () => _exportMasterExcel(filtered, personnelList),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Filters Bar: Search & Squad Tabs for Admin
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Faaliyet veya Tarih Ara...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim().toLowerCase());
                    },
                  ),
                ),
              ],
            ),
          ),

          // Squad Filter Chips (Admin only)
          if (isAdmin && squads.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tüm Timler'),
                    selected: _selectedSquadFilter == null,
                    selectedColor: AppColors.militaryOlive,
                    labelStyle: TextStyle(
                      color: _selectedSquadFilter == null ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _selectedSquadFilter = null),
                  ),
                  const SizedBox(width: 8),
                  ...squads.map((sq) {
                    final isSel = _selectedSquadFilter == sq.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(sq.timAdi),
                        selected: isSel,
                        selectedColor: AppColors.militaryOlive,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => _selectedSquadFilter = sq.id),
                      ),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // Activity List
          Expanded(
            child: activitiesAsync.when(
              data: (activities) {
                final dateFilterStr = _selectedDateFilter != null
                    ? DateFormat('yyyy-MM-dd').format(_selectedDateFilter!)
                    : null;

                final filtered = activities.where((act) {
                  final nameMatch = act.faaliyetAdi.toLowerCase().contains(_searchQuery);
                  final dateMatch = act.tarih.toLowerCase().contains(_searchQuery);
                  final dateFilterMatch = dateFilterStr == null || act.tarih == dateFilterStr;
                  return (nameMatch || dateMatch) && dateFilterMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aradığınız kriterlere uygun faaliyet kaydı bulunamadı.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final act = filtered[index];
                    return _ActivityCard(
                      activity: act,
                      selectedSquadId: _selectedSquadFilter,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Hata: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({
    required this.activity,
    this.selectedSquadId,
  });

  final GunlukFaaliyetTableData activity;
  final int? selectedSquadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;
    final db = ref.watch(databaseProvider);

    return StreamBuilder<List<FaaliyetPersonelAtamaTableData>>(
      stream: (db.select(db.faaliyetPersonelAtamaTable)
            ..where((tbl) => tbl.faaliyetId.equals(activity.id)))
          .watch(),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
        final hasPending = assignments.any((a) => a.durum == AssignmentStatus.beklemede);
        final hasRejected = assignments.any((a) => a.durum == AssignmentStatus.reddedildi);

        String statusLabel = 'ONAYLANDI';
        Color statusColor = AppColors.approvedGreen;
        IconData statusIcon = Icons.check_circle_outline;

        if (hasPending) {
          statusLabel = 'ADMIN ONAYI BEKLİYOR';
          statusColor = AppColors.pendingYellow;
          statusIcon = Icons.hourglass_top;
        } else if (hasRejected) {
          statusLabel = 'ÇAKIŞMA / RED';
          statusColor = AppColors.rejectedRed;
          statusIcon = Icons.cancel_outlined;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(statusIcon, color: Colors.white, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    activity.faaliyetAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '📅 Tarih: ${activity.tarih}  |  👤 Oluşturan: ${activity.olusturanKullanici}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
            trailing: isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPending)
                        IconButton(
                          icon: const Icon(Icons.done_all, color: AppColors.approvedGreen),
                          tooltip: 'Tümünü Onayla',
                          onPressed: () async {
                            final repo = ref.read(activityRepositoryProvider);
                            await repo.approveAllAssignmentsForActivity(activity.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Faaliyet atamaları onaylandı!'),
                                  backgroundColor: AppColors.approvedGreen,
                                ),
                              );
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.rejectedRed),
                        tooltip: 'Faaliyeti Sil',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Faaliyeti Sil'),
                              content: Text(
                                '${activity.faaliyetAdi} (${activity.tarih}) faaliyet kaydı silinecektir. Emin misiniz?',
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
                            await (db.delete(db.gunlukFaaliyetTable)
                                  ..where((tbl) => tbl.id.equals(activity.id)))
                                .go();
                          }
                        },
                      ),
                    ],
                  )
                : null,
            children: [
              _AssignmentDetails(
                activity: activity,
                assignments: assignments,
                selectedSquadId: selectedSquadId,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AssignmentDetails extends ConsumerWidget {
  const _AssignmentDetails({
    required this.activity,
    required this.assignments,
    this.selectedSquadId,
  });

  final GunlukFaaliyetTableData activity;
  final List<FaaliyetPersonelAtamaTableData> assignments;
  final int? selectedSquadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? true;
    final allPersonnelAsync = ref.watch(allPersonnelProvider);
    final personnelList = allPersonnelAsync.value ?? [];
    final pMap = {for (final p in personnelList) p.id: p};

    // Filter assignments by squad if selectedSquadId is provided
    var filteredAssignments = assignments;
    if (selectedSquadId != null) {
      filteredAssignments = filteredAssignments.where((a) {
        final p = pMap[a.personelId];
        return p?.timId == selectedSquadId;
      }).toList();
    }

    if (filteredAssignments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Bu faaliyette seçilen tim için görevlendirilmiş personel kaydı bulunmuyor.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    final rosterRows = <MilitaryRosterRow>[];
    for (var i = 0; i < filteredAssignments.length; i++) {
      final atama = filteredAssignments[i];
      final p = pMap[atama.personelId];
      final rutbe = p?.rutbe ?? '';
      final adSoyad = p?.adSoyad ?? 'Personel #${atama.personelId}';
      final birligi = p?.birlik ?? 'Birlik';
      final digerNote = atama.aciklama ?? atama.gorevVeyaIzin;

      rosterRows.add(MilitaryRosterRow(
        sNu: i + 1,
        birligi: birligi,
        rutbe: rutbe,
        adSoyad: adSoyad,
        diger: '$digerNote (${atama.durum})',
      ));
    }

    return Container(
      color: const Color(0xFFFAFBF8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...filteredAssignments.map((atama) {
            final p = pMap[atama.personelId];
            final displayName = p != null ? '${p.rutbe} ${p.adSoyad}' : 'Personel #${atama.personelId}';
            final birlikInfo = p?.birlik ?? '';
            final digerNote = atama.aciklama ?? '';

            final isPending = atama.durum == AssignmentStatus.beklemede;
            final isApproved = atama.durum == AssignmentStatus.onaylandi;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$displayName ${birlikInfo.isNotEmpty ? "($birlikInfo)" : ""}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (digerNote.isNotEmpty)
                          Text(
                            'Not: $digerNote',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${atama.gorevVeyaIzin} • ${atama.durum.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isApproved
                            ? AppColors.approvedGreen
                            : (isPending ? Colors.orange.shade900 : AppColors.rejectedRed),
                      ),
                    ),
                    backgroundColor: isApproved
                        ? AppColors.approvedGreen.withValues(alpha: 0.12)
                        : (isPending ? AppColors.pendingYellow.withValues(alpha: 0.3) : AppColors.rejectedRed.withValues(alpha: 0.12)),
                  ),
                  if (isAdmin && isPending) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppColors.approvedGreen, size: 22),
                      tooltip: 'Onayla',
                      onPressed: () async {
                        final repo = ref.read(activityRepositoryProvider);
                        await repo.updateAssignmentStatus(atama.id, AssignmentStatus.onaylandi);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.rejectedRed, size: 22),
                      tooltip: 'Reddet',
                      onPressed: () async {
                        final repo = ref.read(activityRepositoryProvider);
                        await repo.updateAssignmentStatus(atama.id, AssignmentStatus.reddedildi);
                      },
                    ),
                  ],
                ],
              ),
            );
          }),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Metin İsim Listesi', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    unawaited(
                      MilitaryRosterExporter.shareTextRoster(
                        faaliyetAdi: activity.faaliyetAdi,
                        tarih: activity.tarih,
                        rows: rosterRows,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.militaryOlive,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.table_chart, size: 16),
                  label: const Text('Resmi Excel Al', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    unawaited(
                      MilitaryRosterExporter.shareExcelRoster(
                        faaliyetAdi: activity.faaliyetAdi,
                        tarih: activity.tarih,
                        rows: rosterRows,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
