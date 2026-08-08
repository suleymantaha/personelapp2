import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/services/app_backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full system backup export and restore integration test',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'temgundrap_documents_v1': jsonEncode([
        {'id': 'doc-100', 'title': 'Doküman 1'}
      ]),
      'bulk_import_keep_audit_text_enabled': true,
      'app_theme_mode': 'dark',
    });

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final service = AppBackupService(database);

    // 1. Populate database with initial data
    final userId = await database.into(database.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: 'admin',
            sifre: const Value('secret123'),
            rol: 'yönetici',
          ),
        );

    final squadId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '1. Komando Timi',
            olusturmaTarihi: '2026-08-01',
            timKomutaniId: Value(userId),
          ),
        );

    final personnelId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Mustafa Demir',
            rutbe: 'Uzm.Çvş.',
            birlik: 'Asayiş K.lığı',
            timId: Value(squadId),
            kayitTarihi: '2026-08-01',
          ),
        );

    // 2. Export full backup
    final exportedBackup = await service.exportBackupJson();
    expect(exportedBackup, contains('nizam-full-backup'));

    // 3. Mutate database records
    await database.delete(database.personelTable).go();
    await database.delete(database.timTable).go();
    await database.delete(database.kullaniciTable).go();

    expect((await database.select(database.personelTable).get()), isEmpty);

    // 4. Restore backup
    final restoreResult = await service.restoreBackupJson(exportedBackup);
    expect(restoreResult.importedPersonnel, equals(1));

    // 5. Verify database records are completely restored
    final restoredPersonnel = await database.select(database.personelTable).get();
    expect(restoredPersonnel.length, equals(1));
    expect(restoredPersonnel.first.id, equals(personnelId));
    expect(restoredPersonnel.first.adSoyad, equals('Mustafa Demir'));
  });
}
