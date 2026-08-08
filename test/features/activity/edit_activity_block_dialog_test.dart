import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/edit_activity_block_dialog.dart';

void main() {
  testWidgets('EditActivityBlockDialog allows selecting duty via chips and dropdown', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final block = ParsedActivityBlock(
      rawTitle: 'Test Card',
      parsedTimName: '6-B',
      parsedActivityType: 'Eski Görev',
      parsedDate: '2026-08-03',
      personnelList: [],
    );

    ParsedActivityBlock? resultBlock;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  resultBlock = await EditActivityBlockDialog.show(context, block);
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Faaliyet kartını düzenle'), findsOneWidget);
    expect(find.text('Hızlı Görev Seçimi'), findsOneWidget);
    expect(find.text('HAZIR KITA'), findsOneWidget);

    // Tap quick chip "HAZIR KITA"
    await tester.tap(find.text('HAZIR KITA'));
    await tester.pumpAndSettle();

    // Tap save button
    await tester.tap(find.byKey(const Key('bulk-edit-save')));
    await tester.pumpAndSettle();

    expect(resultBlock, isNotNull);
    expect(resultBlock!.parsedActivityType, DutyOrLeaveType.hazirKita);
  });
}
