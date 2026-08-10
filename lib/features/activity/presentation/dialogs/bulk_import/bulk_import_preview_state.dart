part of 'bulk_import_preview_section.dart';

class _PreviewProblemState {
  const _PreviewProblemState({
    required this.personnelByBlock,
    required this.totalBlockCount,
  });

  final Map<int, List<int>> personnelByBlock;
  final int totalBlockCount;

  int get readyBlockCount => totalBlockCount - personnelByBlock.length;
}

class _PreviewMetrics {
  const _PreviewMetrics({
    required this.personnelCount,
    required this.dayCount,
    required this.reviewCount,
    required this.actionCount,
    required this.displayCriticalCount,
    required this.hasBlocking,
  });

  final int personnelCount;
  final int dayCount;
  final int reviewCount;
  final int actionCount;
  final int displayCriticalCount;
  final bool hasBlocking;
}

_PreviewProblemState _buildPreviewProblemState({
  required List<ParsedActivityBlock> blocks,
  required List<ProblemLocation> problemLocations,
  required Map<String, List<String>> duplicates,
}) {
  final personnelByBlock = <int, List<int>>{};
  for (final blockEntry in blocks.asMap().entries) {
    final problemIndexes = <int>[];
    for (final personEntry in blockEntry.value.personnelList.asMap().entries) {
      if (_personHasPreviewProblem(
        blocks: blocks,
        problemLocations: problemLocations,
        duplicates: duplicates,
        blockIndex: blockEntry.key,
        personIndex: personEntry.key,
      )) {
        problemIndexes.add(personEntry.key);
      }
    }
    if (problemIndexes.isNotEmpty ||
        _blockHasPreviewProblem(
          problemLocations: problemLocations,
          blockIndex: blockEntry.key,
          block: blockEntry.value,
        )) {
      personnelByBlock[blockEntry.key] = problemIndexes;
    }
  }

  return _PreviewProblemState(
    personnelByBlock: personnelByBlock,
    totalBlockCount: blocks.length,
  );
}

List<MapEntry<int, ParsedActivityBlock>> _filterVisiblePreviewBlocks({
  required List<ParsedActivityBlock> blocks,
  required Map<int, List<int>> problemPersonnelByBlock,
  required bool previewFilterIsProblems,
  required bool previewFilterIsReady,
  required String query,
}) {
  return blocks.asMap().entries.where((entry) {
    final hasProblems = problemPersonnelByBlock.containsKey(entry.key);
    final matchesFilter = previewFilterIsProblems
        ? hasProblems
        : previewFilterIsReady
            ? !hasProblems
            : true;
    return matchesFilter && _matchesPreviewQuery(entry.value, query);
  }).toList(growable: false);
}

_PreviewMetrics _buildPreviewMetrics({
  required List<ParsedActivityBlock> blocks,
  required List<BulkParseIssue> issues,
  required List<ProblemLocation> problemLocations,
}) {
  final personnelCount = blocks.fold<int>(
    0,
    (count, block) => count + block.personnelList.length,
  );
  final criticalCount = problemLocations.where((loc) => loc.isCritical).length;
  final blockingParseIssueCount =
      issues.where((issue) => issue.isBlocking).length;

  return _PreviewMetrics(
    personnelCount: personnelCount,
    dayCount: blocks.map((b) => b.parsedDate).toSet().length,
    reviewCount: problemLocations.where((loc) => !loc.isCritical).length,
    actionCount:
        problemLocations.isNotEmpty ? problemLocations.length : issues.length,
    displayCriticalCount:
        criticalCount > 0 ? criticalCount : blockingParseIssueCount,
    hasBlocking: criticalCount > 0 || blockingParseIssueCount > 0,
  );
}

bool _blockHasPreviewProblem({
  required List<ProblemLocation> problemLocations,
  required int blockIndex,
  required ParsedActivityBlock block,
}) {
  return problemLocations.any((loc) => loc.blockIndex == blockIndex) ||
      block.personnelList.isEmpty ||
      block.parsedDate.trim().isEmpty ||
      block.parsedActivityType.trim().isEmpty;
}

bool _personHasPreviewProblem({
  required List<ParsedActivityBlock> blocks,
  required List<ProblemLocation> problemLocations,
  required Map<String, List<String>> duplicates,
  required int blockIndex,
  required int personIndex,
}) {
  final person = blocks[blockIndex].personnelList[personIndex];
  return !person.isMatched ||
      person.hasWarning ||
      duplicates.containsKey('$blockIndex:$personIndex') ||
      problemLocations.any(
        (loc) => loc.blockIndex == blockIndex && loc.personIndex == personIndex,
      );
}

bool _matchesPreviewQuery(ParsedActivityBlock block, String query) {
  if (query.isEmpty) return true;
  final haystack = StringBuffer()
    ..write(' ${block.rawTitle}')
    ..write(' ${block.parsedTimName}')
    ..write(' ${block.parsedActivityType}')
    ..write(' ${block.parsedDate}')
    ..write(' ${block.parsedTimeRange ?? ''}');
  for (final person in block.personnelList) {
    haystack
      ..write(' ${person.rawRank}')
      ..write(' ${person.rawName}')
      ..write(' ${person.matchedRutbe ?? ''}')
      ..write(' ${person.matchedAdSoyad ?? ''}')
      ..write(' satir ${person.sourceLineNumber ?? ''}');
  }
  return haystack.toString().toLowerCase().contains(query);
}
