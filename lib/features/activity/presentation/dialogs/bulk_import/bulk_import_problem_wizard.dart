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
        if (person.hasWarning && !addedKeys.contains(key)) {
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
      final targetKey = cardKeys[blockIndex];
      if (targetKey?.currentContext != null) {
        Scrollable.ensureVisible(
          targetKey!.currentContext!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
    });
  }
}
