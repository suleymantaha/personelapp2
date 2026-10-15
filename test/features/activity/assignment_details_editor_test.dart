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
      aktif: true, isDemo: false,
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
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-personnel-1')));
    await tester.pumpAndSettle();
    expect(find.text('Farklı görev seç'), findsOneWidget);
    expect(find.text(DutyOrLeaveType.nobetci), findsOneWidget);
    expect(find.text('Not ekle veya düzenle'), findsOneWidget);
  });

  testWidgets('tapping common duty opens bottom sheet duty picker and updates selection',
      (tester) async {
    final draft = ActivityFormDraft(initialDate: DateTime(2026, 10, 3))
      ..setCommonDuty(DutyOrLeaveType.gorevli);
    var changed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ActivityAssignmentDetailsEditor(
          people: const [
            PersonelTableData(
              aktif: true,
              isDemo: false,
              id: 1,
              adSoyad: 'Ahmet',
              rutbe: 'J.Asb.',
              birlik: 'Asayiş',
              kayitTarihi: '2026-10-03',
            )
          ],
          squadNames: const {},
          draft: draft,
          duties: const [DutyOrLeaveType.gorevli, DutyOrLeaveType.nobetci],
          isAdmin: true,
          onChangePerson: () {},
          onChanged: () => changed = true,
        ),
      ),
    ));

    await tester.tap(find.byKey(const Key('common-duty-field')));
    await tester.pumpAndSettle();

    expect(find.text(DutyOrLeaveType.nobetci), findsOneWidget);
    await tester.tap(find.text(DutyOrLeaveType.nobetci));
    await tester.pumpAndSettle();

    expect(draft.commonDuty, DutyOrLeaveType.nobetci);
    expect(changed, isTrue);
  });

  testWidgets(
      'tapping personal duty override opens bottom sheet and updates duty override',
      (tester) async {
    final draft = ActivityFormDraft(initialDate: DateTime(2026, 10, 3))
      ..setCommonDuty(DutyOrLeaveType.gorevli)
      ..togglePersonnel(1)
      ..togglePersonnel(2);
    var changed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ActivityAssignmentDetailsEditor(
          people: const [
            PersonelTableData(
              aktif: true,
              isDemo: false,
              id: 1,
              adSoyad: 'Ahmet',
              rutbe: 'J.Asb.',
              birlik: 'Asayiş',
              kayitTarihi: '2026-10-03',
            ),
            PersonelTableData(
              aktif: true,
              isDemo: false,
              id: 2,
              adSoyad: 'Mehmet',
              rutbe: 'J.Uzm.',
              birlik: 'Asayiş',
              kayitTarihi: '2026-10-03',
            ),
          ],
          squadNames: const {},
          draft: draft,
          duties: const [DutyOrLeaveType.gorevli, DutyOrLeaveType.nobetci],
          isAdmin: true,
          onChangePerson: () {},
          onChanged: () => changed = true,
        ),
      ),
    ));

    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-personnel-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Farklı görev seç'));
    await tester.pumpAndSettle();

    final dutyOption = find.byKey(
      const ValueKey('personnel-duty-1-${DutyOrLeaveType.nobetci}'),
    );
    await tester.tap(dutyOption);
    await tester.pumpAndSettle();

    expect(draft.dutyFor(1), DutyOrLeaveType.nobetci);
    expect(changed, isTrue);
  });
}
