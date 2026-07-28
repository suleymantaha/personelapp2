import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

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

      for (final occurrence
          in occurrences.entries.where((entry) => entry.value.length > 1)) {
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

      final payload = <Map<String, dynamic>>[];
      for (final occurrence in occurrences.values) {
        if (occurrence.length != 1) continue;
        final item = occurrence.single;
        final time = item.block.parsedTimeRange?.trim();
        final note = [
          'Görev Türü: ${item.block.parsedActivityType}',
          if (time != null && time.isNotEmpty) 'Saat: $time',
        ].join(' | ');
        payload.add({
          'personelId': item.person.matchedPersonnelId,
          'gorevVeyaIzin': item.block.parsedActivityType,
          'aciklama': note,
        });
      }

      if (payload.isNotEmpty) {
        requests.add(
          ActivityCreateRequest(
            faaliyetAdi: 'Günlük Tüm Faaliyetler',
            tarih: entry.key,
            olusturanKullanici: 'Admin (Toplu Aktarım)',
            personnelAssignments: payload,
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
