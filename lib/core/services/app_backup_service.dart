import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/services/personnel_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBackupService {
  AppBackupService(this.db, {Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  final AppDatabase db;
  final Future<SharedPreferences> Function() _preferences;

  static const String format = 'nizam-full-backup';
  static const int backupVersion = 2;
  static const int maxBackupBytes = 50 * 1024 * 1024;
  static const int maxRecordsPerTable = 100000;

  static const _preferenceKeys = <String>{
    'temgundrap_documents_v1',
    'temgundrap_approver_defaults_v1',
    'bulk_import_keep_audit_text_enabled',
    'app_theme_mode',
  };

  static bool _isCardOrderKey(String key) {
    const prefix = 'activity_card_order_';
    if (!key.startsWith(prefix)) return false;
    final date = key.substring(prefix.length);
    final parsed = DateTime.tryParse(date);
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) &&
        parsed != null &&
        parsed.toIso8601String().split('T').first == date;
  }

  static Set<String> _savedPreferenceKeys(SharedPreferences prefs) => {
    ..._preferenceKeys,
    ...prefs.getKeys().where(_isCardOrderKey),
  };

  Future<String> exportBackupJson() async {
    final prefs = await _preferences();
    final usersList = await db.select(db.kullaniciTable).get();
    final squadsList = await db.select(db.timTable).get();
    final personnelList = await db.select(db.personelTable).get();
    final userIds = usersList.map((r) => r.id).toSet();
    final squadIds = squadsList.map((r) => r.id).toSet();
    final personnelIds = personnelList.map((r) => r.id).toSet();

    final payload = <String, Object?>{
      'databaseSchemaVersion': db.schemaVersion,
      'tables': <String, Object?>{
        'users':
            usersList
                .map((row) => row.timId != null && !squadIds.contains(row.timId!)
                    ? row.copyWith(timId: const Value(null))
                    : row)
                .map((row) => row.toJson())
                .toList(),
        'squads':
            squadsList
                .map((row) => row.timKomutaniId != null && !userIds.contains(row.timKomutaniId!)
                    ? row.copyWith(timKomutaniId: const Value(null))
                    : row)
                .map((row) => row.toJson())
                .toList(),
        'personnel':
            personnelList
                .map((row) => row.timId != null && !squadIds.contains(row.timId!)
                    ? row.copyWith(timId: const Value(null))
                    : row)
                .map((row) => row.toJson())
                .toList(),
        'activities':
            (await db.select(db.gunlukFaaliyetTable).get())
                .map((row) => row.toJson())
                .toList(),
        'assignments':
            (await db.select(db.faaliyetPersonelAtamaTable).get())
                .where((row) => personnelIds.contains(row.personelId))
                .map((row) => row.gorevTimId != null && !squadIds.contains(row.gorevTimId!)
                    ? row.copyWith(gorevTimId: const Value(null))
                    : row)
                .map((row) => row.toJson())
                .toList(),
        'reports':
            (await db.select(db.raporKayitTable).get())
                .where((row) => personnelIds.contains(row.personelId))
                .map((row) => row.toJson())
                .toList(),
        'membershipHistory':
            (await db.select(db.timUyelikGecmisiTable).get())
                .where((row) => personnelIds.contains(row.personelId))
                .map((row) => row.timId != null && !squadIds.contains(row.timId!)
                    ? row.copyWith(timId: const Value(null))
                    : row)
                .map((row) => row.toJson())
                .toList(),
        'aliases':
            (await db.select(db.personelIsimTakmaAdTable).get())
                .where((row) => personnelIds.contains(row.personelId))
                .map((row) => row.toJson())
                .toList(),
        'bulkImportHistory':
            (await db.select(db.topluAktarimGecmisiTable).get())
                .map((row) => row.toJson())
                .toList(),
      },
      'preferences': <String, Object?>{
        for (final key in _savedPreferenceKeys(prefs))
          if (prefs.containsKey(key)) key: prefs.get(key),
      },
    };
    final envelope = <String, Object?>{
      'format': format,
      'version': backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'checksum': computeCanonicalChecksum(payload),
      'payload': payload,
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  Future<AppBackupPreview> inspectBackupJson(String jsonString) async {
    final decoded = _decode(jsonString);
    if (decoded['format'] != format && decoded['version'] == 1) {
      final personnel = decoded['personnel'];
      final exportedAt = DateTime.tryParse(
        decoded['exportedAt']?.toString() ?? '',
      );
      return AppBackupPreview(
        exportedAt: exportedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        personnelCount: personnel is List<Object?> ? personnel.length : 0,
        activityCount: 0,
        assignmentCount: 0,
        temgundrapDocumentCount: 0,
        legacy: true,
      );
    }
    final parsed = _parseAndValidate(jsonString);
    return parsed.preview;
  }

  Future<AppBackupRestoreResult> restoreBackupJson(String jsonString) async {
    final decoded = _decode(jsonString);
    if (decoded['format'] != format && decoded['version'] == 1) {
      final count = await PersonnelBackupService(
        db,
      ).importBackupJson(jsonString);
      return AppBackupRestoreResult(legacy: true, importedPersonnel: count);
    }

    final parsed = _parseAndValidate(jsonString);
    final prefs = await _preferences();
    final oldPreferences = <String, Object?>{
      for (final key in _savedPreferenceKeys(prefs))
        if (prefs.containsKey(key)) key: prefs.get(key),
    };

    try {
      await _replacePreferences(prefs, parsed.preferences);
      await db.transaction(() => _replaceDatabase(parsed));
    } on Object {
      await _replacePreferences(prefs, oldPreferences);
      rethrow;
    }

    return AppBackupRestoreResult(
      legacy: false,
      importedPersonnel: parsed.personnel.length,
      importedActivities: parsed.activities.length,
      importedTemgundrapDocuments: parsed.preview.temgundrapDocumentCount,
    );
  }

  _ParsedBackup _parseAndValidate(String input) {
    final decoded = _decode(input);
    if (decoded['format'] != format || decoded['version'] != backupVersion) {
      throw const FormatException(
        'Bu yedek biçimi veya sürümü desteklenmiyor.',
      );
    }
    final payload = _object(decoded['payload'], 'payload');
    final expectedChecksum = _string(decoded['checksum'], 'checksum');
    final canonicalChecksum = computeCanonicalChecksum(payload);
    final legacyChecksum =
        sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    if (expectedChecksum != canonicalChecksum &&
        expectedChecksum != legacyChecksum) {
      throw const FormatException(
        'Yedek dosyasının bütünlük kontrolü başarısız. Dosya bozulmuş olabilir.',
      );
    }

    final tables = _object(payload['tables'], 'tables');
    final rawUsers = _rows(tables, 'users', KullaniciTableData.fromJson);
    final rawSquads = _rows(tables, 'squads', TimTableData.fromJson);
    final rawPersonnel = _rows(
      tables,
      'personnel',
      (json) =>
          PersonelTableData.fromJson({'aktif': true, 'isDemo': false, ...json}),
    );
    final activities = _rows(
      tables,
      'activities',
      GunlukFaaliyetTableData.fromJson,
    );
    final rawAssignments = _rows(
      tables,
      'assignments',
      FaaliyetPersonelAtamaTableData.fromJson,
    );
    final rawReports = _rows(tables, 'reports', RaporKayitTableData.fromJson);
    final rawMembershipHistory = _rows(
      tables,
      'membershipHistory',
      TimUyelikGecmisiTableData.fromJson,
    );
    final rawAliases = _rows(
      tables,
      'aliases',
      PersonelIsimTakmaAdTableData.fromJson,
    );
    final bulkImportHistory = _rows(
      tables,
      'bulkImportHistory',
      TopluAktarimGecmisiTableData.fromJson,
    );
    final rawPreferences = _object(payload['preferences'], 'preferences');
    final preferences = _sanitizeAndValidatePreferences(rawPreferences);

    final userIds = rawUsers.map((row) => row.id).toSet();
    final squadIds = rawSquads.map((row) => row.id).toSet();
    final personnelIds = rawPersonnel.map((row) => row.id).toSet();
    final activityIds = activities.map((row) => row.id).toSet();
    _requireUniqueIds('users', rawUsers.map((row) => row.id));
    _requireUniqueIds('squads', rawSquads.map((row) => row.id));
    _requireUniqueIds('personnel', rawPersonnel.map((row) => row.id));
    _requireUniqueIds('activities', activities.map((row) => row.id));
    _requireUniqueIds('assignments', rawAssignments.map((row) => row.id));
    _requireUniqueIds('reports', rawReports.map((row) => row.id));
    _requireUniqueIds(
      'membershipHistory',
      rawMembershipHistory.map((row) => row.id),
    );
    _requireUniqueIds('aliases', rawAliases.map((row) => row.id));
    _requireUniqueIds(
      'bulkImportHistory',
      bulkImportHistory.map((row) => row.id),
    );

    _requireReferences(
      rawAssignments.map((row) => row.faaliyetId),
      activityIds,
      'Faaliyet-atama bağlantısı',
    );
    _requireReferences(
      rawAssignments.map((row) => row.personelId),
      personnelIds,
      'Personel-atama bağlantısı',
    );

    // Otomatik güvenli temizleme (Sanitization):
    // Silinmiş personele ait yetim geçmiş kayıtları veya silinmiş time ait referanslar
    // geri yüklemeyi çökertmemek için güvenli şekilde temizlenir ve sanitize edilir.
    final users = rawUsers
        .map((row) => row.timId != null && !squadIds.contains(row.timId!)
            ? row.copyWith(timId: const Value(null))
            : row)
        .toList();
    final squads = rawSquads
        .map((row) => row.timKomutaniId != null && !userIds.contains(row.timKomutaniId!)
            ? row.copyWith(timKomutaniId: const Value(null))
            : row)
        .toList();
    final personnel = rawPersonnel
        .map((row) => row.timId != null && !squadIds.contains(row.timId!)
            ? row.copyWith(timId: const Value(null))
            : row)
        .toList();
    final assignments = rawAssignments
        .map((row) => row.gorevTimId != null && !squadIds.contains(row.gorevTimId!)
            ? row.copyWith(gorevTimId: const Value(null))
            : row)
        .toList();
    final reports = rawReports
        .where((row) => personnelIds.contains(row.personelId))
        .toList();
    final aliases = rawAliases
        .where((row) => personnelIds.contains(row.personelId))
        .toList();
    final membershipHistory = rawMembershipHistory
        .where((row) => personnelIds.contains(row.personelId))
        .map((row) => row.timId != null && !squadIds.contains(row.timId!)
            ? row.copyWith(timId: const Value(null))
            : row)
        .toList();

    final exportedAt = DateTime.tryParse(
      _string(decoded['exportedAt'], 'exportedAt'),
    );
    if (exportedAt == null) {
      throw const FormatException('Yedek tarihi geçersiz.');
    }
    return _ParsedBackup(
      users: users,
      squads: squads,
      personnel: personnel,
      activities: activities,
      assignments: assignments,
      reports: reports,
      membershipHistory: membershipHistory,
      aliases: aliases,
      bulkImportHistory: bulkImportHistory,
      preferences: preferences,
      preview: AppBackupPreview(
        exportedAt: exportedAt,
        personnelCount: personnel.length,
        activityCount: activities.length,
        assignmentCount: assignments.length,
        temgundrapDocumentCount: _temgundrapCount(preferences),
      ),
    );
  }

  Future<void> _replaceDatabase(_ParsedBackup data) async {
    await db.delete(db.faaliyetPersonelAtamaTable).go();
    await db.delete(db.raporKayitTable).go();
    await db.delete(db.personelIsimTakmaAdTable).go();
    await db.delete(db.timUyelikGecmisiTable).go();
    await db.delete(db.gunlukFaaliyetTable).go();
    await db.delete(db.topluAktarimGecmisiTable).go();
    await db.delete(db.personelTable).go();
    await db
        .update(db.kullaniciTable)
        .write(const KullaniciTableCompanion(timId: Value(null)));
    await db
        .update(db.timTable)
        .write(const TimTableCompanion(timKomutaniId: Value(null)));
    await db.delete(db.timTable).go();
    await db.delete(db.kullaniciTable).go();

    for (final row in data.users) {
      await db
          .into(db.kullaniciTable)
          .insert(row.copyWith(timId: const Value(null)));
    }
    for (final row in data.squads) {
      await db
          .into(db.timTable)
          .insert(row.copyWith(timKomutaniId: const Value(null)));
    }
    for (final row in data.users.where((row) => row.timId != null)) {
      await (db.update(db.kullaniciTable)..where(
        (table) => table.id.equals(row.id),
      )).write(KullaniciTableCompanion(timId: Value(row.timId)));
    }
    for (final row in data.squads.where((row) => row.timKomutaniId != null)) {
      await (db.update(db.timTable)..where(
        (table) => table.id.equals(row.id),
      )).write(TimTableCompanion(timKomutaniId: Value(row.timKomutaniId)));
    }
    await db.batch((batch) {
      batch.insertAll(db.personelTable, data.personnel);
      batch.insertAll(db.gunlukFaaliyetTable, data.activities);
      batch.insertAll(db.faaliyetPersonelAtamaTable, data.assignments);
      batch.insertAll(db.raporKayitTable, data.reports);
      batch.insertAll(db.timUyelikGecmisiTable, data.membershipHistory);
      batch.insertAll(db.personelIsimTakmaAdTable, data.aliases);
      batch.insertAll(db.topluAktarimGecmisiTable, data.bulkImportHistory);
    });
    await db.backfillTaskTeamsFromHistory();
  }

  Future<void> _replacePreferences(
    SharedPreferences prefs,
    Map<String, Object?> values,
  ) async {
    for (final key in {..._savedPreferenceKeys(prefs), ...values.keys}) {
      if (prefs.containsKey(key) && !await prefs.remove(key)) {
        throw StateError('$key tercihi temizlenemedi.');
      }
    }
    for (final entry in values.entries) {
      final value = entry.value;
      final saved = switch (value) {
        final bool v => prefs.setBool(entry.key, v),
        final int v => prefs.setInt(entry.key, v),
        final double v => prefs.setDouble(entry.key, v),
        final String v => prefs.setString(entry.key, v),
        final List<Object?> v => prefs.setStringList(
          entry.key,
          v.map((item) => item as String).toList(),
        ),
        _ => throw FormatException('${entry.key} tercihi geçersiz.'),
      };
      if (!await saved) {
        throw StateError('${entry.key} tercihi kaydedilemedi.');
      }
    }
  }

  Map<String, Object?> _decode(String rawInput) {
    final input = _sanitizeInput(rawInput);
    if (utf8.encode(input).length > maxBackupBytes) {
      throw const FormatException('Yedek dosyası izin verilen boyutu aşıyor.');
    }
    try {
      final decoded = jsonDecode(input);
      return _object(decoded, 'backup');
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Yedek dosyası geçerli JSON içermiyor.');
    }
  }

  static String _sanitizeInput(String rawInput) {
    var cleaned = rawInput.trim();
    if (cleaned.startsWith('\uFEFF')) {
      cleaned = cleaned.substring(1).trim();
    }
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.length >= 2 &&
          lines.first.startsWith('```') &&
          lines.last.trim() == '```') {
        cleaned = lines.sublist(1, lines.length - 1).join('\n').trim();
      }
    }
    if (cleaned.startsWith('"') &&
        cleaned.endsWith('"') &&
        cleaned.length > 2) {
      try {
        final unescaped = jsonDecode(cleaned);
        if (unescaped is String) {
          cleaned = unescaped.trim();
        }
      } catch (_) {}
    }
    return cleaned;
  }

  static Object? _canonicalize(Object? object) {
    if (object is Map) {
      final sortedKeys = object.keys.map((k) => k.toString()).toList()..sort();
      final sortedMap = <String, Object?>{};
      for (final key in sortedKeys) {
        sortedMap[key] = _canonicalize(object[key]);
      }
      return sortedMap;
    } else if (object is List) {
      return object.map((e) => _canonicalize(e)).toList();
    } else {
      return object;
    }
  }

  static String computeCanonicalChecksum(Map<String, Object?> payload) {
    final canonical = _canonicalize(payload);
    final jsonStr = jsonEncode(canonical);
    return sha256.convert(utf8.encode(jsonStr)).toString();
  }

  static String computeLegacyChecksum(Map<String, Object?> payload) {
    return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
  }

  Map<String, Object?> _object(Object? value, String field) {
    if (value is! Map<Object?, Object?>) {
      throw FormatException('$field alanı geçersiz.');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  String _string(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FormatException('$field alanı geçersiz.');
    }
    return value;
  }

  List<T> _rows<T>(
    Map<String, Object?> tables,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = tables[key];
    if (raw is! List<Object?> || raw.length > maxRecordsPerTable) {
      throw FormatException('$key kayıtları geçersiz veya çok büyük.');
    }
    try {
      return raw
          .map((item) => fromJson(_object(item, key).cast<String, dynamic>()))
          .toList(growable: false);
    } on FormatException {
      rethrow;
    } on Object {
      throw FormatException('$key kayıtlarından biri geçersiz.');
    }
  }

  Map<String, Object?> _sanitizeAndValidatePreferences(
    Map<String, Object?> preferences,
  ) {
    final sanitized = <String, Object?>{
      for (final entry in preferences.entries)
        if (_preferenceKeys.contains(entry.key) || _isCardOrderKey(entry.key))
          entry.key: entry.value,
    };
    _validatePreferences(sanitized);
    return sanitized;
  }

  void _validatePreferences(Map<String, Object?> preferences) {
    for (final entry in preferences.entries) {
      final valid =
          entry.value is bool ||
          entry.value is int ||
          entry.value is double ||
          entry.value is String ||
          (entry.value is List<Object?> &&
              (entry.value as List<Object?>).every((item) => item is String));
      if (!valid) throw FormatException('${entry.key} tercihi geçersiz.');
    }
    final defaults = preferences['temgundrap_approver_defaults_v1'];
    if (defaults != null) {
      try {
        final decoded = jsonDecode(defaults as String) as Map<String, dynamic>;
        if (decoded.values.any((value) => value is! String)) {
          throw const FormatException();
        }
      } catch (_) {
        throw const FormatException('Onaylayan varsayılanları geçersiz.');
      }
    }
    for (final entry in preferences.entries.where(
      (entry) => _isCardOrderKey(entry.key),
    )) {
      final value = entry.value;
      if (value is! List<Object?> ||
          value.any((id) => id is! String || int.tryParse(id) == null)) {
        throw const FormatException('Faaliyet kart sıralaması geçersiz.');
      }
    }
    _temgundrapCount(preferences);
  }

  int _temgundrapCount(Map<String, Object?> preferences) {
    final raw = preferences['temgundrap_documents_v1'];
    if (raw == null) return 0;
    if (raw is! String) {
      throw const FormatException('TEMGÜNDRAP verisi geçersiz.');
    }
    try {
      final documents = jsonDecode(raw);
      if (documents is! List<Object?>) {
        throw const FormatException('TEMGÜNDRAP verisi geçersiz.');
      }
      return documents.length;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('TEMGÜNDRAP verisi geçersiz.');
    }
  }

  void _requireUniqueIds(String table, Iterable<int> ids) {
    final list = ids.toList();
    if (list.toSet().length != list.length) {
      throw FormatException('$table tablosunda yinelenen kimlik var.');
    }
  }

  void _requireReferences(
    Iterable<int> references,
    Set<int> validIds,
    String label,
  ) {
    if (references.any((id) => !validIds.contains(id))) {
      throw FormatException('$label yedekte eksik bir kayda işaret ediyor.');
    }
  }
}

class AppBackupPreview {
  const AppBackupPreview({
    required this.exportedAt,
    required this.personnelCount,
    required this.activityCount,
    required this.assignmentCount,
    required this.temgundrapDocumentCount,
    this.legacy = false,
  });

  final DateTime exportedAt;
  final int personnelCount;
  final int activityCount;
  final int assignmentCount;
  final int temgundrapDocumentCount;
  final bool legacy;
}

class AppBackupRestoreResult {
  const AppBackupRestoreResult({
    required this.legacy,
    required this.importedPersonnel,
    this.importedActivities = 0,
    this.importedTemgundrapDocuments = 0,
  });

  final bool legacy;
  final int importedPersonnel;
  final int importedActivities;
  final int importedTemgundrapDocuments;
}

class _ParsedBackup {
  const _ParsedBackup({
    required this.users,
    required this.squads,
    required this.personnel,
    required this.activities,
    required this.assignments,
    required this.reports,
    required this.membershipHistory,
    required this.aliases,
    required this.bulkImportHistory,
    required this.preferences,
    required this.preview,
  });

  final List<KullaniciTableData> users;
  final List<TimTableData> squads;
  final List<PersonelTableData> personnel;
  final List<GunlukFaaliyetTableData> activities;
  final List<FaaliyetPersonelAtamaTableData> assignments;
  final List<RaporKayitTableData> reports;
  final List<TimUyelikGecmisiTableData> membershipHistory;
  final List<PersonelIsimTakmaAdTableData> aliases;
  final List<TopluAktarimGecmisiTableData> bulkImportHistory;
  final Map<String, Object?> preferences;
  final AppBackupPreview preview;
}
