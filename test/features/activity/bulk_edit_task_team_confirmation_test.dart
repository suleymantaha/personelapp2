import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/edit_activity_block_dialog.dart';

void main() {
  const squad =
      TimTableData(id: 7, timAdi: 'Test Timi', olusturmaTarihi: '2000-01-01');
  ParsedActivityBlock? result;

  Future<void> open(WidgetTester tester, {int? taskTeamId}) async {
    result = null;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final block = ParsedActivityBlock(
        rawTitle: 'Test',
        parsedTimName: squad.timAdi,
        parsedActivityType: 'METİ',
        parsedDate: '2001-01-02',
        taskTeamId: taskTeamId,
        personnelList: []);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await EditActivityBlockDialog.show(
                          context, block,
                          availableSquads: const [squad]);
                    },
                    child: const Text('Aç'))))));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final save = find.byKey(const Key('bulk-edit-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('inferred display never silently becomes explicit task team',
      (tester) async {
    await open(tester);
    expect(find.textContaining('Önerilen tim'), findsOneWidget);
    await save(tester);
    expect(result!.taskTeamId, isNull);
  });

  testWidgets('one explicit confirmation accepts the displayed suggested team',
      (tester) async {
    await open(tester);
    final confirm = find.byKey(const Key('bulk-edit-confirm-team'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    await save(tester);
    expect(result!.taskTeamId, squad.id);
    expect(result!.parsedTimName, squad.timAdi);
    expect(result!.parsedDate, '2001-01-02');
  });

  testWidgets('an already explicit task team needs no extra confirmation',
      (tester) async {
    await open(tester, taskTeamId: squad.id);
    expect(find.byKey(const Key('bulk-edit-confirm-team')), findsNothing);
    await save(tester);
    expect(result!.taskTeamId, squad.id);
  });
}
