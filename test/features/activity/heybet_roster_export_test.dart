import 'package:drift/drift.dart';
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
    'Heybet text export appends yesterday without changing archive assignments',
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
      final activity = (await db.select(db.gunlukFaaliyetTable).get()).last;
      final assignments = await db.select(db.faaliyetPersonelAtamaTable).get();
      final personnel = await db.select(db.personelTable).get();
      final shares = <String>[];
      const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        shares.add((call.arguments as Map)['text'] as String);
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
      for (var repeat = 0; repeat < 2; repeat++) {
        await tester.tap(find.byTooltip('Bu Faaliyeti Dışa Aktar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Metin olarak paylaş'));
        await tester.pumpAndSettle();
      }
      expect(shares, hasLength(2));
      expect(shares.first, shares.last);
      final text = shares.first;
      expect(
        text.indexOf('Bugünün personeli'),
        lessThan(text.indexOf('Önceki gün personeli')),
      );
      expect(text, contains('J.Komd.Öz.Hrk.Tb.Klığı'));
      expect(text, isNot(contains('Eklenmemeli')));
      expect(text, isNot(contains('Eski birlik')));
      expect(text, isNot(contains('HAZIR KITA')));
      expect(await db.select(db.faaliyetPersonelAtamaTable).get(), assignments);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
