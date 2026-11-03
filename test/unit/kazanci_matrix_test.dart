import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

void main() {
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  late AppDatabase db;
  late ActivityRepository activities;
  late MatrixRepository matrix;
  late int personId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('admin', 'synthetic-test-hash', 'yönetici')");
    activities = ActivityRepository(db);
    matrix = MatrixRepository(db);
    personId = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Sentetik PERSONEL',
            rutbe: 'J.Uzm.Çvş.',
            birlik: 'KH',
            kayitTarihi: '2026-01-01'));
  });
  tearDown(() async => db.close());

  Future<void> assign(String date, String duty) async {
    await activities.createActivityWithAssignments(
        faaliyetAdi: duty,
        tarih: date,
        olusturanKullanici: 'admin',
        actor: admin,
        personnelAssignments: [
          PersonnelAssignmentInput(
              isOutsideTeam: true, personnelId: personId, duty: duty)
        ]);
  }

  test('Kazancı tek kayıtla 3 ve 4 Kasımda X gösterir ve ayrıntı korunur',
      () async {
    await assign('2026-11-03', 'KAZANCI');
    final days = (await matrix.watchMonthlyMatrix('2026-11').first)[personId]!;
    expect(days.keys, unorderedEquals([3, 4]));
    expect(days[3]!.displayCode, 'X');
    expect(days[4]!.displayCode, 'X');
    expect(days[4]!.entries.single.duty, 'KAZANCI');
    expect(days[4]!.entries.single.isContinuationDay, isTrue);
    expect(
        days[4]!.entries.single.activityId, days[3]!.entries.single.activityId);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
  });

  test('Onay bekleyen Kazancı iki günde B olarak kalır', () async {
    await assign('2026-11-03', 'KAZANCI');
    await db.update(db.faaliyetPersonelAtamaTable).write(
        const FaaliyetPersonelAtamaTableCompanion(durum: Value('beklemede')));
    final days = (await matrix.watchMonthlyMatrix('2026-11').first)[personId]!;
    expect(days[3]!.displayCode, 'B');
    expect(days[4]!.displayCode, 'B');
    expect(days[5], isNull);
  });

  test('Kazancı yıl sonunda sonraki ayın ilk gününde X gösterir', () async {
    await assign('2026-12-31', 'KAZANCI');
    final december = await matrix.watchMonthlyMatrix('2026-12').first;
    final january = await matrix.watchMonthlyMatrix('2027-01').first;
    expect(december[personId]?[31]?.displayCode, 'X');
    expect(january[personId]?[1]?.displayCode, 'X');
    expect(january[personId]?[1]?.entries.single.sourceDate, '2026-12-31');
    expect(january[personId]?[2], isNull);
  });

  test('Kazancı ikinci gününe çakışan yeni atama yazılmaz', () async {
    await assign('2026-11-03', 'KAZANCI');
    await assign('2026-11-04', 'METİ');
    final days = (await matrix.watchMonthlyMatrix('2026-11').first)[personId]!;
    expect(days[4]!.displayCode, 'X');
    expect(days[4]!.entries, hasLength(1));
    expect(days[4]!.entries.single.duty, 'KAZANCI');
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
    expect(
        (await activities
            .getDailyReservationDescriptions('2026-11-04'))[personId],
        contains('KAZANCI'));
  });
}
