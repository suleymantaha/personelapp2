import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/navigation/app_router.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personelapp2/main.dart' show PersonelApp;

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  testWidgets(
      'system back unwinds personnel route, activity card, archive then dashboard',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    const actor = UserSessionState(username: 'admin', role: UserRole.admin);
    final router = createAppRouter(session: actor);
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint('BACK_CHAIN_LAYOUT_DETAILS: ${details.toString()}');
      previousErrorHandler?.call(details);
    };
    try {
      await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
          kullaniciAdi: 'admin', rol: UserRole.admin.storageValue));
      final person = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: 'Synthetic audit',
              rutbe: 'J.Asb.',
              birlik: 'Test',
              kayitTarihi: '2026-11-06'));
      final activity = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Synthetic audit card',
              tarih: DateFormat('yyyy-MM-dd').format(DateTime.now()),
              olusturanKullanici: 'admin',
              olusturmaTarihi: ''));
      await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activity,
              personelId: person,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: 'onaylandi'));
      await tester.pumpWidget(ProviderScope(overrides: [
        databaseProvider.overrideWithValue(db),
        userSessionProvider.overrideWith((ref) => actor),
        appRouterProvider.overrideWithValue(router),
      ], child: const PersonelApp()));
      await tester.pumpAndSettle();
      final baselineBarriers = find.byType(ModalBarrier).evaluate().length;
      router.push<void>(AppRoutes.activityArchive);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('activity-card-$activity')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('activity-detail-screen')), findsOneWidget);
      // Pageless sheets must dismiss before the shell detail route.
      for (final useBarrier in [true, false]) {
        await tester.tap(find.text('+ Personel Ekle'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        if (useBarrier) {
          await tapExposedBarrier(tester, find.byType(BottomSheet));
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byKey(const Key('activity-detail-screen')), findsOneWidget);
      }
      // Mobile bulk import fills the viewport; only desktop exposes a barrier.
      for (final useBarrier in [true, false]) {
        tester.view.physicalSize = Size(useBarrier ? 1000 : 390, 844);
        await tester.pumpAndSettle();
        await tester.tap(find.text('+ Personel Ekle'));
        await tester.pumpAndSettle();
        final bulkOption =
            find.byKey(const Key('activity-add-bulk-personnel-option'));
        await tester.ensureVisible(bulkOption);
        await tester.tap(bulkOption);
        await tester.pumpAndSettle();
        expect(find.byType(BulkImportDialog), findsOneWidget);
        if (useBarrier) {
          await tapExposedBarrier(
              tester,
              find
                  .descendant(
                      of: find.byType(Dialog), matching: find.byType(Material))
                  .first);
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
        expect(find.byType(BulkImportDialog), findsNothing);
        expect(find.byKey(const Key('activity-detail-screen')), findsOneWidget);
      }
      await tester.tap(find.text('+ Personel Ekle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personel Seçerek Ekle'));
      await tester.pumpAndSettle();
      expect(find.byType(AddPersonnelToActivityDialog), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AddPersonnelToActivityDialog), findsNothing);
      expect(find.byKey(const Key('activity-detail-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('activity-detail-screen')), findsNothing);
      expect(find.byType(ActivityArchiveScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
          router.routeInformationProvider.value.uri.path, AppRoutes.dashboard);
      expect(find.byType(ActivityArchiveScreen), findsNothing);
      expect(find.byType(AddPersonnelToActivityDialog), findsNothing);
      expect(find.byType(BulkImportDialog), findsNothing);
      expect(find.byType(ModalBarrier), findsNWidgets(baselineBarriers));
      expect(await db.select(db.gunlukFaaliyetTable).get(), hasLength(1));
      expect(
          await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
      expect(tester.takeException(), isNull);
    } finally {
      FlutterError.onError = previousErrorHandler;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      router.dispose();
      await db.close();
    }
  });
}

Future<void> tapExposedBarrier(WidgetTester tester, Finder surface) async {
  final surfaceRect = tester.getRect(surface);
  final viewport =
      Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);
  final point = surfaceRect.left > viewport.left
      ? Offset((viewport.left + surfaceRect.left) / 2, surfaceRect.center.dy)
      : Offset(surfaceRect.center.dx, (viewport.top + surfaceRect.top) / 2);
  expect(find.byType(ModalBarrier), findsWidgets);
  expect(viewport.contains(point), isTrue);
  expect(surfaceRect.contains(point), isFalse,
      reason: 'Barrier taps must be outside the actual modal surface');
  await tester.tapAt(point);
}
