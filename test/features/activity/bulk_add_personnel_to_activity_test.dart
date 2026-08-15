import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';

void main() {
  testWidgets('activity bulk option opens the full bulk import dialog',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const activity = GunlukFaaliyetTableData(
      id: 10,
      faaliyetAdi: 'Arsiv Faaliyeti',
      tarih: '2026-08-05',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '',
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
        child: const MaterialApp(
          home: Scaffold(
            body: ActivityAssignmentDetails(
              activity: activity,
              assignments: [],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('+ Personel Ekle'));
    await tester.pumpAndSettle();

    expect(find.text('Tek Personel Ekle'), findsOneWidget);
    expect(find.text('Metinden Toplu Ekle'), findsOneWidget);
    expect(find.textContaining('Metinden Personel Ekle'), findsNothing);

    await tester.tap(find.text('Metinden Toplu Ekle'));
    await tester.pumpAndSettle();

    expect(find.text('Metinden Toplu Aktarım'), findsOneWidget);
    expect(find.textContaining('Ham Metni Yapıştır'), findsOneWidget);
    expect(find.textContaining('Metinden Personel Ekle'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity bulk option saves personnel into the selected activity',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final teamId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '1. Tim',
            olusturmaTarihi: '2026-08-05',
          ),
        );
    final personId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ahmet YILMAZ',
            rutbe: 'J.Asb.Cvs.',
            birlik: 'Asayis',
            timId: Value(teamId),
            kayitTarihi: '2026-08-05',
          ),
        );
    final activityId = await database.into(database.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Hedef Faaliyet',
            tarih: '2026-08-05',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-08-05T08:00:00',
          ),
        );
    final activity = GunlukFaaliyetTableData(
      id: activityId,
      faaliyetAdi: 'Hedef Faaliyet',
      tarih: '2026-08-05',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '2026-08-05T08:00:00',
    );
    final person = PersonelTableData(
      id: personId,
      adSoyad: 'Ahmet YILMAZ',
      rutbe: 'J.Asb.Cvs.',
      birlik: 'Asayis',
      timId: teamId,
      kayitTarihi: '2026-08-05',
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
          allPersonnelProvider.overrideWith((ref) => Stream.value([person])),
          allSquadsProvider.overrideWith(
            (ref) => Stream.value([
              TimTableData(
                id: teamId,
                timAdi: '1. Tim',
                olusturmaTarihi: '2026-08-05',
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivityAssignmentDetails(
              activity: activity,
              assignments: const [],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('+ Personel Ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metinden Toplu Ekle'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      '1- J.Asb.Cvs. Ahmet YILMAZ',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bulk-import-save-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('TAMAM'), findsOneWidget);
    await tester.tap(find.text('TAMAM'));
    await tester.pumpAndSettle();

    final assignments =
        await database.select(database.faaliyetPersonelAtamaTable).get();
    expect(assignments, hasLength(1));
    expect(assignments.single.faaliyetId, activityId);
    expect(assignments.single.personelId, personId);
    expect(assignments.single.gorevVeyaIzin, 'Hedef Faaliyet');
    expect(
      await database.select(database.gunlukFaaliyetTable).get(),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });
}
