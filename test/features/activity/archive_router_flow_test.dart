import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_screen.dart';

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

void main() {
  testWidgets('detail actions share a row and combined output stays in archive',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const admin = UserSessionState(username: 'admin', role: UserRole.admin);
    final db = AppDatabase(NativeDatabase.memory());
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', rol: UserRole.admin.storageValue));
    await db
        .into(db.timTable)
        .insert(TimTableCompanion.insert(timAdi: 'K.H', olusturmaTarihi: ''));
    await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
        adSoyad: 'Router Test',
        rutbe: 'J.Uzm.Çvş.',
        birlik: 'Test',
        timId: const Value(1),
        kayitTarihi: date));
    final activity = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'ROUTER TEST',
            tarih: date,
            olusturanKullanici: 'admin',
            olusturmaTarihi: ''));
    await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activity,
            personelId: 1,
            gorevVeyaIzin: 'GÖREVLİ',
            durum: 'onaylandi',
            gorevTimId: const Value(1),
            gorevTimAdi: const Value('K.H')));
    final router = createAppRouter(session: admin)..go('/activity-archive');
    await tester.pumpWidget(ProviderScope(overrides: [
      databaseProvider.overrideWithValue(db),
      userSessionProvider.overrideWith((_) => admin),
    ], child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('activity-card-$activity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-detail-screen')), findsOneWidget);
    expect(find.text('Kartları birleştir'), findsNothing);
    final add = find.widgetWithIcon(TextButton, Icons.person_add_alt_1_rounded);
    final select = find.byKey(const Key('team-selection-start'));
    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpAndSettle();
      expect(tester.getCenter(add).dy, closeTo(tester.getCenter(select).dy, 1));
      expect(tester.takeException(), isNull);
    }
    await tester.tap(select);
    await tester.pumpAndSettle();
    expect(add, findsNothing);
    await tester.tap(find.byKey(const Key('activity-team-header-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('export-selected-teams')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kartları birleştir'));
    await tester.tap(find.text('Kartları birleştir'));
    await tester.pumpAndSettle();
    expect(find.byType(RosterOutputScreen), findsOneWidget);
    await _waitFor(tester, find.byKey(Key('current-activity-$activity')));
    await tester.tap(find.byKey(Key('current-activity-$activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roster-preview')));
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text('Çıktı Hazırlığı'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(RosterOutputScreen), findsOneWidget);
    expect(find.byKey(Key('selected-card-$activity')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-detail-screen')), findsNothing);
    expect(find.byKey(Key('activity-card-$activity')), findsOneWidget);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    router.dispose();
    await db.close();
    await tester.pump(const Duration(milliseconds: 50));
  });
}
