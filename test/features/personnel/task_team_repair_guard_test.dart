import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'task_team_repair_test_support.dart';

void main() {
  testWidgets('session loss after preview prevents file save', (tester) async {
    final h = RepairHarness();
    await h.pump(tester);
    h.container.read(userSessionProvider.notifier).state = null;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('repair-save')), findsNothing);
    expect(h.gateway.saves, 0);
  });

  testWidgets('latest admin actor is passed to apply', (tester) async {
    final h = RepairHarness();
    await h.pump(tester);
    await h.verify(tester);
    const otherAdmin =
        UserSessionState(username: 'other-admin', role: UserRole.admin);
    h.container.read(userSessionProvider.notifier).state = otherAdmin;
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repair-apply')));
    await tester.pumpAndSettle();
    expect(h.service.appliedActor, otherAdmin);
  });

  testWidgets('stale service rejection clears verified backup for retry',
      (tester) async {
    final h = RepairHarness();
    h.service.stale = true;
    await h.pump(tester);
    await h.verify(tester);
    await tester.tap(find.byKey(const Key('repair-apply')));
    await tester.pumpAndSettle();
    expect(find.textContaining('İşlem tamamlanamadı'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('repair-apply')))
            .onPressed,
        isNull);
    expect(h.service.applies, 1);
  });

  testWidgets('busy apply blocks duplicate submit and route dismissal',
      (tester) async {
    final h = RepairHarness();
    h.service.pending = Completer<int>();
    await h.pump(tester);
    await h.verify(tester);
    await tester.tap(find.byKey(const Key('repair-apply')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('repair-apply')));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(h.service.applies, 1);
    expect(find.byKey(const Key('repair-apply')), findsOneWidget);
    h.service.pending!.complete(1);
    await tester.pumpAndSettle();
    expect(find.text('1 kayıt onarıldı.'), findsOneWidget);
  });
}
