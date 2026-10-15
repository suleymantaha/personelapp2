import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/analytics/data/team_analytics_repository.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';

const admin = UserSessionState(username: 'admin', role: UserRole.admin);
void main() {
  late AppDatabase db;
  late TeamAnalyticsRepository repo;
  late int team;
  late int person;
  late int second;
  final october = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');

  Future<int> activity(String date, {String name = 'Devriye'}) => db
      .into(db.gunlukFaaliyetTable)
      .insert(GunlukFaaliyetTableCompanion.insert(
        faaliyetAdi: name,
        tarih: date,
        olusturanKullanici: 'admin',
        olusturmaTarihi: date,
      ));
  Future<void> assign(int id, int pid,
      {String duty = 'HEYBET',
      String status = 'onaylandi',
      bool unknown = false}) async {
    await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: id,
            personelId: pid,
            gorevVeyaIzin: duty,
            durum: status,
            gorevTimId: Value(unknown ? null : team),
            gorevTimAdi: Value(unknown ? null : '1-B')));
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TeamAnalyticsRepository(db);
    team = await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: '1-B', olusturmaTarihi: '2026-01-01'));
    Future<int> add(String name) =>
        db.into(db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: 'Er',
            birlik: '',
            timId: Value(team),
            kayitTarihi: '2026-01-01'));
    person = await add('Ali');
    second = await add('Veli');
  });
  tearDown(() => db.close());

  test('same day different duties and people retain independent participation',
      () async {
    final a = await activity('2026-10-02');
    final b = await activity('2026-10-02', name: 'Nöbet');
    await assign(a, person);
    await assign(a, second);
    await assign(b, person, duty: 'NÖBETÇİ');
    final result = await repo.load(october, admin);
    expect(result.metrics.participations, 2);
    expect(result.metrics.dutyDays, 1);
    expect(result.metrics.uniquePersonnel, 2);
    expect(result.metrics.personnelTasks, 3);
    expect(result.metrics.personnelDays, 2);
    expect(result.entries.length, 3);
  });
  test('repeated assignments collapse but distinct activity IDs remain visible',
      () async {
    final a = await activity('2026-10-02');
    final b = await activity('2026-10-02');
    await assign(a, person);
    await assign(a, person);
    await assign(b, person);
    final result = await repo.load(october, admin);
    expect(result.metrics.participations, 2);
    expect(result.metrics.personnelTasks, 2);
    expect(result.metrics.dutyDays, 1);
    expect(result.duplicateAssignments, 1);
    expect(result.possibleDuplicateActivities, 1);
  });
  test('approval slices never mix and leave is excluded', () async {
    final a = await activity('2026-10-02');
    await assign(a, person);
    await assign(a, second, status: 'beklemede');
    await assign(a, person, duty: 'GÖREVLİ', status: 'reddedildi');
    await assign(a, second, duty: 'İZİNLİ');
    expect((await repo.load(october, admin)).metrics.personnelTasks, 1);
    final pending = await repo.load(
        AnalyticsFilter(
            start: october.start, end: october.end, status: 'beklemede'),
        admin);
    expect(pending.metrics.personnelTasks, 1);
    expect(pending.entries.single.personnelId, second);
    final rejected = await repo.load(
        AnalyticsFilter(
            start: october.start, end: october.end, status: 'reddedildi'),
        admin);
    expect(rejected.entries.single.duty, 'GÖREVLİ');
  });
  test('unknown historical team never falls back to current membership',
      () async {
    await assign(await activity('2026-10-02'), person, unknown: true);
    final result = await repo.load(october, admin);
    expect(result.metrics.participations, 0);
    expect(result.unknownTeamAssignments, 1);
    expect(result.unknownEntries.single.personnelId, person);
  });
  test('month continuation adds days without new participation', () async {
    await assign(await activity('2026-09-30'), person, duty: 'HAZIR KITA');
    final result = await repo.load(october, admin);
    expect(result.metrics.participations, 0);
    expect(result.metrics.dutyDays, 1);
    expect(result.metrics.personnelTasks, 0);
    expect(result.metrics.personnelDays, 1);
    expect(result.monthly.single.month, '2026-10');
    expect(result.entries.single.coveredDates, ['2026-10-01']);
  });
  test('inactive personnel retained and demo excluded', () async {
    await (db.update(db.personelTable)..where((p) => p.id.equals(person)))
        .write(const PersonelTableCompanion(aktif: Value(false)));
    await (db.update(db.personelTable)..where((p) => p.id.equals(second)))
        .write(const PersonelTableCompanion(isDemo: Value(true)));
    final a = await activity('2026-10-02');
    await assign(a, person);
    await assign(a, second);
    expect((await repo.load(october, admin)).metrics.uniquePersonnel, 1);
  });
  test('read analysis leaves all table rows unchanged', () async {
    await assign(await activity('2026-10-02'), person);
    Future<List<Object?>> snapshot() async => [
          await db.select(db.personelTable).get(),
          await db.select(db.timTable).get(),
          await db.select(db.faaliyetPersonelAtamaTable).get(),
          await db.select(db.gunlukFaaliyetTable).get(),
          await db.select(db.timUyelikGecmisiTable).get(),
        ];
    final before = await snapshot();
    await repo.load(october, admin);
    expect(await snapshot(), before);
  });
  test('unauthenticated and stale commander team claims fail closed', () async {
    await assign(await activity('2026-10-02'), person);
    expect((await repo.load(october, null)).entries, isEmpty);
    final commander = UserSessionState(
        username: 'missing', role: UserRole.teamCommander, timId: team);
    final result = await repo.load(october, commander);
    expect(result.entries, isEmpty);
    expect(result.unknownTeamAssignments, 0);
  });
  test('valid commander sees only authorized snapshot team and no unknowns',
      () async {
    final uid = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'commander',
            rol: 'tim_komutani',
            timId: Value(team)));
    await (db.update(db.timTable)..where((t) => t.id.equals(team)))
        .write(TimTableCompanion(timKomutaniId: Value(uid)));
    await assign(await activity('2026-10-02'), person);
    await assign(await activity('2026-10-03'), person, unknown: true);
    final other = await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: '2-B', olusturmaTarihi: '2026-01-01'));
    final id = await activity('2026-10-04');
    await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: id,
            personelId: person,
            gorevVeyaIzin: 'HEYBET',
            durum: 'onaylandi',
            gorevTimId: Value(other)));
    final result = await repo.load(
        october,
        UserSessionState(
            username: 'commander', role: UserRole.teamCommander, timId: other));
    expect(result.entries.single.teamId, team);
    expect(result.unknownTeamAssignments, 0);
    expect(result.teams.keys, [team]);
  });
  test('filters combine and monthly trend includes empty months', () async {
    await assign(await activity('2026-10-02'), person);
    final result = await repo.load(
        AnalyticsFilter(
            start: '2026-09-01',
            end: '2026-11-30',
            teamId: team,
            duty: 'HEYBET'),
        admin);
    expect(result.monthly.map((m) => m.metrics.participations), [0, 1, 0]);
    expect(result.forTeam(team).forDuty('HEYBET').metrics.personnelTasks, 1);
    expect(result.forTeam(team).forDuty('NÖBETÇİ').metrics.personnelTasks, 0);
  });
  test('partial month trend does not recount a carried participation',
      () async {
    await assign(await activity('2026-10-01'), person, duty: 'HAZIR KITA');
    final result = await repo.load(
        AnalyticsFilter(start: '2026-10-02', end: '2026-10-05'), admin);
    expect(result.metrics.participations, 0);
    expect(result.monthly.single.metrics.participations, 0);
    expect(result.monthly.single.metrics.dutyDays, 1);
  });
  test('team transfer does not rewrite historical task attribution', () async {
    await assign(await activity('2026-10-02'), person);
    await (db.update(db.personelTable)..where((p) => p.id.equals(person)))
        .write(const PersonelTableCompanion(timId: Value(null)));
    final result = await repo.load(october, admin);
    expect(result.entries.single.teamId, team);
    expect(result.metrics.participations, 1);
  });
  test('duty filter keeps other authorized duty choices available', () async {
    final a = await activity('2026-10-02');
    await assign(a, person);
    await assign(a, second, duty: 'NÖBETÇİ');
    final result = await repo.load(
        AnalyticsFilter(start: october.start, end: october.end, duty: 'HEYBET'),
        admin);
    expect(result.availableDuties, ['HEYBET', 'NÖBETÇİ']);
    expect(result.entries.single.duty, 'HEYBET');
  });
  test('live provider refreshes on assignments and revoked commander authority',
      () async {
    final uid = await db.into(db.kullaniciTable).insert(
        KullaniciTableCompanion.insert(
            kullaniciAdi: 'live', rol: 'tim_komutani', timId: Value(team)));
    await (db.update(db.timTable)..where((t) => t.id.equals(team)))
        .write(TimTableCompanion(timKomutaniId: Value(uid)));
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      userSessionProvider.overrideWith((ref) => UserSessionState(
          username: 'live', role: UserRole.teamCommander, timId: team)),
    ]);
    addTearDown(container.dispose);
    final populated = Completer<void>();
    final revoked = Completer<void>();
    var hasSeenData = false;
    container.listen(teamAnalyticsProvider(october), (previous, next) {
      final data = next.asData?.value;
      if (data == null) return;
      if (data.entries.isNotEmpty) {
        hasSeenData = true;
        if (!populated.isCompleted) populated.complete();
      } else if (hasSeenData && !revoked.isCompleted) {
        revoked.complete();
      }
    });
    expect(
        (await container.read(teamAnalyticsProvider(october).future)).entries,
        isEmpty);
    await assign(await activity('2026-10-02'), person);
    await populated.future.timeout(const Duration(seconds: 5));
    await (db.update(db.timTable)..where((t) => t.id.equals(team)))
        .write(const TimTableCompanion(timKomutaniId: Value(null)));
    await revoked.future.timeout(const Duration(seconds: 5));
    expect(container.read(teamAnalyticsProvider(october)).requireValue.entries,
        isEmpty);
  });
  test('invalid or unbounded dates are rejected', () {
    expect(() => AnalyticsFilter(start: '2026-02-30', end: '2026-03-01'),
        throwsArgumentError);
    expect(() => AnalyticsFilter(start: '2026-10-02', end: '2026-10-01'),
        throwsArgumentError);
    expect(() => AnalyticsFilter(start: '2024-01-01', end: '2026-01-01'),
        throwsArgumentError);
  });
}
