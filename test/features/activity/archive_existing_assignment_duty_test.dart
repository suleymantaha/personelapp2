import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/reassign_existing_personnel_dialog.dart';

void main() {
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  const commander = UserSessionState(
    username: 'commander',
    role: UserRole.teamCommander,
    timId: 1,
  );

  late AppDatabase db;
  late ActivityRepository repository;
  late int firstId;
  late int secondId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = ActivityRepository(db);
    await db.into(db.gunlukFaaliyetTable).insert(
      const GunlukFaaliyetTableData(
        id: 70,
        faaliyetAdi: 'GÖREVLİ',
        tarih: '2026-10-15',
        olusturanKullanici: 'admin',
        olusturmaTarihi: '',
      ),
    );
    final person1 = await db.into(db.personelTable).insert(
      PersonelTableCompanion.insert(
        adSoyad: 'Muhammet GÜRDEN',
        rutbe: 'J.Asb.Çvş.',
        birlik: 'K.H',
        kayitTarihi: '2026-10-15',
      ),
    );
    final person2 = await db.into(db.personelTable).insert(
      PersonelTableCompanion.insert(
        adSoyad: 'Gökhan ÖZER',
        rutbe: 'J.Uzm.Çvş.',
        birlik: 'K.H',
        kayitTarihi: '2026-10-15',
      ),
    );
    firstId = await db.into(db.faaliyetPersonelAtamaTable).insert(
      FaaliyetPersonelAtamaTableCompanion.insert(
        faaliyetId: 70,
        personelId: person1,
        gorevVeyaIzin: DutyOrLeaveType.gorevli,
        durum: AssignmentStatus.onaylandi,
        aciklama: const Value('Önceden yazılmış not'),
      ),
    );
    secondId = await db.into(db.faaliyetPersonelAtamaTable).insert(
      FaaliyetPersonelAtamaTableCompanion.insert(
        faaliyetId: 70,
        personelId: person2,
        gorevVeyaIzin: DutyOrLeaveType.gorevli,
        durum: AssignmentStatus.onaylandi,
      ),
    );
  });

  tearDown(() async => db.close());

  test('updates existing rows without inserting duplicates or deleting notes', () async {
    final targetDuty = DutyOrLeaveType.dutiesForRole(isAdmin: true)
        .firstWhere((duty) => duty != DutyOrLeaveType.gorevli);
    final changed = await repository.updateExistingAssignmentDuties(
      activityId: 70,
      assignmentIds: [firstId, secondId],
      duty: targetDuty,
      actor: admin,
    );

    expect(changed, 2);
    final rows = await db.select(db.faaliyetPersonelAtamaTable).get();
    expect(rows.length, 2);
    expect(rows.map((row) => row.id).toSet(), {firstId, secondId});
    expect(rows.every((row) => row.gorevVeyaIzin == targetDuty), isTrue);
    expect(rows.every((row) => row.durum == AssignmentStatus.onaylandi), isTrue);
    expect(rows.firstWhere((row) => row.id == firstId).aciklama,
        'Önceden yazılmış not');

    // Idempotent edits preserve the original assignment instead of duplicating it.
    final unchanged = await repository.updateExistingAssignmentDuties(
      activityId: 70,
      assignmentIds: [firstId, secondId],
      duty: targetDuty,
      actor: admin,
    );
    expect(unchanged, 0);
    expect((await db.select(db.faaliyetPersonelAtamaTable).get()).length, 2);
  });

  test('stale selection aborts whole batch without modifying valid rows', () async {
    final targetDuty = DutyOrLeaveType.dutiesForRole(isAdmin: true)
        .firstWhere((duty) => duty != DutyOrLeaveType.gorevli);
    await expectLater(
      repository.updateExistingAssignmentDuties(
        activityId: 70,
        assignmentIds: [firstId, 999999],
        duty: targetDuty,
        actor: admin,
      ),
      throwsA(isA<StateError>()),
    );
    final row = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where((tbl) => tbl.id.equals(firstId)))
        .getSingle();
    expect(row.gorevVeyaIzin, DutyOrLeaveType.gorevli);
  });

  test('non-admin cannot bulk change assignments', () async {
    final duty = DutyOrLeaveType.dutiesForRole(isAdmin: true)
        .firstWhere((item) => item != DutyOrLeaveType.gorevli);
    expect(
      () => repository.updateExistingAssignmentDuties(
        activityId: 70,
        assignmentIds: [firstId],
        duty: duty,
        actor: commander,
      ),
      throwsA(isA<AuthorizationException>()),
    );
  });

  testWidgets('existing assignments can be selected without creating personnel', (tester) async {
    final activity = await (db.select(db.gunlukFaaliyetTable)
          ..where((tbl) => tbl.id.equals(70)))
        .getSingle();
    final assignments = await db.select(db.faaliyetPersonelAtamaTable).get();
    final personnel = await db.select(db.personelTable).get();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReassignExistingPersonnelDialog(
            activity: activity,
            assignments: assignments,
            personnelById: {for (final row in personnel) row.id: row},
          ),
        ),
      ),
    );

    expect(find.text('0 / 2 personel seçildi'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('archive-existing-save'))).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('archive-existing-select-all')));
    await tester.pump();
    expect(find.text('2 / 2 personel seçildi'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('archive-existing-save'))).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('archive-existing-select-all')));
    await tester.pump();
    expect(find.text('0 / 2 personel seçildi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
