import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_add_personnel_to_activity_dialog.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';

void main() {
  testWidgets('matches pasted personnel and applies parsed duty heading',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '1. Tim',
            olusturmaTarihi: '2026-08-05',
          ),
        );
    final personnelId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ahmet YILMAZ',
            rutbe: 'J.Asb.Çvş.',
            birlik: 'Asayiş',
            timId: const Value(1),
            kayitTarihi: '2026-08-05',
          ),
        );
    final person = PersonelTableData(
      id: personnelId,
      adSoyad: 'Ahmet YILMAZ',
      rutbe: 'J.Asb.Çvş.',
      birlik: 'Asayiş',
      timId: 1,
      kayitTarihi: '2026-08-05',
    );
    const activity = GunlukFaaliyetTableData(
      id: 10,
      faaliyetAdi: 'Arşiv Faaliyeti',
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
          allPersonnelProvider.overrideWith((ref) => Stream.value([person])),
          allSquadsProvider.overrideWith(
            (ref) => Stream.value(const [
              TimTableData(id: 1, timAdi: '1. Tim', olusturmaTarihi: ''),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BulkAddPersonnelToActivityDialog(
              activity: activity,
              existingPersonnelIds: {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('activity-bulk-personnel-text')),
      'HEYBET\n1. J.Asb.Çvş. Ahmet YILMAZ',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('activity-bulk-preview-button')),
    );
    await tester.tap(find.byKey(const Key('activity-bulk-preview-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 satır'), findsOneWidget);
    expect(find.textContaining('Ahmet YILMAZ'), findsWidgets);
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('activity-bulk-save-button')),
    );
    expect(saveButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity add button offers single and bulk entry choices',
      (tester) async {
    const activity = GunlukFaaliyetTableData(
      id: 10,
      faaliyetAdi: 'Arşiv Faaliyeti',
      tarih: '2026-08-05',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
  });
}
