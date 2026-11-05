import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/task_team_confirmation.dart';

void main() {
  late AppDatabase db;
  late int team;
  late int otherTeam;
  final people = <int>[];
  List<PersonnelAssignmentInput>? result;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    people.clear();
    result = null;
    team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Test Timi', olusturmaTarihi: '2000-01-01'));
    otherTeam = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Diğer Tim', olusturmaTarihi: '2000-01-01'));
    await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(kullaniciAdi: 'admin', rol: 'yönetici'));
    final commander = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'commander',
            rol: 'tim_komutani',
            timId: Value(team)));
    await (db.update(db.timTable)..where((t) => t.id.equals(team)))
        .write(TimTableCompanion(timKomutaniId: Value(commander)));
    for (final name in ['Ali DENEME', 'Mehmet TEST']) {
      people.add(await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: name,
              rutbe: 'J.Er',
              birlik: 'Test',
              timId: Value(team),
              kayitTarihi: '2000-01-01')));
    }
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester,
      {bool admin = true, bool secondTeamKnown = false}) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      result = await confirmTaskTeams(
                          context: context,
                          repository: ActivityRepository(db),
                          date: '2001-01-02',
                          assignments: [
                            for (final id in people)
                              PersonnelAssignmentInput(
                                  personnelId: id,
                                  duty: 'METİ',
                                  teamId: secondTeamKnown && id == people.last
                                      ? otherTeam
                                      : null)
                          ],
                          actor: UserSessionState(
                              username: admin ? 'admin' : 'commander',
                              role: admin
                                  ? UserRole.admin
                                  : UserRole.teamCommander,
                              timId: admin ? null : team));
                    },
                    child: const Text('Aç'))))));
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'one bulk choice confirms all missing teams without changing membership',
      (tester) async {
    await open(tester);
    expect(find.textContaining('doğrulanamadı'), findsOneWidget);
    final common = find.byKey(const Key('task-team-common-choice'));
    await tester.tap(common);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Timi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-team-apply-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-team-confirm')));
    await tester.pumpAndSettle();
    expect(result, hasLength(2));
    expect(result!.map((a) => a.teamId), everyElement(team));
    expect((await db.select(db.personelTable).get()).map((p) => p.timId),
        everyElement(team));
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
    expect(await db.select(db.timUyelikGecmisiTable).get(), isEmpty);
  });

  testWidgets('bulk choice never overwrites an already explicit assignment',
      (tester) async {
    await open(tester, secondTeamKnown: true);
    expect(
        find.byKey(ValueKey('task-team-choice-${people.last}')), findsNothing);
    await tester.tap(find.byKey(const Key('task-team-common-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Timi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-team-apply-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-team-confirm')));
    await tester.pumpAndSettle();
    expect(result!.first.teamId, team);
    expect(result!.last.teamId, otherTeam);
  });

  testWidgets(
      'commander bulk chooser exposes only own team and no outside option',
      (tester) async {
    await open(tester, admin: false);
    final dropdown = tester.widget<DropdownButtonFormField<int>>(
        find.byKey(const Key('task-team-common-choice')));
    // Open the actual menu: forbidden team labels must not be available.
    expect(dropdown.enabled, isTrue);
    await tester.tap(find.byKey(const Key('task-team-common-choice')));
    await tester.pumpAndSettle();
    expect(find.text('Test Timi'), findsOneWidget);
    expect(find.text('Diğer Tim'), findsNothing);
    expect(find.text('Tim dışı'), findsNothing);
    await tester.tap(find.text('Test Timi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
