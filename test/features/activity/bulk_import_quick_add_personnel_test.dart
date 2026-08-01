import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '6-B Timi',
            olusturmaTarihi: '2026-01-01',
          ),
        );
  });

  tearDown(() => database.close());

  testWidgets(
      'Eşleşmeyen personel için "+ 6-B Timine Ekle" tıklandığında veritabanına eklenir',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BulkImportDialog(
              database: database,
              activityRepository: ActivityRepository(database),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      '''
6/B Heybet Listesi
25.07.2026
1- J.Uzm.Çvş. Hakan KAYA
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Personel DB'de olmadığı için eşleşmemiş görünmeli ve "+ 6-B Timi'ne Ekle" butonu olmalı
    final addButton = find.byKey(const Key('bulk-person-add-new'));
    expect(addButton, findsOneWidget);

    // Ekle butonuna tıkla
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Veritabanına eklenmiş olmalı
    final dbPersonnel = await database.select(database.personelTable).get();
    expect(dbPersonnel.length, equals(1));
    expect(dbPersonnel.first.adSoyad, equals('Hakan KAYA'));
    expect(dbPersonnel.first.rutbe, equals('J.Uzm.Çvş.'));

    // Kart üzerinde eşleştiği görünmeli
    expect(find.byKey(const Key('bulk-person-add-new')), findsNothing);
    expect(find.text('Hakan KAYA'), findsWidgets);
  });
}
