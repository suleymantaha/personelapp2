import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_duty_picker.dart';

void main() {
  testWidgets('Yönetici Kazancı görevini mevcut seçiciden atayabilir',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
          onPressed: () async {
            selected = await showActivityDutyPicker(context,
                title: 'Görev seç',
                duties: DutyOrLeaveType.dutiesForRole(isAdmin: true),
                keyPrefix: 'kazanci');
          },
          child: const Text('Aç')),
    ))));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    final option = find.byKey(const ValueKey('kazanci-KAZANCI'));
    await tester.scrollUntilVisible(option, 150,
        scrollable: find.byType(Scrollable).last);
    expect(option, findsOneWidget);
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(selected, 'KAZANCI');
    expect(tester.takeException(), isNull);
  });
}
