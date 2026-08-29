import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/learned_aliases_dialog.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<int> addSquad(String name) {
    return database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: name,
            olusturmaTarihi: '2026-01-01',
          ),
        );
  }

  Future<void> addAlias({
    required String name,
    required String rank,
    required String rawName,
    int? squadId,
  }) async {
    final personnelId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: rank,
            birlik: '1/B',
            timId: Value(squadId),
            kayitTarihi: '2026-01-01',
          ),
        );
    await BulkImportLearningService(database).rememberAlias(
      rawName: rawName,
      personnelId: personnelId,
    );
  }

  testWidgets('aliases are listed under the official team of their personnel', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(500, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final secondSquad = await addSquad('2-B Timi');
    final firstSquad = await addSquad('1-B Timi');

    await addAlias(
      name: 'Ahmet Furkan ERYILMAZ',
      rank: 'J.Asb.Çvş.',
      rawName: 'A.Furkan ERYILMAZ',
      squadId: secondSquad,
    );
    await addAlias(
      name: 'Abdul Samed HANCI',
      rank: 'J.Uzm.Çvş.',
      rawName: 'Abdul Samet HANCI',
      squadId: firstSquad,
    );
    await addAlias(
      name: 'Mehmet YIDIRIM',
      rank: 'J.Uzm.Çvş.',
      rawName: 'Mehmet YILDIRIM',
    );

    await tester.pumpWidget(
      MaterialApp(
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

    // Groups start collapsed, so only the team headers are visible.
    expect(find.text('Abdul Samet HANCI'), findsNothing);
    expect(find.text('1-B Timi'), findsOneWidget);
    expect(find.text('2-B Timi'), findsOneWidget);
    expect(find.text('Timsiz / Diğer Personeller'), findsOneWidget);

    final firstSquadTop = tester.getTopLeft(find.text('1-B Timi')).dy;
    final secondSquadTop = tester.getTopLeft(find.text('2-B Timi')).dy;
    final unassignedTop =
        tester.getTopLeft(find.text('Timsiz / Diğer Personeller')).dy;
    expect(firstSquadTop, lessThan(secondSquadTop));
    expect(secondSquadTop, lessThan(unassignedTop));

    for (final squad in const [
      '1-B Timi',
      '2-B Timi',
      'Timsiz / Diğer Personeller',
    ]) {
      await tester.tap(find.text(squad));
      await tester.pumpAndSettle();
    }

    // Each alias sits under its own team header once the groups are open.
    final openedFirstTop = tester.getTopLeft(find.text('1-B Timi')).dy;
    final openedSecondTop = tester.getTopLeft(find.text('2-B Timi')).dy;
    final openedUnassignedTop =
        tester.getTopLeft(find.text('Timsiz / Diğer Personeller')).dy;
    expect(
      tester.getTopLeft(find.text('Abdul Samet HANCI')).dy,
      inExclusiveRange(openedFirstTop, openedSecondTop),
    );
    expect(
      tester.getTopLeft(find.text('A.Furkan ERYILMAZ')).dy,
      inExclusiveRange(openedSecondTop, openedUnassignedTop),
    );
    expect(
      tester.getTopLeft(find.text('Mehmet YILDIRIM')).dy,
      greaterThan(openedUnassignedTop),
    );

    // Searching by team name keeps only that team's aliases and reveals the
    // hits without needing another tap.
    await tester.tap(find.text('1-B Timi'));
    await tester.pumpAndSettle();
    expect(find.text('Abdul Samet HANCI'), findsNothing);

    await tester.enterText(find.byType(TextField), '1-B');
    await tester.pumpAndSettle();
    expect(find.text('Abdul Samet HANCI'), findsOneWidget);
    expect(find.text('A.Furkan ERYILMAZ'), findsNothing);
  });
}
