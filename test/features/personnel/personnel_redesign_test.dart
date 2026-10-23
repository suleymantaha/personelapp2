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
  const fullName = 'Ali Mehmet Mustafa Çok Uzun Personel Soyadı';
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    teamId = (await db.select(db.timTable).get()).first.id;
    await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
        adSoyad: fullName,
        rutbe: 'J.Asb.Kd.Bçvş.',
        birlik: 'Birlik',
        kayitTarihi: '2026-10-23',
        timId: Value(teamId)));
  });
  tearDown(() => db.close());
  Widget app() => ProviderScope(overrides: [
        databaseProvider.overrideWithValue(db),
        userSessionProvider.overrideWith((ref) =>
            const UserSessionState(username: 'admin', role: UserRole.admin)),
      ], child: const MaterialApp(home: PersonnelManagementScreen()));
  testWidgets('hidden search expands matches and restores prior expansion',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text(fullName), findsNothing);
    await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('personnel-search-field')), 'Ali');
    await tester.pumpAndSettle();
    expect(find.text(fullName), findsOneWidget);
    expect(find.text('J.Asb.Kd.Bçvş.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text(fullName), findsNothing);
    await tester.tap(find.byKey(ValueKey('team-header-$teamId')));
    await tester.pumpAndSettle();
    expect(find.text(fullName), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('personnel-search-field')), 'bulunamayan');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
    await tester.pumpAndSettle();
    expect(find.text(fullName), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('long full name fits narrow phone with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('team-header-$teamId')));
    await tester.pumpAndSettle();
    final name = tester.widget<Text>(find.text(fullName));
    expect(name.maxLines, isNull);
    expect(name.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.getTopLeft(find.text(fullName)).dy,
        lessThan(tester.getTopLeft(find.text('J.Asb.Kd.Bçvş.')).dy));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'rank search includes more than fifty matches and team search opens members',
      (tester) async {
    for (var i = 0; i < 55; i++) {
      await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
          adSoyad: 'Örnek $i',
          rutbe: 'J.Er',
          birlik: '',
          kayitTarihi: '',
          timId: Value(teamId)));
    }
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personnel-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'J.Er');
    await tester.pumpAndSettle();
    expect(find.textContaining('Örnek '), findsNWidgets(55));
    await tester.enterText(find.byType(TextField), 'K.H');
    await tester.pumpAndSettle();
    expect(find.text(fullName), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
