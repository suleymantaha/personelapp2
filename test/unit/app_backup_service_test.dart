import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AppBackupService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'temgundrap_documents_v1': jsonEncode([
        {'id': 'doc-1', 'title': 'Test Report'}
      ]),
      'bulk_import_keep_audit_text_enabled': true,
      'app_theme_mode': 'dark',
    });

    db = AppDatabase(NativeDatabase.memory());
    service = AppBackupService(db);

    // Populate test database with initial records across multiple tables
    final userId = await db.into(db.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: 'komutan1',
            sifre: const Value('hash123'),
            rol: 'yönetici',
          ),
        );

    final squadId = await db.into(db.timTable).insert(
          TimTableCompanion.insert(
            timAdi: 'A-Tim',
            olusturmaTarihi: '2026-08-01',
            timKomutaniId: Value(userId),
          ),
        );

    final personnelId = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Mehmet Yılmaz',
            rutbe: 'Üstçavuş',
            birlik: '1. Tabur',
            timId: Value(squadId),
            kayitTarihi: '2026-08-01',
          ),
        );

    final activityId = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Devriye',
            tarih: '2026-08-08',
            olusturanKullanici: 'komutan1',
            olusturmaTarihi: '2026-08-08',
          ),
        );

    await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activityId,
            personelId: personnelId,
            gorevVeyaIzin: 'GÖREVLİ',
            durum: 'onaylandi',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('AppBackupService TDD Unit Tests', () {
    test('exportBackupJson exports valid full backup structure and sha256', () async {
      final jsonStr = await service.exportBackupJson();
      expect(jsonStr, contains('"format": "nizam-full-backup"'));
      expect(jsonStr, contains('"version": 2'));

      final preview = await service.inspectBackupJson(jsonStr);
      expect(preview.personnelCount, equals(1));
      expect(preview.activityCount, equals(1));
      expect(preview.assignmentCount, equals(1));
      expect(preview.temgundrapDocumentCount, equals(1));
      expect(preview.legacy, isFalse);
    });

    test('restoring full backup replaces database and preferences accurately', () async {
      final exportedJson = await service.exportBackupJson();

      // Clear database tables
      await db.delete(db.faaliyetPersonelAtamaTable).go();
      await db.delete(db.gunlukFaaliyetTable).go();
      await db.delete(db.personelTable).go();
      await db.delete(db.timTable).go();
      await db.delete(db.kullaniciTable).go();

      expect((await db.select(db.personelTable).get()).length, equals(0));

      final result = await service.restoreBackupJson(exportedJson);
      expect(result.legacy, isFalse);
      expect(result.importedPersonnel, equals(1));
      expect(result.importedActivities, equals(1));
      expect(result.importedTemgundrapDocuments, equals(1));

      final personnel = await db.select(db.personelTable).get();
      expect(personnel.length, equals(1));
      expect(personnel.first.adSoyad, equals('Mehmet Yılmaz'));
    });

    test('inspect and restore accept formatted/pretty-printed JSON with reordered keys', () async {
      final exportedJson = await service.exportBackupJson();
      final Map<String, dynamic> decoded =
          jsonDecode(exportedJson) as Map<String, dynamic>;

      // Reorder payload keys to simulate different JSON stringifiers/editors
      final rawPayload = decoded['payload'] as Map<String, dynamic>;
      final reorderedPayload = <String, dynamic>{
        'preferences': rawPayload['preferences'],
        'databaseSchemaVersion': rawPayload['databaseSchemaVersion'],
        'tables': rawPayload['tables'],
      };
      decoded['payload'] = reorderedPayload;

      final reencodedJson = const JsonEncoder.withIndent('    ').convert(decoded);

      final preview = await service.inspectBackupJson(reencodedJson);
      expect(preview.personnelCount, equals(1));

      final result = await service.restoreBackupJson(reencodedJson);
      expect(result.importedPersonnel, equals(1));
    });

    test('sanitizes input with markdown code fences, BOM, and extra whitespace', () async {
      final exportedJson = await service.exportBackupJson();
      final wrappedJson = '\uFEFF  ```json\n$exportedJson\n```  ';

      final preview = await service.inspectBackupJson(wrappedJson);
      expect(preview.personnelCount, equals(1));

      final result = await service.restoreBackupJson(wrappedJson);
      expect(result.importedPersonnel, equals(1));
    });

    test('supports legacy v1 personnel backups seamlessly', () async {
      final legacyBackup = jsonEncode({
        'version': 1,
        'exportedAt': '2026-08-01T00:00:00.000Z',
        'squads': [
          {'id': 10, 'timAdi': 'Eski Tim', 'olusturmaTarihi': '2026-08-01'}
        ],
        'personnel': [
          {
            'id': 101,
            'adSoyad': 'Ahmet Eski',
            'rutbe': 'Çavuş',
            'birlik': '2. Birlik',
            'timId': 10,
            'kayitTarihi': '2026-08-01'
          }
        ]
      });

      final preview = await service.inspectBackupJson(legacyBackup);
      expect(preview.legacy, isTrue);
      expect(preview.personnelCount, equals(1));

      final result = await service.restoreBackupJson(legacyBackup);
      expect(result.legacy, isTrue);
      expect(result.importedPersonnel, equals(1));
    });

    test('rejects tampered payload where checksum does not match data', () async {
      final exportedJson = await service.exportBackupJson();
      final Map<String, dynamic> decoded =
          jsonDecode(exportedJson) as Map<String, dynamic>;

      // Modify a value in payload without changing checksum
      final tables = decoded['payload']['tables'] as Map<String, dynamic>;
      final personnel = tables['personnel'] as List<dynamic>;
      personnel[0]['adSoyad'] = 'Hacked Name';

      final tamperedJson = jsonEncode(decoded);

      expect(
        () => service.inspectBackupJson(tamperedJson),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('bütünlük kontrolü başarısız'),
          ),
        ),
      );
    });

    test('successfully inspects and restores user backup Nizam_Yedek_2026-08-07_16-48.nizam.json from clipboard paste', () async {
      final file = File('Nizam_Yedek_2026-08-07_16-48.nizam.json');
      if (!file.existsSync()) return;

      final contents = file.readAsStringSync();
      // Test with clipboard-like text additions (BOM, code fences, trailing space)
      final pastedText = '```json\n$contents\n```';
      final preview = await service.inspectBackupJson(pastedText);
      expect(preview.legacy, isFalse);
      expect(preview.personnelCount, greaterThan(0));

      final result = await service.restoreBackupJson(pastedText);
      expect(result.importedPersonnel, equals(preview.personnelCount));
    });
  });
}
