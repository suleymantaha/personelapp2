import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/analytics/data/team_analytics_repository.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';
import 'helpers/daily_analytics_fixture.dart';

// Use a dedicated test emulator. With flutter drive, pass --keep-app-running:
// the driver's default shutdown uninstalls the package and removes app data.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('daily teams, duty details and continuation remain read-only',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final team = await seedDailyAnalytics(db);
    const admin = UserSessionState(username: 'test', role: UserRole.admin);
    Future<List<Object?>> snapshot() async => [
          await db.select(db.faaliyetPersonelAtamaTable).get(),
          await db.select(db.gunlukFaaliyetTable).get(),
          await db.select(db.personelTable).get(),
          await db.select(db.timTable).get(),
          await db.select(db.timUyelikGecmisiTable).get(),
        ];
    final before = await snapshot();
    final filter = AnalyticsFilter(start: '2026-10-23', end: '2026-10-23');
    final repository = TeamAnalyticsRepository(db);
    final result = await repository.load(filter, admin);
    expect(result.forTeam(team).metrics.participations, 2);
    expect(result.forTeam(team).metrics.uniquePersonnel, 2);
    expect(result.unknownTeamAssignments, 1);
    final continuation = await repository.load(
        AnalyticsFilter(start: '2026-10-24', end: '2026-10-24'), admin);
    expect(continuation.metrics.participations, 0);
    expect(continuation.metrics.uniquePersonnel, 2);
    expect(continuation.entries.map((e) => e.activityId).toSet(), hasLength(1));

    Future<void> render(AnalyticsFilter selected, ThemeMode mode) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((ref) => admin),
        ],
        child: MaterialApp(
          themeMode: mode,
          theme: AppTheme.militaryTheme,
          darkTheme: AppTheme.darkMilitaryTheme,
          home: TeamAnalyticsScreen(initialFilter: selected),
        ),
      ));
      await tester.pumpAndSettle();
    }

    await render(filter, ThemeMode.dark);
    await tester.tap(find.byKey(const ValueKey('analytics-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analytics-next-day')));
    await tester.pumpAndSettle();
    expect(find.text('24.10.2026'), findsWidgets);
    expect(find.byKey(ValueKey('report-duty-$team-DDE')), findsNothing);
    expect(find.byKey(ValueKey('report-duty-$team-HAZIR KITA')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('analytics-previous-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('analytics-settings-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('report-team-$team')), findsOneWidget);
    expect(find.text('2-B Timi'), findsOneWidget);
    expect(find.text('ÖRNEK PERSONEL A'), findsNothing);
    expect(find.textContaining('2 gün'), findsNothing);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('teams-collapsed');
    await tester.tap(find.byKey(const ValueKey('analytics-settings')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('daily-settings-dark');
    await tester.tap(find.byKey(const ValueKey('analytics-settings-close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('report-team-toggle-$team')));
    await tester.pumpAndSettle();
    final duty = find.byKey(ValueKey('report-duty-$team-HAZIR KITA'));
    await tester.ensureVisible(duty);
    await tester.tap(duty);
    await tester.pumpAndSettle();
    expect(find.text('ÖRNEK PERSONEL A'), findsOneWidget);
    expect(find.text('ÖRNEK PERSONEL B'), findsOneWidget);
    expect(find.textContaining('2 gün'), findsNothing);
    await binding.takeScreenshot('daily-duty-details-dark');
    expect(tester.takeException(), isNull);

    await render(AnalyticsFilter(start: '2026-10-24', end: '2026-10-24'),
        ThemeMode.light);
    expect(find.byKey(ValueKey('report-team-$team')), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('report-team-toggle-$team')));
    await tester.pumpAndSettle();
    final continued = find.byKey(ValueKey('report-duty-$team-HAZIR KITA'));
    await tester.ensureVisible(continued);
    await tester.tap(continued);
    await tester.pumpAndSettle();
    expect(find.textContaining('Önceki günden devam'), findsWidgets);
    expect(find.text('ÖRNEK PERSONEL A'), findsOneWidget);
    expect(find.textContaining('2 gün'), findsNothing);
    await binding.takeScreenshot('continued-duty-light');
    expect(await snapshot(), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();
  });
}
