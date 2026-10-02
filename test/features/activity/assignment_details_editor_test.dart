import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/view_models/activity_form_draft.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_assignment_details_editor.dart';

void main() {
  testWidgets('remaining single person displays their retained duty override',
      (tester) async {
    final draft = ActivityFormDraft(initialDate: DateTime(2026, 10, 3))
      ..setCommonDuty(DutyOrLeaveType.gorevli)
      ..togglePersonnel(1)
      ..togglePersonnel(2)
      ..setDutyOverride(1, DutyOrLeaveType.nobetci)
      ..togglePersonnel(2);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ActivityAssignmentDetailsEditor(
      people: const [
        PersonelTableData(
            id: 1,
            adSoyad: 'Ahmet',
            rutbe: 'J.Asb.',
            birlik: 'Asayiş',
            kayitTarihi: '2026-10-03')
      ],
      squadNames: const {},
      draft: draft,
      duties: const [DutyOrLeaveType.gorevli, DutyOrLeaveType.nobetci],
      isAdmin: true,
      onChangePerson: () {},
      onChanged: () {},
    ))));
    expect(find.byKey(const Key('assignment-duty-1-NÖBETÇİ')), findsOneWidget);
    expect(find.byKey(const Key('assignment-note-1')), findsNothing);
  });
}
