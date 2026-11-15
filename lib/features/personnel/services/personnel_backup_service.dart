import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/task_team_history.dart';

class PersonnelBackupService {
  PersonnelBackupService(this.db);
  final AppDatabase db;

  static const int backupVersion = 1;
  static const int maxBackupBytes = 2 * 1024 * 1024;
  static const int maxSquadCount = 1000;
  static const int maxPersonnelCount = 10000;
  static const int maxTextLength = 250;

  /// Export all personnel and squads into JSON backup string
  Future<String> exportBackupJson() => db.transaction(_exportBackupJson);

  Future<String> _exportBackupJson() async {
    final personnelList = await db.select(db.personelTable).get();
    final timList = await db.select(db.timTable).get();
    final aliases = await db.select(db.personelIsimTakmaAdTable).get();
    final membershipHistory = await db.select(db.timUyelikGecmisiTable).get();
    final personnelIds = personnelList.map((person) => person.id).toSet();

    final data = {
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'squads': timList
          .map(
            (t) => {
              'id': t.id,
              'timAdi': t.timAdi,
              'sortOrder': t.sortOrder,
              'olusturmaTarihi': t.olusturmaTarihi,
            },
          )
          .toList(),
      'personnel': personnelList
          .map(
            (p) => {
              'id': p.id,
              'adSoyad': p.adSoyad,
              'sortOrder': p.sortOrder,
              'rutbe': p.rutbe,
              'birlik': p.birlik,
              'telefon': p.telefon,
              'aktif': p.aktif,
              'isDemo': p.isDemo,
              'timId': p.timId,
              'kayitTarihi': p.kayitTarihi,
            },
          )
          .toList(),
      'aliases': aliases
          .map(
            (alias) => {
              'normalizeTakmaAd': alias.normalizeTakmaAd,
              'gorunenTakmaAd': alias.gorunenTakmaAd,
              'personelId': alias.personelId,
              'kayitTarihi': alias.kayitTarihi,
            },
          )
          .toList(),
      'membershipHistory': [
        for (final event in membershipHistory)
          if (personnelIds.contains(event.personelId)) event.toJson(),
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import personnel and squads from JSON string
  Future<int> importBackupJson(String jsonString) async {
    if (utf8.encode(jsonString).length > maxBackupBytes) {
      throw const FormatException('Yedek dosyası izin verilen boyutu aşıyor.');
    }
    final decoded = _decodeBackup(jsonString);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Yedek verisi beklenen JSON nesnesi formatında değil.',
      );
    }
    if (decoded['version'] != backupVersion) {
      throw const FormatException('Yedek sürümü desteklenmiyor.');
    }

    final squads = _readObjectList(decoded['squads'], fieldName: 'squads');
    final personnel = _readObjectList(
      decoded['personnel'],
      fieldName: 'personnel',
    );
    final aliases = decoded['aliases'] == null
        ? const <Map<String, Object?>>[]
        : _readObjectList(decoded['aliases'], fieldName: 'aliases');
    final membershipHistory = decoded['membershipHistory'] == null
        ? const <Map<String, Object?>>[]
        : _readObjectList(decoded['membershipHistory'],
            fieldName: 'membershipHistory');
    if (squads.length > maxSquadCount ||
        personnel.length > maxPersonnelCount ||
        aliases.length > maxPersonnelCount * 5 ||
        membershipHistory.length > maxPersonnelCount * 5) {
      throw const FormatException('Yedek çok fazla kayıt içeriyor.');
    }

    for (final record in [...squads, ...personnel]) {
      _readSortOrder(record);
    }
    final exportedAt = decoded['exportedAt'];
    final snapshotDay =
        exportedAt is String ? TaskTeamHistory.validDay(exportedAt) : null;
    final historyByPerson = <int, List<Map<String, Object?>>>{};
    for (final event in membershipHistory) {
      final personId = _readNullableInt(event, 'personelId');
      if (personId == null) {
        throw const FormatException(
            'Tim geçmişindeki personel kimliği geçersiz.');
      }
      (historyByPerson[personId] ??= []).add(event);
    }
    final sourcePersonnelCounts = <String, int>{};
    for (final person in personnel) {
      final key = _personnelKey(
        _readString(person, 'rutbe', fallback: 'J.Uzm.Çvş.'),
        _readString(person, 'adSoyad'),
      );
      sourcePersonnelCounts.update(key, (count) => count + 1,
          ifAbsent: () => 1);
    }
    var importedCount = 0;

    await db.transaction(() async {
      final existingSquads = await db.select(db.timTable).get();
      final squadMap = <String, int>{
        for (final s in existingSquads) s.timAdi.toLowerCase(): s.id,
      };

      // 1. Restore / Match Squads
      for (final squad in squads) {
        final timAdi = _readString(squad, 'timAdi');
        if (timAdi.isEmpty || squadMap.containsKey(timAdi.toLowerCase())) {
          continue;
        }

        final newSquadId = await db.into(db.timTable).insert(
              TimTableCompanion.insert(
                timAdi: timAdi,
                sortOrder: Value(_readSortOrder(squad)),
                olusturmaTarihi: _readString(
                  squad,
                  'olusturmaTarihi',
                  fallback: DateTime.now().toIso8601String(),
                ),
              ),
            );
        squadMap[timAdi.toLowerCase()] = newSquadId;
      }

      final targetSquadIds = <int, int>{};
      for (final squad in squads) {
        final sourceId = _readNullableInt(squad, 'id');
        final targetId = squadMap[_readString(squad, 'timAdi').toLowerCase()];
        if (sourceId != null && targetId != null) {
          targetSquadIds.putIfAbsent(sourceId, () => targetId);
        }
      }

      // 2. Restore Personnel
      final existingPersonnel = await db.select(db.personelTable).get();
      final existingByKey = <String, List<PersonelTableData>>{};
      for (final person in existingPersonnel) {
        final key = _personnelKey(person.rutbe, person.adSoyad);
        (existingByKey[key] ??= []).add(person);
      }
      final personnelByKey = existingByKey.map(
        (key, matches) => MapEntry(key, matches.last.id),
      );
      final restoredHistory = <TimUyelikGecmisiTableCompanion>[];

      for (final p in personnel) {
        final adSoyad = _readString(p, 'adSoyad');
        final rutbe = _readString(p, 'rutbe', fallback: 'J.Uzm.Çvş.');
        final birlik = _readString(p, 'birlik', fallback: '1.J.KÖK.Tug.K.lığı');
        final key = _personnelKey(rutbe, adSoyad);
        if (adSoyad.isEmpty) continue;

        final timId = targetSquadIds[_readNullableInt(p, 'timId')];
        final registeredAt = _readString(p, 'kayitTarihi');
        final registeredDay = TaskTeamHistory.validDay(registeredAt);
        final hasSnapshotTeam =
            p.containsKey('timId') && (p['timId'] == null || timId != null);
        final events = historyByPerson[_readNullableInt(p, 'id')];
        final baselineDay = snapshotDay != null &&
                registeredDay != null &&
                registeredDay.compareTo(snapshotDay) <= 0 &&
                p['aktif'] != false &&
                hasSnapshotTeam
            ? snapshotDay
            : null;

        final existing = existingByKey[key];
        if (personnelByKey.containsKey(key)) {
          if (existing != null &&
              existing.length == 1 &&
              sourcePersonnelCounts[key] == 1 &&
              registeredDay != null &&
              registeredDay ==
                  TaskTeamHistory.validDay(existing.single.kayitTarihi) &&
              existing.single.isDemo == (p['isDemo'] as bool? ?? false) &&
              (events != null || baselineDay != null)) {
            final person = existing.single;
            restoredHistory.addAll(await _historyBeforeLocalRecords(
              person,
              _backupHistory(
                  person.id, events, baselineDay, timId, targetSquadIds),
              matchesCurrentTeam: hasSnapshotTeam && timId == person.timId,
            ));
          }
          continue;
        }

        final newPersonnelId = await db.into(db.personelTable).insert(
              PersonelTableCompanion.insert(
                adSoyad: adSoyad,
                sortOrder: Value(_readSortOrder(p)),
                aktif: Value(p['aktif'] as bool? ?? true),
                isDemo: Value(p['isDemo'] as bool? ?? false),
                rutbe: rutbe,
                birlik: birlik,
                telefon: Value(
                  _readString(p, 'telefon').trim().isEmpty
                      ? null
                      : _readString(p, 'telefon').trim(),
                ),
                timId: Value(timId),
                kayitTarihi: p['kayitTarihi'] == null
                    ? DateTime.now().toIso8601String()
                    : registeredAt,
              ),
            );
        restoredHistory.addAll(_backupHistory(
            newPersonnelId, events, baselineDay, timId, targetSquadIds));
        personnelByKey[key] = newPersonnelId;
        importedCount++;
      }

      if (restoredHistory.isNotEmpty) {
        await db.batch((batch) =>
            batch.insertAll(db.timUyelikGecmisiTable, restoredHistory));
      }

      for (final alias in aliases) {
        final sourcePersonnelId = _readNullableInt(alias, 'personelId');
        if (sourcePersonnelId == null) continue;
        final sourcePersonnel = personnel
            .where(
              (item) => _readNullableInt(item, 'id') == sourcePersonnelId,
            )
            .firstOrNull;
        if (sourcePersonnel == null) continue;
        final key = '${_readString(sourcePersonnel, 'rutbe')}_'
                '${_readString(sourcePersonnel, 'adSoyad')}'
            .toLowerCase();
        final targetPersonnelId = personnelByKey[key];
        final normalized = _readString(alias, 'normalizeTakmaAd');
        final display = _readString(alias, 'gorunenTakmaAd');
        if (targetPersonnelId == null ||
            normalized.isEmpty ||
            display.isEmpty) {
          continue;
        }
        await db.into(db.personelIsimTakmaAdTable).insert(
              PersonelIsimTakmaAdTableCompanion.insert(
                normalizeTakmaAd: normalized,
                gorunenTakmaAd: display,
                personelId: targetPersonnelId,
                kayitTarihi: _readString(
                  alias,
                  'kayitTarihi',
                  fallback: DateTime.now().toIso8601String(),
                ),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });

    return importedCount;
  }

  int? _readSortOrder(Map<String, Object?> record) {
    final value = record['sortOrder'];
    if (value == null) return null;
    if (value is! int || value < 0) {
      throw const FormatException(
          'sortOrder negatif olmayan tam sayı olmalıdır.');
    }
    return value;
  }

  Object? _decodeBackup(String input) {
    var normalized = input.trim();
    if (normalized.startsWith('\uFEFF')) {
      normalized = normalized.substring(1).trimLeft();
    }

    if (normalized.startsWith('```') && normalized.endsWith('```')) {
      final firstLineEnd = normalized.indexOf('\n');
      if (firstLineEnd == -1) {
        throw const FormatException('Yedek kod bloğu boş.');
      }
      normalized =
          normalized.substring(firstLineEnd + 1, normalized.length - 3).trim();
    }

    Object? decoded;
    try {
      decoded = jsonDecode(normalized);
      if (decoded is String) {
        decoded = jsonDecode(decoded.trim());
      }
    } on FormatException {
      throw const FormatException(
        'Yedek metni geçerli JSON biçiminde değil. Metnin tamamını kopyalayın.',
      );
    }
    return decoded;
  }

  List<Map<String, Object?>> _readObjectList(
    Object? value, {
    required String fieldName,
  }) {
    if (value is! List) {
      throw FormatException('$fieldName alanı bir liste olmalıdır.');
    }
    if (value.any((item) => item is! Map<Object?, Object?>)) {
      throw FormatException('$fieldName alanında geçersiz kayıt var.');
    }

    return value
        .whereType<Map<Object?, Object?>>()
        .map<Map<String, Object?>>(
          (item) => item.map(
            (key, itemValue) => MapEntry(key.toString(), itemValue),
          ),
        )
        .toList(growable: false);
  }

  String _readString(
    Map<String, Object?> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key];
    if (value == null) return fallback;
    if (value is! String || value.length > maxTextLength) {
      throw FormatException('$key alanı geçersiz.');
    }
    return value;
  }

  int? _readNullableInt(Map<String, Object?> data, String key) {
    final value = data[key];

    return switch (value) {
      final int intValue => intValue,
      final String stringValue => int.tryParse(stringValue),
      _ => null,
    };
  }

  String _personnelKey(String rank, String name) =>
      '${rank}_$name'.toLowerCase();

  Iterable<TimUyelikGecmisiTableCompanion> _backupHistory(
    int personnelId,
    List<Map<String, Object?>>? events,
    String? baselineDay,
    int? currentTeamId,
    Map<int, int> targetSquadIds,
  ) sync* {
    if (events != null) {
      yield* events.map(
          (event) => _restoreHistoryEvent(event, personnelId, targetSquadIds));
    } else if (baselineDay != null) {
      // A legacy backup captured the current team on export day.
      yield TimUyelikGecmisiTableCompanion.insert(
        personelId: personnelId,
        timId: Value(currentTeamId),
        tarih: baselineDay,
        islem: currentTeamId == null ? 'çıkarıldı' : 'eklendi',
      );
    }
  }

  Future<Iterable<TimUyelikGecmisiTableCompanion>> _historyBeforeLocalRecords(
    PersonelTableData person,
    Iterable<TimUyelikGecmisiTableCompanion> backupHistory, {
    required bool matchesCurrentTeam,
  }) async {
    final localHistory = await (db.select(db.timUyelikGecmisiTable)
          ..where((event) => event.personelId.equals(person.id)))
        .get();
    if (localHistory.isEmpty) {
      return matchesCurrentTeam ? backupHistory : const [];
    }
    String? firstDay;
    for (final event in localHistory) {
      final day = TaskTeamHistory.validDay(event.tarih);
      if (day == null) return const [];
      if (firstDay == null || day.compareTo(firstDay) < 0) firstDay = day;
    }
    final cutoff = firstDay!;
    return backupHistory.where((event) {
      final day = TaskTeamHistory.validDay(event.tarih.value);
      return day != null && day.compareTo(cutoff) < 0;
    });
  }

  TimUyelikGecmisiTableCompanion _restoreHistoryEvent(
    Map<String, Object?> event,
    int personnelId,
    Map<int, int> targetSquadIds,
  ) {
    final date = _readString(event, 'tarih');
    final action = _readString(event, 'islem');
    final teamId = targetSquadIds[_readNullableInt(event, 'timId')];
    // Older personnel records can have an explicitly empty registration date.
    if ((event['tarih'] != '' && TaskTeamHistory.validDay(date) == null) ||
        (action != 'eklendi' && action != 'çıkarıldı') ||
        ((event['timId'] != null || action == 'eklendi') && teamId == null)) {
      throw const FormatException('Tim geçmişinde geçersiz kayıt var.');
    }
    return TimUyelikGecmisiTableCompanion.insert(
      personelId: personnelId,
      timId: Value(teamId),
      tarih: date,
      islem: action,
    );
  }
}
