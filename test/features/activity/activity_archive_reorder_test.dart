import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('dragging a card stores the new order for the day', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
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

    await tester.tap(find.byKey(const Key('activity-reorder-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-reorder-list')), findsOneWidget);

    // Default order is newest first: id 2 sits above id 1.
    final firstHandle = find.byIcon(Icons.drag_indicator_rounded).first;
    final cardHeight =
        tester.getSize(find.byKey(const Key('activity-card-2'))).height;

    final gesture = await tester.startGesture(
      tester.getCenter(firstHandle),
    );
    await tester.pump(kLongPressTimeout);
    await gesture.moveBy(Offset(0, cardHeight + 40));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('activity_card_order_$todayStr'),
      <String>['1', '2'],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
