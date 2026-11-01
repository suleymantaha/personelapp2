import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_preview_section.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    final team = await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: '6-B', olusturmaTarihi: '2026-01-01'));
    await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
        adSoyad: 'Hakan KAYA',
        rutbe: 'J.Uzm.Çvş.',
        birlik: '6-B',
        timId: Value(team),
        kayitTarihi: '2026-01-01'));
  });
  tearDown(() => db.close());
  Future<void> open(WidgetTester tester,
      {ProviderContainer? container,
      GunlukFaaliyetTableData? target,
      String? source}) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container ?? ProviderContainer(),
        child: MaterialApp(
            home: Scaffold(
                body: BulkImportDialog(
                    database: db,
                    activityRepository: ActivityRepository(db),
                    targetActivity: target,
                    initialText: source ??
                        '6/B Heybet Listesi\n25.07.2026\n1- J.Uzm.Çvş. Hakan KAYA')))));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'actorless preview cannot match stored people or quick-add writes',
      (tester) async {
    await open(tester);
    final preview = tester.widget<BulkImportPreviewSection>(
        find.byType(BulkImportPreviewSection));
    expect(
        preview.blocks.single.personnelList.single.matchedPersonnelId, isNull);
    expect(preview.allSquads, isEmpty);
    await tester.tap(find.byKey(const Key('bulk-person-add-new')));
    await tester.pumpAndSettle();
    expect((await db.select(db.personelTable).get()).length, 1);
    expect(await db.select(db.personelIsimTakmaAdTable).get(), isEmpty);
  });
  testWidgets(
      'all target cards use target date and session logout clears matches',
      (tester) async {
    final id = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'HEYBET',
            olusturmaTarihi: '2026-11-01',
            tarih: '2026-11-01',
            olusturanKullanici: 'admin'));
    final target = await (db.select(db.gunlukFaaliyetTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final container = ProviderContainer(overrides: [
      userSessionProvider.overrideWith((ref) =>
          const UserSessionState(username: 'admin', role: UserRole.admin))
    ]);
    addTearDown(container.dispose);
    await open(tester,
        container: container,
        target: target,
        source:
            '6/B Heybet Listesi\n25.07.2026\n1- J.Uzm.Çvş. Hakan KAYA\n\n6/B Hazır Kıta Listesi\n26.07.2026\n1- J.Uzm.Çvş. Hakan KAYA');
    final preview = tester.widget<BulkImportPreviewSection>(
        find.byType(BulkImportPreviewSection));
    expect(preview.blocks.length, 2);
    expect(preview.blocks.map((b) => b.parsedDate), everyElement(target.tarih));
    expect(preview.blocks.first.personnelList.single.matchedPersonnelId,
        isNotNull);
    container.read(userSessionProvider.notifier).state = null;
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<BulkImportPreviewSection>(
                find.byType(BulkImportPreviewSection))
            .blocks,
        isEmpty);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
  });
  testWidgets(
      'commander preview only matches current own team and revocation clears it',
      (tester) async {
    final own = (await db.select(db.timTable).get()).single.id;
    final other = await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: '7-A', olusturmaTarihi: '2026-01-01'));
    await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
        adSoyad: 'Başka KİŞİ',
        rutbe: 'J.Uzm.Çvş.',
        birlik: '7-A',
        timId: Value(other),
        kayitTarihi: '2026-01-01'));
    final account = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'cmd', rol: 'tim_komutani'));
    await PersonnelRepository(db)
        .assignCommanderToSquad(userId: account, timId: own);
    final container = ProviderContainer(overrides: [
      userSessionProvider.overrideWith((ref) => UserSessionState(
          username: 'cmd', role: UserRole.teamCommander, timId: own))
    ]);
    addTearDown(container.dispose);
    await open(tester,
        container: container,
        source:
            '6/B Heybet Listesi\n25.07.2026\n1- J.Uzm.Çvş. Hakan KAYA\n2- J.Uzm.Çvş. Başka KİŞİ');
    final preview = tester.widget<BulkImportPreviewSection>(
        find.byType(BulkImportPreviewSection));
    expect(preview.allSquads.map((t) => t.id), [own]);
    expect(preview.blocks.single.personnelList.first.matchedPersonnelId,
        isNotNull);
    expect(preview.blocks.single.personnelList.last.matchedPersonnelId, isNull);
    await PersonnelRepository(db)
        .assignCommanderToSquad(userId: account, timId: null);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<BulkImportPreviewSection>(
                find.byType(BulkImportPreviewSection))
            .blocks,
        isEmpty);
  });
  testWidgets('commander preview drops a person moved out of current team',
      (tester) async {
    final own = (await db.select(db.timTable).get()).single.id;
    final other = await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: '7-A', olusturmaTarihi: '2026-01-01'));
    final account = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'cmd', rol: 'tim_komutani'));
    await PersonnelRepository(db)
        .assignCommanderToSquad(userId: account, timId: own);
    final container = ProviderContainer(overrides: [
      userSessionProvider.overrideWith((ref) => UserSessionState(
          username: 'cmd', role: UserRole.teamCommander, timId: own))
    ]);
    addTearDown(container.dispose);
    await open(tester, container: container);
    final person = (await db.select(db.personelTable).get()).single;
    await PersonnelRepository(db)
        .updatePersonnel(person.copyWith(timId: Value(other)));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<BulkImportPreviewSection>(
                find.byType(BulkImportPreviewSection))
            .blocks,
        isEmpty);
  });
  testWidgets('demoted admin preview clears while stale session stays open',
      (tester) async {
    final container = ProviderContainer(overrides: [
      userSessionProvider.overrideWith((ref) =>
          const UserSessionState(username: 'admin', role: UserRole.admin))
    ]);
    addTearDown(container.dispose);
    await open(tester, container: container);
    expect(
        tester
            .widget<BulkImportPreviewSection>(
                find.byType(BulkImportPreviewSection))
            .blocks,
        isNotEmpty);
    await (db.update(db.kullaniciTable)
          ..where((t) => t.kullaniciAdi.equals('admin')))
        .write(const KullaniciTableCompanion(rol: Value('tim_komutani')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<BulkImportPreviewSection>(
                find.byType(BulkImportPreviewSection))
            .blocks,
        isEmpty);
  });
}
