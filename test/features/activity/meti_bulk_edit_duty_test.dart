import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/edit_activity_block_dialog.dart';

void main() {
  testWidgets('bulk edit uses shared duty order and saves METİ',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ParsedActivityBlock? result;
    final block = ParsedActivityBlock(
        rawTitle: 'Test',
        parsedTimName: '',
        parsedActivityType: 'HEYBET',
        parsedDate: '2026-10-29',
        personnelList: []);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => TextButton(
          onPressed: () async {
            result = await EditActivityBlockDialog.show(context, block);
          },
          child: const Text('Aç')),
    ))));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    final dropdown = tester
        .widgetList<DropdownButton<String>>(find.byType(DropdownButton<String>))
        .singleWhere((dropdown) =>
            dropdown.items!.any((item) => item.value == 'KULE NÖB.'));
    expect(dropdown.items!.map((item) => item.value),
        DutyOrLeaveType.allDuties.where(DutyOrLeaveType.isOperationalDuty));
    expect(dropdown.items!.map((item) => item.value), contains('METİ'));
    dropdown.onChanged!('METİ');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bulk-edit-save')));
    await tester.pumpAndSettle();
    expect(result!.parsedActivityType, 'METİ');
    expect(tester.takeException(), isNull);
  });
}
