import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';

/// Runs the real UI/repository/export text path using synthetic, in-memory data.
/// Only the final OS share handoff is intercepted: no messages are sent.
void archiveFlowScenario(
    {Future<void> Function(String, WidgetTester)? onScreen}) {
  testWidgets(
      'archive to selected-team export and day export preserves records',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    for (final (id, name) in [(1, 'K.H'), (2, '1-B Timi')]) {
      await db.into(db.timTable).insert(TimTableCompanion.insert(
          id: Value(id), timAdi: name, olusturmaTarihi: ''));
    }
    final activity = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'TEST FAALİYETİ',
            tarih: date,
            olusturanKullanici: 'admin',
            olusturmaTarihi: ''));
    for (final (id, name, team, status) in [
      (1, 'ONAYLI TEST KİŞİSİ', 1, 'onaylandi'),
      (2, 'BEKLEYEN TEST KİŞİSİ', 1, 'beklemede'),
      (3, 'DİĞER TİM TEST KİŞİSİ', 2, 'onaylandi'),
    ]) {
      await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
          id: Value(id),
          adSoyad: name,
          rutbe: 'J.Uzm.Çvş.',
          birlik: 'Test',
          timId: Value(team),
          kayitTarihi: date));
      await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activity,
              personelId: id,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: status,
              gorevTimId: Value(team),
              gorevTimAdi: Value(team == 1 ? 'K.H' : '1-B Timi')));
    }
    final before = await db.select(db.faaliyetPersonelAtamaTable).get();
    final shared = <String>[];
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      shared.add((call.arguments as Map)['text'] as String);
      return 'test.viewer';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((_) =>
              const UserSessionState(username: 'admin', role: UserRole.admin)),
        ],
        child: MaterialApp(
            theme: AppTheme.darkMilitaryTheme,
            home: const ActivityArchiveScreen())));
    await tester.pumpAndSettle();
    if (onScreen != null) {
      await onScreen('01-archive', tester);
    }
    await tester.tap(find.byKey(Key('activity-card-$activity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-detail-screen')), findsOneWidget);
    if (onScreen != null) {
      await onScreen('02-detail', tester);
    }
    await tester.tap(find.byKey(const Key('team-selection-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-team-header-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 tim seçildi'), findsOneWidget);
    if (onScreen != null) {
      await onScreen('03-selection', tester);
    }
    await tester.tap(find.byKey(const Key('export-selected-teams')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    if (onScreen != null) {
      await onScreen('04-output', tester);
    }
    await tester.ensureVisible(find.byKey(const Key('export-option-text')));
    await tester.tap(find.byKey(const Key('export-option-text')));
    await tester.pumpAndSettle();
    expect(shared, hasLength(1));
    expect(shared.single, contains('ONAYLI TEST KİŞİSİ'));
    expect(shared.single, isNot(contains('BEKLEYEN TEST KİŞİSİ')));
    expect(shared.single, isNot(contains('DİĞER TİM TEST KİŞİSİ')));
    await tester.tap(find.byTooltip('Seçimi kapat'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('archive-export-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('activity-card-$activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('archive-export-selected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('archive-export-time-options')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '06.00-08.00');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('export-option-text')));
    await tester.tap(find.byKey(const Key('export-option-text')));
    await tester.pumpAndSettle();
    expect(shared, hasLength(2));
    expect(shared.last, contains('06.00-08.00'));
    expect(shared.last, contains('DİĞER TİM TEST KİŞİSİ'));
    expect(shared.last, isNot(contains('BEKLEYEN TEST KİŞİSİ')));
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), before);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
    await tester.pump(const Duration(milliseconds: 50));
  });
}
