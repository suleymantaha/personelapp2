import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/edit_activity_block_dialog.dart';

void main() {
  testWidgets(
      'editing time does not confirm a team inferred from current personnel',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final block = ParsedActivityBlock(
        rawTitle: 'HEYBET',
        parsedTimName: '1-B Timi',
        parsedActivityType: 'HEYBET',
        parsedDate: '2001-01-02',
        personnelList: []);
    ParsedActivityBlock? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await EditActivityBlockDialog.show(
                          context, block, availableSquads: [
                        const TimTableData(
                            id: 1,
                            timAdi: '1-B Timi',
                            olusturmaTarihi: '2000-01-01')
                      ]);
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('bulk-edit-time')), '08:00 - 09:00');
    await tester.tap(find.byKey(const Key('bulk-edit-save')));
    await tester.pumpAndSettle();
    expect(result!.parsedTimeRange, '08:00 - 09:00');
    expect(result!.taskTeamId, isNull);
  });
}
