import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';
import 'package:personelapp2/features/activity/services/activity_order_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const preferences = ActivityOrderPreferences();
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  test('manual order is stored and cleared per day', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    expect(await preferences.loadOrder(todayStr), isEmpty);

    await preferences.saveOrder(todayStr, [3, 1, 2]);
    expect(await preferences.loadOrder(todayStr), [3, 1, 2]);
    expect(await preferences.loadOrder('2020-01-01'), isEmpty);

    await preferences.clearOrder(todayStr);
    expect(await preferences.loadOrder(todayStr), isEmpty);
  });

  testWidgets('saved order decides how archive cards are stacked', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'activity_card_order_$todayStr': <String>['1', '2'],
    });
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final activities = [
      GunlukFaaliyetTableData(
        id: 1,
        faaliyetAdi: 'Birinci Faaliyet',
        tarih: todayStr,
        olusturanKullanici: 'admin',
        olusturmaTarihi: '',
      ),
      GunlukFaaliyetTableData(
        id: 2,
        faaliyetAdi: 'İkinci Faaliyet',
        tarih: todayStr,
        olusturanKullanici: 'admin',
        olusturmaTarihi: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          filteredActivitiesProvider.overrideWith(
            (ref) => Stream.value(activities),
          ),
          allPersonnelProvider.overrideWith((ref) => Stream.value(const [])),
          allSquadsProvider.overrideWith((ref) => Stream.value(const [])),
          pendingAssignmentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        child: const MaterialApp(home: ActivityArchiveScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Default sorting puts the newest activity (id 2) first; the saved order
    // must override that and lift id 1 to the top.
    final firstCardTop =
        tester.getTopLeft(find.byKey(const Key('activity-card-1'))).dy;
    final secondCardTop =
        tester.getTopLeft(find.byKey(const Key('activity-card-2'))).dy;
    expect(firstCardTop, lessThan(secondCardTop));

    // The reorder mode swaps the plain list for a draggable one.
    await tester.tap(find.byKey(const Key('activity-reorder-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-reorder-list')), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
