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
  late int person;
  List<PersonnelAssignmentInput>? result;
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('admin', 'synthetic-test-hash', 'yönetici')");
    final team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Current team', olusturmaTarihi: '2000-01-01'));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(team)));
    result = null;
  });
  tearDown(() => db.close());
  Future<void> open(WidgetTester tester, {String date = '2001-01-02'}) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await confirmTaskTeams(
                          context: context,
                          repository: ActivityRepository(db),
                          date: date,
                          actor: admin,
                          assignments: [
                            PersonnelAssignmentInput(
                                personnelId: person, duty: 'GÖREVLİ')
                          ]);
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  for (final daysAhead in [0, 1, 365]) {
    testWidgets('assigned team needs no confirmation $daysAhead days ahead',
        (tester) async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day + daysAhead)
          .toIso8601String()
          .split('T')
          .first;
      await open(tester, date: date);
      expect(find.byType(AlertDialog), findsNothing);
      expect(result, hasLength(1));
      expect(result!.single.personnelId, person);
      // Automatic resolution must still be rechecked when writing the record.
      expect(result!.single.teamId, isNull);
      expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
    });
  }

  testWidgets('known past team needs no confirmation', (tester) async {
    final team = await db.select(db.timTable).getSingle();
    await db.into(db.timUyelikGecmisiTable).insert(
        TimUyelikGecmisiTableCompanion.insert(
            personelId: person,
            timId: Value(team.id),
            tarih: '2000-01-01',
            islem: 'eklendi'));
    await open(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(result, hasLength(1));
  });

  testWidgets('missing dated team starts unselected and cancel writes nothing',
      (tester) async {
    await open(tester);
    expect(find.text('Görev tarihindeki timi doğrula'), findsOneWidget);
    final button = tester
        .widget<FilledButton>(find.byKey(const ValueKey('task-team-confirm')));
    expect(button.onPressed, isNull);
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
  });
  testWidgets('explicit outside confirmation returns choice without writing DB',
      (tester) async {
    await open(tester);
    await tester.tap(find.byKey(ValueKey('task-team-choice-$person')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tim dışı').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-team-confirm')));
    await tester.pumpAndSettle();
    expect(result!.single.isOutsideTeam, isTrue);
    expect(result!.single.teamId, isNull);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
  });
}
