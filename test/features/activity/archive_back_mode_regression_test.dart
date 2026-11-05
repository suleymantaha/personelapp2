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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));
  for (final toolbar in [false, true]) {
    for (final mode in ['selection', 'reorder']) {
      testWidgets(
          '${toolbar ? 'Toolbar' : 'Android'} back exits archive $mode before leaving the archive',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final db = AppDatabase(NativeDatabase.memory());
        const actor = UserSessionState(username: 'admin', role: UserRole.admin);
        final router = createAppRouter(session: actor);
        try {
          await db.into(db.kullaniciTable).insert(
              KullaniciTableCompanion.insert(
                  kullaniciAdi: 'admin', rol: UserRole.admin.storageValue));
          await db.into(db.gunlukFaaliyetTable).insert(
              GunlukFaaliyetTableCompanion.insert(
                  faaliyetAdi: 'Synthetic audit card',
                  tarih: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  olusturanKullanici: 'admin',
                  olusturmaTarihi: ''));
          await tester.pumpWidget(ProviderScope(overrides: [
            databaseProvider.overrideWithValue(db),
            userSessionProvider.overrideWith((ref) => actor),
          ], child: MaterialApp.router(routerConfig: router)));
          await tester.pumpAndSettle();
          router.push<void>(AppRoutes.activityArchive);
          await tester.pumpAndSettle();
          final key = mode == 'selection'
              ? 'archive-select-visible'
              : 'archive-reorder-visible';
          await tester.tap(find.byKey(Key(key)));
          await tester.pumpAndSettle();
          if (toolbar) {
            await tester.tap(mode == 'selection'
                ? find.byKey(const Key('activity-selection-close'))
                : find.byType(BackButton));
          } else {
            await tester.binding.handlePopRoute();
          }
          await tester.pumpAndSettle();
          expect(find.byType(ActivityArchiveScreen), findsOneWidget);
          expect(
              find.byKey(const Key('archive-select-visible')), findsOneWidget);
          expect(
              find.byKey(const Key('activity-selection-close')), findsNothing);
          expect(find.byKey(const Key('archive-reorder-close')), findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path,
              AppRoutes.dashboard);
          expect(find.byType(ActivityArchiveScreen), findsNothing);
          expect(await db.select(db.gunlukFaaliyetTable).get(), hasLength(1));
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          router.dispose();
          await db.close();
        }
      });
    }
  }
}
