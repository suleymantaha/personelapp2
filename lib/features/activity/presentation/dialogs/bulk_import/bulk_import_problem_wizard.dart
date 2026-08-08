import 'package:flutter/material.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class ProblemLocation {
  const ProblemLocation({
    required this.blockIndex,
    required this.description,
    this.personIndex,
    this.sourceLineNumber,
    this.isCritical = true,
  });

  final int blockIndex;
  final int? personIndex;
  final int? sourceLineNumber;
  final String description;
  final bool isCritical;
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
        final title = blockEntry.value.parsedActivityType.trim().isEmpty
            ? 'Kart #${blockEntry.key + 1}'
            : blockEntry.value.parsedActivityType;
        locs.add(
          ProblemLocation(
            blockIndex: blockEntry.key,
            personIndex: null,
            sourceLineNumber: null,
            description: '$title kartında personel bulunamadı.',
            isCritical: true,
          ),
        );
        addedKeys.add('${blockEntry.key}:null');
      }
    }

    // Priority 2: Critical block metadata errors (missing date, missing team, missing activity type)
    for (final blockEntry in blocks.asMap().entries) {
      final block = blockEntry.value;
      final key = '${blockEntry.key}:meta';
      if (addedKeys.contains(key)) continue;

      if (block.parsedDate.trim().isEmpty) {
        locs.add(
          ProblemLocation(
            blockIndex: blockEntry.key,
            personIndex: null,
            sourceLineNumber: null,
            description: 'Kart #${blockEntry.key + 1}: Geçerli bir tarih bulunamadı.',
            isCritical: true,
          ),
        );
        addedKeys.add(key);
      } else if (block.parsedTimName.trim().isEmpty) {
        locs.add(
          ProblemLocation(
            blockIndex: blockEntry.key,
            personIndex: null,
            sourceLineNumber: null,
            description: 'Kart #${blockEntry.key + 1}: Takım/tim bilgisi tanınamadı.',
            isCritical: true,
          ),
        );
        addedKeys.add(key);
      } else if (block.parsedActivityType.trim().isEmpty) {
        locs.add(
          ProblemLocation(
            blockIndex: blockEntry.key,
            personIndex: null,
            sourceLineNumber: null,
            description: 'Kart #${blockEntry.key + 1}: Görev türü tanınamadı.',
            isCritical: true,
          ),
        );
        addedKeys.add(key);
      }
    }

    // Priority 2: Unmatched personnel (!isMatched)
    for (final blockEntry in blocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final key = '${blockEntry.key}:${personEntry.key}';
        final person = personEntry.value;
        if (!person.isMatched && !addedKeys.contains(key)) {
          final linePrefix = person.sourceLineNumber != null
              ? 'Satır ${person.sourceLineNumber}: '
              : '';
          locs.add(
            ProblemLocation(
              blockIndex: blockEntry.key,
              personIndex: personEntry.key,
              sourceLineNumber: person.sourceLineNumber,
              description: '$linePrefix${person.rawRank} ${person.rawName} - Personel seçilmedi.',
              isCritical: true,
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
              isCritical: true,
            ),
          );
          addedKeys.add(key);
        }
      }
    }

    // Priority 4: Non-critical review warnings (fuzzy match < 1.0 or teamMismatch)
    for (final blockEntry in blocks.asMap().entries) {
      for (final personEntry
          in blockEntry.value.personnelList.asMap().entries) {
        final key = '${blockEntry.key}:${personEntry.key}';
        final person = personEntry.value;
        if (person.isMatched && person.hasWarning && !addedKeys.contains(key)) {
          final linePrefix = person.sourceLineNumber != null
              ? 'Satır ${person.sourceLineNumber}: '
              : '';
          final reason = person.teamMismatch
              ? 'Tim kontrolü gerektiriyor.'
              : 'Eşleşme kontrolü gerektiriyor.';
          locs.add(
            ProblemLocation(
              blockIndex: blockEntry.key,
              personIndex: personEntry.key,
              sourceLineNumber: person.sourceLineNumber,
              description: '$linePrefix${person.rawRank} ${person.rawName} - $reason',
              isCritical: false,
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
    int? personIndex,
    required ScrollController scrollController,
    required Map<int, GlobalKey> cardKeys,
    Map<String, GlobalKey>? personKeys,
    required List<ParsedActivityBlock> blocks,
    required Map<String, List<String>> duplicates,
    required bool filterIsProblems,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      // If personIndex is specified and its context is already available, scroll directly to the person row
      if (personIndex != null && personKeys != null) {
        final personKey = personKeys['$blockIndex:$personIndex'];
        if (personKey?.currentContext != null) {
          Scrollable.ensureVisible(
            personKey!.currentContext!,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.3,
          );
          return;
        }
      }

      // Otherwise scroll to the card top header first
      final targetKey = cardKeys[blockIndex];
      if (targetKey?.currentContext != null) {
        Scrollable.ensureVisible(
          targetKey!.currentContext!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );

        // After card scrolls into view and lays out expanded children, scroll to person row if present
        if (personIndex != null && personKeys != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final personKey = personKeys['$blockIndex:$personIndex'];
            if (personKey?.currentContext != null) {
              Scrollable.ensureVisible(
                personKey!.currentContext!,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: 0.3,
              );
            }
          });
        }
      }
    });
  }
}
