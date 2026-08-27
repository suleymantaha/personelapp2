import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_summary_card.dart';

void main() {
  testWidgets('long press starts selection and selected-mode tap toggles', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    var longPressCount = 0;
    var toggleCount = 0;
    const activity = GunlukFaaliyetTableData(
      id: 42,
      faaliyetAdi: 'Günlük Tüm Faaliyetler',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          allPersonnelProvider.overrideWith((ref) => Stream.value(const [])),
          allSquadsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onDateChanged: (_) {},
              selectionMode: true,
              isSelected: true,
              onLongPress: () => longPressCount++,
              onSelectionToggle: () => toggleCount++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final card = find.byKey(const Key('activity-card-42'));
    expect(card, findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.longPress(card);
    await tester.pump();
    expect(longPressCount, 1);

    await tester.tap(card);
    await tester.pump();
    expect(toggleCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  for (final width in [320.0, 360.0, 520.0, 800.0]) {
    testWidgets('long activity title stays readable at ${width.toInt()} px', (
      tester,
    ) async {
      tester.view
        ..physicalSize = Size(width, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      const activity = GunlukFaaliyetTableData(
        id: 81,
        faaliyetAdi:
            'Günlük Tüm Faaliyetler ve Uzun Süreli Koordinasyon Toplantısı',
        tarih: '2026-07-31',
        olusturanKullanici: 'Admin (Toplu Aktarım ve Arşiv Kullanıcısı)',
        olusturmaTarihi: '',
      );
      await database.into(database.gunlukFaaliyetTable).insert(activity);
      final personId = await database
          .into(database.personelTable)
          .insert(
            PersonelTableCompanion.insert(
              adSoyad: 'Uzun İsimli Test Personeli',
              rutbe: 'Astsubay',
              birlik: 'Merkez',
              kayitTarihi: '2026-07-31',
            ),
          );
      await database
          .into(database.faaliyetPersonelAtamaTable)
          .insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activity.id,
              personelId: personId,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: 'beklemede',
            ),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            userSessionProvider.overrideWith(
              (ref) => const UserSessionState(
                username: 'admin',
                role: UserRole.admin,
              ),
            ),
            allPersonnelProvider.overrideWith((ref) => Stream.value(const [])),
            allSquadsProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ActivityCard(activity: activity, onDateChanged: (_) {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(find.text(activity.faaliyetAdi));
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(find.text('ADMIN ONAYI BEKLİYOR'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      if (width < 520) {
        expect(find.byKey(const Key('activity-actions-81')), findsOneWidget);
        expect(find.byIcon(Icons.edit_calendar_outlined), findsNothing);

        await tester.tap(find.byKey(const Key('activity-actions-81')));
        await tester.pumpAndSettle();
        expect(find.text('Faaliyet adını değiştir'), findsOneWidget);
      } else {
        expect(find.byKey(const Key('activity-actions-81')), findsNothing);
        expect(find.byIcon(Icons.edit_calendar_outlined), findsOneWidget);
        expect(
          find.byIcon(Icons.drive_file_rename_outline_rounded),
          findsOneWidget,
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });
  }

  testWidgets('admin renames an activity from the card menu', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const activity = GunlukFaaliyetTableData(
      id: 91,
      faaliyetAdi: 'Eski Faaliyet',
      tarih: '2026-08-27',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '',
    );
    await database.into(database.gunlukFaaliyetTable).insert(activity);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          userSessionProvider.overrideWith(
            (ref) =>
                const UserSessionState(username: 'admin', role: UserRole.admin),
          ),
          allPersonnelProvider.overrideWith((ref) => Stream.value(const [])),
          allSquadsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ActivityCard(activity: activity, onDateChanged: _ignoreDate),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('activity-actions-91')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Faaliyet adını değiştir'));
    await tester.pumpAndSettle();

    expect(find.text('Faaliyet Adını Değiştir'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('activity-name-field')),
      'Yeni Nöbet',
    );
    await tester.tap(find.text('KAYDET'));
    await tester.pumpAndSettle();

    final renamed = await (database.select(
      database.gunlukFaaliyetTable,
    )..where((table) => table.id.equals(91))).getSingle();
    expect(renamed.faaliyetAdi, 'Yeni Nöbet');
  });
}

void _ignoreDate(String _) {}
