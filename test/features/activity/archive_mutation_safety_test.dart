import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/edit_assignment_dialog.dart';

const _admin = UserSessionState(username: 'admin', role: UserRole.admin);
const _row = FaaliyetPersonelAtamaTableData(
    id: 1,
    faaliyetId: 1,
    personelId: 1,
    gorevVeyaIzin: 'GÖREVLİ',
    durum: 'onaylandi');

class _SlowDatabase extends AppDatabase {
  _SlowDatabase() : super(NativeDatabase.memory());
  final completion = Completer<void>();
  int calls = 0;
  bool hold = false;
  bool fail = false;
  @override
  Future<T> transaction<T>(Future<T> Function() action,
      {bool requireNew = false}) async {
    if (hold) {
      calls++;
      await completion.future;
      if (fail) throw StateError('Sentetik hata');
    }
    return super.transaction(action, requireNew: requireNew);
  }
}

void main() {
  test('delete revalidates persisted admin role and preserves data on denial',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
        kullaniciAdi: 'admin', rol: 'tim_komutani'));
    final id = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Test',
            tarih: '2026-11-01',
            olusturanKullanici: 'admin',
            olusturmaTarihi: ''));
    final dynamic repo = ActivityRepository(db);
    await expectLater(repo.deleteActivity(activityId: id, actor: _admin),
        throwsA(isA<Exception>()));
    expect(await db.select(db.gunlukFaaliyetTable).get(), hasLength(1));
  });

  test('authorized admin can delete activity', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    final id = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Test',
            tarih: '2026-11-01',
            olusturanKullanici: 'admin',
            olusturmaTarihi: ''));
    final dynamic repo = ActivityRepository(db);
    expect(await repo.deleteActivity(activityId: id, actor: _admin), 1);
    expect(await db.select(db.gunlukFaaliyetTable).get(), isEmpty);
  });

  for (final fail in [false, true]) {
    testWidgets('desktop edit single flight and visible generic error=$fail',
        (tester) async {
      final db = _SlowDatabase();
      final repo = ActivityRepository(db);
      await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
          adSoyad: 'Test',
          rutbe: 'J.Uzm.Çvş.',
          birlik: 'Test',
          kayitTarihi: '2026-11-01'));
      await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Test',
              tarih: '2026-11-01',
              olusturanKullanici: 'admin',
              olusturmaTarihi: ''));
      await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: 1,
              personelId: 1,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: 'onaylandi'));
      db.hold = true;
      db.fail = fail;
      addTearDown(db.close);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            activityRepositoryProvider.overrideWithValue(repo),
            userSessionProvider.overrideWith((_) => _admin),
          ],
          child: MaterialApp(
              home: Scaffold(
                  body: Builder(
                      builder: (context) => TextButton(
                            onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => const EditAssignmentDialog(
                                    assignment: _row,
                                    personnelName: 'Test Kişi',
                                    isAdmin: true)),
                            child: const Text('Düzenle'),
                          ))))));
      await tester.tap(find.text('Düzenle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KAYDET'));
      await tester.pump();
      await tester.tap(find.text('KAYDET'), warnIfMissed: false);
      await tester.pump();
      expect(db.calls, 1);
      db.completion.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (fail) expect(AppNotifications.controller.current, isNotNull);
      AppNotifications.controller.dismiss();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
