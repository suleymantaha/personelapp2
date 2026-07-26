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
import 'package:personelapp2/features/activity/presentation/widgets/activity_summary_card.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_filter_bar.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_header_stats.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';

class ActivityArchiveScreen extends ConsumerStatefulWidget {
  const ActivityArchiveScreen({super.key});

  @override
  ConsumerState<ActivityArchiveScreen> createState() =>
      _ActivityArchiveScreenState();
}

class _ActivityArchiveScreenState extends ConsumerState<ActivityArchiveScreen> {
  String _searchQuery = '';
  DateTime? _selectedDateFilter;
  int? _selectedSquadFilter; // null = Tümü

  Future<List<MilitaryRosterRow>> _buildRosterRowsForMasterExport(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    final db = ref.read(databaseProvider);
    final pMap = {for (final p in personnelList) p.id: p};
    final squadsList = ref.read(allSquadsProvider).value ?? [];
    final squadMap = {for (final s in squadsList) s.id: s.timAdi};

    final allAssignments = <FaaliyetPersonelAtamaTableData>[];
    final seenAssignmentIds = <int>{};

    for (final act in activities) {
      final assignments = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((tbl) => tbl.faaliyetId.equals(act.id))).get();

      for (final a in assignments) {
        if (!seenAssignmentIds.contains(a.id) &&
            DutyOrLeaveType.isOperationalDuty(a.gorevVeyaIzin)) {
          seenAssignmentIds.add(a.id);
          allAssignments.add(a);
        }
      }
    }

    allAssignments.sort((a, b) {
      final catA = MilitaryStructureHelper.getDutyCategoryOrder(
        a.gorevVeyaIzin,
      );
      final catB = MilitaryStructureHelper.getDutyCategoryOrder(
        b.gorevVeyaIzin,
      );
      if (catA != catB) return catA.compareTo(catB);

      final pA = pMap[a.personelId];
      final pB = pMap[b.personelId];

      if (catA == 10) {
        final rA = getRankWeight(pA?.rutbe ?? '');
        final rB = getRankWeight(pB?.rutbe ?? '');
        if (rA != rB) return rA.compareTo(rB);
        return (pA?.adSoyad ?? '').compareTo(pB?.adSoyad ?? '');
      }

      final timNameA = (pA?.timId != null && squadMap.containsKey(pA!.timId))
          ? squadMap[pA.timId]!
          : '';
      final timNameB = (pB?.timId != null && squadMap.containsKey(pB!.timId))
          ? squadMap[pB.timId]!
          : '';
      final rawBirlikA = (pA?.birlik != null && pA!.birlik.isNotEmpty)
          ? pA.birlik
          : timNameA;
      final rawBirlikB = (pB?.birlik != null && pB!.birlik.isNotEmpty)
          ? pB.birlik
          : timNameB;

      final wA = MilitaryStructureHelper.getSquadOrderWeight(rawBirlikA);
      final wB = MilitaryStructureHelper.getSquadOrderWeight(rawBirlikB);
      if (wA != wB) return wA.compareTo(wB);

      final rA = getRankWeight(pA?.rutbe ?? '');
      final rB = getRankWeight(pB?.rutbe ?? '');
      if (rA != rB) return rA.compareTo(rB);

      return (pA?.adSoyad ?? '').compareTo(pB?.adSoyad ?? '');
    });

    final rosterRows = <MilitaryRosterRow>[];
    for (var i = 0; i < allAssignments.length; i++) {
      final atama = allAssignments[i];
      final p = pMap[atama.personelId];
      final rutbe = p?.rutbe ?? '';
      final adSoyad = p?.adSoyad ?? 'Personel #${atama.personelId}';
      final timName = (p?.timId != null && squadMap.containsKey(p!.timId))
          ? squadMap[p.timId]!
          : '';
      final rawBirlik = (p?.birlik != null && p!.birlik.isNotEmpty)
          ? p.birlik
          : timName;
      final birligi = MilitaryStructureHelper.getOfficialBirlikName(
        rawBirlik,
        duty: atama.gorevVeyaIzin,
      );
      final digerNote = MilitaryStructureHelper.getDigerCellText(
        atama.gorevVeyaIzin,
        aciklama: atama.aciklama,
      );

      var groupCode = 'DIGER';
      final dutyUpper = atama.gorevVeyaIzin.toUpperCase().trim();
      if (dutyUpper.contains('HAZIR KITA') || dutyUpper.contains('HAZIRKITA')) {
        groupCode = 'HAZIR_KITA';
      } else if (dutyUpper.contains('GÜLÜŞKÜR') ||
          dutyUpper.contains('GULUSKUR')) {
        groupCode = 'GULUSKUR';
      }

      rosterRows.add(
        MilitaryRosterRow(
          sNu: i + 1,
          birligi: birligi,
          rutbe: rutbe,
          adSoyad: adSoyad,
          diger: digerNote,
          groupCode: groupCode,
        ),
      );
    }
    return rosterRows;
  }

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
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
    );
    final dateTitle = _selectedDateFilter != null
        ? DateFormat('dd.MM.yyyy').format(_selectedDateFilter!)
        : DateFormat('dd.MM.yyyy').format(DateTime.now());
    final mainActivityName = activities.length == 1
        ? activities.first.faaliyetAdi
        : 'GÜNLÜK TÜM FAALİYETLER';

    await MilitaryRosterExporter.shareExcelRoster(
      faaliyetAdi: mainActivityName,
      tarih: dateTitle,
      rows: rows,
    );
  }

  Future<void> _exportMasterPdf(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak faaliyet bulunamadı.')),
      );
      return;
    }
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
    );
    final dateTitle = _selectedDateFilter != null
        ? DateFormat('dd.MM.yyyy').format(_selectedDateFilter!)
        : DateFormat('dd.MM.yyyy').format(DateTime.now());
    final mainActivityName = activities.length == 1
        ? activities.first.faaliyetAdi
        : 'GÜNLÜK TÜM FAALİYETLER';

    if (mounted) {
      await PdfRosterExporter.showStylePickerAndSharePdf(
        context,
        faaliyetAdi: mainActivityName,
        tarih: dateTitle,
        rows: rows,
      );
    }
  }

  Future<void> _exportMasterText(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak faaliyet bulunamadı.')),
      );
      return;
    }
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
    );
    final dateTitle = _selectedDateFilter != null
        ? DateFormat('dd.MM.yyyy').format(_selectedDateFilter!)
        : DateFormat('dd.MM.yyyy').format(DateTime.now());
    final mainActivityName = activities.length == 1
        ? activities.first.faaliyetAdi
        : 'GÜNLÜK TÜM FAALİYETLER';

    await MilitaryRosterExporter.shareTextRoster(
      faaliyetAdi: mainActivityName,
      tarih: dateTitle,
      rows: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final isAdmin = session?.isAdmin ?? false;

    final activitiesAsync = ref.watch(filteredActivitiesProvider);
    final squadsAsync = ref.watch(allSquadsProvider);
    final personnelAsync = ref.watch(allPersonnelProvider);
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

    final pendingCount = pendingAsync.value?.length ?? 0;
    final squads = squadsAsync.value ?? [];
    final allPersonnel = personnelAsync.value ?? [];
    final personnelList = (!isAdmin && session?.timId != null)
        ? allPersonnel.where((p) => p.timId == session!.timId).toList()
        : (!isAdmin ? <PersonelTableData>[] : allPersonnel);

    final dateFilterStr = _selectedDateFilter != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDateFilter!)
        : null;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Faaliyet Arşivi' : 'Tim Faaliyet Arşivi',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
      body: ResponsiveCenter(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header Metrics Card & Master Export Toolbar
            activitiesAsync.when(
              data: (activities) {
                var filteredForExcel = activities;
                if (dateFilterStr != null) {
                  filteredForExcel = filteredForExcel
                      .where((a) => a.tarih == dateFilterStr)
                      .toList();
                }

                return ArchiveHeaderStats(
                  isAdmin: isAdmin,
                  pendingCount: pendingCount,
                  totalActivitiesCount: activities.length,
                  selectedDateStr: dateFilterStr,
                  onExportMasterExcel: () =>
                      _exportMasterExcel(filteredForExcel, personnelList),
                  onExportMasterPdf: () =>
                      _exportMasterPdf(filteredForExcel, personnelList),
                  onExportMasterText: () =>
                      _exportMasterText(filteredForExcel, personnelList),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Filters Bar: Search & Squad Tabs for Admin
            ArchiveFilterBar(
              isAdmin: isAdmin,
              squads: squads,
              selectedSquadId: _selectedSquadFilter,
              searchQuery: _searchQuery,
              onSearchChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
              onSquadSelected: (squadId) {
                setState(() => _selectedSquadFilter = squadId);
              },
            ),

            const SizedBox(height: 6),

            // Activity List
            Expanded(
              child: activitiesAsync.when(
                data: (activities) {
                  final filtered = activities.where((act) {
                    final nameMatch = act.faaliyetAdi.toLowerCase().contains(
                      _searchQuery,
                    );
                    final dateMatch = act.tarih.toLowerCase().contains(
                      _searchQuery,
                    );
                    final dateFilterMatch =
                        dateFilterStr == null || act.tarih == dateFilterStr;
                    return (nameMatch || dateMatch) && dateFilterMatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Aradığınız kriterlere uygun faaliyet kaydı bulunamadı.',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final act = filtered[index];
                      return ActivityCard(
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
      ),
    );
  }
}
