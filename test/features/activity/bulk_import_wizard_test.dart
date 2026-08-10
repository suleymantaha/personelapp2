import 'package:drift/drift.dart' hide isNull;
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
    final teamId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
              timAdi: '6-B Timi', olusturmaTarihi: '2026-01-01'),
        );
    await database.batch((batch) {
      batch.insertAll(database.personelTable, [
        PersonelTableCompanion.insert(
            adSoyad: 'Ali DENEME',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            timId: Value(teamId),
            kayitTarihi: '2026-01-01'),
        PersonelTableCompanion.insert(
            adSoyad: 'Veli SAĞLAM',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            timId: Value(teamId),
            kayitTarihi: '2026-01-01'),
      ]);
    });
  });

  tearDown(() => database.close());

  testWidgets('"Soruna Git" butonu sorunlu personel olduğunda görünür',
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
1- J.Uzm.Çvş. Mehmet BİLİNMEYEN
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // "Soruna Git" butonu (Key: bulk-goto-problem) görünmeli
    expect(find.byKey(const Key('bulk-goto-problem')), findsOneWidget);
  });

  testWidgets('Wizard "Sonraki Sorun" butonu odaklanan kartı değiştirir',
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
1- J.Uzm.Çvş. Mehmet BİLİNMEYEN
6/B Devriye Listesi
25.07.2026
1- J.Uzm.Çvş. Ahmet KAYIP
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // "Soruna Git" butonuna tıkla ile wizard başlat
    await tester.tap(find.byKey(const Key('bulk-goto-problem')));
    await tester.pumpAndSettle();

    // Kompakt hata özeti genişlemiş olmalı, bulk-wizard-next görünmeli
    expect(find.byKey(const Key('bulk-wizard-next')), findsOneWidget);
    // bulk-wizard-next butonuna tıkla
    await tester.tap(find.byKey(const Key('bulk-wizard-next')));
    await tester.pumpAndSettle();

    // Wizard bar hâlâ görünmeli (ikinci soruna geçti)
    expect(find.byKey(const Key('bulk-wizard-next')), findsOneWidget);
  });

  testWidgets('sorun takibi son sorundan sonra ilk personele geri odaklanir',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
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
1- J.Uzm.Cvs. Mehmet KAYIP
6/B Devriye Listesi
25.07.2026
1- J.Uzm.Cvs. Ahmet YOK
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bulk-goto-problem')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 / 2'), findsWidgets);
    expect(find.byKey(const Key('bulk-focused-person-badge')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bulk-wizard-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 / 2'), findsWidgets);
    expect(find.byKey(const Key('bulk-focused-person-badge')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bulk-wizard-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 / 2'), findsWidgets);
    expect(find.byKey(const Key('bulk-focused-person-badge')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kompakt hata özetine tıklayınca wizard başlatılır',
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
1- J.Uzm.Çvş. Mehmet BİLİNMEYEN
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Kompakt hata özeti "Kaydedilemiyor" göstermeli
    expect(find.text('Kaydedilemiyor'), findsOneWidget);

    // "Kaydedilemiyor" alanına tıkla → wizard başlamalı
    await tester.tap(find.text('Kaydedilemiyor'));
    await tester.pumpAndSettle();

    // bulk-wizard-next görünmeli (wizard aktif)
    expect(find.byKey(const Key('bulk-wizard-next')), findsOneWidget);
  });

  testWidgets(
      'İsimler tarihten önce gelse dahi tarih bloğa atanır ve engelleme oluşmaz',
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
Ali DENEME
Veli SAĞLAM
03 AĞUSTOS 2026
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Tarih 2026-08-03 atanmış olmalı ve Kaydedilemiyor engelleyici mesajı çıkmamalı
    expect(find.text('Kaydedilemiyor'), findsNothing);
    expect(find.byKey(const Key('bulk-import-save-button')), findsOneWidget);
  });
}
