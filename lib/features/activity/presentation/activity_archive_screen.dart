import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/responsive_layout.dart';
import 'package:personelapp2/core/theme/spacing.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_summary_card.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_filter_bar.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_header_stats.dart';
import 'package:personelapp2/core/widgets/modern_action_menu.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';

class ActivityArchiveScreen extends ConsumerStatefulWidget {
  const ActivityArchiveScreen({super.key});

  @override
  ConsumerState<ActivityArchiveScreen> createState() =>
      _ActivityArchiveScreenState();
}

class _ActivityArchiveScreenState extends ConsumerState<ActivityArchiveScreen> {
  DateTime _selectedDateFilter = DateTime.now();
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
      return DateFormat('dd.MM.yyyy').format(_selectedDateFilter);
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
    final activityIds = activities.map((act) => act.id).toSet();

    if (activityIds.isNotEmpty) {
      final assignments = await (db.select(
        db.faaliyetPersonelAtamaTable,
      )..where((tbl) => tbl.faaliyetId.isIn(activityIds)))
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

    final orderedAssignments = orderAssignmentsForExport(
      allAssignments,
      pMap,
      squadMap,
    );

    final rosterRows = <MilitaryRosterRow>[];
    for (var i = 0; i < orderedAssignments.length; i++) {
      final atama = orderedAssignments[i];
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

  Future<void> _exportWithSheet(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList, {
    required String subtitle,
  }) async {
    if (activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak faaliyet bulunamadı.')),
      );
      return;
    }

    final action = await showArchiveExportSheet(
      context,
      subtitle: subtitle,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case ArchiveExportType.excel:
        await _exportMasterExcel(activities, personnelList);
        return;
      case ArchiveExportType.pdf:
        await _exportMasterPdf(activities, personnelList);
        return;
      case ArchiveExportType.print:
        await _printSelectedPdf(activities, personnelList);
        return;
      case ArchiveExportType.text:
        await _exportMasterText(activities, personnelList);
        return;
    }
  }

  Future<void> _showSelectedExportOptions(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    final selected = activities
        .where((activity) => _selectedActivityIds.contains(activity.id))
        .toList();
    if (selected.isEmpty) return;

    final subtitle =
        '${_buildExportDateTitle(selected)} • ${selected.length} Seçili Faaliyet';
    await _exportWithSheet(selected, personnelList, subtitle: subtitle);
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

    final dateFilterStr = DateFormat('yyyy-MM-dd').format(_selectedDateFilter);
    final now = DateTime.now();
    final isSelectedToday = _selectedDateFilter.year == now.year &&
        _selectedDateFilter.month == now.month &&
        _selectedDateFilter.day == now.day;

    Future<void> pickArchiveDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDateFilter,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (!mounted || picked == null) return;
      setState(() => _selectedDateFilter = picked);
    }

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
          if (!_selectionMode && context.isMobile)
            PopupMenuButton<String>(
              tooltip: 'Arşiv işlemleri',
              icon: const Icon(Icons.more_vert_rounded),
              elevation: 5,
              shadowColor: context.shadowColor,
              surfaceTintColor: context.colorScheme.surface,
              shape: modernPopupShape(context),
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
              onSelected: (action) async {
                switch (action) {
                  case 'select':
                    setState(() => _selectionMode = true);
                  case 'today':
                    setState(() => _selectedDateFilter = DateTime.now());
                  case 'audit':
                    await _showConflictAudit();
                  case 'date':
                    await pickArchiveDate();
                }
              },
              itemBuilder: (context) => [
                const ModernMenuHeader<String>(
                  title: 'Arşiv İşlemleri',
                  subtitle: 'Görünüm ve arşiv araçları',
                  icon: Icons.inventory_2_outlined,
                ),
                const PopupMenuDivider(),
                ModernPopupMenuItem(
                  option: const ModernActionOption(
                    value: 'select',
                    title: 'Faaliyet seç',
                    subtitle: 'Birden fazla kayıt üzerinde çalış',
                    icon: Icons.checklist_rounded,
                  ),
                ),
                if (!isSelectedToday)
                  ModernPopupMenuItem(
                    option: const ModernActionOption(
                      value: 'today',
                      title: 'Bugüne dön',
                      subtitle: 'Güncel faaliyetleri göster',
                      icon: Icons.today_rounded,
                    ),
                  ),
                if (isAdmin)
                  ModernPopupMenuItem(
                    option: const ModernActionOption(
                      value: 'audit',
                      title: 'Çakışmaları denetle',
                      subtitle: 'Personel görevlendirmelerini kontrol et',
                      icon: Icons.fact_check_outlined,
                    ),
                  ),
                ModernPopupMenuItem(
                  option: const ModernActionOption(
                    value: 'date',
                    title: 'Tarihe göre süz',
                    subtitle: 'Belirli bir günün arşivini aç',
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          if (!_selectionMode && !context.isMobile && !isSelectedToday)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Bugüne Dön',
              onPressed: () =>
                  setState(() => _selectedDateFilter = DateTime.now()),
            ),
          if (!_selectionMode && !context.isMobile && isAdmin)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Geçmiş Çakışmaları Denetle',
              onPressed: _showConflictAudit,
            ),
          if (!_selectionMode && !context.isMobile)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Tarihe Göre Süz',
              onPressed: pickArchiveDate,
            ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: AppSpacing.readableContentWidth,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header Metrics Card & Master Export Toolbar
            activitiesAsync.when(
              data: (activities) {
                final filteredForDate =
                    activities.where((a) => a.tarih == dateFilterStr).toList();

                final dateTitle =
                    DateFormat('dd.MM.yyyy').format(_selectedDateFilter);
                final squadText = _selectedSquadFilter != null &&
                        squads.any((s) => s.id == _selectedSquadFilter)
                    ? ' • ${squads.firstWhere((s) => s.id == _selectedSquadFilter).timAdi}'
                    : '';
                final subtitle =
                    '$dateTitle • ${filteredForDate.length} Faaliyet$squadText';

                return ArchiveHeaderStats(
                  isAdmin: isAdmin,
                  pendingCount: pendingCount,
                  totalActivitiesCount: filteredForDate.length,
                  selectedDateStr: dateFilterStr,
                  onExportRequested: () => _exportWithSheet(
                    filteredForDate,
                    personnelList,
                    subtitle: subtitle,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, _) => const SizedBox.shrink(),
            ),

            // Filters Bar: Squad Tabs for Admin
            ArchiveFilterBar(
              isAdmin: isAdmin,
              squads: squads,
              selectedSquadId: _selectedSquadFilter,
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
                  final filtered = activities
                      .where((act) => act.tarih == dateFilterStr)
                      .toList();
                  _pruneSelectionAfterBuild(
                    filtered.map((activity) => activity.id),
                  );

                  if (filtered.isEmpty) {
                    final formattedDate =
                        DateFormat('dd.MM.yyyy').format(_selectedDateFilter);
                    return Center(
                      child: Text(
                        '$formattedDate tarihine ait faaliyet kaydı bulunamadı.',
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

                  final rows = <Object>[];
                  for (final day in grouped.entries) {
                    rows
                      ..add(day)
                      ..addAll(day.value);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      if (row
                          case MapEntry<String, List<GunlukFaaliyetTableData>>
                              day) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                          child: Text(
                            '${_formatTurkishDay(day.key)}'
                            ' • ${day.value.length} faaliyet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }

                      final act = row as GunlukFaaliyetTableData;
                      return ActivityCard(
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

String _formatTurkishDay(String isoDate) {
  const months = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  final date = DateTime.parse(isoDate);
  return '${date.day} ${months[date.month - 1]}';
}
