part of 'bulk_add_personnel_to_activity_dialog.dart';

extension _BulkAddPersonnelActions on _BulkAddPersonnelToActivityDialogState {
  Future<void> _parse() async {
    if (_textController.text.trim().isEmpty) return;
    _updateState(() => _parsing = true);
    try {
      final parsed = BulkTextParser.parse(
        _textController.text,
        defaultDate: widget.activity.tarih,
      );
      final matched = await PersonnelFuzzyMatcher(
        ref.read(databaseProvider),
      ).matchBlocks(parsed.blocks);
      final session = ref.read(userSessionProvider);
      final rows = <_ActivityImportRow>[];
      for (final block in matched) {
        final parsedDuty =
            kActivityAssignmentDuties.contains(block.parsedActivityType)
                ? block.parsedActivityType
                : _defaultDuty;
        for (final item in block.personnelList) {
          final scopedItem = session?.isAdmin == true ||
                  (session?.timId != null &&
                      item.matchedTimId == session?.timId)
              ? item
              : _withoutMatch(item);
          rows.add(
            _ActivityImportRow(
              personnel: scopedItem,
              duty: parsedDuty,
              alreadyAssigned: scopedItem.matchedPersonnelId != null &&
                  widget.existingPersonnelIds
                      .contains(scopedItem.matchedPersonnelId),
            ),
          );
        }
      }
      if (!mounted) return;
      _updateState(() {
        _rows = rows;
        _previewReady = true;
      });
    } finally {
      if (mounted) _updateState(() => _parsing = false);
    }
  }

  ParsedPersonnelItem _withoutMatch(ParsedPersonnelItem item) {
    return ParsedPersonnelItem(
      rawIndex: item.rawIndex,
      rawRank: item.rawRank,
      rawName: item.rawName,
      sourceLineNumber: item.sourceLineNumber,
    );
  }

  void _updateRow(int index, _ActivityImportRow row) {
    _updateState(() => _rows = List.of(_rows)..[index] = row);
  }

  Future<void> _quickCreate(int index) async {
    final row = _rows[index];
    final session = ref.read(userSessionProvider);
    final allSquads = ref.read(allSquadsProvider).valueOrNull ?? [];
    final squads = session?.isAdmin == true
        ? allSquads
        : allSquads
            .where((squad) => squad.id == session?.timId)
            .toList(growable: false);
    final nameController = TextEditingController(text: row.personnel.rawName);
    final unitController = TextEditingController();
    var rank = row.personnel.rawRank.isEmpty ? null : row.personnel.rawRank;
    int? squadId = session?.isAdmin == true ? null : session?.timId;
    final initialSquad =
        squads.where((squad) => squad.id == squadId).firstOrNull;
    if (initialSquad != null) {
      unitController.text =
          MilitaryStructureHelper.getBolukName(initialSquad.timAdi);
    }
    final created = await showDialog<PersonelTableData>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Personel Oluştur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  menuMaxHeight: modernDropdownMenuMaxHeight(context),
                  borderRadius: modernDropdownBorderRadius,
                  dropdownColor: modernDropdownColor(context),
                  initialValue: rank,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Rütbe'),
                  items: kAskeriRutbeler
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => rank = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Birlik'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int?>(
                  menuMaxHeight: modernDropdownMenuMaxHeight(context),
                  borderRadius: modernDropdownBorderRadius,
                  dropdownColor: modernDropdownColor(context),
                  initialValue: squadId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tim'),
                  items: [
                    if (session?.isAdmin == true)
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tim dışı'),
                      ),
                    ...squads.map(
                      (squad) => DropdownMenuItem<int?>(
                        value: squad.id,
                        child: Text(squad.timAdi),
                      ),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() {
                    squadId = value;
                    final squad = squads
                        .where((candidate) => candidate.id == value)
                        .firstOrNull;
                    if (squad != null && unitController.text.trim().isEmpty) {
                      unitController.text =
                          MilitaryStructureHelper.getBolukName(squad.timAdi);
                    }
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İPTAL'),
            ),
            FilledButton(
              onPressed: rank == null || nameController.text.trim().isEmpty
                  ? null
                  : () async {
                      final repo = ref.read(personnelRepositoryProvider);
                      final id = await repo.addPersonnel(
                        adSoyad: nameController.text.trim(),
                        rutbe: rank!,
                        birlik: unitController.text.trim().isEmpty
                            ? 'Asayiş Timi'
                            : unitController.text.trim(),
                        timId: squadId,
                        kayitTarihi:
                            DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      );
                      final person = PersonelTableData(
                        id: id,
                        adSoyad: nameController.text.trim(),
                        rutbe: rank!,
                        birlik: unitController.text.trim().isEmpty
                            ? 'Asayiş Timi'
                            : unitController.text.trim(),
                        timId: squadId,
                        kayitTarihi:
                            DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(person);
                      }
                    },
              child: const Text('OLUŞTUR'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    unitController.dispose();
    if (created == null || !mounted) return;
    ref.invalidate(allPersonnelProvider);
    _updateRow(
      index,
      row.copyWith(
        personnel: ParsedPersonnelItem(
          rawIndex: row.personnel.rawIndex,
          rawRank: row.personnel.rawRank,
          rawName: row.personnel.rawName,
          matchedPersonnelId: created.id,
          matchedAdSoyad: created.adSoyad,
          matchedRutbe: created.rutbe,
          matchedTimId: created.timId,
          matchConfidence: 1,
          reviewConfirmed: true,
          sourceLineNumber: row.personnel.sourceLineNumber,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final actor = ref.read(userSessionProvider);
    if (actor == null || _saving) return;
    _updateState(() => _saving = true);
    try {
      final result =
          await ref.read(activityRepositoryProvider).addAssignmentsToActivity(
                activityId: widget.activity.id,
                assignments: [
                  for (final row in _rows)
                    if (row.canSave && !row.alreadyAssigned)
                      PersonnelAssignmentInput(
                        personnelId: row.personnel.matchedPersonnelId!,
                        duty: row.duty,
                        note: row.note.trim().isEmpty ? null : row.note.trim(),
                      ),
                ],
                actor: actor,
              );
      await BulkImportLearningService(ref.read(databaseProvider))
          .rememberAliases(
        _rows.where((row) => row.canSave).map(
              (row) => (
                rawName: row.personnel.rawName,
                personnelId: row.personnel.matchedPersonnelId!,
              ),
            ),
      );
      if (mounted) Navigator.of(context).pop(result);
    } finally {
      if (mounted) _updateState(() => _saving = false);
    }
  }
}
