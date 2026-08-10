import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/core/notifications/app_notification_host.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

void clearNotifications() {
  while (AppNotifications.controller.current != null) {
    AppNotifications.controller.dismiss();
  }
}

Future<void> pumpBulkImport(
  WidgetTester tester,
  AppDatabase database,
) async {
  tester.view.physicalSize = const Size(1000, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: AppNotificationHost(
          child: Scaffold(
            body: BulkImportDialog(
              database: database,
              activityRepository: ActivityRepository(database),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> parseText(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
  await tester.pumpAndSettle();
}

Future<void> deleteCardAt(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(Key('bulk-card-menu-$index')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Kartı sil').last);
  await tester.pumpAndSettle();
}

Future<void> performQueuedUndo(WidgetTester tester) async {
  AppNotifications.controller.performAction();
  await tester.pump();
}

void main() {
  late AppDatabase database;

  setUp(() {
    clearNotifications();
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    clearNotifications();
    await database.close();
  });

  test('stable undo order survives model copies', () {
    final firstPerson = ParsedPersonnelItem(
      rawIndex: 1,
      rawRank: 'J.Uzm.Çvş.',
      rawName: 'Birinci KİŞİ',
    );
    final secondPerson = ParsedPersonnelItem(
      rawIndex: 2,
      rawRank: 'J.Uzm.Çvş.',
      rawName: 'İkinci KİŞİ',
    );
    final block = ParsedActivityBlock(
      rawTitle: 'Heybet',
      parsedTimName: '6/B',
      parsedActivityType: 'Heybet',
      parsedDate: '2026-07-25',
      personnelList: [firstPerson, secondPerson],
    );

    expect(secondPerson.stableOrder, greaterThan(firstPerson.stableOrder));
    expect(firstPerson.copyWith(rawName: 'Güncel').stableOrder,
        firstPerson.stableOrder);
    expect(block.copyWith(rawTitle: 'Güncel').stableOrder, block.stableOrder);
  });

  testWidgets('restores two same-type cards in their original order',
      (tester) async {
    await pumpBulkImport(tester, database);
    await parseText(
      tester,
      '''
6/B Heybet Listesi
25.07.2026
1- J.Uzm.Çvş. Birinci KİŞİ
6/B Heybet Listesi
26.07.2026
1- J.Uzm.Çvş. İkinci KİŞİ
6/B Devriye Listesi
27.07.2026
1- J.Uzm.Çvş. Üçüncü KİŞİ
''',
    );

    expect(
      tester
          .widgetList<ActivityBlockCard>(find.byType(ActivityBlockCard))
          .take(2)
          .map((card) => card.block.parsedDate),
      ['2026-07-25', '2026-07-26'],
    );

    await deleteCardAt(tester, 0);
    await deleteCardAt(tester, 0);

    await performQueuedUndo(tester);
    await performQueuedUndo(tester);

    final dates = tester
        .widgetList<ActivityBlockCard>(find.byType(ActivityBlockCard))
        .map((card) => card.block.parsedDate)
        .toList();
    expect(dates.take(2), ['2026-07-25', '2026-07-26']);
  });

  testWidgets(
      'restores the middle card then its previous card in original order',
      (tester) async {
    await pumpBulkImport(tester, database);
    await parseText(
      tester,
      '''
6/B Heybet Listesi
25.07.2026
1- J.Uzm.Çvş. Birinci KİŞİ
6/B Heybet Listesi
26.07.2026
1- J.Uzm.Çvş. İkinci KİŞİ
6/B Devriye Listesi
27.07.2026
1- J.Uzm.Çvş. Üçüncü KİŞİ
''',
    );

    await deleteCardAt(tester, 1);
    await deleteCardAt(tester, 0);

    await performQueuedUndo(tester);
    await performQueuedUndo(tester);

    final dates = tester
        .widgetList<ActivityBlockCard>(find.byType(ActivityBlockCard))
        .map((card) => card.block.parsedDate)
        .toList();
    expect(dates.take(2), ['2026-07-25', '2026-07-26']);
  });

  testWidgets('restores middle then previous personnel in their original order',
      (tester) async {
    await pumpBulkImport(tester, database);
    await parseText(
      tester,
      '''
6/B Heybet Listesi
25.07.2026
1- J.Uzm.Çvş. Aynı KİŞİ
2- J.Uzm.Çvş. Aynı KİŞİ
3- J.Uzm.Çvş. Son KİŞİ
''',
    );

    await tester.tap(find.byKey(const Key('bulk-person-delete')).at(1));
    await tester.pump();
    await tester.tap(find.byKey(const Key('bulk-person-delete')).first);
    await tester.pump();

    await performQueuedUndo(tester);
    await performQueuedUndo(tester);

    final rawIndexes = tester
        .widgetList<PersonnelMatchCard>(find.byType(PersonnelMatchCard))
        .map((card) => card.item.rawIndex)
        .toList();
    expect(rawIndexes, [1, 2, 3]);
  });
}
