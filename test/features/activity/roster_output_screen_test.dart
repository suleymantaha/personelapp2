import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
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
        for (final name in ['Heybet personeli', 'Z Personel', 'A Personel']) {
          await db
              .into(db.personelTable)
              .insert(
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
          final id = await db
              .into(db.gunlukFaaliyetTable)
              .insert(
                GunlukFaaliyetTableCompanion.insert(
                  faaliyetAdi: item.$1,
                  tarih: item.$2,
                  olusturanKullanici: 'admin',
                  olusturmaTarihi: '',
                ),
              );
          await db
              .into(db.faaliyetPersonelAtamaTable)
              .insert(
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
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('current-activity-1')),
            )
            .value,
        false,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('roster-preview')))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('previous-activity-3')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('previous-activity-3')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('current-activity-2')),
      );
      await tester.tap(find.byKey(const ValueKey('current-activity-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('selected-card-1')), findsNothing);
      await tester.tap(find.byKey(const Key('roster-preview')));
      await waitFor(tester, find.text('Birleşik Çıktı Önizlemesi'));
      expect(find.text('1. Z Personel'), findsOneWidget);
      expect(find.text('2. A Personel'), findsOneWidget);
      expect(find.textContaining('Heybet personeli'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Çıktı Hazırla'), findsOneWidget);
      expect(find.byKey(const ValueKey('selected-card-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('selected-card-3')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('remove-card-2')));
      await tester.tap(find.byKey(const Key('remove-card-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roster-preview')));
      await waitFor(tester, find.text('Birleşik Çıktı Önizlemesi'));
      expect(find.text('1. A Personel'), findsOneWidget);
      expect(find.textContaining('Z Personel'), findsNothing);
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
