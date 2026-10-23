import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/presentation/personnel_management_screen.dart';

void main() {
  late AppDatabase db;
  late int teamId;
  late int firstId;
  late int secondId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    teamId = (await db.select(db.timTable).get())
        .firstWhere((t) => t.timAdi == '1-B Timi')
        .id;
    Future<int> add(String name) =>
        db.into(db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: 'J.Er',
            birlik: '',
            kayitTarihi: '',
            timId: Value(teamId)));
    firstId = await add('Ali');
    secondId = await add('Veli');
  });
  tearDown(() => db.close());

  Widget app({bool admin = true}) => ProviderScope(overrides: [
        databaseProvider.overrideWithValue(db),
        userSessionProvider.overrideWith((ref) => UserSessionState(
            username: 'admin',
            role: admin ? UserRole.admin : UserRole.teamCommander,
            timId: teamId)),
      ], child: const MaterialApp(home: PersonnelManagementScreen()));

  testWidgets('filtered screen edits full team and persists order',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ali');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-personnel-order')));
    await tester.pumpAndSettle();
    for (var i = 0;
        i < 20 && find.byKey(ValueKey('order-team-$teamId')).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.ensureVisible(find.byKey(ValueKey('order-team-$teamId')));
    await tester.tap(find.byKey(ValueKey('order-team-$teamId')));
    await tester.pumpAndSettle();
    expect(find.text('Veli'), findsOneWidget);
    final handle = find.byKey(ValueKey('order-person-handle-$firstId'));
    await tester.ensureVisible(handle);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 150));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    for (var i = 0;
        i < 20 && find.text('Kaydediliyor…').evaluate().isNotEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final rows = await db.select(db.personelTable).get();
    expect(rows.firstWhere((p) => p.id == secondId).sortOrder, 0);
    expect(rows.firstWhere((p) => p.id == firstId).sortOrder, 1);
    expect(rows.every((p) => p.timId == teamId), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('commander cannot open the global ordering editor',
      (tester) async {
    await tester.pumpWidget(app(admin: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-personnel-order')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
