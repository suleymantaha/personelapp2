part of 'activity_archive_screen.dart';

extension _ActivityArchiveActions on _ActivityArchiveScreenState {
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
    _updateState(() {
      _selectionMode = true;
      _selectedActivityIds.add(activityId);
    });
  }

  void _toggleSelection(int activityId) {
    _updateState(() {
      if (!_selectedActivityIds.add(activityId)) {
        _selectedActivityIds.remove(activityId);
      }
      if (_selectedActivityIds.isEmpty) _selectionMode = false;
    });
  }

  void _clearSelection() {
    _updateState(() {
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
      _updateState(() {
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
      AppNotifications.info('Dışa aktarılacak faaliyet bulunamadı.');
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
      AppNotifications.info('Dışa aktarılacak faaliyet bulunamadı.');
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
      AppNotifications.info('Dışa aktarılacak faaliyet bulunamadı.');
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
      AppNotifications.info('Dışa aktarılacak faaliyet bulunamadı.');
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
}
