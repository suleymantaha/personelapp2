import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/navigation/app_navigator.dart';
import 'package:personelapp2/core/navigation/app_routes.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_screen.dart';
import 'roster_output_screen_test.dart' show waitFor;

void main() {
  for (final scenario in [
    'valid',
    'demoted',
    'deleted',
    'demoted-before-list'
  ]) {
    testWidgets('combined output validates live admin for $scenario',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
          kullaniciAdi: 'admin', rol: 'yönetici'));
      final p = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: 'Protected Person',
              rutbe: 'J.Er',
              birlik: '1/B',
              kayitTarihi: '2026-10-06'));
      final id = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Protected Source',
              tarih: '2026-10-06',
              olusturanKullanici: 'admin',
              olusturmaTarihi: '2026-10-06'));
      await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: id,
              personelId: p,
              gorevVeyaIzin: 'HEYBET',
              durum: 'onaylandi'));
      Future<int> demote() => (db.update(db.kullaniciTable)
            ..where((u) => u.kullaniciAdi.equals('admin')))
          .write(const KullaniciTableCompanion(rol: Value('tim_komutani')));
      if (scenario == 'demoted-before-list') await demote();
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        userSessionProvider.overrideWith((ref) =>
            const UserSessionState(username: 'admin', role: UserRole.admin))
      ]);
      addTearDown(container.dispose);
      late RosterOutputPreviewArgs preview;
      final router = GoRouter(initialLocation: '/output', routes: [
        GoRoute(
            path: '/output',
            builder: (_, __) =>
                const RosterOutputScreen(initialDate: '2026-10-06')),
        GoRoute(
            path: AppRoutes.rosterOutputPreview,
            builder: (_, state) {
              preview = state.extra! as RosterOutputPreviewArgs;
              return const Scaffold(body: Text('Preview route'));
            }),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      if (scenario == 'demoted-before-list') {
        expect(find.text('Protected Source'), findsNothing);
        expect(find.byKey(ValueKey('current-activity-$id')), findsNothing);
      } else {
        await waitFor(tester, find.byKey(ValueKey('current-activity-$id')));
        await tester.tap(find.byKey(ValueKey('current-activity-$id')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('roster-preview')));
        await waitFor(tester, find.text('Preview route'));
        if (scenario == 'demoted') await demote();
        if (scenario == 'deleted') {
          await (db.delete(db.kullaniciTable)
                ..where((u) => u.kullaniciAdi.equals('admin')))
              .go();
        }
        if (scenario == 'valid') {
          expect((await preview.loadRows()).single.adSoyad, 'Protected Person');
        } else {
          await expectLater(preview.loadRows(), throwsException);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 20));
    });
  }
}
