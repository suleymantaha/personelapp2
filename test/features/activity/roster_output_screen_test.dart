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

Future<void> waitFor(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 100 && target.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('preview reload survives disposal and rechecks the session',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() async {
      await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
          kullaniciAdi: 'admin', rol: 'yönetici'));
      await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: 'Test Personel',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '',
            kayitTarihi: '',
          ));
      final cardId = await db.into(db.gunlukFaaliyetTable).insert(
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Devriye',
              tarih: '2026-10-06',
              olusturanKullanici: 'admin',
              olusturmaTarihi: '',
            ),
          );
      await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: cardId,
              personelId: 1,
              gorevVeyaIzin: 'HAZIR KITA',
              durum: 'onaylandi',
            ),
          );
    });
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      userSessionProvider.overrideWith((ref) => const UserSessionState(
            username: 'admin',
            role: UserRole.admin,
          )),
    ]);
    addTearDown(container.dispose);
    late RosterOutputPreviewArgs preview;
    final router = GoRouter(initialLocation: '/output', routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(
        path: '/output',
        builder: (_, __) => const RosterOutputScreen(initialDate: '2026-10-06'),
      ),
      GoRoute(
        path: AppRoutes.rosterOutputPreview,
        builder: (_, state) {
          preview = state.extra! as RosterOutputPreviewArgs;
          return const Scaffold(body: Text('Preview route'));
        },
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await waitFor(tester, find.byKey(const ValueKey('current-activity-1')));
    await tester
        .ensureVisible(find.byKey(const ValueKey('current-activity-1')));
    await tester.tap(find.byKey(const ValueKey('current-activity-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roster-preview')));
    await waitFor(tester, find.text('Preview route'));
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.byType(RosterOutputScreen, skipOffstage: false), findsNothing);
    final rows = await tester.runAsync(preview.loadRows);
    expect(rows!.map((row) => row.adSoyad), ['Test Personel']);
    container.read(userSessionProvider.notifier).state = null;
    await expectLater(preview.loadRows(), throwsException);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'starts unselected, preserves card order and selection after preview back',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.runAsync(() async {
        await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
            kullaniciAdi: 'admin', rol: 'yönetici'));
        for (final name in ['Heybet personeli', 'Z Personel', 'A Personel']) {
          await db.into(db.personelTable).insert(
                PersonelTableCompanion.insert(
                  adSoyad: name,
                  rutbe: 'J.Uzm.Çvş.',
                  birlik: '',
                  kayitTarihi: '',
                ),
              );
        }
        for (final item in [
          ('Heybet', '2026-10-06'),
          ('Devriye', '2026-10-06'),
          ('Hazır Kıta', '2026-10-05'),
        ]) {
          final id = await db.into(db.gunlukFaaliyetTable).insert(
                GunlukFaaliyetTableCompanion.insert(
                  faaliyetAdi: item.$1,
                  tarih: item.$2,
                  olusturanKullanici: 'admin',
                  olusturmaTarihi: '',
                ),
              );
          await db.into(db.faaliyetPersonelAtamaTable).insert(
                FaaliyetPersonelAtamaTableCompanion.insert(
                  faaliyetId: id,
                  personelId: id,
                  gorevVeyaIzin: 'HAZIR KITA',
                  durum: 'onaylandi',
                ),
              );
        }
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userSessionProvider.overrideWith(
              (ref) => const UserSessionState(
                username: 'admin',
                role: UserRole.admin,
              ),
            ),
          ],
          child: const MaterialApp(
            home: RosterOutputScreen(initialDate: '2026-10-06'),
          ),
        ),
      );
      await waitFor(tester, find.byKey(const ValueKey('current-activity-2')));
      expect(find.byKey(const ValueKey('current-activity-1')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('roster-preview')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('roster-previous-tab')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('previous-activity-3')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('previous-activity-3')));
      await tester.pumpAndSettle();

      // Seçilen kart alttaki havuzdan eksildi
      expect(find.byKey(const ValueKey('previous-activity-3')), findsNothing);
      expect(find.byKey(const ValueKey('selected-card-3')), findsOneWidget);

      await tester.tap(find.byKey(const Key('roster-today-tab')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('current-activity-2')),
      );
      await tester.tap(find.byKey(const ValueKey('current-activity-2')));
      await tester.pumpAndSettle();

      // Seçilen kart alttaki havuzdan eksildi
      expect(find.byKey(const ValueKey('current-activity-2')), findsNothing);
      expect(find.byKey(const ValueKey('selected-card-2')), findsOneWidget);
      // Seçilmeyen kart halen havuzda
      expect(find.byKey(const ValueKey('current-activity-1')), findsOneWidget);

      expect(find.byKey(const ValueKey('selected-card-1')), findsNothing);
      await waitFor(tester, find.text('2 kişiyle önizle'));
      expect(
          tester
              .widget<Text>(find.byKey(const Key('roster-total-people')))
              .data,
          '2');
      await tester.tap(find.byKey(const Key('roster-preview')));
      await waitFor(tester, find.text('Çıktı Hazırlığı'));
      // Preparation must finish independently of the preview route's lifetime.
      // Browser history can restore this screen without completing push's Future.
      expect(
        tester
            .widget<FilledButton>(find.byKey(
              const Key('roster-preview'),
              skipOffstage: false,
            ))
            .onPressed,
        isNotNull,
      );
      await tester.ensureVisible(
        find.byKey(const Key('roster-preview-people-toggle')),
      );
      await tester.tap(find.byKey(const Key('roster-preview-people-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Z Personel'), findsOneWidget);
      expect(find.text('A Personel'), findsOneWidget);
      expect(find.textContaining('Heybet personeli'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Çıktı Hazırla'), findsOneWidget);
      expect(find.byKey(const ValueKey('selected-card-2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('roster-previous-tab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('selected-card-3')), findsOneWidget);
      await tester.tap(find.byKey(const Key('roster-today-tab')));
      await tester.pumpAndSettle();
      // Geri dönüldüğünde de seçilenler altta bulunmamalı
      expect(find.byKey(const ValueKey('current-activity-2')), findsNothing);

      await tester.tap(find.byKey(const Key('roster-sort')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('remove-card-2')));
      await tester.tap(find.byKey(const Key('remove-card-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roster-sort')));
      await tester.pumpAndSettle();

      // Üstten kaldırılan kart alttaki seçim havuzuna geri döndü
      expect(find.byKey(const ValueKey('selected-card-2')), findsNothing);
      expect(find.byKey(const ValueKey('current-activity-2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('roster-preview')));
      await waitFor(tester, find.text('Çıktı Hazırlığı'));
      await tester.ensureVisible(
        find.byKey(const Key('roster-preview-people-toggle')),
      );
      await tester.tap(find.byKey(const Key('roster-preview-people-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('A Personel'), findsOneWidget);
      expect(find.textContaining('Z Personel'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'shows separate day counts and one unique total for an overlapping person',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.runAsync(() async {
        await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
            kullaniciAdi: 'admin', rol: 'yönetici'));
        for (final name in ['Ortak Kişi', 'Bugünün Kişisi']) {
          await db.into(db.personelTable).insert(
                PersonelTableCompanion.insert(
                  adSoyad: name,
                  rutbe: 'J.Uzm.Çvş.',
                  birlik: '',
                  kayitTarihi: '',
                ),
              );
        }
        for (final date in ['2026-10-05', '2026-10-06']) {
          final cardId = await db.into(db.gunlukFaaliyetTable).insert(
                GunlukFaaliyetTableCompanion.insert(
                  faaliyetAdi: 'HEYBET',
                  tarih: date,
                  olusturanKullanici: 'admin',
                  olusturmaTarihi: '',
                ),
              );
          for (final personId in cardId == 1 ? [1] : [1, 2]) {
            await db.into(db.faaliyetPersonelAtamaTable).insert(
                  FaaliyetPersonelAtamaTableCompanion.insert(
                    faaliyetId: cardId,
                    personelId: personId,
                    gorevVeyaIzin: 'HAZIR KITA',
                    durum: 'onaylandi',
                  ),
                );
          }
        }
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((ref) => const UserSessionState(
                username: 'admin',
                role: UserRole.admin,
              )),
        ],
        child: const MaterialApp(
          home: RosterOutputScreen(initialDate: '2026-10-06'),
        ),
      ));
      await waitFor(tester, find.byKey(const Key('roster-today-tab')));
      await tester.tap(find.byKey(const ValueKey('current-activity-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roster-previous-tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('previous-activity-1')));
      await waitFor(
          tester, find.textContaining('1 ortak kişi çıktıda bir kez'));
      expect(
          tester
              .widget<Text>(find.byKey(const Key('roster-total-people')))
              .data,
          '2');
      expect(find.text('2 kişiyle önizle'), findsOneWidget);
      expect(find.text('1 kişi'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'empty preparation fits narrow screens and refuses preview without a session',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userSessionProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: RosterOutputScreen(initialDate: '2026-10-06'),
          ),
        ),
      );
      await waitFor(tester, find.textContaining('Oturum doğrulanamadı'));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('roster-preview')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
