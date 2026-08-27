import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_date_navigator.dart';

void main() {
  testWidgets('date navigator moves one day in either direction', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArchiveDateNavigator(
            selectedDate: DateTime(2026, 8, 27),
            activityCount: 5,
            onDateSelected: (date) => selected = date,
          ),
        ),
      ),
    );

    expect(find.text('27 Ağustos'), findsOneWidget);
    expect(find.text('5 faaliyet'), findsOneWidget);
    expect(
      tester.getSize(find.byType(ArchiveDateNavigator)).height,
      lessThanOrEqualTo(64),
    );

    await tester.tap(find.byKey(const Key('archive-previous-day')));
    expect(selected, DateTime(2026, 8, 26));

    await tester.tap(find.byKey(const Key('archive-next-day')));
    expect(selected, DateTime(2026, 8, 28));
  });
}
