import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_summary_card.dart';

void main() {
  testWidgets('long press starts selection and selected-mode tap toggles', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    var longPressCount = 0;
    var toggleCount = 0;
    const activity = GunlukFaaliyetTableData(
      id: 42,
      faaliyetAdi: 'Günlük Tüm Faaliyetler',
      tarih: '2026-07-28',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          allPersonnelProvider.overrideWith((ref) => Stream.value(const [])),
          allSquadsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              onDateChanged: (_) {},
              selectionMode: true,
              isSelected: true,
              onLongPress: () => longPressCount++,
              onSelectionToggle: () => toggleCount++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('activity-card-42'));
    expect(card, findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.longPress(card);
    await tester.pump();
    expect(longPressCount, 1);

    await tester.tap(card);
    await tester.pump();
    expect(toggleCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
