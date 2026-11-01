import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'roster_output_screen_test.dart' show waitFor;

void main() {
  for (final demoted in [false, true]) {
    testWidgets('default matrix loader checks live admin demoted=$demoted',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
          kullaniciAdi: 'admin', rol: 'yönetici'));
      final rows = [
        MilitaryRosterRow(
            sNu: 1,
            personelId: 1,
            birligi: '1/B',
            rutbe: 'J.Er',
            adSoyad: 'Person',
            diger: '')
      ];
      await tester.pumpWidget(ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userSessionProvider.overrideWith((ref) => const UserSessionState(
                username: 'admin', role: UserRole.admin)),
          ],
          child: MaterialApp(
              home: RosterOutputPreviewScreen(
                  date: '2026-10-06',
                  sources: const [],
                  rows: rows,
                  loadRows: () async => rows))));
      await tester.pumpAndSettle();
      if (demoted) {
        await (db.update(db.kullaniciTable)
              ..where((u) => u.kullaniciAdi.equals('admin')))
            .write(const KullaniciTableCompanion(rol: Value('tim_komutani')));
      }
      await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
      await tester.pumpAndSettle();
      if (demoted) {
        expect(find.textContaining('Oturum yetkisi artık geçerli değil'),
            findsOneWidget);
        expect(find.text('1 kişi çıktıda'), findsNothing);
      } else {
        await waitFor(tester, find.text('1 kişi çıktıda'));
        expect(find.text('1 kişi çıktıda'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 20));
    });
  }
}
