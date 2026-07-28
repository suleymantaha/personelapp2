import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_assignment_groups.dart';

void main() {
  const personnel = {
    1: PersonelTableData(
      id: 1,
      adSoyad: 'Ziya KAYA',
      rutbe: 'J.Uzm.Çvş.',
      birlik: 'K.H',
      timId: 1,
      kayitTarihi: '2026-01-01',
    ),
    2: PersonelTableData(
      id: 2,
      adSoyad: 'Ahmet YILMAZ',
      rutbe: 'J.Bnb.',
      birlik: 'K.H',
      timId: 1,
      kayitTarihi: '2026-01-01',
    ),
    3: PersonelTableData(
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
      faaliyetId: 10,
      personelId: 1,
      gorevVeyaIzin: 'HEYBET',
      durum: 'onaylandi',
    ),
    FaaliyetPersonelAtamaTableData(
      id: 2,
      faaliyetId: 10,
      personelId: 2,
      gorevVeyaIzin: 'HEYBET',
      durum: 'onaylandi',
    ),
    FaaliyetPersonelAtamaTableData(
      id: 3,
      faaliyetId: 10,
      personelId: 3,
      gorevVeyaIzin: 'HEYBET',
      durum: 'onaylandi',
    ),
  ];

  Widget buildSubject({int? selectedSquadId}) {
    return MaterialApp(
      home: Scaffold(
        body: ActivityAssignmentGroups(
          assignments: assignments,
          personnelById: personnel,
          squadNames: const {1: 'K.H', 2: '7-B Timi'},
          selectedSquadId: selectedSquadId,
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

    expect(find.text('K.H — 2 kişi'), findsOneWidget);
    expect(find.text('7-B Timi — 1 kişi'), findsOneWidget);
    expect(find.byKey(const Key('assignment-1')), findsNothing);
    expect(find.byKey(const Key('assignment-3')), findsNothing);
    expect(
      tester.getTopLeft(find.text('K.H — 2 kişi')).dy,
      lessThan(tester.getTopLeft(find.text('7-B Timi — 1 kişi')).dy),
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

  testWidgets('selected team opens automatically', (tester) async {
    await tester.pumpWidget(buildSubject(selectedSquadId: 2));

    expect(find.byKey(const Key('assignment-3')), findsOneWidget);
    expect(find.byKey(const Key('assignment-1')), findsNothing);
  });
}
