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
  final Set<int> _selectedActivityIds = {};
  bool _selectionMode = false;

  Future<void> _showConflictAudit() async {
    final conflicts = await ref
        .read(activityRepositoryProvider)
        .auditExistingDailyConflicts();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Geçmiş Kayıt Çakışma Denetimi'),
        content: SizedBox(
          width: 600,
          child: conflicts.isEmpty
              ? const Text('Çakışan geçmiş kayıt bulunamadı.')
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bu liste salt okunurdur; hiçbir kayıt silinmedi.',
                      ),
                      const SizedBox(height: 12),
                      for (final conflict in conflicts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• $conflict'),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('KAPAT'),
          ),
        ],
      ),
    );
  }

  void _startSelection(int activityId) {
    setState(() {
      _selectionMode = true;
      _selectedActivityIds.add(activityId);
    });
  }

  void _toggleSelection(int activityId) {
    setState(() {
      if (!_selectedActivityIds.add(activityId)) {
        _selectedActivityIds.remove(activityId);
      }
      if (_selectedActivityIds.isEmpty) _selectionMode = false;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedActivityIds.clear();
    });
  }

  void _pruneSelectionAfterBuild(Iterable<int> visibleActivityIds) {
    if (!_selectionMode) return;
    final visible = visibleActivityIds.toSet();
    if (_selectedActivityIds.every(visible.contains)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedActivityIds.retainAll(visible);
        if (_selectedActivityIds.isEmpty) _selectionMode = false;
      });
    });
  }

  String _buildExportDateTitle(
    List<GunlukFaaliyetTableData> activities,
  ) {
    final dates = activities.map((activity) => activity.tarih).toSet().toList()
      ..sort();
    if (dates.isEmpty) {
      return DateFormat('dd.MM.yyyy').format(DateTime.now());
    }
    String display(String isoDate) {
      final parsed = DateTime.tryParse(isoDate);
      return parsed == null ? isoDate : DateFormat('dd.MM.yyyy').format(parsed);
    }

    if (dates.length == 1) return display(dates.single);
    return '${display(dates.first)} - ${display(dates.last)}';
  }

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
    final allowedPersonnelIds = pMap.keys.toSet();

    for (final act in activities) {
      final assignments = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((tbl) => tbl.faaliyetId.equals(act.id)))
          .get();

      for (final a in assignments) {
        final person = pMap[a.personelId];
        final isAllowedTeam = _selectedSquadFilter == null ||
            person?.timId == _selectedSquadFilter;
        if (allowedPersonnelIds.contains(a.personelId) &&
            isAllowedTeam &&
            !seenAssignmentIds.contains(a.id) &&
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
      final birlikA = MilitaryStructureHelper.getRosterBirlikName(
        timName: timNameA,
        birlik: pA?.birlik ?? '',
        duty: a.gorevVeyaIzin,
      );
      final birlikB = MilitaryStructureHelper.getRosterBirlikName(
        timName: timNameB,
        birlik: pB?.birlik ?? '',
        duty: b.gorevVeyaIzin,
      );

      final wA = MilitaryStructureHelper.getSquadOrderWeight(birlikA);
      final wB = MilitaryStructureHelper.getSquadOrderWeight(birlikB);
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
      final birligi = MilitaryStructureHelper.getRosterBirlikName(
        timName: timName,
        birlik: p?.birlik ?? '',
        duty: atama.gorevVeyaIzin,
      );
      final digerNote = MilitaryStructureHelper.getDigerCellText(
        atama.gorevVeyaIzin,
        aciklama: atama.aciklama,
      );

      final groupCode = MilitaryStructureHelper.getRosterGroupCode(
        atama.gorevVeyaIzin,
      );

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
    final dateTitle = _buildExportDateTitle(activities);
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
    );
    await MilitaryRosterExporter.shareExcelRoster(
      faaliyetAdi: activities.length == 1
          ? activities.first.faaliyetAdi
          : 'GÜNLÜK TÜM FAALİYETLER',
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
    final dateTitle = _buildExportDateTitle(activities);
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
    final dateTitle = _buildExportDateTitle(activities);
    final mainActivityName = activities.length == 1
        ? activities.first.faaliyetAdi
        : 'GÜNLÜK TÜM FAALİYETLER';

    await MilitaryRosterExporter.shareTextRoster(
      faaliyetAdi: mainActivityName,
      tarih: dateTitle,
      rows: rows,
    );
  }

  Future<void> _printSelectedPdf(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
    );
    if (!mounted || rows.isEmpty) return;
    await PdfRosterExporter.showStylePickerAndPrintPdf(
      context,
      faaliyetAdi: activities.length == 1
          ? activities.first.faaliyetAdi
          : 'GÜNLÜK TÜM FAALİYETLER',
      tarih: _buildExportDateTitle(activities),
      rows: rows,
    );
  }

  Future<void> _showSelectedExportOptions(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    final selected = activities
        .where((activity) => _selectedActivityIds.contains(activity.id))
        .toList();
    if (selected.isEmpty) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF Paylaş'),
              onTap: () => Navigator.pop(sheetContext, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Doğrudan Yazdır'),
              onTap: () => Navigator.pop(sheetContext, 'print'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Excel Olarak Aktar'),
              onTap: () => Navigator.pop(sheetContext, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Metin Listesi Paylaş'),
              onTap: () => Navigator.pop(sheetContext, 'text'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'pdf') {
      await _exportMasterPdf(selected, personnelList);
    } else if (action == 'print') {
      await _printSelectedPdf(selected, personnelList);
    } else if (action == 'excel') {
      await _exportMasterExcel(selected, personnelList);
    } else if (action == 'text') {
      await _exportMasterText(selected, personnelList);
    }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: _selectionMode ? null : 0,
        leading: _selectionMode
            ? IconButton(
                key: const Key('activity-selection-close'),
                icon: const Icon(Icons.close),
                tooltip: 'Seçimi Kapat',
                onPressed: _clearSelection,
              )
            : null,
        title: Text(
          _selectionMode
              ? '${_selectedActivityIds.length} faaliyet seçildi'
              : (isAdmin ? 'Faaliyet Arşivi' : 'Tim Faaliyet Arşivi'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              key: const Key('activity-selection-export'),
              icon: const Icon(Icons.ios_share),
              tooltip: 'Seçilenleri Dışa Aktar',
              onPressed: () => _showSelectedExportOptions(
                activitiesAsync.value ?? [],
                personnelList,
              ),
            )
          else if (!context.isMobile)
            TextButton.icon(
              key: const Key('activity-selection-start'),
              onPressed: () => setState(() => _selectionMode = true),
              icon: const Icon(Icons.checklist),
              label: const Text('Seç'),
            ),
          if (!_selectionMode && _selectedDateFilter != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Tarih Filtresini Temizle',
              onPressed: () => setState(() => _selectedDateFilter = null),
            ),
          if (!_selectionMode && isAdmin)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Geçmiş Çakışmaları Denetle',
              onPressed: _showConflictAudit,
            ),
          if (!_selectionMode)
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
                if (!mounted || picked == null) return;
                setState(() => _selectedDateFilter = picked);
              },
            ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 860,
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
              error: (err, _) => const SizedBox.shrink(),
            ),

            // Filters Bar: Search & Squad Tabs for Admin
            ArchiveFilterBar(
              isAdmin: isAdmin,
              squads: squads,
              selectedSquadId: _selectedSquadFilter,
              searchQuery: _searchQuery,
              onSearchChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                  _selectedActivityIds.clear();
                  _selectionMode = false;
                });
              },
              onSquadSelected: (squadId) {
                setState(() {
                  _selectedSquadFilter = squadId;
                  _selectedActivityIds.clear();
                  _selectionMode = false;
                });
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
                  _pruneSelectionAfterBuild(
                    filtered.map((activity) => activity.id),
                  );

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

                  filtered.sort((a, b) {
                    final dateOrder = b.tarih.compareTo(a.tarih);
                    return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
                  });
                  final grouped = <String, List<GunlukFaaliyetTableData>>{};
                  for (final activity in filtered) {
                    grouped.putIfAbsent(activity.tarih, () => []).add(activity);
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    children: [
                      for (final day in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                          child: Text(
                            '${DateFormat('dd MMMM').format(DateTime.parse(day.key))}'
                            ' • ${day.value.length} faaliyet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        for (final act in day.value)
                          ActivityCard(
                            activity: act,
                            selectedSquadId: _selectedSquadFilter,
                            selectionMode: _selectionMode,
                            isSelected: _selectedActivityIds.contains(act.id),
                            onLongPress: () => _startSelection(act.id),
                            onSelectionToggle: () => _toggleSelection(act.id),
                            onDateChanged: (newDate) {
                              final parsed = DateTime.tryParse(newDate);
                              if (parsed != null) {
                                setState(() => _selectedDateFilter = parsed);
                              }
                            },
                          ),
                      ],
                    ],
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
