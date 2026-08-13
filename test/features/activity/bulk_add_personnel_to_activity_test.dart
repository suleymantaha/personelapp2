import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_detail_sheet.dart';

void main() {
  testWidgets('activity bulk option opens the full bulk import dialog',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const activity = GunlukFaaliyetTableData(
      id: 10,
      faaliyetAdi: 'Arsiv Faaliyeti',
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
    expect(find.textContaining('Metinden Personel Ekle'), findsNothing);

    await tester.tap(find.text('Metinden Toplu Ekle'));
    await tester.pumpAndSettle();

    expect(find.text('Metinden Toplu Aktarım'), findsOneWidget);
    expect(find.textContaining('Ham Metni Yapıştır'), findsOneWidget);
    expect(find.textContaining('Metinden Personel Ekle'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
