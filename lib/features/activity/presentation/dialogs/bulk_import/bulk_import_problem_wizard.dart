import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class ProblemLocation {
  const ProblemLocation({
    required this.blockIndex,
    required this.description,
    this.personIndex,
    this.sourceLineNumber,
  });

  final int blockIndex;
  final int? personIndex;
  final int? sourceLineNumber;
  final String description;
}

class BulkImportProblemWizard {
  static List<ProblemLocation> getProblemLocations({
    required List<ParsedActivityBlock> blocks,
    required Map<String, List<String>> duplicates,
  }) {
    final locs = <ProblemLocation>[];
    final addedKeys = <String>{};

    // Priority 1: Critical empty blocks (0 personnel)
    for (final blockEntry in blocks.asMap().entries) {
      if (blockEntry.value.personnelList.isEmpty) {
        locs.add(
          ProblemLocation(
            blockIndex: blockEntry.key,
            personIndex: null,
            sourceLineNumber: null,
            description: '${blockEntry.value.parsedActivityType} kartında personel bulunamadı.',
          ),
        );
        addedKeys.add('${blockEntry.key}:null');
      }
    }

    // Priority 2: Personnel needing match review
    for (final blockEntry in blocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final key = '${blockEntry.key}:${personEntry.key}';
        final person = personEntry.value;
        if (person.needsReview && !addedKeys.contains(key)) {
          final linePrefix = person.sourceLineNumber != null
              ? 'Satır ${person.sourceLineNumber}: '
              : '';
          locs.add(
            ProblemLocation(
              blockIndex: blockEntry.key,
              personIndex: personEntry.key,
              sourceLineNumber: person.sourceLineNumber,
              description: '$linePrefix${person.rawRank} ${person.rawName} - Eşleşme kontrolü gerektiriyor.',
            ),
          );
          addedKeys.add(key);
        }
      }
    }

    // Priority 3: Secondary duplicate assignments
    for (final blockEntry in blocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final key = '${blockEntry.key}:${personEntry.key}';
        final person = personEntry.value;
        if (duplicates.containsKey(key) && !addedKeys.contains(key)) {
          final linePrefix = person.sourceLineNumber != null
              ? 'Satır ${person.sourceLineNumber}: '
              : '';
          locs.add(
            ProblemLocation(
              blockIndex: blockEntry.key,
              personIndex: personEntry.key,
              sourceLineNumber: person.sourceLineNumber,
              description: '$linePrefix${person.rawRank} ${person.rawName} - Çakışan görev ekli.',
            ),
          );
          addedKeys.add(key);
        }
      }
    }

    return locs;
  }

  static void scrollToProblemLocation({
    required int blockIndex,
    required ScrollController scrollController,
    required Map<int, GlobalKey> cardKeys,
    required List<ParsedActivityBlock> blocks,
    required Map<String, List<String>> duplicates,
    required bool filterIsProblems,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      // 1. Direct Context Check: If already mounted in viewport, scroll directly!
      final directKey = cardKeys[blockIndex];
      if (directKey?.currentContext != null) {
        Scrollable.ensureVisible(
          directKey!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
        return;
      }

      // 2. Filter visible blocks
      final visibleBlockEntries = blocks.asMap().entries.where((entry) {
        if (!filterIsProblems) return true;
        final hasReview = entry.value.personnelList.any((p) => p.needsReview);
        final hasDup = entry.value.personnelList
            .asMap()
            .keys
            .any((pIdx) => duplicates.containsKey('${entry.key}:$pIdx'));
        return entry.value.personnelList.isEmpty || hasReview || hasDup;
      }).toList();

      final visibleIndex =
          visibleBlockEntries.indexWhere((e) => e.key == blockIndex);
      final targetIndex = visibleIndex >= 0 ? visibleIndex : blockIndex;

      // 3. Accurate height estimation
      // Header & top stat cards: ~180px
      // Empty card: ~144px
      // Card with N personnel: ~88px + N * 90px
      const headerOffset = 180.0;
      var accumulatedOffset = headerOffset;
      for (var i = 0; i < targetIndex && i < visibleBlockEntries.length; i++) {
        final blk = visibleBlockEntries[i].value;
        if (blk.personnelList.isEmpty) {
          accumulatedOffset += 144.0;
        } else {
          accumulatedOffset += 88.0 + (blk.personnelList.length * 90.0);
        }
      }

      // 4. Jump to target offset to force layout of target sliver
      final initialMax = scrollController.position.maxScrollExtent;
      final targetOffset = accumulatedOffset.clamp(0.0, initialMax + 5000.0);
      scrollController.jumpTo(targetOffset);

      // 5. Retry loop to execute ensureVisible once mounted
      void tryEnsureVisible(int retriesLeft) {
        if (!scrollController.hasClients) return;
        final targetKey = cardKeys[blockIndex];
        if (targetKey?.currentContext != null) {
          Scrollable.ensureVisible(
            targetKey!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.15,
          );
          return;
        }

        if (retriesLeft > 0) {
          final current = scrollController.offset;
          final maxExtent = scrollController.position.maxScrollExtent;
          // Step scroll if slightly misaligned
          scrollController.jumpTo((current + 100.0).clamp(0.0, maxExtent));
          WidgetsBinding.instance.addPostFrameCallback((_) => tryEnsureVisible(retriesLeft - 1));
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => tryEnsureVisible(3));
    });
  }
}
