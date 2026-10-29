import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'task_team_repair_test_support.dart';

void main() {
  testWidgets('non-admin cannot prepare or apply repair', (tester) async {
    final h = RepairHarness();
    await h.pump(tester, actor: commander);
    expect(h.service.prepares, 0);
    expect(find.byKey(const Key('repair-apply')), findsNothing);
    expect(find.textContaining('yönetici'), findsOneWidget);
  });

  testWidgets('zero candidates never offers file save', (tester) async {
    final h = RepairHarness();
    h.service.empty = true;
    await h.pump(tester);
    expect(find.text('Onarılabilecek kayıt yok.'), findsOneWidget);
    expect(find.byKey(const Key('repair-save')), findsNothing);
    expect(h.gateway.saves, 0);
  });

  for (final mode in [
    'cancel-save',
    'fail-save',
    'cancel-open',
    'mismatch',
    'fail-open'
  ]) {
    testWidgets('$mode keeps apply disabled and never writes', (tester) async {
      final h = RepairHarness();
      h.gateway.saveResult = mode != 'cancel-save';
      h.gateway.failSave = mode == 'fail-save';
      h.gateway.failOpen = mode == 'fail-open';
      if (mode == 'cancel-open') h.gateway.reopened = null;
      if (mode == 'mismatch') h.gateway.reopened = 'wrong backup';
      await h.pump(tester);
      await tester.tap(find.byKey(const Key('repair-save')));
      await tester.pumpAndSettle();
      if (mode == 'cancel-open' || mode == 'mismatch' || mode == 'fail-open') {
        await tester.tap(find.byKey(const Key('repair-verify')));
        await tester.pumpAndSettle();
      }
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('repair-apply')))
              .onPressed,
          isNull);
      expect(h.service.applies, 0);
      expect(find.textContaining('private'), findsNothing);
    });
  }

  testWidgets('exact saved backup enables explicit apply', (tester) async {
    final h = RepairHarness();
    await h.pump(tester);
    expect(find.textContaining('11'), findsOneWidget);
    expect(find.textContaining('2026-10-01'), findsOneWidget);
    expect(find.textContaining('Test Tim'), findsOneWidget);
    expect(find.textContaining('Belirsiz: 2'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('repair-apply')))
            .onPressed,
        isNull);
    await h.verify(tester);
    expect(h.service.applies, 0);
    await tester.tap(find.byKey(const Key('repair-apply')));
    await tester.pumpAndSettle();
    expect(h.service.applies, 1);
    expect(h.service.appliedActor, admin);
    expect(find.text('1 kayıt onarıldı.'), findsOneWidget);
  });
}
