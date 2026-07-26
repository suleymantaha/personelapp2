import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/database.dart';

class PersonnelBackupService {
  final AppDatabase db;

  PersonnelBackupService(this.db);

  /// Export all personnel and squads into JSON backup string
  Future<String> exportBackupJson() async {
    final personnelList = await db.select(db.personelTable).get();
    final timList = await db.select(db.timTable).get();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'squads': timList
          .map((t) => {
                'id': t.id,
                'timAdi': t.timAdi,
                'olusturmaTarihi': t.olusturmaTarihi,
              })
          .toList(),
      'personnel': personnelList
          .map((p) => {
                'id': p.id,
                'adSoyad': p.adSoyad,
                'rutbe': p.rutbe,
                'birlik': p.birlik,
                'timId': p.timId,
                'kayitTarihi': p.kayitTarihi,
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import personnel and squads from JSON string
  Future<int> importBackupJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> squads = data['squads'] ?? [];
    final List<dynamic> personnel = data['personnel'] ?? [];

    int importedCount = 0;

    await db.transaction(() async {
      final existingSquads = await db.select(db.timTable).get();
      final squadMap = {for (final s in existingSquads) s.timAdi.toLowerCase(): s.id};

      // 1. Restore / Match Squads
      for (final squad in squads) {
        final timAdi = squad['timAdi']?.toString() ?? '';
        if (timAdi.isNotEmpty && !squadMap.containsKey(timAdi.toLowerCase())) {
          final newSquadId = await db.into(db.timTable).insert(
                TimTableCompanion.insert(
                  timAdi: timAdi,
                  olusturmaTarihi: squad['olusturmaTarihi']?.toString() ?? DateTime.now().toIso8601String(),
                ),
              );
          squadMap[timAdi.toLowerCase()] = newSquadId;
        }
      }

      // 2. Restore Personnel
      final existingPersonnel = await db.select(db.personelTable).get();
      final personnelSet = {
        for (final p in existingPersonnel) '${p.rutbe}_${p.adSoyad}'.toLowerCase(),
      };

      for (final p in personnel) {
        final adSoyad = p['adSoyad']?.toString() ?? '';
        final rutbe = p['rutbe']?.toString() ?? 'J.Uzm.Çvş.';
        final birlik = p['birlik']?.toString() ?? '1.J.KÖK.Tug.K.lığı';
        final key = '${rutbe}_$adSoyad'.toLowerCase();

        if (adSoyad.isNotEmpty && !personnelSet.contains(key)) {
          int? timId;
          final timIdVal = p['timId'];
          if (timIdVal != null) {
            // Find squad name if present
            final squadObj = squads.firstWhere((s) => s['id'] == timIdVal, orElse: () => null);
            if (squadObj != null) {
              final squadName = squadObj['timAdi']?.toString().toLowerCase();
              timId = squadMap[squadName];
            }
          }

          await db.into(db.personelTable).insert(
                PersonelTableCompanion.insert(
                  adSoyad: adSoyad,
                  rutbe: rutbe,
                  birlik: birlik,
                  timId: Value(timId),
                  kayitTarihi: p['kayitTarihi']?.toString() ?? DateTime.now().toIso8601String(),
                ),
              );
          importedCount++;
        }
      }
    });

    return importedCount;
  }
}
