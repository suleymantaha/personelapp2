part of 'activity_archive_screen.dart';

extension _ActivityArchiveActions on _ActivityArchiveScreenState {
  Future<void> _showConflictAudit() async {
    final conflicts =
        await ref
            .read(activityRepositoryProvider)
            .auditExistingDailyConflicts();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.l10n.activityArchiveConflictAuditTitle),
            content: SizedBox(
              width: 600,
              child:
                  conflicts.isEmpty
                      ? Text(context.l10n.activityArchiveConflictAuditNone)
                      : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.activityArchiveConflictAuditReadOnly,
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
                child: Text(context.l10n.commonClose),
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

  String _buildExportDateTitle(List<GunlukFaaliyetTableData> activities) {
    final dates =
        activities.map((activity) => activity.tarih).toSet().toList()..sort();
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
    final session = ref.read(userSessionProvider);
    if (session == null) throw StateError('Oturum doğrulanamadı.');
    final authorizedTeam = session.isAdmin ? null :
      await ref.read(personnelRepositoryProvider).currentCommanderTeam(session.username);
    if (!session.isAdmin && authorizedTeam == null) throw StateError('Tim yetkiniz sona erdi.');
    final pMap = {for (final p in personnelList) p.id: p};
    final squadsList = ref.read(allSquadsProvider).value ?? [];
    final squadMap = {for (final s in squadsList) s.id: s.timAdi};

    final allAssignments = <FaaliyetPersonelAtamaTableData>[];
    final seenAssignmentIds = <int>{};
    final allowedPersonnelIds = pMap.keys.toSet();
    final activityIds = activities.map((act) => act.id).toSet();

    if (activityIds.isNotEmpty) {
      final assignments =
          await (db.select(db.faaliyetPersonelAtamaTable)
            ..where((tbl) => tbl.faaliyetId.isIn(activityIds))).get();

      for (final a in assignments) {
        final isAllowedTeam =
            _selectedSquadFilter == null ||
            a.gorevTimId == _selectedSquadFilter;
        if (allowedPersonnelIds.contains(a.personelId) &&
            isAllowedTeam &&
            (session.isAdmin || a.gorevTimId == authorizedTeam) &&
            !seenAssignmentIds.contains(a.id) &&
            DutyOrLeaveType.isApprovedOperationalDuty(
              a.gorevVeyaIzin,
              a.durum,
            )) {
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
      final timName = atama.gorevTimAdi ?? 'Tim geçmişi bilinmiyor';
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
      AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      return;
    }
    final defaultTitle = context.l10n.activityArchiveAllActivitiesDefaultName;
    final dateTitle = _buildExportDateTitle(activities);
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
    );
    await MilitaryRosterExporter.shareExcelRoster(
      faaliyetAdi:
          activities.length == 1
              ? activities.first.faaliyetAdi
              : defaultTitle,
      tarih: dateTitle,
      rows: rows,
    );
  }

  Future<void> _exportMasterPdf(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    if (activities.isEmpty) {
      AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      return;
    }
    final defaultTitle = context.l10n.activityArchiveAllActivitiesDefaultName;
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
    );
    final dateTitle = _buildExportDateTitle(activities);
    final mainActivityName =
        activities.length == 1
            ? activities.first.faaliyetAdi
            : defaultTitle;

    if (mounted) {
      await PdfRosterExporter.showStylePickerAndSharePdf(
        context,
        faaliyetAdi: mainActivityName,
        tarih: dateTitle,
        rows: rows,
        loadRows: () => _buildRosterRowsForMasterExport(activities, personnelList),
      );
    }
  }

  Future<void> _exportMasterText(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    if (activities.isEmpty) {
      AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      return;
    }
    final defaultTitle = context.l10n.activityArchiveAllActivitiesDefaultName;
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
    );
    final dateTitle = _buildExportDateTitle(activities);
    final mainActivityName =
        activities.length == 1
            ? activities.first.faaliyetAdi
            : defaultTitle;

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
      faaliyetAdi:
          activities.length == 1
              ? activities.first.faaliyetAdi
              : context.l10n.activityArchiveAllActivitiesDefaultName,
      tarih: _buildExportDateTitle(activities),
      rows: rows,
      loadRows: () => _buildRosterRowsForMasterExport(activities, personnelList),
    );
  }

  Future<void> _exportWithSheet(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList, {
    required String subtitle,
  }) async {
    if (activities.isEmpty) {
      AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      return;
    }

    final action = await showArchiveExportSheet(context, subtitle: subtitle);
    if (!mounted || action == null) return;
    try {
    switch (action.type) {
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
    } catch (error) {
      if (mounted) AppNotifications.error(context.l10n.activityArchiveExportFailed('$error'));
    }
  }

  Future<void> _showSelectedExportOptions(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    final selected =
        activities
            .where((activity) => _selectedActivityIds.contains(activity.id))
            .toList();
    if (selected.isEmpty) return;

    final subtitle =
        '${_buildExportDateTitle(selected)} • ${selected.length} Seçili Faaliyet';
    await _exportWithSheet(selected, personnelList, subtitle: subtitle);
  }
}
