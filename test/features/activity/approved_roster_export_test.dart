import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';

void main() {
  testWidgets('archive text export includes only approved operational personnel', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final activity = await db.into(db.gunlukFaaliyetTable).insert(
      GunlukFaaliyetTableCompanion.insert(faaliyetAdi: 'Heybet', tarih: today,
        olusturanKullanici: 'admin', olusturmaTarihi: today),
    );
    for (final entry in [
      ('Onaylı KİŞİ', AssignmentStatus.onaylandi, 'HEYBET'),
      ('Bekleyen KİŞİ', AssignmentStatus.beklemede, 'HEYBET'),
      ('Reddedilen KİŞİ', AssignmentStatus.reddedildi, 'HEYBET'),
      ('İzinli KİŞİ', AssignmentStatus.onaylandi, 'İZİNLİ'),
    ]) {
      final person = await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
        adSoyad: entry.$1, rutbe: 'J.Er', birlik: '1/B', kayitTarihi: today,
      ));
      await db.into(db.faaliyetPersonelAtamaTable).insert(FaaliyetPersonelAtamaTableCompanion.insert(
        faaliyetId: activity, personelId: person, gorevVeyaIzin: entry.$3, durum: entry.$2,
      ));
    }
    final sharedTexts = <String>[];
    const share = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(share, (call) async {
      final args = call.arguments as Map;
      sharedTexts.add(args['text'] as String);
      return 'test.viewer';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(share, null));
    await tester.pumpWidget(ProviderScope(overrides: [
      databaseProvider.overrideWithValue(db),
      userSessionProvider.overrideWith((ref) => const UserSessionState(username: 'admin', role: UserRole.admin)),
    ], child: const MaterialApp(home: ActivityArchiveScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Arşiv işlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dışa Aktar / Yazdır'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metin Listesi Paylaş'));
    await tester.pumpAndSettle();
    expect(sharedTexts, hasLength(1));
    expect(sharedTexts.single, contains('Onaylı KİŞİ'));
    expect(sharedTexts.single, isNot(contains('Bekleyen KİŞİ')));
    expect(sharedTexts.single, isNot(contains('Reddedilen KİŞİ')));
    expect(sharedTexts.single, isNot(contains('İzinli KİŞİ')));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
