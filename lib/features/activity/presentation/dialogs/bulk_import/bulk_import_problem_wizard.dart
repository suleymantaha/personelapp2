import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

typedef ProblemLocation = ({int blockIndex, int? personIndex});

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
        locs.add((blockIndex: blockEntry.key, personIndex: null));
        addedKeys.add('${blockEntry.key}:null');
      }
    }

    // Priority 2: Personnel needing match review
    for (final blockEntry in blocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final key = '${blockEntry.key}:${personEntry.key}';
        if (personEntry.value.needsReview && !addedKeys.contains(key)) {
          locs.add((blockIndex: blockEntry.key, personIndex: personEntry.key));
          addedKeys.add(key);
        }
      }
    }

    // Priority 3: Secondary duplicate assignments
    for (final blockEntry in blocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final key = '${blockEntry.key}:${personEntry.key}';
        if (duplicates.containsKey(key) && !addedKeys.contains(key)) {
          locs.add((blockIndex: blockEntry.key, personIndex: personEntry.key));
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

      final cardKey = cardKeys[blockIndex];
      if (cardKey?.currentContext != null) {
        Scrollable.ensureVisible(
          cardKey!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
        return;
      }

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

      final maxExtent = scrollController.position.maxScrollExtent;
      const headerOffset = 180.0;
      final estimatedOffset =
          (headerOffset + targetIndex * 220.0).clamp(0.0, maxExtent);

      scrollController
          .animateTo(
        estimatedOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      )
          .then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final targetKey = cardKeys[blockIndex];
          if (targetKey?.currentContext != null) {
            Scrollable.ensureVisible(
              targetKey!.currentContext!,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
          }
        });
      });
    });
  }
}
