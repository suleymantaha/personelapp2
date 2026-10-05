import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';

void main() {
  testWidgets(
    'only separate Excel action adds previous day; normal text stays unchanged',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (final name in ['Bugünün personeli', 'Önceki gün personeli']) {
        await db.into(db.personelTable).insert(
              PersonelTableCompanion.insert(
                adSoyad: name,
                rutbe: 'J.Uzm.Çvş.',
                birlik: 'Eski birlik',
                kayitTarihi: '',
              ),
            );
      }
      for (final date in ['2026-08-01', '2026-08-02']) {
        await db.into(db.gunlukFaaliyetTable).insert(
              GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: 'Heybet',
                tarih: date,
                olusturanKullanici: 'admin',
                olusturmaTarihi: date,
              ),
            );
      }
      await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: 1,
              personelId: 2,
              gorevVeyaIzin: 'HAZIR KITA',
              durum: 'onaylandi',
              aciklama: const Value('Eklenmemeli'),
            ),
          );
      await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: 2,
              personelId: 1,
              gorevVeyaIzin: 'HAZIR KITA',
              durum: 'onaylandi',
              aciklama: const Value('Eklenmemeli'),
            ),
          );
      await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Devriye',
              tarih: '2026-08-01',
              olusturanKullanici: 'admin',
              olusturmaTarihi: '2026-08-01'));
      final activity = (await db.select(db.gunlukFaaliyetTable).get())
          .singleWhere((a) => a.id == 2);
      final assignments = await db.select(db.faaliyetPersonelAtamaTable).get();
      final personnel = await db.select(db.personelTable).get();
      final dir = Directory.systemTemp.createTempSync('separate_heybet_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final shares = <Map<dynamic, dynamic>>[];
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(paths, (_) async => dir.path);
      addTearDown(() => messenger.setMockMethodCallHandler(paths, null));
      const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        shares.add(call.arguments as Map<dynamic, dynamic>);
        return 'dev.test.viewer';
      });
      addTearDown(() => messenger.setMockMethodCallHandler(shareChannel, null));
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
            allPersonnelProvider.overrideWith((ref) => Stream.value(personnel)),
            allSquadsProvider.overrideWith(
              (ref) => Stream.value(<TimTableData>[]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ActivityAssignmentDetails(
                activity: activity,
                assignments: assignments
                    .where((a) => a.faaliyetId == activity.id)
                    .toList(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Önceki gün personeli'), findsNothing);
      Future<void> choose(String label) async {
        await tester.tap(find.byTooltip('Bu Faaliyeti Dışa Aktar'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final expectedShares = shares.length + 1;
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          if (label == 'Önceki Gün Kartlarıyla Ayrı Excel') {
            for (var wait = 0;
                wait < 100 &&
                    find
                        .text('Önceki Günün Tüm Faaliyetleri')
                        .evaluate()
                        .isEmpty;
                wait++) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              await tester.pump();
            }
            expect(find.text('Devriye'), findsOneWidget);
            expect(shares.length, expectedShares - 1);
            expect(
                tester
                    .widget<FilledButton>(
                        find.widgetWithText(FilledButton, 'Önizleme (0)'))
                    .onPressed,
                isNull);
            await tester.tap(find.byKey(const ValueKey('previous-activity-1')));
            await tester.pump();
            await tester.tap(find.text('Önizleme (1)'));
            for (var wait = 0;
                wait < 100 &&
                    find.text('Ayrı Excel Önizlemesi').evaluate().isEmpty;
                wait++) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              await tester.pump();
            }
            expect(find.text('Ayrı Excel Önizlemesi'), findsOneWidget);
            expect(find.textContaining('Önceki gün personeli'), findsOneWidget);
            expect(shares.length, expectedShares - 1);
            await tester.tap(find.text('Excel’i Paylaş'));
            await tester.pumpAndSettle();
          }
          for (var wait = 0;
              wait < 100 && shares.length < expectedShares;
              wait++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
          }
          expect(shares.length, expectedShares);
        });
        await tester.pumpAndSettle();
      }

      await choose('Metin olarak paylaş');
      expect(shares.single['text'], contains('Bugünün personeli'));
      expect(shares.single['text'], isNot(contains('Önceki gün personeli')));
      expect(shares.single['text'], contains('Eski birlik'));
      expect(shares.single['text'], contains('HAZIR KITA'));
      List<String> excelValues(Map<dynamic, dynamic> share) {
        final path = (share['paths'] as List).single as String;
        return Excel.decodeBytes(File(path).readAsBytesSync())['İsim Listesi']
            .rows
            .expand((r) => r)
            .map((cell) => cell?.value?.toString() ?? '')
            .toList();
      }

      await choose('Excel’e aktar');
      final normalExcel = excelValues(shares.last);
      expect(normalExcel, isNot(contains('Önceki gün personeli')));
      expect(normalExcel, contains('Eski birlik'));
      expect(normalExcel, contains('HAZIR KITA'));
      final combinedPaths = <String>[];
      for (var repeat = 0; repeat < 2; repeat++) {
        await choose('Önceki Gün Kartlarıyla Ayrı Excel');
        final path = (shares.last['paths'] as List).single as String;
        combinedPaths.add(path);
        final workbook = Excel.decodeBytes(File(path).readAsBytesSync());
        final sheet = workbook['İsim Listesi'];
        expect(sheet.spannedItems, isEmpty);
        for (var index = 2; index < 4; index++) {
          expect(
              sheet
                  .cell(CellIndex.indexByColumnRow(
                      columnIndex: 1, rowIndex: index))
                  .value
                  ?.toString(),
              'J.Komd.Öz.Hrk.Tb.Klığı');
          expect(
              sheet
                      .cell(CellIndex.indexByColumnRow(
                          columnIndex: 4, rowIndex: index))
                      .value
                      ?.toString() ??
                  '',
              '');
        }
        final values = workbook['İsim Listesi']
            .rows
            .expand((r) => r)
            .map((cell) => cell?.value?.toString() ?? '')
            .toList();
        expect(values.indexOf('Bugünün personeli'),
            lessThan(values.indexOf('Önceki gün personeli')));
        expect(values, contains('J.Komd.Öz.Hrk.Tb.Klığı'));
        expect(values, isNot(contains('Eski birlik')));
        expect(values, isNot(contains('Eklenmemeli')));
        expect(values, isNot(contains('HAZIR KITA')));
        expect(
            shares.last['text'], contains('Seçilen Önceki Gün Faaliyetleri'));
      }
      expect(combinedPaths.first, isNot(combinedPaths.last));
      await choose('Excel’e aktar');
      expect(excelValues(shares.last), normalExcel);
      await choose('Metin olarak paylaş');
      expect(shares.last['text'], shares.first['text']);
      expect(await db.select(db.faaliyetPersonelAtamaTable).get(), assignments);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
