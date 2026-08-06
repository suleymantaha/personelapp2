import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/learned_aliases_dialog.dart';

void main() {
  late AppDatabase database;
  late int personnelId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    personnelId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Hüseyin ORUÇTUTAN',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '9/B',
            kayitTarihi: '2026-01-01',
          ),
        );
  });

  tearDown(() => database.close());

  testWidgets(
      'LearnedAliasesDialog renders empty state and list items correctly',
      (tester) async {
    final learningService = BulkImportLearningService(database);
    await learningService.rememberAlias(
      rawName: 'Hüseyin ORUCTUTAN',
      personnelId: personnelId,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => LearnedAliasesDialog.show(context, database),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Sistem Hafızası'), findsOneWidget);
    expect(find.text('1 Öğrenilmiş İsim Takma Adı'), findsOneWidget);
    expect(find.text('Metindeki ad'), findsOneWidget);
    expect(find.text('Hüseyin ORUCTUTAN'), findsOneWidget);
    expect(find.text('J.Uzm.Çvş. Hüseyin ORUÇTUTAN'), findsOneWidget);

    // Test search filter
    await tester.enterText(find.byType(TextField), 'NonExistentName');
    await tester.pumpAndSettle();
    expect(find.text('Aramanıza uygun takma ad bulunamadı.'), findsOneWidget);

    // Clear search filter
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.text('Hüseyin ORUCTUTAN'), findsOneWidget);

    // Test delete dialog opening
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Eşleşmeyi Sil'), findsOneWidget);

    // Confirm delete
    await tester.tap(find.text('SİL'));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Henüz öğrenilmiş bir takma ad bulunmuyor.\nToplu aktarımlarda onayladığınız eşleşmeler otomatik hafızaya alınır.'),
        findsOneWidget);
  });

  for (final size in const [
    Size(320, 640),
    Size(360, 800),
    Size(412, 915),
  ]) {
    testWidgets('LearnedAliasesDialog is readable on $size', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await database.into(database.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: 'Mehmet Selahattin Çok Uzun Soyadlı Personel',
              rutbe: 'J.Uzm.Çvş.',
              birlik: '1/B',
              kayitTarihi: '2026-01-01',
            ),
          );
      final longPersonnel = await (database.select(database.personelTable)
            ..where((row) => row.adSoyad
                .equals('Mehmet Selahattin Çok Uzun Soyadlı Personel')))
          .getSingle();
      await BulkImportLearningService(database).rememberAlias(
        rawName: 'M. Selahattin Çok Uzun Yazılmış İsim',
        personnelId: longPersonnel.id,
      );

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => LearnedAliasesDialog.show(context, database),
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<Dialog>(find.byType(Dialog).last);
      expect(dialog.insetPadding, EdgeInsets.zero);
      expect(find.text('Metindeki ad'), findsOneWidget);
      expect(find.text('Eşleştiği personel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
