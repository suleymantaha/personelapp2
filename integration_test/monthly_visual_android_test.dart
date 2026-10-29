import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';
import 'helpers/monthly_visual_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('monthly summary, modern day detail and matrix on Android',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await initializeDateFormatting('tr_TR');
    final filter = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');
    await tester.pumpWidget(ProviderScope(
        overrides: [
          teamAnalyticsProvider.overrideWith(
              (ref, selected) => Stream.value(monthlyVisualFixture(selected))),
        ],
        child: MaterialApp(
            theme: AppTheme.darkMilitaryTheme,
            home: TeamAnalyticsScreen(initialFilter: filter, initialTab: 1))));
    await tester.pumpAndSettle();
    expect(find.text('185 kişi'), findsOneWidget);
    expect(find.text('178 kişi'), findsOneWidget);
    expect(find.text('2.407 atama'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('monthly-summary-android');
    final day = find.byKey(const ValueKey('monthly-day-2026-10-09'));
    await Scrollable.ensureVisible(tester.element(day), alignment: .5);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('monthly-chart-android');
    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('monthly-detail-sheet')),
            matching: find.textContaining('148')),
        findsNWidgets(2));
    expect(find.bySemanticsLabel('Toplam görevlendirme: 148 atama'),
        findsOneWidget);
    expect(find.bySemanticsLabel('Görev alan farklı kişi: 148 kişi'),
        findsOneWidget);
    await binding.takeScreenshot('monthly-detail-duties-android');
    await tester.tap(find.byKey(const ValueKey('monthly-detail-tab-teams')));
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('monthly-detail-fixed-header'));
    final headerBefore = tester.getTopLeft(header);
    final metric =
        find.byKey(const ValueKey('monthly-detail-assignment-count'));
    final metricBefore = tester.getTopLeft(metric);
    final listController =
        tester.widget<ListView>(find.byType(ListView).last).controller!;
    final offsetBefore = listController.offset;
    await binding.takeScreenshot('monthly-detail-teams-android');
    await tester.drag(find.byType(ListView).last, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Kapat').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(header), headerBefore);
    expect(tester.getTopLeft(metric), metricBefore);
    expect(listController.offset, greaterThan(offsetBefore));
    expect(metric.hitTestable(), findsOneWidget);
    await binding.takeScreenshot('monthly-detail-teams-scroll-android');
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Tim × görev matrisi'), 400,
        scrollable: find.byType(Scrollable).first);
    await binding.takeScreenshot('monthly-matrix-android');
    expect(tester.takeException(), isNull);
    await Scrollable.ensureVisible(tester.element(day), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();
    semantics.dispose();
  });
}
