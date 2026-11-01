import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/notifications/app_notification_host.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

void main() {
  testWidgets(
      'metadata failure rolls back staged import and retry saves exactly once',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: '6-B', olusturmaTarihi: '2026-01-01'));
    await db.customStatement(
        'CREATE TRIGGER fail_import BEFORE INSERT ON ${db.topluAktarimGecmisiTable.actualTableName} BEGIN SELECT RAISE(ABORT, "metadata failure"); END');
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    await tester.pumpWidget(ProviderScope(
        overrides: [
          userSessionProvider.overrideWith((ref) =>
              const UserSessionState(username: 'admin', role: UserRole.admin))
        ],
        child: MaterialApp(
            home: AppNotificationHost(
                child: Scaffold(
                    body: Builder(
                        builder: (context) => FilledButton(
                            onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => BulkImportDialog(
                                    database: db,
                                    activityRepository: ActivityRepository(db),
                                    initialText:
                                        '6/B Heybet Listesi\n$date\n1- J.Uzm.Çvş. Hakan KAYA')),
                            child: const Text('İçe aktar'))))))));
    await tester.tap(find.text('İçe aktar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bulk-person-add-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bulk-import-save-button')));
    await tester.pumpAndSettle();
    expect(await db.select(db.personelTable).get(), isEmpty);
    expect(await db.select(db.timUyelikGecmisiTable).get(), isEmpty);
    expect(await db.select(db.gunlukFaaliyetTable).get(), isEmpty);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
    expect(await db.select(db.personelIsimTakmaAdTable).get(), isEmpty);
    expect(await db.select(db.topluAktarimGecmisiTable).get(), isEmpty);
    await db.customStatement('DROP TRIGGER fail_import');
    await tester.tap(find.byKey(const Key('bulk-import-save-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect((await db.select(db.personelTable).get()).length, 1,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '));
    expect((await db.select(db.faaliyetPersonelAtamaTable).get()).length, 1);
    expect((await db.select(db.personelIsimTakmaAdTable).get()).length, 1);
    expect((await db.select(db.topluAktarimGecmisiTable).get()).length, 1);
    await tester.tap(find.text('TAMAM'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
