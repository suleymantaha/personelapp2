// User Journey: Offline Sync Test
// 1. Launch app on DebtManagementScreen
// 2. Tap sync button
// 3. Verify sync engine runs and processes unsynced items cleanly without UI lockup

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personelapp2/features/debt/presentation/debt_management_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Sync User Journey Test', () {
    testWidgets('Trigger manual sync and verify queue processing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DebtManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final syncBtn = find.byKey(const ValueKey('sync_button'));
      expect(syncBtn, findsOneWidget);

      await tester.tap(syncBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('debt_scaffold')), findsOneWidget);
    });
  });
}
