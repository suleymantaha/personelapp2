import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_settings.dart';
import 'task_team_repair_test_support.dart';

void main() {
  for (final actor in [admin, commander]) {
    testWidgets('settings entry follows current ${actor.role.name} session',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [userSessionProvider.overrideWith((ref) => actor)],
        child: MaterialApp(
            home: Scaffold(
                body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => DashboardSettings.showSettingsBottomSheet(
                context, ref, 'test-user', true),
            child: const Text('settings'),
          ),
        ))),
      ));
      await tester.tap(find.text('settings'));
      await tester.pumpAndSettle();
      expect(find.text('Görev timi geçmişini onar'),
          actor.isAdmin ? findsOneWidget : findsNothing);
    });
  }

  for (final width in [320.0, 800.0]) {
    testWidgets('repair preview fits ${width.toInt()} px', (tester) async {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = RepairHarness();
      await h.pump(tester);
      await tester.ensureVisible(find.byKey(const Key('repair-save')));
      await tester.tap(find.byKey(const Key('repair-save')));
      await tester.pumpAndSettle();
      expect(h.gateway.saves, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
