import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';
import 'package:personelapp2/features/activity/services/heybet_roster_projection.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

void main() {
  late AppDatabase db;
  late HeybetRosterProjection projection;
  late Map<int, PersonelTableData> personnel;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    projection = HeybetRosterProjection(db);
    for (var i = 1; i <= 6; i++) {
      await db.into(db.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: 'Personel $i',
              rutbe: 'J.Uzm.Çvş.',
              birlik: 'Kullanıcının birlik metni',
              kayitTarihi: '',
            ),
          );
    }
    personnel = {
      for (final p in await db.select(db.personelTable).get()) p.id: p,
    };
  });
  tearDown(() => db.close());

  Future<GunlukFaaliyetTableData> activity(String name, String date) async {
    final id = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: name,
            tarih: date,
            olusturanKullanici: 'admin',
            olusturmaTarihi: date,
          ),
        );
    return (db.select(
      db.gunlukFaaliyetTable,
    )..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> assign(
    int activityId,
    int personId,
    String duty, {
    String status = 'onaylandi',
    String? note,
  }) async {
    await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activityId,
            personelId: personId,
            gorevVeyaIzin: duty,
            durum: status,
            aciklama: Value(note),
          ),
        );
  }

  final original = MilitaryRosterRow(
    sNu: 1,
    birligi: '6-B Timi',
    rutbe: '',
    adSoyad: 'Bugünün Heybeti',
    diger: '',
  );

  test(
    'appends only previous calendar day approved ready force and guard rows',
    () async {
      final previous = await activity('Hazır Kıta', '2026-12-31');
      final target = await activity('Heybet', '2027-01-01');
      final older = await activity('Hazır Kıta', '2026-12-30');
      await assign(previous.id, 1, 'HAZIR KITA', note: 'Verilen metin');
      await assign(previous.id, 2, 'NÖB. SB.', note: 'Nöbet notu');
      await assign(previous.id, 3, 'GÜLÜŞKÜR');
      await assign(previous.id, 4, 'MEBS NÖB.', status: 'beklemede');
      await assign(previous.id, 5, 'GARAJ NÖB.', status: 'reddedildi');
      await assign(older.id, 6, 'HAZIR KITA');
      final before = await db.select(db.faaliyetPersonelAtamaTable).get();
      final activitiesBefore = await db.select(db.gunlukFaaliyetTable).get();
      for (var repeat = 0; repeat < 2; repeat++) {
        final rows = await projection.appendPreviousDay(
          activities: [target],
          rows: [original],
          personnelById: personnel,
          squadNames: {},
        );
        expect(rows.map((r) => r.adSoyad), [
          'Bugünün Heybeti',
          'Personel 2',
          'Personel 1',
        ]);
        expect(rows.map((r) => r.sNu), [1, 2, 3]);
        expect(
          rows.skip(1).map((r) => r.birligi),
          everyElement('J.Komd.Öz.Hrk.Tb.Klığı'),
        );
        expect(rows.skip(1).map((r) => r.diger), ['', '']);
        expect(
          rows.skip(1).map((r) => r.sourceDate),
          everyElement('2026-12-31'),
        );
        expect(rows.skip(1).every((r) => r.sourceAssignmentId != null), isTrue);
      }
      expect(await db.select(db.faaliyetPersonelAtamaTable).get(), before);
      expect(await db.select(db.gunlukFaaliyetTable).get(), activitiesBefore);
      final matrix =
          await MatrixRepository(db).watchMonthlyMatrix('2027-01').first;
      expect(matrix[1]?[1]?.displayCode, 'X');
      expect(matrix[1]?[1]?.entries, hasLength(1));
      expect(matrix[1]?[1]?.entries.single.sourceDate, '2026-12-31');
      expect(matrix[1]?[1]?.entries.single.isContinuationDay, isTrue);
      expect(matrix[1]?[2], isNull);
      expect(
        DutyCoverage.coveredDates(startDate: '2026-12-31', duty: 'HAZIR KITA'),
        ['2026-12-31', '2027-01-01'],
      );
    },
  );

  test(
      'other activities stay unchanged; personnel visibility applies to carryover',
      () async {
    final previous = await activity('Hazır Kıta', '2026-08-01');
    await assign(previous.id, 1, 'HAZIR KITA');
    final other = await activity('Devriye', '2026-08-02');
    expect(
      await projection.appendPreviousDay(
        activities: [other],
        rows: [original],
        personnelById: personnel,
        squadNames: {},
      ),
      [original],
    );
    final target = await activity('Heybet Tepe', '2026-08-02');
    expect(
      await projection.appendPreviousDay(
        activities: [target],
        rows: [original],
        personnelById: {},
        squadNames: {},
      ),
      [original],
    );
    final rows = await projection.appendPreviousDay(
      activities: [target, target],
      rows: [original],
      personnelById: personnel,
      squadNames: {},
    );
    expect(rows, hasLength(2));
    expect(rows.last.diger, '');
    final repeated = await projection.appendPreviousDay(
      activities: [target],
      rows: rows,
      personnelById: personnel,
      squadNames: {},
    );
    expect(repeated, rows);
  });
  test('mixed-date export does not append a source activity already selected',
      () async {
    final previous = await activity('Hazır Kıta', '2026-08-01');
    final target = await activity('Heybet', '2026-08-02');
    await assign(previous.id, 1, 'HAZIR KITA');
    final rows = await projection.appendPreviousDay(
        activities: [previous, target],
        rows: [original],
        personnelById: personnel,
        squadNames: {});
    expect(rows, [original]);
  });
}
