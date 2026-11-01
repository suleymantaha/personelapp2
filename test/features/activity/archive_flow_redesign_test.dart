import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_assignment_groups.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_summary_card.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_date_navigator.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_export_sheet.dart';

const _activity = GunlukFaaliyetTableData(
  id: 10,
  faaliyetAdi: 'HAZIR KITA',
  tarih: '2026-11-01',
  olusturanKullanici: 'admin',
  olusturmaTarihi: '2026-11-01',
);
const _row = FaaliyetPersonelAtamaTableData(
  id: 1,
  faaliyetId: 10,
  personelId: 1,
  gorevTimId: 1,
  gorevTimAdi: 'Tarihi Tim',
  gorevVeyaIzin: 'METİ',
  durum: 'onaylandi',
);

Widget _groups(List<FaaliyetPersonelAtamaTableData> rows,
        {Future<void> Function(List<FaaliyetPersonelAtamaTableData>)?
            onDelete}) =>
    MaterialApp(
      home: Scaffold(
          body: ActivityAssignmentGroups(
        assignments: rows,
        personnelById: const {},
        squadNames: const {1: 'Yeniden adlandırılmış tim'},
        onExportSelected: (_) async {},
        onDeleteSelected: onDelete,
        assignmentBuilder: (_) => const Text('Kişi ayrıntısı'),
      )),
    );

void main() {
  testWidgets('team selection is discoverable without long press',
      (tester) async {
    await tester.pumpWidget(_groups([_row]));
    await tester.tap(find.byKey(const Key('team-selection-start')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    expect(find.text('1 tim seçildi'), findsOneWidget);
    expect(find.byKey(const Key('export-selected-teams')), findsOneWidget);
  });

  testWidgets('cancelled removal retains selected teams', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_groups([_row], onDelete: (_) async {
      calls++;
    }));
    await tester.longPress(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('selected-teams-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-selected-teams')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('1 tim seçildi'), findsOneWidget);
  });

  testWidgets('team expand button inspects people without changing selection',
      (tester) async {
    await tester.pumpWidget(_groups([_row]));
    await tester.longPress(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('activity-team-expand-1')));
    await tester.pump();
    expect(find.text('Kişi ayrıntısı'), findsOneWidget);
    expect(find.text('1 tim seçildi'), findsOneWidget);
  });

  testWidgets('stream update removes disappeared teams from selection',
      (tester) async {
    await tester.pumpWidget(_groups([_row]));
    await tester.longPress(find.byKey(const Key('activity-team-header-1')));
    await tester.pump();
    expect(find.text('1 tim seçildi'), findsOneWidget);
    await tester.pumpWidget(_groups([]));
    await tester.pump();
    expect(find.text('1 tim seçildi'), findsNothing);
    expect(find.byKey(const Key('export-selected-teams')), findsNothing);
  });

  testWidgets('team header uses saved task team name after rename',
      (tester) async {
    await tester.pumpWidget(_groups([_row]));
    expect(find.text('Tarihi Tim'), findsOneWidget);
    expect(find.text('Yeniden adlandırılmış tim'), findsNothing);
  });

  testWidgets('optional export hours are collapsed until requested',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: ArchiveExportSheet(
          subtitle: '1 Kasım 2026 · K.H · 2 kişi', showTemgundrap: false),
    )));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('1 Kasım 2026 · K.H · 2 kişi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('archive-export-time-options')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('archive date includes year', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ArchiveDateNavigator(
      selectedDate: DateTime(2031, 1, 1),
      activityCount: 2,
      onDateSelected: (_) {},
      onCalendarTap: () {},
    ))));
    expect(find.text('1 Ocak 2031'), findsOneWidget);
  });

  testWidgets(
      'compact activity opens separate detail instead of nested expansion',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.gunlukFaaliyetTable)
        .insert(GunlukFaaliyetTableCompanion.insert(
          id: const Value(10),
          faaliyetAdi: _activity.faaliyetAdi,
          tarih: _activity.tarih,
          olusturanKullanici: 'admin',
          olusturmaTarihi: '',
        ));
    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((_) =>
              const UserSessionState(username: 'admin', role: UserRole.admin)),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: ActivityCard(
                    activity: _activity, onDateChanged: (_) {})))));
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsNothing);
    await tester.tap(find.byKey(const Key('activity-card-10')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activity-detail-screen')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
