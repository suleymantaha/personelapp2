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
            timAdi: '6/B',
            olusturmaTarihi: '2026-01-01',
          ),
        );
    await database.batch((batch) {
      batch.insertAll(database.personelTable, [
        PersonelTableCompanion.insert(
          adSoyad: 'Ali DENEME',
          rutbe: 'J.Uzm.Çvş.',
          birlik: '6/B',
          timId: Value(teamId),
          kayitTarihi: '2026-01-01',
        ),
        PersonelTableCompanion.insert(
          adSoyad: 'Veli SAĞLAM',
          rutbe: 'J.Uzm.Çvş.',
          birlik: '6/B',
          timId: Value(teamId),
          kayitTarihi: '2026-01-01',
        ),
      ]);
    });
  });

  tearDown(() => database.close());

  testWidgets('stat cards show correct counts after parsing', (tester) async {
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
1- J.Uzm.Çvş. Ali DENEME
2- J.Uzm.Çvş. Veli SAĞLAM
6/B Devriye Listesi
25.07.2026
1- J.Uzm.Çvş. Mehmet BİLİNMEYEN
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Stat kartları görünmeli (Faz 2)
    expect(find.text('2'), findsWidgets); // 2 kart
    expect(find.text('3'), findsWidgets); // 3 personel
    expect(find.text('1'),
        findsWidgets); // 1 gün (unique date) - also appears in stepper
  });

  testWidgets('unknown personnel shows error summary and save is blocked',
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
6/B Devriye Listesi
25.07.2026
1- J.Uzm.Çvş. Mehmet BİLİNMEYEN
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Kompakt hata özeti "Kaydedilemiyor" metnini göstermeli (Faz 3)
    expect(find.text('Kaydedilemiyor'), findsOneWidget);

    // "Soruna Git" butonu görünmeli (Faz 5)
    expect(find.byKey(const Key('bulk-goto-problem')), findsOneWidget);

    // Kaydet butonu devre dışı olmalı
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('bulk-import-save-button')),
    );
    expect(button.onPressed == null, isTrue);
  });

  testWidgets(
      'preview v2 shows correctness panel, issue filters, and active issue context',
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
6-B Timi Heybet Listesi
25.07.2026
1- J.Uzm.Çvş. Mehmet BİLİNMEYEN
6-B Timi Devriye Listesi
25.07.2026
1- J.Uzm.Çvş. Ali DENEME
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('Doğruluk Paneli'), findsOneWidget);
    expect(find.textContaining('Kaydetmeden önce'), findsOneWidget);
    expect(find.text('Sorunlar'), findsOneWidget);
    expect(find.text('Tümü'), findsOneWidget);
    expect(find.text('Hazır'), findsOneWidget);
    expect(find.text('Personel, tim veya satır ara'), findsOneWidget);
    expect(find.textContaining('1 / 1'), findsWidgets);
    expect(find.textContaining('Mehmet BİLİNMEYEN'), findsWidgets);
    expect(find.text('Düzelt'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('bulk-import-save-button')),
    );
    expect(button.onPressed == null, isTrue);
    expect(find.text('Kaydetmek için 1 işlem kaldı'), findsOneWidget);
  });

  testWidgets('preview v2 ready filter only shows cards without issues',
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
6-B Timi Heybet Listesi
25.07.2026
1- J.Uzm.Çvş. Mehmet BİLİNMEYEN
6-B Timi Devriye Listesi
25.07.2026
1- J.Uzm.Çvş. Ali DENEME
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hazır'));
    await tester.pumpAndSettle();

    expect(find.textContaining('GÖREVLİ', skipOffstage: false), findsWidgets);
    expect(find.textContaining('Mehmet BİLİNMEYEN'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'team mismatch on matched personnel displays warning tag but does not block saving',
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
2. TİM KARAKEÇİ Listesi
25.07.2026
1- J.Uzm.Çvş. Ali DENEME
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Ali DENEME is matched (100% confidence), but KARAKEÇİ team differs from 6-B Timi in DB
    expect(find.textContaining('Ali DENEME'), findsWidgets);
    expect(
        find.byKey(const Key('bulk-team-mismatch-warning'),
            skipOffstage: false),
        findsWidgets);

    // Save button should be enabled (team mismatch doesn't block save)
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('bulk-import-save-button')),
    );
    expect(button.onPressed != null, isTrue);
  });
}
