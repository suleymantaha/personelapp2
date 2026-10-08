import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/add_personnel_dialog.dart';

void main() {
  for (final width in [320.0, 412.0]) {
    for (final existing in [false, true]) {
      testWidgets('multi assignment existing=$existing at width $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final team = await db
            .into(db.timTable)
            .insert(
              TimTableCompanion.insert(
                timAdi: '1. Tim',
                olusturmaTarihi: '2026-10-03',
              ),
            );
        final person = await db
            .into(db.personelTable)
            .insert(
              PersonelTableCompanion.insert(
                adSoyad: 'Ahmet Yılmaz',
                rutbe: 'J.Asb.',
                birlik: 'Asayiş',
                timId: Value(team),
                kayitTarihi: '2026-10-03',
              ),
            );
        final second = await db
            .into(db.personelTable)
            .insert(
              PersonelTableCompanion.insert(
                adSoyad: 'Mehmet Kaya',
                rutbe: 'J.Asb.',
                birlik: 'Asayiş',
                timId: Value(team),
                kayitTarihi: '2026-10-03',
              ),
            );
        final activityId = await db
            .into(db.gunlukFaaliyetTable)
            .insert(
              GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: 'Uzun isimli arşiv faaliyeti ve gece nöbeti',
                tarih: '2026-10-03',
                olusturanKullanici: 'admin',
                olusturmaTarihi: '2026-10-02',
              ),
            );
        final activity = (await db.select(db.gunlukFaaliyetTable).get()).single;
        final people = await db.select(db.personelTable).get();
        final teams = await db.select(db.timTable).get();
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
              allPersonnelProvider.overrideWith((ref) => Stream.value(people)),
              allSquadsProvider.overrideWith((ref) => Stream.value(teams)),
            ],
            child: MaterialApp(
              theme: AppTheme.militaryTheme,
              home: Builder(
                builder:
                    (context) => Scaffold(
                      body: TextButton(
                        onPressed:
                            () => Navigator.of(context).push(
                              MaterialPageRoute<bool>(
                                builder:
                                    (_) => AddPersonnelToActivityDialog(
                                      activity: activity,
                                      isAdmin: true,
                                      existingPersonnelIds:
                                          existing ? {person} : const {},
                                    ),
                              ),
                            ),
                        child: const Text('Arşiv'),
                      ),
                    ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Arşiv'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('personnel-search-field')),
          'yilmaz',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('personnel-option-$person')));
        await tester.pumpAndSettle();
        if (existing) {
          expect(find.text('0 personel seçildi'), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Devam et'),
                )
                .onPressed,
            isNull,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Arşiv'), findsOneWidget);
          expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
          expect(tester.takeException(), isNull);
          return;
        }
        if (width == 412) {
          await tester.enterText(
            find.byKey(const Key('personnel-search-field')),
            '',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(Key('personnel-squad-select-$team')));
        } else {
          await tester.enterText(
            find.byKey(const Key('personnel-search-field')),
            'kaya',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(Key('personnel-option-$second')));
        }
        await tester.pumpAndSettle();
        expect(find.text('2 personel seçildi'), findsOneWidget);
        await tester.tap(find.text('Devam et'));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('assignment-note-$person')), findsNothing);
        await tester.tap(
          find.byKey(Key('assignment-duty-$second-${DutyOrLeaveType.gorevli}')),
        );
        await tester.pumpAndSettle();
        final targetTile = find.byKey(
          ValueKey('assignment-duty-$second-${DutyOrLeaveType.nobetci}'),
        );
        await tester.scrollUntilVisible(
          targetTile,
          50,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -100));
        await tester.pumpAndSettle();
        await tester.tap(targetTile);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Not ekle').first);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(Key('assignment-note-$person')),
          'Kapı nöbeti',
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('2 personel seçildi'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Değişikliklerden vazgeçilsin mi?'), findsOneWidget);
        await tester.tap(find.text('DÜZENLEMEYE DEVAM ET'));
        await tester.pumpAndSettle();
        expect(find.text('2 personel seçildi'), findsOneWidget);
        await tester.tap(find.text('Devam et'));
        await tester.pumpAndSettle();
        expect(find.text('Kapı nöbeti'), findsOneWidget);
        await tester.tap(find.text('Faaliyete Ekle'));
        await tester.pumpAndSettle();
        expect(find.text('Arşiv'), findsOneWidget);
        final rows = await db.select(db.faaliyetPersonelAtamaTable).get();
        expect(rows, hasLength(2));
        expect(rows.every((r) => r.faaliyetId == activityId), isTrue);
        expect(rows.map((r) => r.personelId), containsAll([person, second]));
        expect(
          rows.singleWhere((r) => r.personelId == person).aciklama,
          'Kapı nöbeti',
        );
        expect(
          rows.singleWhere((r) => r.personelId == second).gorevVeyaIzin,
          DutyOrLeaveType.nobetci,
        );
        expect(
          rows.singleWhere((r) => r.personelId == person).gorevVeyaIzin,
          DutyOrLeaveType.gorevli,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
