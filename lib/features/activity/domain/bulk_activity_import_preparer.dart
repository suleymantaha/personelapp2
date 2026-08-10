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
    ) matchBlocks,
  }) async {
    final parseResult = BulkTextParser.parse(
      rawText,
      defaultDate: defaultDate,
    );
    final matchedBlocks = await matchBlocks(parseResult.blocks);
    final deduplicated =
        BulkActivityImportPreparer.deduplicateSameDuty(matchedBlocks);

    return BulkActivityImportDraft(
      blocks: List<ParsedActivityBlock>.unmodifiable(deduplicated.blocks),
      issues: List<BulkParseIssue>.unmodifiable(parseResult.issues),
      deduplicatedPersonnelCount: deduplicated.removedCount,
      ignoredLineCount: parseResult.ignoredLineCount,
      declaredTotals:
          List<BulkDeclaredTotal>.unmodifiable(parseResult.declaredTotals),
    );
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

  static ({
    List<ParsedActivityBlock> blocks,
    int removedCount,
  }) deduplicateSameDuty(List<ParsedActivityBlock> blocks) {
    final seen = <String>{};
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
        final key = '${block.parsedDate}:'
            '${block.parsedActivityType.trim().toUpperCase()}:$id';
        if (seen.add(key)) {
          personnel.add(person);
        } else {
          removedCount++;
        }
      }
      if (personnel.isNotEmpty) {
        result.add(block.copyWith(personnelList: personnel));
      }
    }
    return (blocks: result, removedCount: removedCount);
  }

  static BulkImportPreparation prepare(
    Iterable<ParsedActivityBlock> blocks,
  ) {
    final byDate = <String, List<ParsedActivityBlock>>{};
    for (final block in blocks) {
      byDate.putIfAbsent(block.parsedDate, () => []).add(block);
    }

    final requests = <ActivityCreateRequest>[];
    final duplicates = <BulkImportDuplicate>[];

    for (final entry in byDate.entries) {
      final occurrences = <int,
          List<
              ({
                ParsedActivityBlock block,
                ParsedPersonnelItem person,
              })>>{};
      for (final block in entry.value) {
        for (final person in block.personnelList) {
          final id = person.matchedPersonnelId;
          if (id == null) continue;
          occurrences
              .putIfAbsent(id, () => [])
              .add((block: block, person: person));
        }
      }

      final uniqueOccurrences = <int,
          List<
              ({
                ParsedActivityBlock block,
                ParsedPersonnelItem person,
              })>>{};
      for (final occurrence in occurrences.entries) {
        final byDuty = <String,
            ({
          ParsedActivityBlock block,
          ParsedPersonnelItem person,
        })>{};
        for (final item in occurrence.value) {
          byDuty.putIfAbsent(
            item.block.parsedActivityType.trim().toUpperCase(),
            () => item,
          );
        }
        uniqueOccurrences[occurrence.key] = byDuty.values.toList();
      }

      for (final occurrence in uniqueOccurrences.entries
          .where((entry) => entry.value.length > 1)) {
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
        payloadByDuty.putIfAbsent(dutyKey, () => []).add(
              PersonnelAssignmentInput(
                personnelId: item.person.matchedPersonnelId!,
                duty: duty,
                note: 'Görev Türü: $duty',
                teamId: item.person.matchedTimId,
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

    return BulkImportPreparation(
      requests: requests,
      duplicates: duplicates,
    );
  }

  static String _assignmentLabel(ParsedActivityBlock block) {
    final time = block.parsedTimeRange?.trim();
    return time == null || time.isEmpty
        ? block.parsedActivityType
        : '${block.parsedActivityType} ($time)';
  }
}
