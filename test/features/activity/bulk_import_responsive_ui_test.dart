import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  for (final size in const [
    Size(320, 640),
    Size(360, 800),
    Size(412, 915),
  ]) {
    testWidgets('bulk import uses a full-screen mobile dialog at $size',
        (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => BulkImportDialog(
                      database: database,
                      activityRepository: ActivityRepository(database),
                    ),
                  ),
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<Dialog>(find.byType(Dialog).last);
      expect(dialog.insetPadding, EdgeInsets.zero);
      expect(tester.takeException(), isNull);
      expect(find.text('Metinden Toplu Aktarım'), findsOneWidget);
    });
  }

  testWidgets('long personnel names remain readable without ellipsis',
      (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const longName = 'Mehmet Selahattin Uzunsoyadlı Personel';
    final item = ParsedPersonnelItem(
      rawIndex: 1,
      rawRank: 'J.Uzm.Çvş.',
      rawName: longName,
      matchedPersonnelId: 1,
      matchedAdSoyad: longName,
      matchedRutbe: 'J.Uzm.Çvş.',
      matchConfidence: 1,
      reviewConfirmed: true,
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
          body: PersonnelMatchCard(
            item: item,
            teamName: 'Çok Uzun İsimli 1-B Operasyon Timi',
            onSelect: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    final name = tester.widget<Text>(
      find.text('J.Uzm.Çvş. $longName'),
    );
    expect(name.maxLines, 2);
    expect(name.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });
}
