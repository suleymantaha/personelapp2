import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_form/activity_duty_picker.dart';

void main() {
  testWidgets('mobile duty picker orders Heybet/Kule/METİ and returns METİ',
      (tester) async {
    tester.view.physicalSize = const Size(466, 946);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
          onPressed: () async {
            selected = await showActivityDutyPicker(context,
                title: 'Görev seç',
                duties: DutyOrLeaveType.dutiesForRole(isAdmin: true),
                keyPrefix: 'test-duty');
          },
          child: const Text('Aç')),
    ))));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data)
        .toList();
    expect(titles.sublist(5, 10),
        ['HEYBET', 'HAZIR KITA', 'GÜLÜŞKÜR', 'KULE NÖB.', 'METİ']);
    await tester.ensureVisible(find.byKey(const ValueKey('test-duty-METİ')));
    await tester.tap(find.byKey(const ValueKey('test-duty-METİ')));
    await tester.pumpAndSettle();
    expect(selected, 'METİ');
    expect(tester.takeException(), isNull);
  });
}
