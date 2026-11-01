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
        title: Text(context.l10n.activityArchiveConflictAuditTitle),
        content: SizedBox(
          width: 600,
          child: conflicts.isEmpty
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
      _reorderMode = false;
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

  Future<ActivityOutputSnapshot> _loadMasterSnapshot(
    List<GunlukFaaliyetTableData> activities,
    List<int> selectedAssignmentIds,
  ) async {
    final actor = ref.read(userSessionProvider);
    if (actor == null) throw StateError(context.l10n.authSessionUnverified);
    return ref.read(activityRepositoryProvider).loadOutputSnapshot(
          actor: actor,
          sources: activities,
          selectedAssignmentIds: selectedAssignmentIds,
          selectedSquadId: _selectedSquadFilter,
        );
  }

  Future<List<MilitaryRosterRow>> _buildRosterRowsForMasterExport(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList, {
    required List<int> selectedAssignmentIds,
  }) async {
    final l10n = context.l10n;
    final snapshot =
        await _loadMasterSnapshot(activities, selectedAssignmentIds);
    final pMap = snapshot.personnelMap;
    final squadsList = ref.read(allSquadsProvider).value ?? [];
    final squadMap = {for (final s in squadsList) s.id: s.timAdi};
    final allAssignments = snapshot.assignments;

    final orderedAssignments = orderAssignmentsForExport(
      allAssignments,
      pMap,
      squadMap,
      squadOrders: {for (final s in squadsList) s.id: s.sortOrder},
    );

    final rosterRows = <MilitaryRosterRow>[];
    for (var i = 0; i < orderedAssignments.length; i++) {
      final atama = orderedAssignments[i];
      final p = pMap[atama.personelId];
      final rutbe = p?.rutbe ?? '';
      final adSoyad = p?.adSoyad ??
          l10n.activityArchiveFallbackPersonnelName(atama.personelId);
      final timName =
          atama.gorevTimAdi ?? l10n.activityArchiveUnknownTeamHistory;
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
    List<PersonelTableData> personnelList, {
    required List<int> selectedAssignmentIds,
    String? timeRange,
  }) async {
    if (activities.isEmpty) {
      AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      return;
    }
    final defaultTitle = context.l10n.activityArchiveAllActivitiesDefaultName;
    final dateTitle = _buildExportDateTitle(activities);
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
      selectedAssignmentIds: selectedAssignmentIds,
    );
    await MilitaryRosterExporter.shareExcelRoster(
      faaliyetAdi:
          activities.length == 1 ? activities.first.faaliyetAdi : defaultTitle,
      tarih: dateTitle,
      rows: rows,
      timeRange: timeRange,
    );
  }

  Future<void> _exportMasterPdf(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList, {
    required List<int> selectedAssignmentIds,
    String? timeRange,
  }) async {
    if (activities.isEmpty) {
      AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      return;
    }
    final defaultTitle = context.l10n.activityArchiveAllActivitiesDefaultName;
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
      selectedAssignmentIds: selectedAssignmentIds,
    );
    final dateTitle = _buildExportDateTitle(activities);
    final mainActivityName =
        activities.length == 1 ? activities.first.faaliyetAdi : defaultTitle;

    if (mounted) {
      await PdfRosterExporter.showStylePickerAndSharePdf(
        context,
        faaliyetAdi: mainActivityName,
        tarih: dateTitle,
        rows: rows,
        timeRange: timeRange,
        loadRows: () => _buildRosterRowsForMasterExport(
            activities, personnelList,
            selectedAssignmentIds: selectedAssignmentIds),
      );
    }
  }

  Future<void> _exportMasterText(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList, {
    required List<int> selectedAssignmentIds,
    String? timeRange,
  }) async {
    if (activities.isEmpty) {
      AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      return;
    }
    final defaultTitle = context.l10n.activityArchiveAllActivitiesDefaultName;
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
      selectedAssignmentIds: selectedAssignmentIds,
    );
    final dateTitle = _buildExportDateTitle(activities);
    final mainActivityName =
        activities.length == 1 ? activities.first.faaliyetAdi : defaultTitle;

    await MilitaryRosterExporter.shareTextRoster(
      faaliyetAdi: mainActivityName,
      tarih: dateTitle,
      rows: rows,
      timeRange: timeRange,
    );
  }

  Future<void> _printSelectedPdf(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList, {
    required List<int> selectedAssignmentIds,
    String? timeRange,
  }) async {
    final rows = await _buildRosterRowsForMasterExport(
      activities,
      personnelList,
      selectedAssignmentIds: selectedAssignmentIds,
    );
    if (!mounted || rows.isEmpty) return;
    await PdfRosterExporter.showStylePickerAndPrintPdf(
      context,
      faaliyetAdi: activities.length == 1
          ? activities.first.faaliyetAdi
          : context.l10n.activityArchiveAllActivitiesDefaultName,
      tarih: _buildExportDateTitle(activities),
      rows: rows,
      timeRange: timeRange,
      loadRows: () => _buildRosterRowsForMasterExport(activities, personnelList,
          selectedAssignmentIds: selectedAssignmentIds),
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

    try {
      final db = ref.read(databaseProvider);
      final candidates = await (db.select(db.faaliyetPersonelAtamaTable)
            ..where((t) => t.faaliyetId.isIn(activities.map((a) => a.id))))
          .get();
      final initial = await _loadMasterSnapshot(
          activities, candidates.map((a) => a.id).toList());
      final selectedAssignmentIds =
          initial.assignments.map((a) => a.id).toList();
      if (!mounted) return;
      final action = await showArchiveExportSheet(context, subtitle: subtitle);
      if (!mounted || action == null) return;
      switch (action.type) {
        case ArchiveExportType.excel:
          await _exportMasterExcel(activities, personnelList,
              selectedAssignmentIds: selectedAssignmentIds,
              timeRange: action.timeRange);
          return;
        case ArchiveExportType.image:
          final rows = await _buildRosterRowsForMasterExport(
              activities, personnelList,
              selectedAssignmentIds: selectedAssignmentIds);
          if (!mounted || rows.isEmpty) return;
          await saveRosterImage(context,
              faaliyetAdi: activities.length == 1
                  ? activities.first.faaliyetAdi
                  : context.l10n.activityArchiveAllActivitiesDefaultName,
              tarih: _buildExportDateTitle(activities),
              rows: rows,
              timeRange: action.timeRange);
          return;
        case ArchiveExportType.pdf:
          await _exportMasterPdf(activities, personnelList,
              selectedAssignmentIds: selectedAssignmentIds,
              timeRange: action.timeRange);
          return;
        case ArchiveExportType.print:
          await _printSelectedPdf(activities, personnelList,
              selectedAssignmentIds: selectedAssignmentIds,
              timeRange: action.timeRange);
          return;
        case ArchiveExportType.text:
          await _exportMasterText(activities, personnelList,
              selectedAssignmentIds: selectedAssignmentIds,
              timeRange: action.timeRange);
          return;
        case ArchiveExportType.temgundrap:
          await _exportToTemgundrap(activities, personnelList,
              selectedAssignmentIds: selectedAssignmentIds,
              timeRange: action.timeRange);
          return;
      }
    } catch (error) {
      if (mounted) {
        AppNotifications.error(
            context.l10n.activityArchiveExportFailed('$error'));
      }
    }
  }

  Future<void> _exportToTemgundrap(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList, {
    List<int>? selectedAssignmentIds,
    String? timeRange,
  }) async {
    if (activities.isEmpty) {
      AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      return;
    }

    final db = ref.read(databaseProvider);
    final ids = selectedAssignmentIds ??
        (await (db.select(db.faaliyetPersonelAtamaTable)
                  ..where(
                      (t) => t.faaliyetId.isIn(activities.map((a) => a.id))))
                .get())
            .map((a) => a.id)
            .toList();
    final snapshot = await _loadMasterSnapshot(activities, ids);
    final eligible = snapshot.operationalActivities;
    if (eligible.isEmpty) {
      if (mounted) {
        AppNotifications.info(context.l10n.activityArchiveNoActivitiesToExport);
      }
      return;
    }
    final operations = TemgundrapActivityConverter.convertAll(
      activities: eligible,
      allAssignments: snapshot.assignments,
      personnelMap: snapshot.personnelMap,
    );

    final repo = TemgundrapRepository();
    final defaults = await repo.getApproverDefaults();

    DateTime docDate = _selectedDateFilter;
    if (eligible.isNotEmpty) {
      final parsed = DateTime.tryParse(eligible.first.tarih);
      if (parsed != null) docDate = parsed;
    }

    final draft = TemgundrapDocument(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: docDate,
      unitTitle: defaults.unitTitle.isNotEmpty
          ? defaults.unitTitle
          : defaultTemgundrapUnitTitle,
      approverName: defaults.name,
      approverRank: defaults.rank,
      approverDuty: defaults.duty,
      operations: operations,
      isDraft: true,
      updatedAt: DateTime.now(),
    );

    if (!mounted) return;
    await AppNavigator.toTemgundrapForm(context,
        document: draft, date: docDate);
  }

  Future<void> _showSelectedExportOptions(
    List<GunlukFaaliyetTableData> activities,
    List<PersonelTableData> personnelList,
  ) async {
    final selected = activities
        .where((activity) => _selectedActivityIds.contains(activity.id))
        .toList();
    if (selected.isEmpty) return;

    final subtitle = context.l10n.activityArchiveSelectedActivitiesCount(
      _buildExportDateTitle(selected),
      selected.length,
    );
    await _exportWithSheet(selected, personnelList, subtitle: subtitle);
  }
}
