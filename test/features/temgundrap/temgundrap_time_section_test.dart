import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_time_section.dart';

void main() {
  testWidgets('askerî başlangıç ve bitiş zamanını gösterir', (tester) async {
    var startTapped = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TemgundrapTimeSection(
      startAt: DateTime(2026, 8, 6, 9, 15),
      endAt: DateTime(2026, 8, 6, 10),
      onStartTap: () => startTapped = true,
      onEndTap: () {},
    ))));
    expect(find.text('06 0915 AGU 26'), findsOneWidget);
    expect(find.text('06 1000 AGU 26'), findsOneWidget);
    await tester.tap(find.byKey(const Key('operation-start-time')));
    expect(startTapped, isTrue);
  });
}
