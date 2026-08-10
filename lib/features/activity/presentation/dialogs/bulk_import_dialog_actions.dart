part of 'bulk_import_dialog.dart';

extension _BulkImportDialogActions on _BulkImportDialogState {
  Future<void> _processText() async {
    final rawText = _textController.text;
    if (rawText.trim().isEmpty) return;

    _updateState(() {
      _isParsing = true;
    });

    try {
      final parseResult = BulkTextParser.parse(rawText);
      final fuzzyMatcher = PersonnelFuzzyMatcher(widget.database);
      final matchedBlocks = await fuzzyMatcher.matchBlocks(parseResult.blocks);
      final deduplicated =
          BulkImportSaveHandler.deduplicateSameDuty(matchedBlocks);
      if (!mounted) return;

      _updateState(() {
        _cardKeys.clear();
        _personKeys.clear();
        _parsedBlocks = deduplicated.blocks;
        _parseIssues = List<BulkParseIssue>.from(parseResult.issues);
        _deduplicatedPersonnelCount = deduplicated.removedCount;
        _previewFilter = _BulkPreviewFilter.all;
        _parseIssuesExpanded = _parseIssues.any((issue) => issue.isBlocking);
        if (_parsedBlocks.isNotEmpty || _parseIssues.isNotEmpty) {
          _currentStep = 1;
          _activeIssueFocusIndex = -1;
        }
      });
    } finally {
      if (mounted) {
        _updateState(() {
          _isParsing = false;
        });
      }
    }
  }

  Future<void> _saveAllToFaaliyet() async {
    if (_parsedBlocks.isEmpty) {
      AppNotifications.warning('Kaydedilecek kart bulunamadı.');
      return;
    }
    if (_unresolvedPersonnelCount > 0) {
      AppNotifications.error(
        '$_unresolvedPersonnelCount personel eşleşmedi. Lütfen tüm personelleri seçin veya listeden kaldırın.',
      );
      return;
    }
    if (_parsedBlocks.any((block) => block.personnelList.isEmpty)) {
      AppNotifications.error(
        'Personeli bulunmayan boş kartlar var. Lütfen kartları düzenleyin veya silin.',
      );
      return;
    }
    if (_parseIssues.any((issue) => issue.isBlocking)) {
      AppNotifications.error(
        'Lütfen önce çözülmemiş kart sorunlarını (tarih, tim veya görev türü) tamamlayın.',
      );
      return;
    }

    try {
      final actor = ref.read(userSessionProvider);
      final confirmed = await BulkImportSaveHandler.confirmSavePreflight(
        context: context,
        database: widget.database,
        actor: actor,
        blocks: _parsedBlocks,
        squads: _allSquads,
      );
      if (!confirmed || !mounted) return;

      _updateState(() {
        _isSaving = true;
      });

      await BulkImportSaveHandler.saveAllToFaaliyet(
        context: context,
        database: widget.database,
        activityRepository: widget.activityRepository,
        actor: actor,
        blocks: _parsedBlocks,
        squads: _allSquads,
        keepAuditText: _keepAuditText,
        rawText: _textController.text,
        deduplicatedPersonnelCount: _deduplicatedPersonnelCount,
        skipPreflight: true,
      );
    } on Object catch (e) {
      if (mounted) {
        AppNotifications.error('Hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        _updateState(() {
          _isSaving = false;
        });
      }
    }
  }

  Map<String, List<String>> _duplicateAssignments() {
    return BulkImportSaveHandler.findDuplicateAssignments(_parsedBlocks);
  }

  int get _unresolvedPersonnelCount => _parsedBlocks
      .expand((block) => block.personnelList)
      .where((person) => !person.isMatched)
      .length;

  Future<void> _removePerson(int blockIndex, int personIndex) async {
    final block = _parsedBlocks[blockIndex];
    final removed = block.personnelList[personIndex];
    final updated = List<ParsedPersonnelItem>.from(block.personnelList)
      ..removeAt(personIndex);
    _updateState(() {
      _parsedBlocks[blockIndex] = block.copyWith(personnelList: updated);
    });
    AppNotifications.info(
      '${removed.rawRank} ${removed.rawName} kaldırıldı.',
      actionLabel: 'GERİ AL',
      onAction: () {
        if (!mounted) return;
        final currentBlockIndex = _parsedBlocks.indexWhere(
          (candidate) => identical(candidate.identity, block.identity),
        );
        if (currentBlockIndex < 0) return;
        _updateState(() {
          final current = _parsedBlocks[currentBlockIndex];
          final restored =
              List<ParsedPersonnelItem>.from(current.personnelList);
          restored.insert(
            _stableRestoreIndex(
              restored,
              removedOrder: removed.stableOrder,
              orderOf: (item) => item.stableOrder,
            ),
            removed,
          );
          _parsedBlocks[currentBlockIndex] =
              current.copyWith(personnelList: restored);
        });
      },
    );
  }

  void _removeBlock(int blockIndex) {
    final removed = _parsedBlocks[blockIndex];
    _updateState(() => _parsedBlocks.removeAt(blockIndex));
    AppNotifications.info(
      '${removed.parsedActivityType} kartı kaldırıldı.',
      actionLabel: 'GERİ AL',
      onAction: () {
        if (!mounted) return;
        _updateState(() {
          _parsedBlocks.insert(
            _stableRestoreIndex(
              _parsedBlocks,
              removedOrder: removed.stableOrder,
              orderOf: (block) => block.stableOrder,
            ),
            removed,
          );
        });
      },
    );
  }

  int _stableRestoreIndex<T>(
    List<T> items, {
    required int removedOrder,
    required int Function(T item) orderOf,
  }) {
    final nextIndex = items.indexWhere((item) => orderOf(item) > removedOrder);
    return nextIndex < 0 ? items.length : nextIndex;
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Önizlemeyi temizle?'),
        content: const Text(
          'Oluşturulan tüm kartlar ve ayrıştırma uyarıları kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('TEMİZLE'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _updateState(() {
        _parsedBlocks.clear();
        _parseIssues.clear();
        _previewFilter = _BulkPreviewFilter.all;
        _parseIssuesExpanded = false;
        _deduplicatedPersonnelCount = 0;
        _cardKeys.clear();
        _personKeys.clear();
        _currentStep = 0;
      });
    }
  }

  Future<void> _editBlock(int blockIndex) async {
    final block = _parsedBlocks[blockIndex];
    final updated = await EditActivityBlockDialog.show(
      context,
      block,
      availableSquads: _allSquads,
    );
    if (updated != null && mounted && blockIndex < _parsedBlocks.length) {
      _updateState(() => _parsedBlocks[blockIndex] = updated);
    }
  }

  Future<void> _confirmAllSuggestions() async {
    final learningService = BulkImportLearningService(widget.database);
    final aliasPairs = <({String rawName, int personnelId})>[];

    _updateState(() {
      for (var bIdx = 0; bIdx < _parsedBlocks.length; bIdx++) {
        final block = _parsedBlocks[bIdx];
        final updatedList = List<ParsedPersonnelItem>.from(block.personnelList);
        var changed = false;

        for (var pIdx = 0; pIdx < updatedList.length; pIdx++) {
          final item = updatedList[pIdx];
          if (item.hasWarning &&
              item.isMatched &&
              item.matchedPersonnelId != null) {
            updatedList[pIdx] = item.copyWith(
              matchConfidence: 1.0,
              teamMismatch: false,
              reviewConfirmed: true,
            );
            changed = true;
            aliasPairs.add((
              rawName: item.rawName,
              personnelId: item.matchedPersonnelId!,
            ));
          }
        }

        if (changed) {
          _parsedBlocks[bIdx] = block.copyWith(personnelList: updatedList);
        }
      }
    });

    if (aliasPairs.isNotEmpty) {
      await learningService.rememberAliases(aliasPairs);
    }

    if (mounted) {
      AppNotifications.success(
        'Tüm önerilen personel eşleşmeleri onaylandı.',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _quickAddNewPersonnelToTim(
      int blockIndex, int personIndex) async {
    final block = _parsedBlocks[blockIndex];
    final item = block.personnelList[personIndex];

    final normalizedTeam = block.parsedTimName
        .toLowerCase()
        .replaceAll('timi', '')
        .replaceAll(' ', '');
    final timId = _allSquads
        .where(
          (team) => team.timAdi
              .toLowerCase()
              .replaceAll('timi', '')
              .replaceAll(' ', '')
              .contains(normalizedTeam),
        )
        .map((team) => team.id)
        .firstOrNull;

    final timName = _allSquads
            .where((t) => t.id == timId)
            .map((t) => t.timAdi)
            .firstOrNull ??
        block.parsedTimName;

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final newId =
        await widget.database.into(widget.database.personelTable).insert(
              PersonelTableCompanion.insert(
                adSoyad: item.rawName,
                rutbe: item.rawRank,
                birlik: block.parsedTimName,
                timId: Value(timId),
                kayitTarihi: todayStr,
              ),
            );

    await _loadPersonnel();

    if (!mounted || blockIndex >= _parsedBlocks.length) return;

    _updateState(() {
      final currentBlock = _parsedBlocks[blockIndex];
      final updatedList =
          List<ParsedPersonnelItem>.from(currentBlock.personnelList);
      updatedList[personIndex] = updatedList[personIndex].copyWith(
        matchedPersonnelId: newId,
        matchedAdSoyad: item.rawName,
        matchedRutbe: item.rawRank,
        matchedTimId: timId,
        matchConfidence: 1.0,
        teamMismatch: false,
        reviewConfirmed: true,
      );
      _parsedBlocks[blockIndex] =
          currentBlock.copyWith(personnelList: updatedList);
    });

    await BulkImportLearningService(widget.database).rememberAlias(
      rawName: item.rawName,
      personnelId: newId,
    );

    if (mounted) {
      AppNotifications.success(
        '${item.rawRank} ${item.rawName} veritabanına ($timName) eklendi ve eşleştirildi.',
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _selectPersonnel(int blockIndex, int personIndex) async {
    final block = _parsedBlocks[blockIndex];
    final item = block.personnelList[personIndex];
    final normalizedTeam = block.parsedTimName
        .toLowerCase()
        .replaceAll('timi', '')
        .replaceAll(' ', '');
    final preferredTeamId = _allSquads
        .where(
          (team) => team.timAdi
              .toLowerCase()
              .replaceAll('timi', '')
              .replaceAll(' ', '')
              .contains(normalizedTeam),
        )
        .map((team) => team.id)
        .firstOrNull;
    final disabledReasons = <int, String>{};
    for (final otherBlock in _parsedBlocks) {
      if (otherBlock.parsedDate != block.parsedDate) continue;
      for (final person in otherBlock.personnelList) {
        final id = person.matchedPersonnelId;
        if (id == null || id == item.matchedPersonnelId) continue;
        disabledReasons[id] = otherBlock.parsedActivityType;
      }
    }
    final person = await showPersonnelPicker(
      context: context,
      personnel: _allPersonnel,
      squads: _allSquads,
      selectedPersonnelId: item.matchedPersonnelId,
      preferredTimId: item.matchedTimId ?? preferredTeamId,
      disabledReasons: disabledReasons,
    );
    if (person != null &&
        mounted &&
        blockIndex < _parsedBlocks.length &&
        personIndex < _parsedBlocks[blockIndex].personnelList.length) {
      _updateState(() {
        final currentBlock = _parsedBlocks[blockIndex];
        final updatedList =
            List<ParsedPersonnelItem>.from(currentBlock.personnelList);
        updatedList[personIndex] = updatedList[personIndex].copyWith(
          matchedPersonnelId: person.id,
          matchedAdSoyad: person.adSoyad,
          matchedRutbe: person.rutbe,
          matchedTimId: person.timId,
          matchConfidence: 1,
          teamMismatch: false,
          reviewConfirmed: true,
        );
        _parsedBlocks[blockIndex] =
            currentBlock.copyWith(personnelList: updatedList);
      });
      await BulkImportLearningService(widget.database).rememberAlias(
        rawName: item.rawName,
        personnelId: person.id,
      );
    }
  }
}
