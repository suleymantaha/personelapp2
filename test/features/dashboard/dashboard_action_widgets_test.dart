import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_archive_action.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_menu_card.dart';

void main() {
  Widget subject(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return MaterialApp(
      theme: AppTheme.militaryTheme,
      darkTheme: AppTheme.darkMilitaryTheme,
      themeMode: mode,
      home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))),
    );
  }

  testWidgets('menu card exposes one button semantic and invokes tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      subject(
        SizedBox(
          height: 184,
          child: DashboardMenuCard(
            icon: Icons.edit_calendar,
            title: 'Faaliyet Çizelgesi',
            subtitle: 'Günlük görev gir',
            tone: DashboardActionTone.primary,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Faaliyet Çizelgesi, Günlük görev gir'),
      findsOneWidget,
    );
    await tester.tap(find.text('Faaliyet Çizelgesi'));
    expect(taps, 1);
  });

  testWidgets('archive action is horizontal and works in dark mode', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      subject(
        DashboardArchiveAction(
          icon: Icons.inventory_2_outlined,
          title: 'Faaliyet Arşivi',
          subtitle: 'Arama ve İnceleme',
          onTap: () => taps++,
        ),
        mode: ThemeMode.dark,
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Faaliyet Arşivi'));
    expect(taps, 1);
  });
}
