import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/notifications/app_notification.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';

void main() {
  late AppDatabase db;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });
  tearDown(() => db.close());
  for (final scenario in ['admin', 'commander', 'selected-reassigned', 'pdf-revoked']) {
    final commander = scenario != 'admin';
    testWidgets(
      'archive text export approval and team scope scenario=$scenario',
      (tester) async {
        tester.view.physicalSize = const Size(500, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final team = await db
            .into(db.timTable)
            .insert(
              TimTableCompanion.insert(timAdi: '1-B', olusturmaTarihi: today),
            );
        final otherTeam = await db
            .into(db.timTable)
            .insert(
              TimTableCompanion.insert(timAdi: '2-B', olusturmaTarihi: today),
            );
        if (commander) {
          final user = await db
              .into(db.kullaniciTable)
              .insert(
                KullaniciTableCompanion.insert(
                  kullaniciAdi: 'komutan',
                  rol: 'tim_komutani',
                  timId: Value(team),
                ),
              );
          await (db.update(db.timTable)..where(
            (t) => t.id.equals(team),
          )).write(TimTableCompanion(timKomutaniId: Value(user)));
        }
        final activity = await db
            .into(db.gunlukFaaliyetTable)
            .insert(
              GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: 'Heybet',
                tarih: today,
                olusturanKullanici: 'admin',
                olusturmaTarihi: today,
              ),
            );
        for (final entry in [
          ('Onaylı KİŞİ', AssignmentStatus.onaylandi, 'HEYBET'),
          ('Bekleyen KİŞİ', AssignmentStatus.beklemede, 'HEYBET'),
          ('Reddedilen KİŞİ', AssignmentStatus.reddedildi, 'HEYBET'),
          ('İzinli KİŞİ', AssignmentStatus.onaylandi, 'İZİNLİ'),
          ('Diğer Tim KİŞİ', AssignmentStatus.onaylandi, 'HEYBET'),
        ]) {
          final person = await db
              .into(db.personelTable)
              .insert(
                PersonelTableCompanion.insert(
                  adSoyad: entry.$1,
                  rutbe: 'J.Er',
                  birlik: '1/B',
                  kayitTarihi: today,
                ),
              );
          await db
              .into(db.faaliyetPersonelAtamaTable)
              .insert(
                FaaliyetPersonelAtamaTableCompanion.insert(
                  faaliyetId: activity,
                  personelId: person,
                  gorevVeyaIzin: entry.$3,
                  durum: entry.$2,
                  gorevTimId: Value(
                    entry.$1 == 'Diğer Tim KİŞİ' ? otherTeam : team,
                  ),
                  gorevTimAdi: Value(
                    entry.$1 == 'Diğer Tim KİŞİ' ? '2-B' : '1-B',
                  ),
                ),
              );
        }
        final sharedTexts = <String>[];
        const share = MethodChannel('dev.fluttercommunity.plus/share');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(share, (call) async {
          final args = call.arguments as Map<dynamic, dynamic>;
          sharedTexts.add(args['text'] as String);
          return 'test.viewer';
        });
        addTearDown(() => messenger.setMockMethodCallHandler(share, null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              userSessionProvider.overrideWith(
                (ref) => UserSessionState(
                  username: commander ? 'komutan' : 'admin',
                  role: commander ? UserRole.teamCommander : UserRole.admin,
                  timId: commander ? team : null,
                ),
              ),
            ],
            child: const MaterialApp(home: ActivityArchiveScreen()),
          ),
        );
        await tester.pumpAndSettle();
        if (scenario == 'selected-reassigned') {
          await tester.tap(find.byKey(Key('activity-card-$activity')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(Key('activity-team-select-$team')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('export-selected-teams')));
          await tester.pumpAndSettle();
          await (db.update(db.kullaniciTable)..where((u) => u.kullaniciAdi.equals('komutan')))
              .write(KullaniciTableCompanion(timId: Value(otherTeam)));
          await (db.update(db.timTable)..where((t) => t.id.equals(team)))
              .write(const TimTableCompanion(timKomutaniId: Value(null)));
          final account = await (db.select(db.kullaniciTable)..where((u) => u.kullaniciAdi.equals('komutan'))).getSingle();
          await (db.update(db.timTable)..where((t) => t.id.equals(otherTeam)))
              .write(TimTableCompanion(timKomutaniId: Value(account.id)));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Metin Listesi Paylaş'));
          await tester.pumpAndSettle();
          expect(sharedTexts, isEmpty);
          expect(tester.takeException(), isNull);
        } else {
          await tester.tap(find.byTooltip('Arşiv işlemleri'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Dışa Aktar / Yazdır'));
          await tester.pumpAndSettle();
          if (scenario == 'pdf-revoked') {
            await tester.tap(find.text('PDF Belgesi Paylaş'));
            await tester.pumpAndSettle();
            await (db.update(db.timTable)..where((t) => t.id.equals(team)))
                .write(const TimTableCompanion(timKomutaniId: Value(null)));
            await tester.pumpAndSettle();
            while (AppNotifications.controller.current != null) {
              AppNotifications.controller.dismiss();
            }
            await tester.tap(find.text('Stil 1: Dikey Blok Mimarisi (VIP Format)'));
            await tester.pumpAndSettle();
            expect(AppNotifications.controller.current?.message, contains('Tim yetkiniz sona erdi'));
            expect(sharedTexts, isEmpty);
            expect(tester.takeException(), isNull);
          } else {
            await tester.tap(find.text('Metin Listesi Paylaş'));
            await tester.pumpAndSettle();
        expect(sharedTexts, hasLength(1));
        expect(sharedTexts.single, contains('Onaylı KİŞİ'));
        expect(
          sharedTexts.single,
          commander
              ? isNot(contains('Diğer Tim KİŞİ'))
              : contains('Diğer Tim KİŞİ'),
        );
        expect(sharedTexts.single, isNot(contains('Bekleyen KİŞİ')));
        expect(sharedTexts.single, isNot(contains('Reddedilen KİŞİ')));
        expect(sharedTexts.single, isNot(contains('İzinli KİŞİ')));
          }
        }
        while (AppNotifications.controller.current != null) {
          AppNotifications.controller.dismiss();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 10));
      },
    );
  }
}
