import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';

class PersonnelBackupService {
  PersonnelBackupService(this.db);
  final AppDatabase db;

  static const int backupVersion = 1;
  static const int maxBackupBytes = 2 * 1024 * 1024;
  static const int maxSquadCount = 1000;
  static const int maxPersonnelCount = 10000;
  static const int maxTextLength = 250;

  /// Export all personnel and squads into JSON backup string
  Future<String> exportBackupJson() async {
    final personnelList = await db.select(db.personelTable).get();
    final timList = await db.select(db.timTable).get();
    final aliases = await db.select(db.personelIsimTakmaAdTable).get();

    final data = {
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'squads': timList
          .map(
            (t) => {
              'id': t.id,
              'timAdi': t.timAdi,
              'olusturmaTarihi': t.olusturmaTarihi,
            },
          )
          .toList(),
      'personnel': personnelList
          .map(
            (p) => {
              'id': p.id,
              'adSoyad': p.adSoyad,
              'rutbe': p.rutbe,
              'birlik': p.birlik,
              'telefon': p.telefon,
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
    if (squads.length > maxSquadCount ||
        personnel.length > maxPersonnelCount ||
        aliases.length > maxPersonnelCount * 5) {
      throw const FormatException('Yedek çok fazla kayıt içeriyor.');
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
                olusturmaTarihi: _readString(
                  squad,
                  'olusturmaTarihi',
                  fallback: DateTime.now().toIso8601String(),
                ),
              ),
            );
        squadMap[timAdi.toLowerCase()] = newSquadId;
      }

      // 2. Restore Personnel
      final existingPersonnel = await db.select(db.personelTable).get();
      final personnelByKey = {
        for (final p in existingPersonnel)
          '${p.rutbe}_${p.adSoyad}'.toLowerCase(): p.id,
      };

      for (final p in personnel) {
        final adSoyad = _readString(p, 'adSoyad');
        final rutbe = _readString(p, 'rutbe', fallback: 'J.Uzm.Çvş.');
        final birlik = _readString(p, 'birlik', fallback: '1.J.KÖK.Tug.K.lığı');
        final key = '${rutbe}_$adSoyad'.toLowerCase();

        if (adSoyad.isNotEmpty && !personnelByKey.containsKey(key)) {
          int? timId;
          final timIdVal = _readNullableInt(p, 'timId');
          if (timIdVal != null) {
            // Find squad name if present
            final squadObj = _findSquadBySourceId(squads, timIdVal);
            if (squadObj != null) {
              final squadName = _readString(squadObj, 'timAdi').toLowerCase();
              timId = squadMap[squadName];
            }
          }

          final newPersonnelId = await db.into(db.personelTable).insert(
                PersonelTableCompanion.insert(
                  adSoyad: adSoyad,
                  rutbe: rutbe,
                  birlik: birlik,
                  telefon: Value(
                    _readString(p, 'telefon').trim().isEmpty
                        ? null
                        : _readString(p, 'telefon').trim(),
                  ),
                  timId: Value(timId),
                  kayitTarihi: _readString(
                    p,
                    'kayitTarihi',
                    fallback: DateTime.now().toIso8601String(),
                  ),
                ),
              );
          personnelByKey[key] = newPersonnelId;
          importedCount++;
        }
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

  Map<String, Object?>? _findSquadBySourceId(
    List<Map<String, Object?>> squads,
    int sourceId,
  ) {
    for (final squad in squads) {
      if (_readNullableInt(squad, 'id') == sourceId) {
        return squad;
      }
    }

    return null;
  }
}
