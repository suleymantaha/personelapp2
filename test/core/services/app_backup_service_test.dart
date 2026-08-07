import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase(NativeDatabase.memory());
    service = AppBackupService(db);
  });

  tearDown(() => db.close());

  test('exports and replaces every durable application data source', () async {
    await _seedAllData(db);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'temgundrap_documents_v1',
      '[{"id":"tem-1","date":"2026-08-07"}]',
    );
    await prefs.setBool('bulk_import_keep_audit_text_enabled', true);
    await prefs.setString('app_theme_mode', 'dark');
    await prefs.setString('session_username', 'should-not-be-backed-up');

    final backup = await service.exportBackupJson();
    final preview = await service.inspectBackupJson(backup);
    expect(preview.personnelCount, 1);
    expect(preview.activityCount, 1);
    expect(preview.assignmentCount, 1);
    expect(preview.temgundrapDocumentCount, 1);

    await db.delete(db.faaliyetPersonelAtamaTable).go();
    await db.delete(db.raporKayitTable).go();
    await db.delete(db.personelIsimTakmaAdTable).go();
    await db.delete(db.timUyelikGecmisiTable).go();
    await db.delete(db.gunlukFaaliyetTable).go();
    await db.delete(db.topluAktarimGecmisiTable).go();
    await db.delete(db.personelTable).go();
    await prefs.setString('temgundrap_documents_v1', '[]');
    await prefs.setBool('bulk_import_keep_audit_text_enabled', false);
    await prefs.setString('app_theme_mode', 'light');
    await prefs.setString('session_username', 'current-session');

    final result = await service.restoreBackupJson(backup);

    expect(result.legacy, isFalse);
    expect(result.importedPersonnel, 1);
    expect(result.importedActivities, 1);
    expect(result.importedTemgundrapDocuments, 1);
    expect(await db.select(db.kullaniciTable).get(), hasLength(1));
    expect((await db.select(db.kullaniciTable).get()).single.timId, 10);
    expect(await db.select(db.timTable).get(), hasLength(1));
    expect((await db.select(db.timTable).get()).single.timKomutaniId, 1);
    expect(await db.select(db.personelTable).get(), hasLength(1));
    expect(await db.select(db.gunlukFaaliyetTable).get(), hasLength(1));
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
    expect(await db.select(db.raporKayitTable).get(), hasLength(1));
    expect(await db.select(db.timUyelikGecmisiTable).get(), hasLength(1));
    expect(await db.select(db.personelIsimTakmaAdTable).get(), hasLength(1));
    expect(await db.select(db.topluAktarimGecmisiTable).get(), hasLength(1));
    expect(prefs.getString('temgundrap_documents_v1'), contains('tem-1'));
    expect(prefs.getBool('bulk_import_keep_audit_text_enabled'), isTrue);
    expect(prefs.getString('app_theme_mode'), 'dark');
    expect(prefs.getString('session_username'), 'current-session');
  });

  test('checksum failure is rejected before existing data changes', () async {
    await _seedAllData(db);
    final backup = await service.exportBackupJson();
    final corrupted = backup.replaceFirst('Ahmet KAYA', 'Mehmet KAYA');

    await expectLater(
      service.restoreBackupJson(corrupted),
      throwsA(isA<FormatException>()),
    );

    final personnel = await db.select(db.personelTable).get();
    expect(personnel.single.adSoyad, 'Ahmet KAYA');
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
  });

  test('broken foreign-key references are rejected before writes', () async {
    await _seedAllData(db);
    final envelope =
        jsonDecode(await service.exportBackupJson()) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    final tables = payload['tables'] as Map<String, dynamic>;
    final assignments = tables['assignments'] as List<dynamic>;
    (assignments.single as Map<String, dynamic>)['personelId'] = 9999;
    envelope['checksum'] =
        sha256.convert(utf8.encode(jsonEncode(payload))).toString();

    await expectLater(
      service.restoreBackupJson(jsonEncode(envelope)),
      throwsA(isA<FormatException>()),
    );

    expect((await db.select(db.personelTable).get()).single.id, 100);
  });

  test('database failure rolls back tables and restored preferences', () async {
    await _seedAllData(db);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', 'dark');
    final envelope =
        jsonDecode(await service.exportBackupJson()) as Map<String, dynamic>;
    final payload = envelope['payload'] as Map<String, dynamic>;
    final tables = payload['tables'] as Map<String, dynamic>;
    final aliases = tables['aliases'] as List<dynamic>;
    final duplicate = Map<String, dynamic>.from(
      aliases.single as Map<String, dynamic>,
    )..['id'] = 601;
    aliases.add(duplicate);
    envelope['checksum'] =
        sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    await prefs.setString('app_theme_mode', 'light');

    await expectLater(
      service.restoreBackupJson(jsonEncode(envelope)),
      throwsA(isA<Exception>()),
    );

    expect(await db.select(db.personelTable).get(), hasLength(1));
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
    expect(await db.select(db.personelIsimTakmaAdTable).get(), hasLength(1));
    expect(prefs.getString('app_theme_mode'), 'light');
  });

  test('legacy version 1 personnel backups remain importable', () async {
    const legacy = '{"version":1,"squads":[],"personnel":['
        '{"id":1,"adSoyad":"Eski Personel","rutbe":"Astsubay",'
        '"birlik":"Merkez","timId":null,"kayitTarihi":"2026-08-01"}'
        '],"aliases":[]}';

    final preview = await service.inspectBackupJson(legacy);
    final result = await service.restoreBackupJson(legacy);

    expect(preview.legacy, isTrue);
    expect(result.legacy, isTrue);
    expect(result.importedPersonnel, 1);
    expect((await db.select(db.personelTable).get()).single.adSoyad,
        'Eski Personel');
  });
}

Future<void> _seedAllData(AppDatabase db) async {
  await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
          id: const Value(1),
          kullaniciAdi: 'admin',
          sifre: const Value('hashed-password'),
          rol: 'yönetici',
        ),
      );
  await db.into(db.timTable).insert(
        TimTableCompanion.insert(
          id: const Value(10),
          timAdi: '1-B Timi',
          timKomutaniId: const Value(1),
          olusturmaTarihi: '2026-08-01',
        ),
      );
  await (db.update(db.kullaniciTable)..where((table) => table.id.equals(1)))
      .write(const KullaniciTableCompanion(timId: Value(10)));
  await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
          id: const Value(100),
          adSoyad: 'Ahmet KAYA',
          rutbe: 'Astsubay',
          birlik: 'Merkez',
          telefon: const Value('5551112233'),
          timId: const Value(10),
          kayitTarihi: '2026-08-01',
        ),
      );
  await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
          id: const Value(200),
          faaliyetAdi: 'Devriye',
          tarih: '2026-08-07',
          olusturanKullanici: 'admin',
          olusturmaTarihi: '2026-08-07T08:00:00',
        ),
      );
  await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
          id: const Value(300),
          faaliyetId: 200,
          personelId: 100,
          gorevVeyaIzin: 'GÖREVLİ',
          durum: 'onaylandi',
          aciklama: const Value('Gece'),
        ),
      );
  await db.into(db.raporKayitTable).insert(
        RaporKayitTableCompanion.insert(
          id: const Value(400),
          personelId: 100,
          raporBaslangic: '2026-08-08',
          raporBitis: '2026-08-09',
          aciklama: const Value('Kontrol'),
        ),
      );
  await db.into(db.timUyelikGecmisiTable).insert(
        TimUyelikGecmisiTableCompanion.insert(
          id: const Value(500),
          personelId: 100,
          timId: const Value(10),
          tarih: '2026-08-01',
          islem: 'eklendi',
        ),
      );
  await db.into(db.personelIsimTakmaAdTable).insert(
        PersonelIsimTakmaAdTableCompanion.insert(
          id: const Value(600),
          normalizeTakmaAd: 'ahmet',
          gorunenTakmaAd: 'Ahmet',
          personelId: 100,
          kayitTarihi: '2026-08-01',
        ),
      );
  await db.into(db.topluAktarimGecmisiTable).insert(
        TopluAktarimGecmisiTableCompanion.insert(
          id: const Value(700),
          parmakIzi: 'fingerprint',
          tarihler: '["2026-08-07"]',
          blokSayisi: 1,
          personelSayisi: 1,
          aktaranKullanici: 'admin',
          kayitTarihi: '2026-08-07T08:00:00',
          hamMetin: const Value('Devriye listesi'),
        ),
      );
}
