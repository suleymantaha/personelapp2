import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/personnel/presentation/widgets/personnel_inline_order_editor.dart';

void main() {
  late AppDatabase db;
  late int team, first, second;
  late bool closed, saved;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    team = (await db.select(db.timTable).get()).first.id;
    Future<int> add(String name) =>
        db.into(db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: 'J.Er',
            birlik: '',
            kayitTarihi: '',
            timId: Value(team)));
    first = await add('Ali Uzun İsim YILMAZ');
    second = await add('Veli DEMİR');
    closed = false;
    saved = false;
  });
  tearDown(() => db.close());
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((ref) =>
              const UserSessionState(username: 'admin', role: UserRole.admin)),
        ],
        child: MaterialApp(
            home: PersonnelInlineOrderEditor(
                onClose: () => closed = true, onSaved: () => saved = true))));
    await tester.pumpAndSettle();
    for (var i = 0;
        i < 20 && find.byKey(ValueKey('order-team-$team')).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(ValueKey('order-team-$team')));
    await tester.pumpAndSettle();
  }

  testWidgets('drag saves complete personnel order and cancel does not write',
      (tester) async {
    await open(tester);
    expect(find.text('Ali Uzun İsim YILMAZ'), findsOneWidget);
    final handle = find.byKey(ValueKey('order-person-handle-$first'));
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
    for (var i = 0; i < 20 && !saved; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(saved, isTrue,
        reason: find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' | '));
    final rows = await db.select(db.personelTable).get();
    expect(rows.firstWhere((p) => p.id == second).sortOrder, 0);
    expect(rows.firstWhere((p) => p.id == first).sortOrder, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('cancel leaves database positions unchanged at narrow large text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(saved, isFalse);
    expect(
        (await db.select(db.personelTable).get())
            .every((p) => p.sortOrder == null),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'personnel drag scrolls long lists and cancellation discards changes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (var i = 0; i < 35; i++) {
      await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
          adSoyad: 'Z Personel $i',
          rutbe: 'J.Er',
          birlik: '',
          kayitTarihi: '',
          timId: Value(team)));
    }
    await open(tester);
    final handle = find.byKey(ValueKey('order-person-handle-$first'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(const Offset(350, 750));
    await tester.pump(const Duration(milliseconds: 600));
    final outer = tester
        .widget<ReorderableListView>(find.byType(ReorderableListView).first);
    expect(outer.scrollController!.offset, greaterThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(
        (await db.select(db.personelTable).get())
            .every((p) => p.sortOrder == null),
        isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('team drag saves team order without moving personnel membership',
      (tester) async {
    await open(tester);
    await tester.tap(find.byKey(ValueKey('order-team-$team')));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey('order-team-handle-$team'))));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 140));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 20 && !saved; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(saved, isTrue);
    expect(
        (await db.select(db.timTable).get())
            .firstWhere((t) => t.id == team)
            .sortOrder,
        greaterThan(0));
    expect(
        (await db.select(db.personelTable).get()).every((p) => p.timId == team),
        isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
