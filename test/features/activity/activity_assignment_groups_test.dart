import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_assignment_groups.dart';

void main() {
  const personnel = {
    1: PersonelTableData(
      aktif: true,
      isDemo: false,
      id: 1,
      adSoyad: 'Ziya KAYA',
      rutbe: 'J.Uzm.Çvş.',
      birlik: 'K.H',
      timId: 1,
      kayitTarihi: '2026-01-01',
    ),
    2: PersonelTableData(
      aktif: true,
      isDemo: false,
      id: 2,
      adSoyad: 'Ahmet YILMAZ',
      rutbe: 'J.Bnb.',
      birlik: 'K.H',
      timId: 1,
      kayitTarihi: '2026-01-01',
    ),
    3: PersonelTableData(
      aktif: true,
      isDemo: false,
      id: 3,
      adSoyad: 'Mehmet DEMİR',
      rutbe: 'J.Asb.',
      birlik: '7-B',
      timId: 2,
      kayitTarihi: '2026-01-01',
    ),
  };
  const assignments = [
    FaaliyetPersonelAtamaTableData(
      id: 1,
      gorevTimId: 1,
      gorevTimAdi: 'K.H',
      faaliyetId: 10,
      personelId: 1,
      gorevVeyaIzin: 'HEYBET',
      durum: 'onaylandi',
    ),
    FaaliyetPersonelAtamaTableData(
      id: 2,
      gorevTimId: 1,
      gorevTimAdi: 'K.H',
      faaliyetId: 10,
      personelId: 2,
      gorevVeyaIzin: 'HEYBET',
      durum: 'onaylandi',
    ),
    FaaliyetPersonelAtamaTableData(
      id: 3,
      gorevTimId: 2,
      gorevTimAdi: '7-B Timi',
      faaliyetId: 10,
      personelId: 3,
      gorevVeyaIzin: 'HEYBET',
      durum: 'onaylandi',
    ),
  ];

  Widget buildSubject({
    List<FaaliyetPersonelAtamaTableData> visibleAssignments = assignments,
    int? selectedSquadId,
    Map<int, int?> squadOrders = const {},
    Map<int, String> squadNames = const {1: 'K.H', 2: '7-B Timi'},
    Future<void> Function(int? squadId, String squadName)? onTransferSquad,
    Future<void> Function(List<FaaliyetPersonelAtamaTableData>)?
        onExportSelected,
    Future<void> Function(List<FaaliyetPersonelAtamaTableData>)?
        onDeleteSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ActivityAssignmentGroups(
          assignments: visibleAssignments,
          personnelById: personnel,
          squadNames: squadNames,
          squadOrders: squadOrders,
          selectedSquadId: selectedSquadId,
          onTransferSquad: onTransferSquad,
          onExportSelected: onExportSelected,
          onDeleteSelected: onDeleteSelected,
          assignmentBuilder: (assignment) => Text(
            personnel[assignment.personelId]!.adSoyad,
            key: Key('assignment-${assignment.id}'),
          ),
        ),
      ),
    );
  }

  testWidgets('groups start closed and behave as an accordion', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('K.H'), findsOneWidget);
    expect(find.text('2 kişi'), findsOneWidget);
    expect(find.text('7-B Timi'), findsOneWidget);
    expect(find.text('1 kişi'), findsOneWidget);
    expect(find.text('K.H — 2 kişi'), findsNothing);
    expect(find.byKey(const Key('assignment-1')), findsNothing);
    expect(find.byKey(const Key('assignment-3')), findsNothing);
    expect(
      tester.getTopLeft(find.text('K.H')).dy,
      lessThan(tester.getTopLeft(find.text('7-B Timi')).dy),
    );

    await tester.tap(find.byKey(const Key('activity-team-header-2')));
    await tester.pump();
    expect(find.byKey(const Key('assignment-3')), findsOneWidget);
    expect(find.byKey(const Key('assignment-1')), findsNothing);

    await tester.tap(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    expect(find.byKey(const Key('assignment-3')), findsNothing);
    expect(find.byKey(const Key('assignment-1')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ahmet YILMAZ')).dy,
      lessThan(tester.getTopLeft(find.text('Ziya KAYA')).dy),
    );
  });

  testWidgets('rank wins, then saved position; transferred position is ignored',
      (tester) async {
    final people = {
      1: personnel[1]!.copyWith(sortOrder: const Value(0)),
      2: personnel[2]!.copyWith(sortOrder: const Value(9)),
      3: personnel[1]!
          .copyWith(id: 3, adSoyad: 'Ali', sortOrder: const Value(1)),
      4: personnel[1]!.copyWith(
          id: 4,
          adSoyad: 'A Transfer',
          timId: const Value(2),
          sortOrder: const Value(0)),
    };
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ActivityAssignmentGroups(
        assignments: [
          for (final id in people.keys)
            assignments[0].copyWith(id: id, personelId: id)
        ],
        personnelById: people,
        squadNames: const {1: 'K.H'},
        selectedSquadId: 1,
        assignmentBuilder: (a) => Text('row-${a.personelId}'),
      ),
    )));
    final visibleOrder = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((t) => t?.startsWith('row-') ?? false)
        .toList();
    expect(visibleOrder, ['row-2', 'row-1', 'row-3', 'row-4']);
  });

  testWidgets('saved team order overrides official order and updates live',
      (tester) async {
    await tester.pumpWidget(buildSubject(squadOrders: {1: 1, 2: 0}));
    expect(tester.getTopLeft(find.text('7-B Timi')).dy,
        lessThan(tester.getTopLeft(find.text('K.H')).dy));
    await tester.pumpWidget(buildSubject(squadOrders: {1: 0, 2: 1}));
    expect(tester.getTopLeft(find.text('K.H')).dy,
        lessThan(tester.getTopLeft(find.text('7-B Timi')).dy));
  });

  testWidgets('selected team opens automatically', (tester) async {
    await tester.pumpWidget(buildSubject(selectedSquadId: 2));

    expect(find.byKey(const Key('assignment-3')), findsOneWidget);
    expect(find.byKey(const Key('assignment-1')), findsNothing);
  });

  testWidgets('long team names remain usable at 320px with large text',
      (tester) async {
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: buildSubject(
          visibleAssignments: [
            for (final row in assignments)
              row.gorevTimId == 1
                  ? row.copyWith(
                      gorevTimAdi:
                          const Value('Çok Uzun Karargâh Hizmet Destek Timi'))
                  : row,
          ],
          squadNames: const {
            1: 'Renamed current team',
            2: '7-B Timi',
          },
          onTransferSquad: (_, __) async {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('activity-team-header-1')), findsOneWidget);
    expect(find.text('Çok Uzun Karargâh Hizmet Destek Timi'), findsOneWidget);
    expect(find.text('Renamed current team'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    expect(find.byKey(const Key('assignment-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exports and deletes all assignments from selected teams',
      (tester) async {
    List<int>? exportedIds;
    List<int>? deletedIds;
    await tester.pumpWidget(
      buildSubject(
        onExportSelected: (selected) async {
          exportedIds = selected.map((assignment) => assignment.id).toList()
            ..sort();
        },
        onDeleteSelected: (selected) async {
          deletedIds = selected.map((assignment) => assignment.id).toList()
            ..sort();
        },
      ),
    );

    // Long press to start selection mode on team 1
    await tester.longPress(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    expect(find.text('1 tim seçildi'), findsOneWidget);

    // In selection mode, single tap on team 2 toggles selection
    await tester.tap(find.byKey(const Key('activity-team-header-2')));
    await tester.pump();

    expect(find.text('2 tim seçildi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-selected-teams')));
    await tester.pump();
    expect(exportedIds, [1, 2, 3]);

    await tester.tap(find.byKey(const Key('selected-teams-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-selected-teams')));
    await tester.pump();
    expect(deletedIds, [1, 2, 3]);
    // The repository stream removes deleted rows; prune selection on refresh.
    await tester.pumpWidget(buildSubject(visibleAssignments: const []));
    await tester.pump();
    expect(find.text('2 tim seçildi'), findsNothing);
  });
}
