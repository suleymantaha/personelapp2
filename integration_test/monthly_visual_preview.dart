import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/analytics/domain/monthly_analytics_report.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/presentation/monthly_day_detail_sheet.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_provider.dart';
import 'package:personelapp2/features/analytics/presentation/team_analytics_screen.dart';
import 'helpers/monthly_visual_fixture.dart';

/// Interactive synthetic preview, built only in the separate analyticsqa package.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  runApp(ProviderScope(
      overrides: [
        teamAnalyticsProvider.overrideWith(
            (ref, filter) => Stream.value(monthlyVisualFixture(filter))),
      ],
      child: MaterialApp(
          theme: AppTheme.darkMilitaryTheme, home: const _MonthlyPreview())));
}

class _MonthlyPreview extends StatefulWidget {
  const _MonthlyPreview();
  @override
  State<_MonthlyPreview> createState() => _MonthlyPreviewState();
}

class _MonthlyPreviewState extends State<_MonthlyPreview> {
  final filter = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final report = MonthlyAnalyticsReport(
          data: monthlyVisualFixture(filter), asOf: DateTime(2026, 10, 29));
      showMonthlyDayDetail(context, report.days[8]);
    });
  }

  @override
  Widget build(BuildContext context) =>
      TeamAnalyticsScreen(initialFilter: filter, initialTab: 1);
}
