import 'package:personelapp2/features/activity/domain/models/activity_create_request.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

class BulkActivityImportDraft {
  const BulkActivityImportDraft({
    required this.blocks,
    required this.issues,
    this.deduplicatedPersonnelCount = 0,
    this.ignoredLineCount = 0,
    this.declaredTotals = const [],
  });

  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final int deduplicatedPersonnelCount;
  final int ignoredLineCount;
  final List<BulkDeclaredTotal> declaredTotals;

  bool get hasBlockingIssues => issues.any((issue) => issue.isBlocking);
  bool get hasBlocks => blocks.isNotEmpty;

  BulkImportPreparation toPreparation() =>
      BulkActivityImportPreparer.prepare(blocks);

  static Future<BulkActivityImportDraft> fromRawText(
    String rawText, {
    String? defaultDate,
    required Future<List<ParsedActivityBlock>> Function(
      List<ParsedActivityBlock> blocks,
    )
    matchBlocks,
  }) async {
    final parseResult = BulkTextParser.parse(rawText, defaultDate: defaultDate);
    final matchedBlocks = await matchBlocks(parseResult.blocks);
    final deduplicated = BulkActivityImportPreparer.deduplicateSameDuty(
      matchedBlocks,
    );

    return BulkActivityImportDraft(
      blocks: List<ParsedActivityBlock>.unmodifiable(deduplicated.blocks),
      issues: List<BulkParseIssue>.unmodifiable([
        ...parseResult.issues,
        ...declaredTotalIssues(parseResult.blocks, parseResult.declaredTotals),
      ]),
      deduplicatedPersonnelCount: deduplicated.removedCount,
      ignoredLineCount: parseResult.ignoredLineCount,
      declaredTotals: List<BulkDeclaredTotal>.unmodifiable(
        parseResult.declaredTotals,
      ),
    );
  }

  static List<BulkParseIssue> declaredTotalIssues(
    Iterable<ParsedActivityBlock> blocks,
    Iterable<BulkDeclaredTotal> totals,
  ) {
    final issues = <BulkParseIssue>[];
    final previousLines = <String, int>{};
    for (final total in totals) {
      final key = '${total.date}|${total.teamName}|${total.activityType}';
      final previous = previousLines[key] ?? 0;
      final count =
          blocks
              .where(
                (b) =>
                    b.parsedDate == total.date &&
                    b.parsedTimName == total.teamName &&
                    b.parsedActivityType == total.activityType,
              )
              .expand((b) => b.personnelList)
              .where(
                (p) =>
                    p.sourceLineNumber != null &&
                    p.sourceLineNumber! > previous &&
                    p.sourceLineNumber! < total.lineNumber,
              )
              .length;
      if (count != total.expectedCount) {
        issues.add(
          BulkParseIssue(
            lineNumber: total.lineNumber,
            rawLine: 'Toplam ${total.expectedCount}',
            code: 'declared_total_mismatch',
            message:
                '${total.teamName} ${total.activityType}: bildirilen ${total.expectedCount} kişi, ayrıştırılan $count kişi. Kaynak listeyi tamamlayıp yeniden ayrıştırın.',
            severity: BulkParseIssueSeverity.error,
          ),
        );
      }
      previousLines[key] = total.lineNumber;
    }
    return issues;
  }
}

class BulkImportDuplicate {
  const BulkImportDuplicate({
    required this.personnelId,
    required this.personnelName,
    required this.teamId,
    required this.date,
    required this.assignments,
  });

  final int personnelId;
  final String personnelName;
  final int? teamId;
  final String date;
  final List<String> assignments;
}

class BulkImportPreparation {
  const BulkImportPreparation({
    required this.requests,
    required this.duplicates,
  });

  final List<ActivityCreateRequest> requests;
  final List<BulkImportDuplicate> duplicates;

  bool get canSave => requests.isNotEmpty && duplicates.isEmpty;
}

class BulkActivityImportPreparer {
  const BulkActivityImportPreparer._();

  static ({List<ParsedActivityBlock> blocks, int removedCount})
  deduplicateSameDuty(List<ParsedActivityBlock> blocks) {
    final seen = <String, ({int block, int person})>{};
    var removedCount = 0;
    final result = <ParsedActivityBlock>[];
    for (final block in blocks) {
      final personnel = <ParsedPersonnelItem>[];
      for (final person in block.personnelList) {
        final id = person.matchedPersonnelId;
        if (id == null) {
          personnel.add(person);
          continue;
        }
        final key =
            '${block.parsedDate}:'
            '${block.parsedActivityType.trim().toUpperCase()}:$id';
        final first = seen[key];
        if (first == null) {
          seen[key] = (block: result.length, person: personnel.length);
          personnel.add(
            person.copyWith(
              sourceTimeRanges:
                  {
                    ...person.sourceTimeRanges,
                    if (block.parsedTimeRange?.trim().isNotEmpty ?? false)
                      block.parsedTimeRange!.trim(),
                  }.toList(),
            ),
          );
        } else {
          final firstPeople =
              first.block == result.length
                  ? personnel
                  : List<ParsedPersonnelItem>.of(
                    result[first.block].personnelList,
                  );
          final original = firstPeople[first.person];
          firstPeople[first.person] = original.copyWith(
            sourceTimeRanges:
                {
                  ...original.sourceTimeRanges,
                  ...person.sourceTimeRanges,
                  if (block.parsedTimeRange?.trim().isNotEmpty ?? false)
                    block.parsedTimeRange!.trim(),
                }.toList(),
          );
          if (first.block != result.length) {
            result[first.block] = result[first.block].copyWith(
              personnelList: firstPeople,
            );
          }
          removedCount++;
        }
      }
      if (personnel.isNotEmpty) {
        result.add(block.copyWith(personnelList: personnel));
      }
    }
    return (blocks: result, removedCount: removedCount);
  }

  static BulkImportPreparation prepare(Iterable<ParsedActivityBlock> blocks) {
    final byDate = <String, List<ParsedActivityBlock>>{};
    for (final block in blocks) {
      byDate.putIfAbsent(block.parsedDate, () => []).add(block);
    }

    final requests = <ActivityCreateRequest>[];
    final duplicates = <BulkImportDuplicate>[];

    for (final entry in byDate.entries) {
      final occurrences =
          <
            int,
            List<({ParsedActivityBlock block, ParsedPersonnelItem person})>
          >{};
      for (final block in entry.value) {
        for (final person in block.personnelList) {
          final id = person.matchedPersonnelId;
          if (id == null) continue;
          occurrences.putIfAbsent(id, () => []).add((
            block: block,
            person: person,
          ));
        }
      }

      final uniqueOccurrences =
          <
            int,
            List<({ParsedActivityBlock block, ParsedPersonnelItem person})>
          >{};
      for (final occurrence in occurrences.entries) {
        final byDuty =
            <
              String,
              ({ParsedActivityBlock block, ParsedPersonnelItem person})
            >{};
        for (final item in occurrence.value) {
          final dutyKey = item.block.parsedActivityType.trim().toUpperCase();
          final previous = byDuty[dutyKey];
          final times = {
            ...?previous?.person.sourceTimeRanges,
            ...item.person.sourceTimeRanges,
            if (previous?.block.parsedTimeRange?.trim().isNotEmpty ?? false)
              previous!.block.parsedTimeRange!.trim(),
            if (item.block.parsedTimeRange?.trim().isNotEmpty ?? false)
              item.block.parsedTimeRange!.trim(),
          };
          byDuty[dutyKey] = (
            block: previous?.block ?? item.block,
            person: (previous?.person ?? item.person).copyWith(
              sourceTimeRanges: times.toList(),
            ),
          );
        }
        uniqueOccurrences[occurrence.key] = byDuty.values.toList();
      }

      for (final occurrence in uniqueOccurrences.entries.where(
        (entry) => entry.value.length > 1,
      )) {
        final first = occurrence.value.first.person;
        duplicates.add(
          BulkImportDuplicate(
            personnelId: occurrence.key,
            personnelName: first.matchedAdSoyad ?? first.rawName,
            teamId: first.matchedTimId,
            date: entry.key,
            assignments: occurrence.value
                .map((item) => _assignmentLabel(item.block))
                .toList(growable: false),
          ),
        );
      }

      final payloadByDuty = <String, List<PersonnelAssignmentInput>>{};
      final displayDutyByKey = <String, String>{};
      for (final occurrence in uniqueOccurrences.values) {
        if (occurrence.length != 1) continue;
        final item = occurrence.single;
        final duty = item.block.parsedActivityType.trim();
        if (duty.isEmpty) continue;
        final dutyKey = duty.toUpperCase();
        displayDutyByKey.putIfAbsent(dutyKey, () => duty);
        payloadByDuty
            .putIfAbsent(dutyKey, () => [])
            .add(
              PersonnelAssignmentInput(
                personnelId: item.person.matchedPersonnelId!,
                duty: duty,
                note:
                    'Görev Türü: $duty${item.person.sourceTimeRanges.isEmpty ? '' : ' (${item.person.sourceTimeRanges.join('; ')})'}',
                teamId: item.block.taskTeamId ?? item.person.matchedTimId,
              ),
            );
      }

      for (final payloadEntry in payloadByDuty.entries) {
        final activityName = displayDutyByKey[payloadEntry.key]!;
        requests.add(
          ActivityCreateRequest(
            faaliyetAdi: activityName,
            tarih: entry.key,
            olusturanKullanici: 'Admin (Toplu Aktarım)',
            personnelAssignments: payloadEntry.value,
          ),
        );
      }
    }

    return BulkImportPreparation(requests: requests, duplicates: duplicates);
  }

  static String _assignmentLabel(ParsedActivityBlock block) {
    final time = block.parsedTimeRange?.trim();
    return time == null || time.isEmpty
        ? block.parsedActivityType
        : '${block.parsedActivityType} ($time)';
  }
}
