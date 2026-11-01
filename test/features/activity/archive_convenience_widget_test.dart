import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/reassign_existing_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_assignment_groups.dart';

final _assignments = [
  for (final (id, team) in [(11, 1), (12, 1), (13, 2), (14, 3)])
    FaaliyetPersonelAtamaTableData(
      id: id,
      faaliyetId: 70,
      personelId: id,
      gorevTimId: team,
      gorevTimAdi: 'Tim $team',
      gorevVeyaIzin: 'GÖREVLİ',
      durum: 'onaylandi',
    ),
];
final _people = {
  for (final row in _assignments)
    row.personelId: PersonelTableData(
      id: row.personelId,
      adSoyad: 'Test Personel ${row.personelId}',
      rutbe: 'J.Uzm.Çvş.',
      birlik: 'Test',
      // Everyone has moved since this archived activity was recorded.
      timId: 99,
      kayitTarihi: '2026-01-01',
      aktif: true,
      isDemo: false,
    ),
};

Widget _groups({
  Future<void> Function(List<FaaliyetPersonelAtamaTableData>)? onReassign,
  bool otherActions = false,
}) =>
    MaterialApp(
      home: Scaffold(
        body: ActivityAssignmentGroups(
          assignments: _assignments,
          personnelById: _people,
          squadNames: const {1: 'Tim 1', 2: 'Tim 2', 3: 'Tim 3'},
          onReassignSelected: onReassign,
          onExportSelected: otherActions ? (_) async {} : null,
          onDeleteSelected: otherActions ? (_) async {} : null,
          assignmentBuilder: (row) => Text('Assignment ${row.id}'),
        ),
      ),
    );

void main() {
  testWidgets('reassign receives only selected historical team assignments',
      (tester) async {
    final calls = <List<FaaliyetPersonelAtamaTableData>>[];
    await tester.pumpWidget(_groups(onReassign: (rows) async {
      calls.add(rows);
    }));
    expect(find.byKey(const Key('reassign-selected-teams')), findsNothing);

    await tester.longPress(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    expect(find.text('1 tim seçildi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('activity-team-header-2')));
    await tester.pump();
    expect(find.text('2 tim seçildi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reassign-selected-teams')));
    await tester.pump();
    expect(calls, hasLength(1));
    expect(calls.single.map((row) => row.id), unorderedEquals([11, 12, 13]));
    expect(
        calls.single.map((row) => row.gorevTimId), unorderedEquals([1, 1, 2]));
    expect(find.byTooltip('Görev Değiştir'), findsOneWidget);
  });

  testWidgets('selection toolbar fits 320px with all actions and enlarged text',
      (tester) async {
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
      child: _groups(onReassign: (_) async {}, otherActions: true),
    ));

    await tester.longPress(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    expect(find.byKey(const Key('reassign-selected-teams')), findsOneWidget);
    expect(find.byKey(const Key('export-selected-teams')), findsOneWidget);
    expect(find.byKey(const Key('delete-selected-teams')), findsNothing);
    await tester.tap(find.byKey(const Key('selected-teams-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-selected-teams')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection has no reassign action without callback',
      (tester) async {
    await tester.pumpWidget(_groups());
    await tester.longPress(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    expect(find.text('1 tim seçildi'), findsOneWidget);
    expect(find.byKey(const Key('reassign-selected-teams')), findsNothing);
  });

  for (final preselect in [false, true]) {
    testWidgets('existing assignment dialog initial selection is $preselect',
        (tester) async {
      const activity = GunlukFaaliyetTableData(
        id: 70,
        faaliyetAdi: 'GÖREVLİ',
        tarih: '2026-10-15',
        olusturanKullanici: 'admin',
        olusturmaTarihi: '',
      );
      final rows = _assignments.take(2).toList();
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: preselect
              ? ReassignExistingPersonnelDialog(
                  activity: activity,
                  assignments: rows,
                  personnelById: _people,
                  selectAllInitially: true,
                )
              : ReassignExistingPersonnelDialog(
                  activity: activity,
                  assignments: rows,
                  personnelById: _people,
                ),
        ),
      ));

      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      for (final id in [11, 12]) {
        expect(
          tester
              .widget<CheckboxListTile>(
                find.byKey(Key('archive-existing-assignment-$id')),
              )
              .value,
          preselect,
        );
      }
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('archive-existing-save')),
            )
            .onPressed,
        preselect ? isNotNull : isNull,
      );
      await tester.tap(find.byKey(const Key('archive-existing-select-all')));
      await tester.pump();
      expect(find.text('${preselect ? 0 : 2} / 2 personel seçildi'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
