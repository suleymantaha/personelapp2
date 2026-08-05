import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

class BulkImportLearningService {
  BulkImportLearningService(this.database);

  final AppDatabase database;

  static String normalizeName(String input) => input
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<Map<String, int>> loadAliases() async {
    final rows = await database.select(database.personelIsimTakmaAdTable).get();
    return {
      for (final row in rows) row.normalizeTakmaAd: row.personelId,
    };
  }

  Future<void> rememberAlias({
    required String rawName,
    required int personnelId,
  }) async {
    final normalized = normalizeName(rawName);
    if (normalized.isEmpty) return;
    final existing = await (database.select(
      database.personelIsimTakmaAdTable,
    )..where((table) => table.normalizeTakmaAd.equals(normalized)))
        .getSingleOrNull();
    if (existing == null) {
      await database.into(database.personelIsimTakmaAdTable).insert(
            PersonelIsimTakmaAdTableCompanion.insert(
              normalizeTakmaAd: normalized,
              gorunenTakmaAd: rawName.trim(),
              personelId: personnelId,
              kayitTarihi: DateTime.now().toIso8601String(),
            ),
          );
      return;
    }
    await (database.update(database.personelIsimTakmaAdTable)
          ..where((table) => table.id.equals(existing.id)))
        .write(
      PersonelIsimTakmaAdTableCompanion(
        gorunenTakmaAd: Value(rawName.trim()),
        personelId: Value(personnelId),
        kayitTarihi: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> rememberAliases(
    Iterable<({String rawName, int personnelId})> pairs,
  ) async {
    final uniqueMap = <String, ({String rawName, int personnelId})>{};
    for (final pair in pairs) {
      final normalized = normalizeName(pair.rawName);
      if (normalized.isNotEmpty) {
        uniqueMap[normalized] = (
          rawName: pair.rawName.trim(),
          personnelId: pair.personnelId,
        );
      }
    }
    for (final entry in uniqueMap.entries) {
      await rememberAlias(
        rawName: entry.value.rawName,
        personnelId: entry.value.personnelId,
      );
    }
  }

  Future<List<LearnedAliasItem>> getAliasList() async {
    final query = database.select(database.personelIsimTakmaAdTable).join([
      innerJoin(
        database.personelTable,
        database.personelTable.id.equalsExp(
          database.personelIsimTakmaAdTable.personelId,
        ),
      ),
    ]);
    final rows = await query.get();
    return rows.map((row) {
      final alias = row.readTable(database.personelIsimTakmaAdTable);
      final person = row.readTable(database.personelTable);
      return LearnedAliasItem(
        id: alias.id,
        normalizeTakmaAd: alias.normalizeTakmaAd,
        gorunenTakmaAd: alias.gorunenTakmaAd,
        personnelId: alias.personelId,
        personelAdSoyad: person.adSoyad,
        personelRutbe: person.rutbe,
        kayitTarihi: alias.kayitTarihi,
      );
    }).toList();
  }

  Future<void> deleteAlias(int aliasId) async {
    await (database.delete(database.personelIsimTakmaAdTable)
          ..where((table) => table.id.equals(aliasId)))
        .go();
  }

  static String fingerprint(Iterable<ParsedActivityBlock> blocks) {
    final assignments = <String>{};
    for (final block in blocks) {
      for (final person in block.personnelList) {
        final personnelId = person.matchedPersonnelId;
        if (personnelId == null) continue;
        assignments.add(
          '${block.parsedDate}|'
          '${block.parsedActivityType.trim().toUpperCase()}|$personnelId',
        );
      }
    }
    final canonical = assignments.toList()..sort();
    return sha256.convert(utf8.encode(canonical.join('\n'))).toString();
  }

  Future<int> countActiveAssignments(
    Iterable<ParsedActivityBlock> blocks,
  ) async {
    final query = database.select(database.faaliyetPersonelAtamaTable).join([
      innerJoin(
        database.gunlukFaaliyetTable,
        database.gunlukFaaliyetTable.id.equalsExp(
          database.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ]);
    final rows = await query.get();

    var activeCount = 0;
    for (final block in blocks) {
      for (final person in block.personnelList) {
        final pId = person.matchedPersonnelId;
        if (pId == null) continue;
        final match = rows.any((row) {
          final activity = row.readTable(database.gunlukFaaliyetTable);
          final assignment = row.readTable(database.faaliyetPersonelAtamaTable);
          return activity.tarih == block.parsedDate &&
              assignment.personelId == pId &&
              assignment.gorevVeyaIzin.trim().toUpperCase() ==
                  block.parsedActivityType.trim().toUpperCase();
        });
        if (match) activeCount++;
      }
    }
    return activeCount;
  }

  Future<void> deleteImportRecord(String fingerprint) async {
    await (database.delete(database.topluAktarimGecmisiTable)
          ..where((table) => table.parmakIzi.equals(fingerprint)))
        .go();
  }

  Future<TopluAktarimGecmisiTableData?> findImport(String fingerprint) =>
      (database.select(database.topluAktarimGecmisiTable)
            ..where((table) => table.parmakIzi.equals(fingerprint)))
          .getSingleOrNull();

  Future<void> recordImport({
    required String fingerprint,
    required Iterable<ParsedActivityBlock> blocks,
    required String actor,
    String? rawText,
  }) async {
    final dates = blocks.map((block) => block.parsedDate).toSet().toList()
      ..sort();
    final personnel = <int>{};
    for (final block in blocks) {
      personnel.addAll(
        block.personnelList
            .map((person) => person.matchedPersonnelId)
            .whereType<int>(),
      );
    }
    final record = TopluAktarimGecmisiTableCompanion.insert(
      parmakIzi: fingerprint,
      tarihler: dates.join(', '),
      blokSayisi: blocks.length,
      personelSayisi: personnel.length,
      aktaranKullanici: actor,
      kayitTarihi: DateTime.now().toIso8601String(),
      hamMetin: Value(rawText),
    );
    await database.into(database.topluAktarimGecmisiTable).insert(
          record,
          onConflict: DoUpdate(
            (_) => record,
            target: [database.topluAktarimGecmisiTable.parmakIzi],
          ),
        );
  }
}

class LearnedAliasItem {
  final int id;
  final String normalizeTakmaAd;
  final String gorunenTakmaAd;
  final int personnelId;
  final String personelAdSoyad;
  final String? personelRutbe;
  final String kayitTarihi;

  const LearnedAliasItem({
    required this.id,
    required this.normalizeTakmaAd,
    required this.gorunenTakmaAd,
    required this.personnelId,
    required this.personelAdSoyad,
    this.personelRutbe,
    required this.kayitTarihi,
  });
}
